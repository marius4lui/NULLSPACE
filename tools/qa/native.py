#!/usr/bin/env python3
"""Start/control/stop one isolated GPU game session. No host desktop capture."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import time
from typing import Any

from qa_common import resolve_executable, write_json


def send(directory: Path, request: dict[str, Any]) -> Any:
    state = json.loads((directory / "state.json").read_text())
    if state["status"] != "ready":
        raise RuntimeError(f'Session is {state["status"]}: {state.get("error", "")}')
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.settimeout(30)
        client.connect(state["control_socket"])
        client.sendall(json.dumps(request).encode() + b"\n")
        content = b""
        while b"\n" not in content:
            block = client.recv(8192)
            if not block:
                raise RuntimeError("Supervisor closed without responding")
            content += block
    result = json.loads(content)
    if not result["ok"]:
        raise RuntimeError(result["error"])
    return result["result"]


def start(args: argparse.Namespace) -> Any:
    directory = args.run_dir.resolve()
    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    if not command:
        raise ValueError("Provide a game executable after --")
    if args.allow_physical_input != (args.method == "manual_native"):
        raise ValueError("Physical input requires both --method manual_native and --allow-physical-input; controlled methods forbid it")
    command[0] = str(resolve_executable(command[0]))
    if directory.exists():
        raise ValueError("Start requires a new run directory; existing evidence is never overwritten")
    directory.mkdir(parents=True, mode=0o700)
    write_json(directory / "launch.json", {"command": command, "cwd": str(args.cwd.resolve()),
               "width": args.width, "height": args.height, "icd": str(args.icd.resolve()),
               "startup_timeout": args.startup_timeout, "method": args.method,
               "allow_physical_input": args.allow_physical_input, "weston": args.weston})
    with (directory / "supervisor.log").open("wb") as log:
        process = subprocess.Popen([sys.executable, str(Path(__file__).resolve()), "_serve",
                                    "--run-dir", str(directory)], stdout=log, stderr=log,
                                   stdin=subprocess.DEVNULL, start_new_session=True)
    deadline = time.monotonic() + args.startup_timeout + 35
    while time.monotonic() < deadline:
        path = directory / "state.json"
        if path.exists():
            state = json.loads(path.read_text())
            if state["status"] in ("ready", "failed", "stopped"):
                if state["status"] != "ready":
                    raise RuntimeError(f'Startup failed: {state.get("error", state)}; evidence: {directory}')
                return state
        if process.poll() is not None:
            raise RuntimeError(f"Supervisor exited: {process.returncode}; evidence: {directory}")
        time.sleep(0.1)
    process.terminate()
    raise RuntimeError(f"Supervisor readiness timeout; evidence: {directory}")


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    commands = result.add_subparsers(dest="action", required=True)
    launch = commands.add_parser("start")
    launch.add_argument("--run-dir", type=Path, required=True)
    launch.add_argument("--cwd", type=Path, default=Path.cwd())
    launch.add_argument("--width", type=int, default=1920)
    launch.add_argument("--height", type=int, default=1080)
    launch.add_argument("--startup-timeout", type=float, default=60.0)
    launch.add_argument("--icd", type=Path, default=Path("/usr/share/vulkan/icd.d/radeon_icd.x86_64.json"))
    launch.add_argument("--method", choices=("scripted_diagnostic", "adaptive_native", "manual_native"),
                        default="scripted_diagnostic")
    launch.add_argument("--allow-physical-input", action="store_true",
                        help="Explicit physical-seat opt-in, permitted only with manual_native")
    launch.add_argument("--weston", default=str(Path.home() / ".local/share/nullspace/toolchains/weston-15.0.1-fedora44/usr/bin/weston"),
                        help="Verified Weston 15.0.1 executable for inputless controlled sessions")
    launch.add_argument("command", nargs=argparse.REMAINDER)
    for action in ("status", "focus", "blur", "release", "stop", "record-stop", "recover", "_serve"):
        entry = commands.add_parser(action)
        entry.add_argument("--run-dir", type=Path, required=True)
    capture = commands.add_parser("screenshot")
    capture.add_argument("--run-dir", type=Path, required=True)
    capture.add_argument("--name", required=True)
    record = commands.add_parser("record")
    record.add_argument("--run-dir", type=Path, required=True)
    record.add_argument("--name", required=True)
    record.add_argument("--seconds", type=float, default=10.0)
    inject = commands.add_parser("input")
    inject.add_argument("--run-dir", type=Path, required=True)
    for name in ("key-down", "key-up", "tap"):
        inject.add_argument("--" + name, action="append", default=[])
    for name in ("button-down", "button-up", "click"):
        inject.add_argument("--" + name, type=int, action="append", default=[])
    inject.add_argument("--move", type=int, nargs=2, default=[0, 0], metavar=("DX", "DY"))
    inject.add_argument("--pointer", type=int, nargs=2, metavar=("X", "Y"),
                        help="Absolute game-window coordinates for visible menu pointer")
    inject.add_argument("--hold", type=float, default=0.0)
    inject.add_argument("--lease", type=float, default=10.0)
    inject.add_argument("--release", action="store_true")
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        if args.action == "_serve":
            from native_session import supervise
            return supervise(args.run_dir.resolve())
        if args.action == "start":
            result = start(args)
        elif args.action == "recover":
            from recover_session import recover
            result = recover(args.run_dir.resolve())
        else:
            request = {key: value for key, value in vars(args).items() if key != "run_dir"}
            if args.action == "status":
                state = json.loads((args.run_dir / "state.json").read_text())
                if state["status"] == "ready":
                    try:
                        result = send(args.run_dir, request)
                    except (OSError, RuntimeError):
                        # A normal game exit can close IPC while stop finalizes.
                        # Return the terminal manifest once present; never turn
                        # an unresolved live-session error into a success.
                        deadline = time.monotonic() + 5
                        while state["status"] == "ready" and time.monotonic() < deadline:
                            time.sleep(0.1)
                            state = json.loads((args.run_dir / "state.json").read_text())
                        if state["status"] == "ready":
                            raise
                        result = state
                else:
                    result = state
            else:
                result = send(args.run_dir, request)
            if args.action == "stop":
                deadline = time.monotonic() + 25
                while time.monotonic() < deadline:
                    state = json.loads((args.run_dir / "state.json").read_text())
                    if state["status"] in ("stopped", "failed"):
                        result = state
                        break
                    time.sleep(0.1)
                else:
                    raise RuntimeError("Supervisor did not finish cleanup within 25 seconds")
        print(json.dumps(result, indent=2, sort_keys=True))
        return 0
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        print(json.dumps({"ok": False, "error": str(error)}), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
