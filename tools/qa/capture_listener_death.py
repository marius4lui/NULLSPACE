#!/usr/bin/env python3
"""Record the concrete death fixtures after their scene/audio are ready."""
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
parser.add_argument("godot", type=Path)
parser.add_argument("--edges", action="store_true")
parser.add_argument("--mobile", action="store_true", help="Exercise the Mobile renderer and touch menu on the isolated desktop seat")
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
run = args.run_dir.resolve()
signal.alarm(300)
# Wait for the existing cooperative lease; do not stop another task or hold it
# while starting the supervisor (the supervisor acquires its own same lease).
with (Path(os.environ["XDG_RUNTIME_DIR"]) / "nullspace-qa-gpu.lock").open("a") as lock:
    fcntl.flock(lock, fcntl.LOCK_EX)
signal.alarm(0)
scene = "test_death_edges" if args.edges else "test_listener_death"
command = [sys.executable, str(root / "tools/qa/native.py"), "start", "--run-dir", str(run),
           "--method", "scripted_diagnostic", "--cwd", str(root), "--", str(args.godot),
           "--path", str(root / "game"), "--display-driver", "x11", "--rendering-method", "mobile" if args.mobile else "forward_plus",
           "--rendering-driver", "vulkan", "--audio-driver", "PulseAudio", "--windowed",
           f"res://tests/section/{scene}.tscn"]
if args.mobile:
    command += ["--", "--touch-ui"]
subprocess.run(command, check=True, stdout=subprocess.DEVNULL)
try:
    deadline = time.monotonic() + 50
    while time.monotonic() < deadline:
        if "DEATH_CAPTURE_READY" in (run / "game.log").read_text():
            break
        time.sleep(.25)
    else:
        raise RuntimeError("Actual scene did not become ready")
    send(run, {"action": "record", "name": "death-edges.mkv" if args.edges else "death-matrix.mkv", "seconds": 45})
    print("Recording actual death fixtures", flush=True)
    deadline = time.monotonic() + 75
    while time.monotonic() < deadline:
        state = json.loads((run / "state.json").read_text())
        if state["status"] in ("stopped", "failed"):
            print(json.dumps({"status": state["status"], "cleanup_errors": state.get("cleanup_errors"), "error": state.get("error")}))
            break
        time.sleep(.5)
    else:
        raise RuntimeError("Fixture did not terminate within its bounded run")
finally:
    state = json.loads((run / "state.json").read_text())
    if state["status"] in ("ready", "closing"):
        send(run, {"action": "stop"})
