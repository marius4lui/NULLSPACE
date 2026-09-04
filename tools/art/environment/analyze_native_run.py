#!/usr/bin/env python3
"""Read retained M4 native evidence; never grades art or substitutes for opening it."""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image


def read_json(path: Path) -> dict:
    return json.loads(path.read_text())


def compare(run: Path, external: str, reference: str) -> dict:
    a = np.asarray(Image.open(run / external).convert("RGB"), dtype=np.int16)
    b = np.asarray(Image.open(run / reference).convert("RGB"), dtype=np.int16)
    difference = np.abs(a - b)
    return {
        "external": external, "later_viewport_reference": reference,
        "resolution": list(a.shape[1::-1]), "same_dimensions": a.shape == b.shape,
        "rgb_exact_equal": bool(np.array_equal(a, b)),
        "mean_absolute_channel_difference_8bit": float(difference.mean()),
        "max_absolute_channel_difference_8bit": int(difference.max()),
        "fraction_pixels_different": float(np.any(difference, axis=-1).mean()),
        "interpretation": "Metrics only. Stationary TAA may differ between frames; open both originals and correlate actual scene/pose."
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("run", type=Path)
    args = parser.parse_args()
    run = args.run.resolve()
    state = read_json(run / "state.json")
    pairs = [("entry_composite.png", "viewport/m4_001.png"),
             ("view3_composite.png", "viewport/m4_003.png"),
             ("view7_composite.png", "viewport/m4_005.png"),
             ("paper_flashlight_composite.png", "viewport/m4_008.png"),
             ("effects_disabled_composite.png", "viewport/m4_014.png")]
    trace = [json.loads(line) for line in (run / "viewport/accepted_input_trace.jsonl").read_text().splitlines()]
    journal = [json.loads(line) for line in (run / "supervisor-events.jsonl").read_text().splitlines()]
    raw = [event for event in journal if event.get("event") == "private_xi2_raw"]
    captures = {path.stem: read_json(path) for path in sorted((run / "viewport").glob("m4_*.json"))}
    video = {path.name: {key: read_json(path).get(key) for key in ["sha256", "seconds_requested", "exit_code", "probe", "method"]}
             for path in sorted(run.glob("*.mkv.json"))}
    report = {
        "scope": "Implementer M4 native diagnostic evidence; no M4/art/performance/experiential PASS.",
        "state": {key: state.get(key) for key in ["status", "started_utc", "ended_utc", "game_git", "harness_git", "game_source_hashes", "executable_sha256", "controlled_provenance_valid", "cleanup_errors", "host_defaults_unchanged", "vulkan_device_lines"]},
        "external_viewport_pairs": [compare(run, a, b) for a, b in pairs if (run / a).exists() and (run / b).exists()],
        "captures": captures, "videos": video,
        "input": {
            "trace_event_count": len(trace),
            "non_echo_key_down_counts": dict(Counter(event["key_name"] for event in trace if event.get("pressed") and event.get("class") == "InputEventKey" and not event.get("echo"))),
            "mouse_motion_events": [event for event in trace if event.get("class") == "InputEventMouseMotion"],
            "raw_source_counts": dict(Counter(str(event.get("source_id")) for event in raw)),
            "raw_non_xtest_events": [event for event in raw if not event.get("source_is_xtest")],
            "request_count": sum(event.get("event") == "request" for event in journal),
            "note": "XTEST provenance alone is not correct camera behavior. Re-capture jump retained; second movement used a settled captured pose."
        },
        "incomplete_capture_requests": "Last P request immediately before explicit stop did not finish;21 PNG/JSON pairs exist, not22. No result claimed for that final request.",
    }
    report["artifact_hashes"] = {
        str(path.relative_to(run)): hashlib.sha256(path.read_bytes()).hexdigest()
        for path in sorted(run.rglob("*")) if path.is_file() and "profile" not in path.relative_to(run).parts and path.name != "analysis.json"
    }
    destination = run / "analysis.json"
    destination.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"output": str(destination), "captures": len(captures), "pairs": report["external_viewport_pairs"], "raw_non_xtest_count": len(report["input"]["raw_non_xtest_events"]), "artifacts": len(report["artifact_hashes"])}, indent=2))


if __name__ == "__main__":
    main()
