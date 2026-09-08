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
parser.add_argument("--keep-open", action="store_true", help="Retain the owned session for immediate adaptive UI checks")
parser.add_argument("--data-home", type=Path, help="Reuse only a prior isolated death-QA profile to check process persistence")
parser.add_argument("--attach", action="store_true", help="Use this task's already-owned session at its title menu")
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
run = args.run_dir.resolve()
data_home = args.data_home.resolve() if args.data_home else run / "profile/data"
if args.data_home:
    data_home.relative_to(root / "evidence/listener-death")
old_logs = set((data_home / "NULLSPACE/telemetry").glob("*.jsonl"))
if args.attach: old_logs = set()
source = root / "evidence/section/solo-e/unarmed-export-02/supervisor-events.jsonl"
requests = [entry["request"] for entry in map(json.loads, source.read_text().splitlines())
            if entry["event"] == "request" and entry["request"]["action"] == "input"]
requests = [r for r in requests if "Escape" not in r["key_down"]]
game_command = [str(root / "build/linux/nullspace.x86_64")]
if args.data_home: game_command = ["/usr/bin/env", "XDG_DATA_HOME=" + str(data_home)] + game_command
if not args.attach:
    signal.alarm(300)
    with (Path(os.environ["XDG_RUNTIME_DIR"]) / "nullspace-qa-gpu.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
    signal.alarm(0)
    subprocess.run([sys.executable, str(root / "tools/qa/native.py"), "start", "--run-dir", str(run),
                    "--cwd", str(root), "--method", "scripted_diagnostic", "--",
                    *game_command, "--display-driver", "x11", "--rendering-method",
                    "forward_plus", "--rendering-driver", "vulkan", "--audio-driver", "PulseAudio", "--windowed"],
                   check=True, stdout=subprocess.DEVNULL)

def events():
    files = list(set((data_home / "NULLSPACE/telemetry").glob("*.jsonl")) - old_logs)
    if not files:
        return []
    return [json.loads(line) for line in max(files, key=lambda p: p.stat().st_mtime).read_text().splitlines() if line.strip()]

history = []
try:
    deadline = time.monotonic() + 45
    while not any(e["event"] == "section_ready" for e in events()):
        if time.monotonic() > deadline: raise RuntimeError("Scene did not become ready")
        time.sleep(.25)
    time.sleep(.3)
    baseline = len(events())
    already_open = False
    for index, request in enumerate(requests):
        if index in (59, 61):
            # The Listener may already have opened the return door. A blind
            # replay closed it in route03; observe its actual semantic state.
            door = next((e["values"] for e in reversed(events()) if e["event"] == "door"
                         and e["values"]["id"] == "office_door"), {})
            if door.get("open"):
                if index == 59: already_open = True
                request = {"action": "input", "hold": .06}
        if index == 62 and already_open:
            # Account for having walked through the open leaf on step60; keep
            # the same clear -10.7m return corridor instead of overshooting it.
            request = dict(request, hold=.35)
        send(run, request)
        if index == 0:
            # A cold export may still compile the first menu/world pipelines.
            # Never dispatch the opening look before the actual restore and gate.
            deadline = time.monotonic() + 20
            while not any(e["event"] == "section_restored" for e in events()[baseline:]):
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
    all_data = events()
    data = all_data[baseline:]
    ending = [e for e in data if e["event"] == "escape_complete"]
    deaths = [e for e in data if e["event"] == "death_sequence_started"]
    result_name = "attached-route-result" if args.attach else "route-result"
    send(run, {"action": "screenshot", "name": result_name + ".png"})
    result = {"method": "OS-input replay of retained route; no state injection", "source_route": str(source.relative_to(root)),
              "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip(),
              "build_info": (root / "build/linux/BUILD_INFO.txt").read_text(),
              "boot_settings": next(e["values"]["settings"] for e in all_data if e["event"] == "boot"),
              "success": bool(ending) and not deaths, "ending": ending, "death_count": len(deaths), "history": history}
    (run / (result_name + ".json")).write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({"success": result["success"], "ending": ending, "death_count": len(deaths)}), flush=True)
finally:
    state = json.loads((run / "state.json").read_text())
    if state["status"] in ("ready", "closing") and not args.keep_open: send(run, {"action": "stop"})
