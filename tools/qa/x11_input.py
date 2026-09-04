"""XTEST control confined to one authenticated, owned X11 window."""
from __future__ import annotations

import os
import math
import time
import threading
from functools import wraps
from collections.abc import Callable
from typing import Any

import Xlib.threaded
from Xlib import X, XK, display
from Xlib.ext import xtest


def locked(method: Callable[..., Any]) -> Callable[..., Any]:
    @wraps(method)
    def call(self: Any, *args: Any, **kwargs: Any) -> Any:
        with self.lock:
            return method(self, *args, **kwargs)
    return call


class GameWindow:
    def __init__(self, display_name: str, authority: str, game_pid: int) -> None:
        self.lock = threading.RLock()
        self.cancel = threading.Event()
        # This changes only the supervisor's environment, never the login session.
        os.environ["XAUTHORITY"] = authority
        self.connection = display.Display(display_name)
        if not self.connection.has_extension("XTEST"):
            raise RuntimeError("Private X server does not expose XTEST")
        self.root = self.connection.screen().root
        self.pid_atom = self.connection.intern_atom("_NET_WM_PID")
        self.game_pid = game_pid
        self.window: Any = None
        self.keys: dict[int, str] = {}
        self.buttons: set[int] = set()
        self.release_deadline = 0.0

    def _pid(self, window: Any) -> int | None:
        prop = window.get_full_property(self.pid_atom, X.AnyPropertyType)
        return int(prop.value[0]) if prop is not None and len(prop.value) else None

    @locked
    def discover(self) -> bool:
        candidates = []
        for window in self.root.query_tree().children:
            if self._pid(window) == self.game_pid:
                attr = window.get_attributes()
                geo = window.get_geometry()
                if attr.map_state == X.IsViewable and geo.width > 32 and geo.height > 32:
                    candidates.append((geo.width * geo.height, window))
        if not candidates:
            return False
        self.window = max(candidates, key=lambda item: item[0])[1]
        return True

    @locked
    def ensure_owned(self) -> None:
        if self.window is None or self._pid(self.window) != self.game_pid:
            raise RuntimeError("Capture/input target no longer belongs to the launched process")
        if self.window.get_attributes().map_state != X.IsViewable:
            raise RuntimeError("Owned game window is not viewable")
        foreign = []
        for window in self.root.query_tree().children:
            if window.get_attributes().map_state == X.IsViewable:
                if self._pid(window) != self.game_pid:
                    foreign.append(window.id)
        if foreign:
            raise RuntimeError(f"Unexpected mapped windows on private display: {foreign}")

    @locked
    def focus(self) -> dict[str, Any]:
        self.ensure_owned()
        self.window.configure(stack_mode=X.Above)
        self.window.set_input_focus(X.RevertToParent, X.CurrentTime)
        self.connection.sync()
        state = self.status()
        if not state["focused"]:
            raise RuntimeError("The owned game window did not acquire X11 input focus")
        return state

    @locked
    def blur(self) -> dict[str, Any]:
        """Move X11 focus to this private root, never to a host desktop window."""
        self.ensure_owned()
        self.release()
        self.root.set_input_focus(X.RevertToNone, X.CurrentTime)
        self.connection.sync()
        return self.status()

    @locked
    def status(self) -> dict[str, Any]:
        self.ensure_owned()
        geo = self.window.get_geometry()
        pointer = self.window.query_pointer()
        focus = self.connection.get_input_focus().focus
        focus_id = focus.id if hasattr(focus, "id") else int(focus)
        return {
            "window_id": self.window.id,
            "window_pid": self._pid(self.window),
            "title": self.window.get_wm_name(),
            "width": geo.width,
            "height": geo.height,
            "focused": focus_id == self.window.id,
            "focus_window_id": focus_id,
            "held_keys": sorted(self.keys.values()),
            "held_buttons": sorted(self.buttons),
            "pointer": [pointer.win_x, pointer.win_y],
        }

    def _keycode(self, name: str) -> int:
        sym = XK.string_to_keysym(name)
        if not sym and len(name) == 1:
            sym = ord(name)
        code = self.connection.keysym_to_keycode(sym)
        if not code:
            raise ValueError(f"Unknown X11 key name: {name}")
        return code

    def apply(self, request: dict[str, Any]) -> dict[str, Any]:
        taps, clicks, hold = self._begin_input(request)
        # Deliberately outside the X/key-state lock. The safety thread enforces
        # lease/focus/device policy throughout a hold, capture, or stalled IPC.
        if hold or taps or clicks:
            self.cancel.wait(max(hold, 0.08))
        return self._end_input(taps, clicks, bool(request.get("release", False)))

    @locked
    def _begin_input(self, request: dict[str, Any]) -> tuple[list[tuple[int, str]], list[int], float]:
        self.focus()
        # Validate the complete command before changing any key state.
        down = [(self._keycode(name), name) for name in request.get("key_down", [])]
        up = [(self._keycode(name), name) for name in request.get("key_up", [])]
        taps = [(self._keycode(name), name) for name in request.get("tap", [])]
        button_down = [int(value) for value in request.get("button_down", [])]
        button_up = [int(value) for value in request.get("button_up", [])]
        clicks = [int(value) for value in request.get("click", [])]
        if any(value < 1 or value > 9 for value in button_down + button_up + clicks):
            raise ValueError("X11 mouse button must be between 1 and 9")
        move = request.get("move", [0, 0])
        if len(move) != 2 or any(abs(int(value)) > 16000 for value in move):
            raise ValueError("Relative motion must have two signed deltas <= 16000")
        pointer = request.get("pointer")
        if pointer is not None:
            geometry = self.window.get_geometry()
            if len(pointer) != 2 or not 0 <= int(pointer[0]) < geometry.width or not 0 <= int(pointer[1]) < geometry.height:
                raise ValueError("Absolute pointer must remain inside the owned game window")
        hold = float(request.get("hold", 0.0))
        lease = float(request.get("lease", 10.0))
        if not math.isfinite(hold) or not math.isfinite(lease) or not 0.0 <= hold <= 10.0 or not 0.1 <= lease <= 30.0:
            raise ValueError("Hold must be 0–10 seconds; lease must be 0.1–30 seconds")
        if pointer is not None:
            xtest.fake_input(self.connection, X.MotionNotify, detail=0,
                             x=geometry.x + int(pointer[0]), y=geometry.y + int(pointer[1]))
            self.connection.sync()
        for code, _ in up:
            xtest.fake_input(self.connection, X.KeyRelease, code)
            self.keys.pop(code, None)
        for button in button_up:
            xtest.fake_input(self.connection, X.ButtonRelease, button)
            self.buttons.discard(button)
        for code, name in down + taps:
            if code not in self.keys:
                xtest.fake_input(self.connection, X.KeyPress, code)
            self.keys[code] = name
        for button in button_down + clicks:
            if button not in self.buttons:
                xtest.fake_input(self.connection, X.ButtonPress, button)
            self.buttons.add(button)
        self.connection.sync()
        # XTEST MotionNotify detail=1 means relative device motion. This is not
        # SendEvent and is not a Godot Input.action_press shortcut.
        if move != [0, 0]:
            xtest.fake_input(self.connection, X.MotionNotify, detail=1,
                             x=int(move[0]), y=int(move[1]))
        self.connection.sync()
        self.release_deadline = time.monotonic() + lease
        return taps, clicks, hold

    @locked
    def _end_input(self, taps: list[tuple[int, str]], clicks: list[int], release: bool) -> dict[str, Any]:
        for code, _ in taps:
            xtest.fake_input(self.connection, X.KeyRelease, code)
            self.keys.pop(code, None)
        for button in clicks:
            xtest.fake_input(self.connection, X.ButtonRelease, button)
            self.buttons.discard(button)
        self.connection.sync()
        if release:
            self.release()
        return self.status()

    @locked
    def release(self) -> None:
        # Release even if focus/ownership checks fail: this connection reaches
        # only the private X server, and must never leave a stuck key there.
        for code in tuple(self.keys):
            xtest.fake_input(self.connection, X.KeyRelease, code)
        for button in tuple(self.buttons):
            xtest.fake_input(self.connection, X.ButtonRelease, button)
        self.keys.clear()
        self.buttons.clear()
        self.connection.sync()

    @locked
    def release_all_private(self) -> None:
        """Recovery after supervisor death: query pressed keys on this server only."""
        self.ensure_owned()
        bitmap = self.connection.query_keymap()
        for code in range(8, 256):
            if bitmap[code // 8] & (1 << (code % 8)):
                xtest.fake_input(self.connection, X.KeyRelease, code)
        for button in range(1, 10):
            xtest.fake_input(self.connection, X.ButtonRelease, button)
        self.keys.clear()
        self.buttons.clear()
        self.connection.sync()

    @locked
    def watchdog(self) -> bool:
        if (self.keys or self.buttons) and time.monotonic() >= self.release_deadline:
            self.release()
            return True
        return False

    @locked
    def safety_tick(self) -> str | None:
        if self.watchdog():
            return "key_lease_expired_all_released"
        if (self.keys or self.buttons) and not self.status()["focused"]:
            self.release()
            return "focus_lost_all_keys_released"
        return None

    @locked
    def close(self) -> None:
        try:
            self.release()
        finally:
            self.connection.close()
