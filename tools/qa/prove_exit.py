#!/usr/bin/env python3
"""Bounded native QA-007 reproduction; never a game/playthrough acceptance."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import time
from typing import Any

from native import send
from prove_freshness import compare_images
from qa_common import same_process, sha256, utc, write_json


def state(directory: Path) -> dict[str, Any]:
    return json.loads((directory / "state.json").read_text())


def rows(path: Path) -> list[dict[str, Any]]:
    return [json.loads(line) for line in path.read_text().splitlines()]


def wait_file(path: Path, seconds: float = 10) -> None:
    deadline = time.monotonic() + seconds
    while not path.exists():
        if time.monotonic() > deadline:
            raise RuntimeError(f"Missing diagnostic output: {path}")
        time.sleep(0.05)


def terminal(directory: Path) -> dict[str, Any]:
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline:
        value = state(directory)
        if value["status"] in ("stopped", "failed"):
            return value
        time.sleep(0.05)
    raise RuntimeError("Owned exit did not finish within diagnostic bound")


def launch(directory: Path, command: list[str]) -> None:
    # Use the documented CLI process boundary. Calling start() in this long-
    # lived proof process would leave its detached supervisor as our unreaped
    # child until Python's next Popen, confusing actual cleanup with a zombie.
    subprocess.run([sys.executable, str(Path(__file__).with_name("native.py")),
        "start", "--run-dir", str(directory),
        "--cwd", str(Path(__file__).resolve().parents[2]), "--method", "scripted_diagnostic",
        "--", *command], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)


def prove(root: Path, godot_export: Path) -> dict[str, Any]:
    if root.exists():
        raise ValueError("A new evidence root is required")
    root.mkdir(parents=True)
    result: dict[str, Any] = {"started_utc": utc(), "method": "scripted_native_exit_diagnostic",
        "experiential_review": "unverified", "export_sha256": sha256(godot_export), "checks": {}}
    checks = result["checks"]
    current: Path | None = None

    def check(name: str, passed: bool, observed: Any) -> None:
        checks[name] = {"passed": bool(passed), "observation": observed}
        if not passed:
            raise AssertionError(name)

    def cleanup_check(name: str, directory: Path, final: dict[str, Any]) -> None:
        pids = [final["supervisor"], *final["processes"].values()]
        # Final manifest is published just before the supervisor returns.
        deadline = time.monotonic() + 2
        while any(same_process(identity) for identity in pids) and time.monotonic() < deadline:
            time.sleep(0.025)
        journal = rows(directory / "supervisor-events.jsonl")
        raw = [row for row in journal if row["event"] == "private_xi2_raw"]
        check(name + "/owned_cleanup", not final["cleanup_errors"]
            and final["host_defaults_unchanged"] and not Path(final["runtime_dir"]).exists()
            and not any(same_process(identity) for identity in pids),
            {"cleanup_errors": final["cleanup_errors"], "defaults_unchanged": final["host_defaults_unchanged"]})
        check(name + "/xtest_only", bool(raw) and all(row["source_is_xtest"] for row in raw),
            {"raw_events": len(raw), "source_ids": sorted({row["source_id"] for row in raw})})

    try:
        fixture = Path(__file__).resolve().parent / "fixtures/window_exit.py"
        scenarios = [
            ("escape", [], False, "stopped", 0, None),
            ("quit-click", [], True, "stopped", 0, None),
            ("nonzero", ["--exit-code", "7"], False, "failed", 7, "exited unexpectedly: 7"),
            ("windowless-timeout", ["--delay", "3"], False, "failed", -15, "2-second"),
            ("foreign-during-grace", ["--delay", "3", "--foreign-after-destroy"], False,
             "failed", -15, "Unexpected mapped windows")]
        for name, extra, click, expected_status, expected_code, expected_error in scenarios:
            current = root / name
            launch(current, [sys.executable, str(fixture), *extra])
            wait_file(current / "exit-fixture-events.jsonl")
            send(current, {"action": "screenshot", "name": "01-native-quit.png"})
            send(current, {"action": "input", "key_down": ["w"], "lease": 30})
            if click:
                response = send(current, {"action": "input", "pointer": [250, 250], "click": [1]})
            else:
                response = send(current, {"action": "input", "tap": ["Escape"]})
            check(name + "/request_race_handled", response.get("status") == "closing", response)
            final = terminal(current)
            events = rows(current / "exit-fixture-events.jsonl")
            destroyed = next(row for row in events if row["event"] == "window_destroyed")
            released = next(row for row in events if row["event"] == "after_destroy_keymap"
                            and not row["pressed_keycodes"])
            delay = released["monotonic"] - destroyed["monotonic"]
            check(name + "/actual_private_keys_released", 0 <= delay < 0.45,
                  {"after_destroy_seconds": delay, "observed_keymap": released})
            check(name + "/exit_result", final["status"] == expected_status
                and final["processes"]["game"]["exit_code"] == expected_code
                and (expected_error is None or expected_error in final.get("error", "")),
                {"status": final["status"], "exit_code": final["processes"]["game"]["exit_code"],
                 "error": final.get("error"), "lifecycle": final.get("window_lifecycle")})
            if expected_code in (0, 7):
                check(name + "/buffered_stdout_flushed", "QA_EXIT_BUFFERED_NATURAL_SHUTDOWN "
                    + str(expected_code) in (current / "game.log").read_text(), (current / "game.log").read_text())
            cleanup_check(name, current, final)
            print(name, "checked", flush=True)

        for index in (1, 2):
            name = f"godot-export-{index:02d}"
            current = root / name
            launch(current, [str(godot_export), "--display-driver", "x11", "--rendering-method", "forward_plus",
                "--rendering-driver", "vulkan", "--audio-driver", "PulseAudio", "--resolution", "1920x1080",
                "--windowed", "--disable-vsync", "--max-fps", "60", "--", "--output-dir", str(current)])
            wait_file(current / "viewport-000-initial.png")
            send(current, {"action": "input", "tap": ["space"]})
            send(current, {"action": "input", "key_down": ["a"], "hold": 0.25, "release": True})
            send(current, {"action": "input", "tap": ["f"]})
            time.sleep(0.2)
            send(current, {"action": "screenshot", "name": "01-native-paused-lamp-off.png"})
            send(current, {"action": "input", "tap": ["F12"]})
            wait_file(current / "viewport-001-requested.png")
            comparison = compare_images(current / "01-native-paused-lamp-off.png", current / "viewport-001-requested.png")
            write_json(current / "image-comparison.json", comparison)
            check(name + "/current_full_rgb", comparison["exact_rgb_match"], comparison)
            response = send(current, {"action": "input", "tap": ["Escape"]})
            write_json(current / "escape-response.json", response)
            final = terminal(current)
            log = (current / "game.log").read_text()
            check(name + "/actual_godot_forward_plus_radv", "forward_plus" in log
                and "RADV REMBRANDT" in log and "native_ready" in log, log)
            check(name + "/natural_exit_zero", final["status"] == "stopped"
                and final["processes"]["game"]["exit_code"] == 0
                and final["controlled_provenance_valid"],
                {"status": final["status"], "exit_code": final["processes"]["game"]["exit_code"],
                 "lifecycle": final.get("window_lifecycle")})
            cleanup_check(name, current, final)
            print(name, "checked", flush=True)
        result["status"] = "PASS_SCRIPTED_NATIVE_EXIT"
    except Exception as error:
        result.update({"status": "FAIL", "error": str(error)})
        raise
    finally:
        if current is not None and (current / "state.json").exists():
            value = state(current)
            if value["status"] in ("ready", "closing"):
                try:
                    send(current, {"action": "stop"})
                    terminal(current)
                except Exception as error:
                    result["cleanup_error"] = str(error)
        result["ended_utc"] = utc()
        write_json(root / "exit-verification.json", result)
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-root", type=Path, required=True)
    parser.add_argument("--godot-export", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(prove(args.run_root.resolve(), args.godot_export.resolve()), indent=2))
