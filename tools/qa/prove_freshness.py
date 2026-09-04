#!/usr/bin/env python3
"""Correlate external native snapshots with later actual viewport readbacks.

Fixture only. No continuous animation/barcode is added to force presentation.
The external PNG is always acquired BEFORE requesting Godot's frame_post_draw
reference. Exact RGB comparison includes the full scene and state HUD.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import time
from typing import Any

import numpy as np
from PIL import Image

from native import send
from prove_fixture import latest, rows
from qa_common import utc, write_json


def compare_images(native: Path, reference: Path) -> dict[str, Any]:
    with Image.open(native) as source, Image.open(reference) as viewport:
        left = np.asarray(source.convert("RGB"))
        right = np.asarray(viewport.convert("RGB"))
    if left.shape != (1080, 1920, 3) or right.shape != left.shape:
        raise AssertionError("Freshness proof requires two original 1920x1080 RGB images")
    delta = np.abs(left.astype(np.int16) - right.astype(np.int16))
    return {"exact_rgb_match": bool(np.array_equal(left, right)),
            "mean_absolute_difference": float(delta.mean()),
            "maximum_difference": int(delta.max()),
            "hud_mean_difference": float(delta[24:274, 24:1184].mean()),
            "native_rgb_sha256": hashlib.sha256(left.tobytes()).hexdigest(),
            "reference_rgb_sha256": hashlib.sha256(right.tobytes()).hexdigest()}


def prove(directory: Path) -> dict[str, Any]:
    result: dict[str, Any] = {"method": "scripted_diagnostic_freshness",
        "started_utc": utc(), "pairs": [], "status": "FAIL",
        "experiential_review": "unverified",
        "boundary": "External screenshot first, then F12 frame_post_draw viewport PNG; exact RGB match."}
    try:
        if send(directory, {"action": "status"})["recording"] is not None:
            raise AssertionError("Freshness challenge must run WITHOUT an active recorder")
        result["completed_recordings"] = [path.name for path in directory.glob("*.mkv.json")]
        if latest(directory)["mode"] != "playing":
            send(directory, {"action": "input", "tap": ["Return"]})
        scenarios: list[tuple[str, dict[str, Any]]] = [
            ("baseline", {}),
            ("captured_left", {"move": [-100, 20], "key_down": ["w"], "click": [1], "hold": 0.3, "release": True}),
            ("captured_right", {"move": [45, -15], "key_down": ["d"], "click": [1], "hold": 0.3, "release": True}),
            ("paused", {"tap": ["Escape"]}),
            ("menu", {"tap": ["Tab"]}),
            ("resumed", {"tap": ["Return"]}),
            ("captured_final", {"move": [90, -10], "key_down": ["s"], "click": [1], "hold": 0.3, "release": True}),
        ]
        previous_rgb: str | None = None
        for index, (label, request) in enumerate(scenarios, 1):
            if request:
                send(directory, {"action": "input", **request})
            time.sleep(0.4)  # Settle fixture flash and released movement, not a render-forcing API.
            state = latest(directory)
            if any(state["keys"].values()):
                raise AssertionError("Freshness reference requires released, settled input")
            capture = send(directory, {"action": "screenshot", "name": f"freshness-{index:02d}-{label}.png"})
            reference_count = sum(row["event"] == "viewport_capture" for row in rows(directory))
            send(directory, {"action": "input", "tap": ["F12"]})
            deadline = time.monotonic() + 3
            while True:
                references = [row for row in rows(directory) if row["event"] == "viewport_capture"]
                if len(references) > reference_count:
                    reference = references[-1]
                    break
                if time.monotonic() >= deadline:
                    raise AssertionError("Fixture did not produce the requested viewport reference")
                time.sleep(0.03)
            comparison = compare_images(Path(capture["path"]), Path(reference["path"]))
            pair = {"scenario": label, "before": state, "native": capture,
                    "reference": reference, "comparison": comparison}
            result["pairs"].append(pair)
            if reference["result"] != 0 or reference["frame"] <= state["frame"]:
                raise AssertionError(f"{label}: viewport reference did not follow snapshot state")
            for field in ("mode", "position", "yaw", "pitch", "shots", "mouse_total", "captured"):
                if reference[field] != state[field]:
                    raise AssertionError(f"{label}: state changed before viewport readback: {field}")
            if not comparison["exact_rgb_match"]:
                raise AssertionError(f"{label}: native snapshot is not the current viewport image")
            if previous_rgb == comparison["native_rgb_sha256"]:
                raise AssertionError(f"{label}: requested changed state did not change the actual image")
            previous_rgb = comparison["native_rgb_sha256"]
        result["status"] = "PASS_SCRIPTED_FRESHNESS"
    except Exception as error:
        result["error"] = str(error)
        raise
    finally:
        send(directory, {"action": "release"})
        result["ended_utc"] = utc()
        write_json(directory / "freshness-verification.json", result)
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(prove(args.run_dir.resolve()), indent=2))
