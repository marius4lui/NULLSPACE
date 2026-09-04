#!/usr/bin/env python3
"""Private native X11 teardown diagnostic, not game/rendering-quality content.

Escape or the visible Quit area destroys this fixture's window before a short
delayed process exit. It records real private-server key release during that
gap and deliberately leaves stdout buffered until normal process shutdown.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import sys
import time

from Xlib import X, XK, display


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--delay", type=float, default=0.4)
    parser.add_argument("--exit-code", type=int, default=0)
    parser.add_argument("--foreign-after-destroy", action="store_true")
    args = parser.parse_args()
    if not 0.2 <= args.delay <= 10 or not 0 <= args.exit_code <= 255:
        parser.error("Delay must be 0.2–10 seconds and exit code 0–255")
    directory = Path(os.environ["NULLSPACE_QA_RUN_DIR"])
    manifest = json.loads((directory / "state.json").read_text())
    if (os.environ.get("DISPLAY") != manifest.get("display")
        or manifest.get("compositor", {}).get("host_parent_display") is not None
        or "compositor" not in manifest):
        raise RuntimeError("This fixture may only run inside the owned inputless supervisor")
    connection = display.Display()
    root = connection.screen().root
    window = root.create_window(0, 0, 1920, 1080, 0, X.CopyFromParent, X.InputOutput,
        X.CopyFromParent, background_pixel=0x123044,
        event_mask=X.ExposureMask | X.KeyPressMask | X.KeyReleaseMask | X.ButtonPressMask)
    pid_atom = connection.intern_atom("_NET_WM_PID")
    cardinal_atom = connection.intern_atom("CARDINAL")
    window.change_property(pid_atom, cardinal_atom, 32, [os.getpid()])
    window.set_wm_name("NULLSPACE QA-007 owned-window exit diagnostic")
    window.map()
    connection.sync()
    gc = window.create_gc(foreground=0xf0efdf, background=0x123044)
    journal = (directory / "exit-fixture-events.jsonl").open("a", encoding="utf-8")

    def record(kind: str, **values: object) -> None:
        journal.write(json.dumps({"event": kind, "monotonic": time.monotonic(),
            "utc_unix": time.time(), **values}, sort_keys=True) + "\n")
        journal.flush()

    record("ready", window_id=window.id, pid=os.getpid(), delay=args.delay, exit_code=args.exit_code)
    quitting = False
    while not quitting:
        event = connection.next_event()
        if event.type == X.Expose:
            window.draw_text(gc, 80, 90, "QA-007: verified private native window teardown")
            window.draw_text(gc, 80, 130, "Escape or click Quit; actual XTEST controls only")
            window.rectangle(gc, 80, 190, 340, 110)
            window.draw_text(gc, 210, 250, "Quit")
            connection.flush()
        elif event.type in (X.KeyPress, X.KeyRelease):
            record("key", keycode=event.detail, pressed=event.type == X.KeyPress)
            if event.type == X.KeyPress and connection.keycode_to_keysym(event.detail, 0) == XK.XK_Escape:
                quitting = True
        elif event.type == X.ButtonPress and 80 <= event.event_x <= 420 and 190 <= event.event_y <= 300:
            record("quit_click", button=event.detail)
            quitting = True
    window.destroy()
    connection.sync()
    destroyed = time.monotonic()
    record("window_destroyed", window_id=window.id)
    print("QA_EXIT_BUFFERED_NATURAL_SHUTDOWN", args.exit_code)
    foreign = None
    while time.monotonic() - destroyed < args.delay:
        if args.foreign_after_destroy and foreign is None and time.monotonic() - destroyed >= 0.12:
            foreign = root.create_window(0, 0, 300, 200, 0, X.CopyFromParent, X.InputOutput,
                X.CopyFromParent, background_pixel=0xaa2030)
            foreign.change_property(pid_atom, cardinal_atom, 32, [os.getpid() + 1])
            foreign.map()
            connection.sync()
            record("foreign_window_mapped", window_id=foreign.id)
        bitmap = connection.query_keymap()
        pressed = [code for code in range(8, 256) if bitmap[code // 8] & (1 << (code % 8))]
        record("after_destroy_keymap", pressed_keycodes=pressed)
        time.sleep(0.025)
    record("exiting", exit_code=args.exit_code)
    journal.close()
    connection.close()
    return args.exit_code


if __name__ == "__main__":
    sys.exit(main())
