"""Capture only the verified game window and the run's private sink monitor."""
from __future__ import annotations

import json
import os
from pathlib import Path
import signal
import subprocess
from typing import Any

from qa_common import run, sha256, write_json
from window_capture import WindowCapture


def unload_owned_sink(env: dict[str, str], sink_name: str, module_id: str) -> bool:
    # pactl JSON module entries omit index on this PipeWire version. Sinks do
    # retain owner_module, so validate both the unique sink and that owner ID.
    sinks = json.loads(run(["pactl", "-f", "json", "list", "sinks"], env=env))
    sink = next((entry for entry in sinks if entry["name"] == sink_name), None)
    if sink is None:
        return False
    if str(sink["owner_module"]) != str(module_id):
        raise RuntimeError("Refused to unload sink whose module ownership no longer matches")
    run(["pactl", "unload-module", str(module_id)], env=env)
    remaining = json.loads(run(["pactl", "-f", "json", "list", "sinks"], env=env))
    if any(entry["name"] == sink_name for entry in remaining):
        raise RuntimeError("Owned sink remained after unload-module")
    return True


def owned_sink(env: dict[str, str], sink_name: str, game_pid: int,
               *, require_stream: bool = False) -> dict[str, Any]:
    sinks = json.loads(run(["pactl", "-f", "json", "list", "sinks"], env=env))
    sink = next((entry for entry in sinks if entry["name"] == sink_name), None)
    if sink is None:
        raise RuntimeError("Run's private audio sink is absent")
    streams = json.loads(run(["pactl", "-f", "json", "list", "sink-inputs"], env=env))
    selected = [entry for entry in streams if int(entry["sink"]) == int(sink["index"])]
    if any(str(entry.get("properties", {}).get("application.process.id")) != str(game_pid)
           for entry in selected):
        raise RuntimeError("Foreign audio stream connected to run's private sink")
    if require_stream and not selected:
        raise RuntimeError("Game has no verified stream on its private sink")
    return {"sink_name": sink_name, "sink_index": sink["index"],
            "monitor": sink_name + ".monitor", "owner_module": sink["owner_module"],
            "stream_ids": [entry["index"] for entry in selected],
            "stream_pids": [entry["properties"].get("application.process.id") for entry in selected],
            "sample_specification": sink["sample_specification"],
            "channel_map": sink["channel_map"]}


def target_path(directory: Path, name: str, extension: str) -> Path:
    if Path(name).name != name or name in ("", ".", "..") or not name.endswith(extension):
        raise ValueError(f"Artifact name must be a filename ending in {extension}")
    path = directory / name
    if path.exists():
        raise ValueError(f"Refusing to overwrite artifact: {path}")
    return path


def video_input(display_name: str, window: dict[str, Any], fps: int = 60) -> list[str]:
    return ["-thread_queue_size", "512", "-f", "x11grab", "-framerate", str(fps),
            "-draw_mouse", "0", "-window_id", str(window["window_id"]),
            "-video_size", f'{window["width"]}x{window["height"]}', "-i", display_name]


def screenshot(directory: Path, name: str, capture: WindowCapture) -> dict[str, Any]:
    path = target_path(directory, name, ".png")
    pixels, result = capture.snapshot()
    pixels.save(path)
    result.update({"path": str(path), "sha256": sha256(path)})
    write_json(path.with_suffix(".png.json"), result)
    return result


def start_recording(directory: Path, name: str, env: dict[str, str],
                    window: dict[str, Any], sink: dict[str, Any], seconds: float
                    ) -> tuple[subprocess.Popen[bytes], dict[str, Any]]:
    if not 1.0 <= seconds <= 7200.0:
        raise ValueError("Recording duration must be 1–7200 seconds")
    path = target_path(directory, name, ".mkv")
    command = ["ffmpeg", "-hide_banner", "-nostdin", "-loglevel", "info",
               *video_input(env["DISPLAY"], window),
               "-thread_queue_size", "512", "-f", "pulse", "-name", "NULLSPACE QA capture",
               "-sample_rate", "48000", "-channels", "2", "-fragment_size", "3840",
               "-wallclock", "1", "-i", sink["monitor"],
               "-map", "0:v:0", "-map", "1:a:0", "-c:v", "libx264", "-preset", "ultrafast",
               "-crf", "18", "-pix_fmt", "yuv420p", "-r", "60", "-fps_mode", "cfr",
               "-c:a", "flac", "-t", str(seconds), str(path)]
    with path.with_suffix(".ffmpeg.log").open("wb") as log:
        process = subprocess.Popen(command, env=env, stdout=log, stderr=log,
                                   stdin=subprocess.DEVNULL, start_new_session=True)
    return process, {"path": str(path), "pid": process.pid, "command": command,
                     "seconds_requested": seconds, "window": window, "audio": sink,
                     "method": "x11grab_composite_redirected_owned_window"}


def finish_recording(process: subprocess.Popen[bytes], metadata: dict[str, Any],
                     *, interrupt: bool = False) -> dict[str, Any]:
    if interrupt and process.poll() is None:
        process.send_signal(signal.SIGINT)
    try:
        process.wait(timeout=10)
    except subprocess.TimeoutExpired:
        process.terminate()
        try:
            process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=3)
    metadata["exit_code"] = process.returncode
    path = Path(metadata["path"])
    if path.exists() and path.stat().st_size:
        metadata["sha256"] = sha256(path)
        try:
            metadata["probe"] = json.loads(run(["ffprobe", "-v", "error", "-show_streams",
                                                "-show_format", "-of", "json", str(path)]))
        except subprocess.CalledProcessError as error:
            metadata["probe_error"] = error.stderr
    write_json(path.with_suffix(".mkv.json"), metadata)
    return metadata
