#!/usr/bin/env python3
"""Scripted diagnostic, never an independent or experiential game playthrough."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import time
from typing import Any

from native import send
from qa_common import utc, write_json


def rows(directory: Path) -> list[dict[str, Any]]:
    return [json.loads(line) for line in (directory / "fixture-events.jsonl").read_text().splitlines()]


def latest(directory: Path) -> dict[str, Any]:
    return next(row for row in reversed(rows(directory)) if row["event"] == "state")


def prove(directory: Path) -> dict[str, Any]:
    checks: dict[str, Any] = {}
    def inject(**values: Any) -> dict[str, Any]:
        return send(directory, {"action": "input", **values})
    def sample() -> dict[str, Any]:
        time.sleep(0.16)
        return latest(directory)
    def check(name: str, passed: bool, observation: Any) -> None:
        checks[name] = {"passed": bool(passed), "observation": observation}
        if not passed:
            raise AssertionError(name)
    result: dict[str, Any] = {"method": "scripted_diagnostic", "started_utc": utc(),
                              "checks": checks, "experiential_review": "unverified"}
    try:
        deadline = time.monotonic() + 30
        while True:
            path = directory / "fixture-events.jsonl"
            if path.exists() and any(row["event"] == "state" for row in rows(directory)):
                if send(directory, {"action": "status"})["audio"]["stream_ids"]:
                    break
            if time.monotonic() > deadline:
                raise RuntimeError("Fixture and owned audio stream not ready after 30 seconds")
            time.sleep(0.1)
        before = sample()
        check("initial_menu", before["mode"] == "menu", before)
        send(directory, {"action": "screenshot", "name": "01-menu.png"})
        send(directory, {"action": "record", "name": "input-proof.mkv", "seconds": 10})
        time.sleep(0.6)
        inject(tap=["Return"])
        playing = sample()
        check("enter_captures_mouse", playing["mode"] == "playing" and playing["captured"], playing)
        inject(key_down=["w", "d", "Shift_L"], move=[120, -25], click=[1], hold=0.45)
        moving = sample()
        check("simultaneous_keyboard", all(moving["keys"][key] for key in ("w", "d", "shift")), moving)
        check("captured_relative_mouse", moving["captured"] and moving["mouse_total"] == [120.0, -25.0]
              and abs(moving["yaw"] + 0.36) < 0.001 and abs(moving["pitch"] - 0.075) < 0.001, moving)
        check("motion_and_fire", moving["shots"] == 1 and moving["position"] != playing["position"], moving)
        send(directory, {"action": "release"})
        released = sample()
        check("explicit_release", not any(released["keys"].values()), released)
        send(directory, {"action": "screenshot", "name": "02-moved.png"})
        inject(click=[1])
        inject(tap=["Escape"])
        paused = sample()
        inject(key_down=["w"], click=[1], move=[60, 20], hold=0.3)
        blocked = sample()
        check("pause_blocks_motion_fire", blocked["mode"] == "paused" and not blocked["captured"]
              and blocked["position"] == paused["position"] and blocked["shots"] == paused["shots"]
              and blocked["keys"]["w"], blocked)
        send(directory, {"action": "release"})
        send(directory, {"action": "screenshot", "name": "03-paused.png"})
        inject(tap=["Escape"])
        resumed = sample()
        check("resume_recaptures_mouse", resumed["mode"] == "playing" and resumed["captured"], resumed)
        inject(key_down=["w", "a"], move=[-60, 10], click=[1], hold=0.25, release=True)
        resumed_move = sample()
        check("resume_input_works", resumed_move["shots"] == 3 and resumed_move["position"] != resumed["position"]
              and resumed_move["mouse_total"] == [60.0, -15.0], resumed_move)
        inject(tap=["Tab"])
        menu = sample()
        inject(key_down=["d"], click=[1], hold=0.2, release=True)
        menu_blocked = sample()
        check("menu_blocks_motion_fire", menu_blocked["mode"] == "menu" and not menu_blocked["captured"]
              and menu_blocked["position"] == menu["position"] and menu_blocked["shots"] == menu["shots"], menu_blocked)
        inject(tap=["Return"])
        inject(key_down=["w"], lease=0.2)
        time.sleep(0.6)
        leased = sample()
        check("expired_lease_releases_key", not any(leased["keys"].values()), leased)
        inject(key_down=["d"])
        try:
            inject(key_down=["NoSuchKey_NULLSPACE"])
        except RuntimeError as error:
            checks["invalid_command_rejected"] = {"passed": True, "observation": str(error)}
        else:
            raise AssertionError("invalid_command_rejected")
        invalid = sample()
        check("command_failure_releases_key", not any(invalid["keys"].values()), invalid)
        deadline = time.monotonic() + 15
        while send(directory, {"action": "status"})["recording"] is not None:
            if time.monotonic() > deadline:
                raise AssertionError("recording_did_not_finish")
            time.sleep(0.25)
        send(directory, {"action": "screenshot", "name": "04-final.png"})
        check("native_x11_radv_fixture", any(row["event"] == "ready" and row["display"] == "X11"
              and "RADV" in row["adapter"] for row in rows(directory)), rows(directory)[0])
        result["status"] = "PASS_SCRIPTED_DIAGNOSTIC"
    except Exception as error:
        result["status"] = "FAIL"
        result["error"] = str(error)
        raise
    finally:
        send(directory, {"action": "release"})
        result["ended_utc"] = utc()
        write_json(directory / "input-verification.json", result)
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(prove(args.run_dir.resolve()), indent=2))
