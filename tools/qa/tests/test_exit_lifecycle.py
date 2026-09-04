"""Owned-window teardown guards: fake X resources, real owned child processes.

These tests are not native rendering/input evidence; the native exit fixture
and exported Godot diagnostic exercise that separate boundary.
"""
from __future__ import annotations

from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import threading
import time
from types import SimpleNamespace
import unittest

from Xlib import X, error as xerror

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from native_session import NativeSession
from qa_common import process_identity, write_json
from x11_input import GameWindow


def bad_window(xid: int) -> xerror.BadWindow:
    decoder = SimpleNamespace(get_resource_class=lambda name: None)
    return xerror.BadWindow(decoder, struct.pack("=BBHIHB21x", 0, 3, 1, xid, 0, 20))


class Node:
    def __init__(self, xid: int, pid: int, mapped: bool = True) -> None:
        self.id, self.pid, self.mapped = xid, pid, mapped

    def get_attributes(self) -> SimpleNamespace:
        return SimpleNamespace(map_state=X.IsViewable if self.mapped else X.IsUnmapped)

    def get_full_property(self, *args: object) -> SimpleNamespace:
        return SimpleNamespace(value=[self.pid])


class Window(GameWindow):
    def __init__(self, pid: int) -> None:
        self.lock = threading.RLock()
        self.cancel = threading.Event()
        self.game_pid, self.pid_atom = pid, 1
        self.window = Node(42, pid)
        self.verified_window_id = 42
        self.children: list[Node] = []
        self.root = SimpleNamespace(query_tree=lambda: SimpleNamespace(children=self.children))
        self.keys, self.buttons = {25: "w"}, {1}
        self.released_at: float | None = None

    def release(self) -> None:
        with self.lock:
            if self.keys or self.buttons:
                self.released_at = time.monotonic()
            self.keys.clear()
            self.buttons.clear()


class ExitTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="nullspace-owned-exit-test-")
        self.directory = Path(self.temporary.name)
        write_json(self.directory / "launch.json", {"method": "scripted_diagnostic"})
        self.session = NativeSession(self.directory)
        self.child = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(10)"],
                                      stdout=subprocess.PIPE, start_new_session=True)
        self.session.processes = {"game": self.child}
        self.session.state.update({"status": "ready", "processes": {"game": process_identity(self.child.pid)}})
        self.window = Window(self.child.pid)
        self.session.window = self.window
        self.session.seat = SimpleNamespace(audit=lambda: {"test_double": True})
        self.session.server = object()  # Only already-exited serve paths use it.

    def tearDown(self) -> None:
        if self.child.poll() is None:
            self.child.terminate()
        self.child.wait(timeout=2)
        self.child.stdout.close()
        self.temporary.cleanup()

    def begin(self) -> None:
        self.assertTrue(self.session.begin_owned_window_exit(bad_window(42)))

    def test_exact_destroyed_verified_target_enters_fixed_grace(self) -> None:
        self.begin()
        deadline = self.session.window_exit_deadline
        self.assertTrue(self.window.cancel.is_set())
        self.assertFalse(self.window.keys or self.window.buttons)
        self.assertEqual(self.session.state["status"], "closing")
        self.begin()
        self.assertEqual(self.session.window_exit_deadline, deadline)
        self.assertIsNone(self.child.poll())

    def test_wrong_resource_error_is_not_normal_exit(self) -> None:
        self.assertFalse(self.session.begin_owned_window_exit(bad_window(777)))
        self.assertIsNone(self.session.window_exit_deadline)
        self.assertFalse(self.window.cancel.is_set())

    def test_unverified_target_is_not_normal_exit(self) -> None:
        self.window.verified_window_id = 43
        self.assertFalse(self.session.begin_owned_window_exit(bad_window(42)))

    def test_still_existing_target_is_not_normal_exit(self) -> None:
        self.window.children = [self.window.window]
        self.assertFalse(self.session.begin_owned_window_exit(bad_window(42)))

    def test_hidden_window_failure_is_not_normal_exit(self) -> None:
        self.assertFalse(self.session.begin_owned_window_exit(RuntimeError("Owned game window is not viewable")))

    def test_mapped_foreign_window_refused_before_grace(self) -> None:
        self.window.children = [Node(77, self.child.pid + 1)]
        with self.assertRaisesRegex(RuntimeError, "Unexpected mapped windows"):
            self.begin()
        self.assertIsNone(self.session.window_exit_deadline)

    def test_changed_process_start_identity_refused(self) -> None:
        self.session.state["processes"]["game"]["start_ticks"] -= 1
        with self.assertRaisesRegex(RuntimeError, "PID/start identity changed"):
            self.begin()

    def test_cancel_prevents_new_input_before_focus_or_xtest(self) -> None:
        self.window.cancel.set()
        with self.assertRaisesRegex(RuntimeError, "no new controls"):
            self.window._begin_input({"key_down": ["w"]})

    def test_closing_refuses_input_focus_and_capture_but_allows_status_release_stop(self) -> None:
        self.begin()
        for action in ("input", "focus", "blur", "screenshot", "record"):
            with self.subTest(action=action), self.assertRaisesRegex(RuntimeError, "new input and capture"):
                self.session.handle({"action": action})
        for action in ("status", "release"):
            self.assertEqual(self.session.handle({"action": action})["status"], "closing")
        self.assertTrue(self.session.handle({"action": "stop"})["stopping"])
        self.assertTrue(self.session.stop_requested)

    def test_expired_grace_terminates_only_owned_child_and_fails(self) -> None:
        self.begin()
        self.session.window_exit_deadline = time.monotonic() - 0.1
        self.session.safety_loop()
        self.child.wait(timeout=2)
        self.assertEqual(self.child.returncode, -15)
        self.assertIn("2-second", self.session.safety_error)
        self.assertFalse(self.session.state["controlled_provenance_valid"])

    def test_foreign_window_during_grace_remains_failure(self) -> None:
        self.begin()
        self.window.children = [Node(77, self.child.pid + 1)]
        self.session.safety_loop()
        self.child.wait(timeout=2)
        self.assertIn("Unexpected mapped windows", self.session.safety_error)
        self.assertFalse(self.session.state["controlled_provenance_valid"])

    def test_seat_fault_during_grace_remains_failure(self) -> None:
        self.begin()
        def fail() -> dict:
            raise RuntimeError("Non-XTEST source detected")
        self.session.seat = SimpleNamespace(audit=fail)
        self.session.safety_loop()
        self.child.wait(timeout=2)
        self.assertIn("Non-XTEST", self.session.safety_error)

    def test_clean_child_exit_is_preserved_without_signal(self) -> None:
        self.child.terminate()
        self.child.wait(timeout=2)
        self.child.stdout.close()
        self.child = subprocess.Popen([sys.executable, "-c",
            "import time; print('buffered natural exit'); time.sleep(.15)"],
            stdout=subprocess.PIPE, start_new_session=True)
        self.session.processes["game"] = self.child
        self.session.state["processes"]["game"] = process_identity(self.child.pid)
        self.window.game_pid = self.child.pid
        self.begin()
        self.child.wait(timeout=2)
        self.session.serve()
        self.assertEqual(self.child.returncode, 0)
        self.assertIn(b"buffered natural exit", self.child.stdout.read())
        self.assertEqual(self.session.state["window_lifecycle"]["phase"], "exited")
        self.assertNotIn("error", self.session.state)

    def test_nonzero_child_exit_is_not_hidden_by_grace(self) -> None:
        self.begin()
        self.child.terminate()
        self.child.wait(timeout=2)
        with self.assertRaisesRegex(RuntimeError, "Owned game exited unexpectedly: -15"):
            self.session.serve()

    def test_concurrent_begin_and_manifest_save_do_not_extend_grace_or_race_tmp(self) -> None:
        failures: list[Exception] = []
        def work() -> None:
            try:
                for _ in range(8):
                    self.session.begin_owned_window_exit(bad_window(42))
                    self.session.save()
            except Exception as error:
                failures.append(error)
        threads = [threading.Thread(target=work) for _ in range(3)]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join(2)
        self.assertEqual(failures, [])
        self.assertTrue(all(not thread.is_alive() for thread in threads))
        events = (self.directory / "supervisor-events.jsonl").read_text()
        self.assertEqual(events.count('"event": "owned_window_destroyed_input_released"'), 1)


if __name__ == "__main__":
    unittest.main(verbosity=2)
