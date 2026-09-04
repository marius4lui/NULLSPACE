#!/usr/bin/env python3
"""Native fault tests after prove_fixture; ends the run with an owned SIGTERM.

Reads actual Godot key/position events. Does not claim experiential acceptance.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import signal
import socket
import threading
import time
from typing import Any

from native import send
from prove_fixture import latest, rows
from qa_common import same_process, utc, write_json


def prove(directory: Path) -> dict[str, Any]:
    checks: dict[str, Any] = {}
    result = {"method": "scripted_native_fault_diagnostic", "started_utc": utc(),
              "checks": checks, "experiential_review": "unverified"}

    def check(name: str, passed: bool, observed: Any) -> None:
        checks[name] = {"passed": bool(passed), "observation": observed}
        if not passed:
            raise AssertionError(name)

    def begin(key: str, lease: float = 0.2) -> tuple[float, float]:
        started = (time.monotonic(), time.time())
        send(directory, {"action": "input", "key_down": [key], "lease": lease})
        return started

    def key_release(key: str, started: tuple[float, float]) -> dict[str, Any]:
        physical = ord(key.upper())
        deadline = started[0] + 1.0
        while time.monotonic() < deadline:
            events = [row for row in rows(directory) if row["event"] == "key"
                      and row["physical_keycode"] == physical and row["utc_unix"] >= started[1]]
            press = next((row for row in events if row["pressed"]), None)
            release = next((row for row in events if not row["pressed"]), None)
            if press and release:
                return {"press": press, "release": release,
                        "release_since_request_seconds": release["utc_unix"] - started[1],
                        "observed_after_seconds": time.monotonic() - started[0]}
            time.sleep(0.015)
        raise AssertionError(f"Actual Godot press/release missing for {key}")

    def connection() -> socket.socket:
        state = json.loads((directory / "state.json").read_text())
        client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        client.settimeout(3)
        client.connect(state["control_socket"])
        return client

    def async_request(request: dict[str, Any]) -> tuple[threading.Thread, dict[str, Any]]:
        response: dict[str, Any] = {}
        def run() -> None:
            try:
                response["result"] = send(directory, request)
            except Exception as error:
                response["error"] = str(error)
            response["ended_monotonic"] = time.monotonic()
        thread = threading.Thread(target=run)
        thread.start()
        return thread, response

    try:
        send(directory, {"action": "release"})
        time.sleep(0.15)
        status = send(directory, {"action": "status"})
        seat = status["private_seat"]
        check("inputless_private_seat", seat["policy"] == "xtest_only_inputless_compositor"
              and len(seat["devices"]) == 8 and all(d["role"] in ("master", "xtest", "inputless_protocol")
              and d["enabled"] for d in seat["devices"]), seat)
        before = latest(directory)
        time.sleep(2)
        after = latest(directory)
        fields = ("position", "yaw", "pitch", "shots", "mouse_total", "mode")
        check("quiet_idle_has_no_unrequested_controls", all(before[k] == after[k] for k in fields)
              and not any(after["keys"].values()) and after["frame"] - before["frame"] >= 80,
              {"before": before, "after": after})

        started = begin("w")
        with connection() as client:
            client.sendall(b'{"action":')
            observed = key_release("w", started)
            check("partial_ipc_does_not_starve_native_lease", observed["release_since_request_seconds"] < 0.45, observed)
            response = client.recv(8192).decode()
            check("partial_ipc_total_deadline", "500 ms" in response
                  and time.monotonic() - started[0] < 0.9, response)

        started = begin("d")
        with connection() as client:
            client.sendall(b'{')
            for _ in range(7):
                time.sleep(0.05)
                client.sendall(b' ')
            observed = key_release("d", started)
            check("drip_ipc_does_not_starve_native_lease", observed["release_since_request_seconds"] < 0.45, observed)
            response = client.recv(8192).decode()
            check("drip_ipc_cannot_extend_deadline", "500 ms" in response
                  and time.monotonic() - started[0] < 0.9, response)

        started = begin("a")
        # Named-pixmap snapshots can finish before a 200 ms lease. Exercise a
        # real capture burst across that deadline instead of requiring one
        # deliberately slow screenshot or inserting a fake supervisor delay.
        response = {"captures": [], "started_monotonic": time.monotonic()}
        def capture_burst() -> None:
            try:
                for index in range(32):
                    name = "06-lease-during-capture.png" if index == 0 else f"06-lease-burst-{index:02d}.png"
                    response["captures"].append(send(directory, {"action": "screenshot", "name": name}))
                    if time.monotonic() - response["started_monotonic"] >= 0.8:
                        break
            except Exception as error:
                response["error"] = str(error)
            response["ended_monotonic"] = time.monotonic()
        thread = threading.Thread(target=capture_burst)
        thread.start()
        observed = key_release("a", started)
        check("capture_burst_does_not_starve_native_lease", observed["release_since_request_seconds"] < 0.45
              and thread.is_alive(), observed)
        thread.join(18)
        check("capture_burst_completed_after_release", not thread.is_alive() and "error" not in response
              and len(response["captures"]) >= 2
              and response["ended_monotonic"] - response["started_monotonic"] >= 0.8, response)

        started = (time.monotonic(), time.time())
        thread, response = async_request({"action": "input", "key_down": ["s"], "hold": 0.9, "lease": 0.2})
        observed = key_release("s", started)
        check("long_hold_cannot_extend_native_lease", observed["release_since_request_seconds"] < 0.45
              and thread.is_alive(), observed)
        thread.join(2)
        check("long_hold_returns_released", not thread.is_alive() and "error" not in response
              and not response["result"]["held_keys"], response)

        send(directory, {"action": "input", "key_down": ["w"]})
        blurred = send(directory, {"action": "blur"})
        time.sleep(0.15)
        check("private_root_blur_releases_keys", not blurred["focused"]
              and not blurred["held_keys"] and not any(latest(directory)["keys"].values()), blurred)
        send(directory, {"action": "focus"})

        started = (time.monotonic(), time.time())
        thread, response = async_request({"action": "input", "key_down": ["w"], "hold": 10, "lease": 30})
        deadline = time.monotonic() + 2
        while not latest(directory)["keys"]["w"]:
            if time.monotonic() > deadline:
                raise AssertionError("Long-hold key did not reach the game")
            time.sleep(0.02)
        state = json.loads((directory / "state.json").read_text())
        if not same_process(state["supervisor"]):
            raise AssertionError("Supervisor identity changed before owned signal test")
        signal_time = time.monotonic()
        os.kill(state["supervisor"]["pid"], signal.SIGTERM)
        observed = key_release("w", started)
        thread.join(3)
        deadline = time.monotonic() + 5
        while state["status"] == "ready" and time.monotonic() < deadline:
            time.sleep(0.05)
            state = json.loads((directory / "state.json").read_text())
        check("sigterm_interrupts_ten_second_hold", not thread.is_alive()
              and time.monotonic() - signal_time < 5, {"response": response, "key_event": observed,
              "cleanup_after_signal_seconds": time.monotonic() - signal_time})
        check("owned_cleanup_after_fault_tests", state["status"] == "stopped"
              and not state["cleanup_errors"] and state["host_defaults_unchanged"]
              and not Path(state["runtime_dir"]).exists(), state)
        journal = [json.loads(line) for line in (directory / "supervisor-events.jsonl").read_text().splitlines()]
        raw = [row for row in journal if row["event"] == "private_xi2_raw"]
        check("all_raw_input_from_verified_xtest_devices", bool(raw)
              and all(row["source_is_xtest"] for row in raw),
              {"event_count": len(raw), "source_ids": sorted({row["source_id"] for row in raw})})
        check("no_seat_drift_or_guard_error", state["controlled_provenance_valid"]
              and not any(row["event"] in ("safety_guard_failed", "private_seat_hierarchy_changed",
                                         "private_seat_property_changed") for row in journal),
              state["private_seat"])
        result["status"] = "PASS_SCRIPTED_NATIVE_SAFETY"
    except Exception as error:
        result["status"] = "FAIL"
        result["error"] = str(error)
        raise
    finally:
        result["ended_utc"] = utc()
        write_json(directory / "safety-verification.json", result)
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(prove(args.run_dir.resolve()), indent=2))
