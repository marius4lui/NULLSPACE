"""Fast isolation-safety regressions; fake X window, real IPC/thread loops.

These checks cannot replace the recorded native fixture proof.
"""
from __future__ import annotations

from pathlib import Path
import socket
import sys
import tempfile
import threading
import time
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from native_session import NativeSession
from x11_input import GameWindow


class Window(GameWindow):
    def __init__(self) -> None:
        self.lock = threading.RLock()
        self.cancel = threading.Event()
        self.keys = {25: "w"}
        self.buttons: set[int] = set()
        self.release_deadline = time.monotonic() + 0.2
        self.released_at: float | None = None
        self.focused = True

    def release(self) -> None:
        with self.lock:
            if self.keys and self.released_at is None:
                self.released_at = time.monotonic()
            self.keys.clear()
            self.buttons.clear()

    def status(self) -> dict:
        return {"focused": self.focused, "held_keys": list(self.keys.values())}


class Seat:
    def audit(self) -> dict:
        return {"test_double": True}


class Process:
    def poll(self) -> None:
        return None


class SafetyTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="nullspace-qa-ipc-test-")
        self.address = str(Path(self.temporary.name) / "control.sock")
        self.server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.server.bind(self.address)
        self.server.listen(4)
        self.server.settimeout(0.05)
        self.session = NativeSession.__new__(NativeSession)
        session = self.session
        session.server = self.server
        session.window = Window()
        session.seat = Seat()
        session.processes = {"game": Process()}
        session.recording = None
        session.stop_requested = False
        session.safety_error = None
        session.safety_stop = threading.Event()
        session.state = {"status": "ready"}
        session.directory = Path(self.temporary.name)
        session.env = {}
        self.events: list[dict] = []
        self.exceptions: list[Exception] = []
        session.event = lambda kind, **values: self.events.append({"event": kind, **values})
        session.save = lambda: None
        self.safety = threading.Thread(target=session.safety_loop)
        def serve() -> None:
            try:
                session.serve()
            except Exception as error:
                self.exceptions.append(error)
        self.service = threading.Thread(target=serve)
        self.safety.start()
        self.service.start()

    def tearDown(self) -> None:
        self.session.stop_requested = True
        self.session.window.cancel.set()
        self.service.join(2)
        self.session.safety_stop.set()
        self.safety.join(2)
        self.server.close()
        self.temporary.cleanup()
        self.assertFalse(self.service.is_alive())
        self.assertFalse(self.safety.is_alive())
        self.assertEqual(self.exceptions, [])

    def client(self) -> socket.socket:
        connection = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        connection.settimeout(2)
        connection.connect(self.address)
        return connection

    def assert_lease_released(self) -> None:
        window = self.session.window
        deadline = time.monotonic() + 0.45
        while window.released_at is None and time.monotonic() < deadline:
            time.sleep(0.01)
        self.assertIsNotNone(window.released_at)
        self.assertLess(window.released_at - window.release_deadline, 0.2)
        self.assertFalse(window.keys)

    def test_partial_command_cannot_starve_lease(self) -> None:
        with self.client() as client:
            started = time.monotonic()
            client.sendall(b'{"action":')
            self.assert_lease_released()
            response = client.recv(8192)
            self.assertIn(b"500 ms", response)
            self.assertLess(time.monotonic() - started, 0.8)

    def test_drip_fed_command_has_total_deadline(self) -> None:
        with self.client() as client:
            started = time.monotonic()
            client.sendall(b'{')
            for _ in range(8):
                time.sleep(0.05)
                client.sendall(b' ')
            self.assert_lease_released()
            self.assertIn(b"500 ms", client.recv(8192))
            self.assertLess(time.monotonic() - started, 0.8)

    def test_capture_wait_cannot_starve_lease(self) -> None:
        def slow_capture(*args: object) -> dict:
            time.sleep(0.65)
            return {"test_double": True}
        with patch("native_session.screenshot", side_effect=slow_capture):
            with self.client() as client:
                client.sendall(b'{"action":"screenshot","name":"fake.png"}\n')
                self.assert_lease_released()
                self.assertIn(b'"ok": true', client.recv(8192))

    def test_stop_releases_and_cancels_long_hold(self) -> None:
        self.session.window.release_deadline = time.monotonic() + 30
        held = threading.Thread(target=lambda: self.session.window.cancel.wait(10))
        held.start()
        started = time.monotonic()
        self.session.stop_requested = True
        held.join(0.3)
        self.assertFalse(held.is_alive())
        self.assertFalse(self.session.window.keys)
        self.assertLess(time.monotonic() - started, 0.3)

    def test_focus_loss_releases_before_long_lease(self) -> None:
        self.session.window.release_deadline = time.monotonic() + 30
        self.session.window.focused = False
        time.sleep(0.12)
        self.assertFalse(self.session.window.keys)


if __name__ == "__main__":
    unittest.main(verbosity=2)
