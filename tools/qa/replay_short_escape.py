#!/usr/bin/env python3
"""Replay the retained successful small-map input route on the real Linux export.

This is OS-input automation, not a first-play duration or experiential claim.
No fixture positions, game-state writes, checkpoint edits or AI disabling.
"""
import argparse
import fcntl
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time
from native import send

parser = argparse.ArgumentParser()
parser.add_argument("run_dir", type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
run = args.run_dir.resolve()
source = root / "evidence/section/solo-e/unarmed-export-02/supervisor-events.jsonl"
requests = [entry["request"] for entry in map(json.loads, source.read_text().splitlines())
            if entry["event"] == "request" and entry["request"]["action"] == "input"]
requests = [r for r in requests if "Escape" not in r["key_down"]]
signal.alarm(300)
with (Path(os.environ["XDG_RUNTIME_DIR"]) / "nullspace-qa-gpu.lock").open("a") as lock:
    fcntl.flock(lock, fcntl.LOCK_EX)
signal.alarm(0)
subprocess.run([sys.executable, str(root / "tools/qa/native.py"), "start", "--run-dir", str(run),
                "--cwd", str(root), "--method", "scripted_diagnostic", "--",
                str(root / "build/linux/nullspace.x86_64"), "--display-driver", "x11", "--rendering-method",
                "forward_plus", "--rendering-driver", "vulkan", "--audio-driver", "PulseAudio", "--windowed"],
               check=True, stdout=subprocess.DEVNULL)

def events():
    files = list((run / "profile/data/NULLSPACE/telemetry").glob("*.jsonl"))
    if not files:
        return []
    return [json.loads(line) for line in files[-1].read_text().splitlines() if line.strip()]

history = []
try:
    deadline = time.monotonic() + 45
    while not any(e["event"] == "section_ready" for e in events()):
        if time.monotonic() > deadline: raise RuntimeError("Scene did not become ready")
        time.sleep(.25)
    time.sleep(.3)
    for index, request in enumerate(requests):
        send(run, request)
        if index == 0:
            # A cold export may still compile the first menu/world pipelines.
            # Never dispatch the opening look before the actual restore and gate.
            deadline = time.monotonic() + 20
            while not any(e["event"] == "section_restored" for e in events()):
                if time.monotonic() > deadline: raise RuntimeError("Start did not restore the scene")
                time.sleep(.1)
            time.sleep(.25)
        else:
            time.sleep(.06)
        data = events()
        pose = next((e["values"] for e in reversed(data) if e["event"] == "player_pose"), {})
        flow = data[-1]["flow"]
        history.append({"step": index, "request": request, "flow": flow, "pose": pose})
        if index % 12 == 0: print(json.dumps({"step": index, "flow": flow, "position": pose.get("position")}), flush=True)
        if flow in ("DEAD", "DYING", "ENDING"): break
    time.sleep(.4)
    data = events()
    ending = [e for e in data if e["event"] == "escape_complete"]
    deaths = [e for e in data if e["event"] == "death_sequence_started"]
    send(run, {"action": "screenshot", "name": "route-result.png"})
    result = {"method": "OS-input replay of retained route; no state injection", "source_route": str(source.relative_to(root)),
              "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
              "build_info": (root / "build/linux/BUILD_INFO.txt").read_text(),
              "success": bool(ending) and not deaths, "ending": ending, "death_count": len(deaths), "history": history}
    (run / "route-result.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({"success": result["success"], "ending": ending, "death_count": len(deaths)}), flush=True)
finally:
    state = json.loads((run / "state.json").read_text())
    if state["status"] in ("ready", "closing"): send(run, {"action": "stop"})
