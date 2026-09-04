"""Conservative orphan recovery; never kill a PID without start-time identity."""
from __future__ import annotations

import json
import os
from pathlib import Path
import signal
import time
from typing import Any

from media_capture import unload_owned_sink
from qa_common import audio_defaults, same_process, utc, write_json
from x11_input import GameWindow


def recover(directory: Path) -> dict[str, Any]:
    state = json.loads((directory / "state.json").read_text())
    if same_process(state["supervisor"]):
        raise RuntimeError("Supervisor is still alive; use stop instead of recovery")
    report: dict[str, Any] = {"utc": utc(), "defaults_before": audio_defaults(os.environ.copy()),
                              "actions": [], "errors": []}
    processes = state.get("processes", {})
    game = processes.get("game")
    xwayland = processes.get("xwayland")
    if game and xwayland and same_process(game) and same_process(xwayland):
        try:
            target = GameWindow(state["display"], state["authority"], game["pid"])
            if target.discover():
                target.release_all_private()
                report["actions"].append("released_query_keymap_on_owned_private_window")
                time.sleep(0.12)
            target.close()
        except Exception as error:
            report["errors"].append(f"private key release: {error}")
    for name in ("recording", "game", "xwayland"):
        identity = processes.get(name)
        if not identity or not same_process(identity):
            continue
        os.kill(identity["pid"], signal.SIGINT if name == "recording" else signal.SIGTERM)
        deadline = time.monotonic() + 5
        while same_process(identity) and time.monotonic() < deadline:
            time.sleep(0.1)
        if same_process(identity):
            os.kill(identity["pid"], signal.SIGKILL)
        report["actions"].append({"stopped": name, "identity": identity})
    if state.get("sink_module"):
        try:
            removed = unload_owned_sink(os.environ.copy(), state["sink_name"], state["sink_module"])
            report["actions"].append({"owned_sink_removed": removed, "name": state["sink_name"]})
        except Exception as error:
            report["errors"].append(f"sink: {error}")
    runtime = Path(state["runtime_dir"]) if state.get("runtime_dir") else None
    expected_parent = Path(os.environ["XDG_RUNTIME_DIR"])
    if runtime and runtime.exists():
        if runtime.parent != expected_parent or not runtime.name.startswith("nullspace-qa-") or runtime.is_symlink():
            raise RuntimeError("Refused cleanup of unrecognized runtime path")
        for name in ("control.sock", "Xauthority"):
            (runtime / name).unlink(missing_ok=True)
        runtime.rmdir()
        report["actions"].append("removed_owned_runtime_directory")
    report["defaults_after"] = audio_defaults(os.environ.copy())
    report["host_defaults_unchanged"] = report["defaults_before"] == report["defaults_after"]
    report["status"] = "RECOVERED" if not report["errors"] else "RECOVERY_ERRORS"
    write_json(directory / "recovery.json", report)
    return report
