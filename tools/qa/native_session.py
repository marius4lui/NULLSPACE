"""Owned-process supervisor for isolated, real-time native game QA."""
from __future__ import annotations

import fcntl
import json
import os
from pathlib import Path
import secrets
import select
import signal
import socket
import struct
import subprocess
import tempfile
import time
from typing import Any

from media_capture import finish_recording, owned_sink, screenshot, start_recording, unload_owned_sink
from qa_common import (audio_defaults, git_identity, process_identity, run, sha256, source_hashes,
                       utc, write_json)
from x11_input import GameWindow


class NativeSession:
    def __init__(self, directory: Path) -> None:
        self.directory = directory
        self.launch = json.loads((directory / "launch.json").read_text())
        self.host_env = os.environ.copy()
        self.env = self.host_env.copy()
        self.state: dict[str, Any] = {"schema": 1, "status": "starting", "started_utc": utc(),
                                     "run_dir": str(directory), "supervisor": process_identity(os.getpid()),
                                     "method": self.launch["method"], "observed_or_heard": [],
                                     "experiential_review": "unverified"}
        self.processes: dict[str, subprocess.Popen[bytes]] = {}
        self.window: GameWindow | None = None
        self.server: socket.socket | None = None
        self.runtime: Path | None = None
        self.sink_module: str | None = None
        self.sink_name = "nullspace_qa_" + secrets.token_hex(8)
        self.recording: tuple[subprocess.Popen[bytes], dict[str, Any]] | None = None
        self.stop_requested = False
        self.gpu_lock: Any = None

    def save(self) -> None:
        write_json(self.directory / "state.json", self.state)

    def event(self, kind: str, **values: Any) -> None:
        with (self.directory / "supervisor-events.jsonl").open("a", encoding="utf-8") as stream:
            stream.write(json.dumps({"utc": utc(), "monotonic": time.monotonic(),
                                     "event": kind, **values}, sort_keys=True) + "\n")

    def spawn(self, name: str, command: list[str], env: dict[str, str],
              *, pass_fds: tuple[int, ...] = (), cwd: str | None = None
              ) -> subprocess.Popen[bytes]:
        with (self.directory / f"{name}.log").open("wb") as log:
            process = subprocess.Popen(command, env=env, cwd=cwd, stdout=log, stderr=log,
                                       stdin=subprocess.DEVNULL, pass_fds=pass_fds,
                                       start_new_session=True)
        self.processes[name] = process
        self.state.setdefault("processes", {})[name] = process_identity(process.pid)
        self.event("process_started", name=name, pid=process.pid, command=command)
        self.save()
        return process

    @staticmethod
    def write_authority(path: Path, display_number: str, cookie: bytes) -> None:
        # Xauthority records contain secret cookies. Never put a cookie in argv,
        # evidence or logs. Server and clients read only this mode-0600 file.
        fields = [socket.gethostname().encode(), display_number.encode(),
                  b"MIT-MAGIC-COOKIE-1", cookie]
        content = struct.pack(">H", 256)  # FamilyLocal
        for value in fields:
            content += struct.pack(">H", len(value)) + value
        descriptor = os.open(path, os.O_CREAT | os.O_WRONLY | os.O_TRUNC, 0o600)
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(content)

    def setup(self) -> None:
        runtime_parent = Path(self.host_env["XDG_RUNTIME_DIR"])
        if not self.host_env.get("WAYLAND_DISPLAY"):
            raise RuntimeError("A native Wayland compositor is required for rootful Xwayland")
        self.gpu_lock = (runtime_parent / "nullspace-qa-gpu.lock").open("a")
        try:
            fcntl.flock(self.gpu_lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise RuntimeError("Another native QA session owns the GPU validation lease") from error
        self.runtime = Path(tempfile.mkdtemp(prefix="nullspace-qa-", dir=runtime_parent))
        self.state["runtime_dir"] = str(self.runtime)
        authority = self.runtime / "Xauthority"
        cookie = secrets.token_bytes(16)
        self.write_authority(authority, "0", cookie)
        self.state["defaults_before"] = audio_defaults(self.host_env)
        self.state["host"] = {"os": run(["uname", "-srmo"]),
                              "xwayland": run(["rpm", "-q", "xorg-x11-server-Xwayland"]),
                              "ffmpeg": run(["ffmpeg", "-version"]).splitlines()[0],
                              "pipewire": run(["pipewire", "--version"])}
        self.state["harness_git"] = git_identity(Path(__file__).resolve().parents[2])
        self.state["harness_source_hashes"] = source_hashes(Path(__file__).resolve().parent)
        command = self.launch["command"]
        if "--path" in command and command.index("--path") + 1 < len(command):
            project = Path(command[command.index("--path") + 1])
            if not project.is_absolute():
                project = Path(self.launch["cwd"]) / project
        else:
            project = Path(command[0]).parent
        self.state["game_project"] = str(project.resolve())
        self.state["game_git"] = git_identity(project)
        self.state["game_source_hashes"] = source_hashes(project)
        self.state["executable_sha256"] = sha256(Path(self.launch["command"][0]))
        self.state["command"] = self.launch["command"]
        icd = Path(self.launch["icd"])
        if not icd.is_file():
            raise RuntimeError(f"Pinned RADV ICD file is unavailable: {icd}")
        self.env["VK_DRIVER_FILES"] = str(icd)
        self.env.pop("VK_ICD_FILENAMES", None)
        self.env.pop("LIBGL_ALWAYS_SOFTWARE", None)
        self.env.pop("MESA_LOADER_DRIVER_OVERRIDE", None)
        reader, writer = os.pipe()
        try:
            command = ["Xwayland", "-displayfd", str(writer), "-auth", str(authority),
                       "-nolisten", "tcp", "-noreset", "-geometry",
                       f'{self.launch["width"]}x{self.launch["height"]}',
                       "-glamor", "gl", "-nokeymap", "-a", "1", "-t", "0"]
            xwayland = self.spawn("xwayland", command, self.env, pass_fds=(writer,))
            os.close(writer)
            writer = -1
            if not select.select([reader], [], [], 20)[0]:
                raise RuntimeError("Xwayland did not publish a ready private display in 20 seconds")
            display_number = os.read(reader, 64).decode().strip()
            if not display_number.isdecimal() or xwayland.poll() is not None:
                raise RuntimeError("Xwayland startup failed; inspect xwayland.log")
        finally:
            os.close(reader)
            if writer != -1:
                os.close(writer)
        self.write_authority(authority, display_number, cookie)
        del cookie
        self.env["DISPLAY"] = ":" + display_number
        self.env["XAUTHORITY"] = str(authority)
        self.env.pop("WAYLAND_DISPLAY", None)
        # Keep runtime IPC available; isolate data/config/cache, not the host HOME.
        for suffix in ("data", "config", "cache", "state"):
            path = self.directory / "profile" / suffix
            path.mkdir(parents=True, exist_ok=True, mode=0o700)
            self.env["XDG_" + suffix.upper() + "_HOME"] = str(path)
        self.env["NULLSPACE_QA_RUN_DIR"] = str(self.directory)
        self.sink_module = run(["pactl", "load-module", "module-null-sink",
                                f"sink_name={self.sink_name}", "rate=48000", "channels=2",
                                "channel_map=front-left,front-right",
                                "sink_properties=device.description=NULLSPACE_QA_Private"], env=self.host_env)
        if not self.sink_module.isdecimal():
            raise RuntimeError("Pulse did not return a valid owned module identifier")
        self.env["PULSE_SINK"] = self.sink_name
        self.env["PULSE_SOURCE"] = self.sink_name + ".monitor"
        self.env["PULSE_SERVER"] = self.host_env.get("PULSE_SERVER", str(runtime_parent / "pulse/native"))
        self.state.update({"display": self.env["DISPLAY"], "authority": str(authority),
                           "sink_name": self.sink_name, "sink_module": self.sink_module,
                           "monitor": self.sink_name + ".monitor",
                           "profile": str(self.directory / "profile"),
                           "gpu_icd": str(icd)})
        self.save()
        gpu = run(["vulkaninfo", "--summary"], env=self.env, timeout=20)
        (self.directory / "vulkaninfo.txt").write_text(gpu + "\n")
        if "DRIVER_ID_MESA_RADV" not in gpu or "PHYSICAL_DEVICE_TYPE_CPU" in gpu:
            raise RuntimeError("Private display does not expose exclusively real RADV hardware")
        self.state["vulkan_device_lines"] = [line.strip() for line in gpu.splitlines()
                                              if any(key in line for key in ("deviceName", "deviceType", "driverName", "driverInfo"))]
        game = self.spawn("game", self.launch["command"], self.env, cwd=self.launch["cwd"])
        self.window = GameWindow(self.env["DISPLAY"], str(authority), game.pid)
        deadline = time.monotonic() + float(self.launch["startup_timeout"])
        while not self.window.discover():
            if game.poll() is not None:
                raise RuntimeError(f"Game exited before its window appeared: {game.returncode}; inspect game.log")
            if time.monotonic() > deadline:
                raise RuntimeError("No viewable owned game window before startup timeout")
            time.sleep(0.1)
        self.state["window"] = self.window.focus()
        self.state["audio"] = owned_sink(self.host_env, self.sink_name, game.pid)
        self.server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.server.bind(str(self.runtime / "control.sock"))
        self.server.listen(4)
        self.server.settimeout(0.2)
        self.state["control_socket"] = str(self.runtime / "control.sock")
        self.state["status"] = "ready"
        self.state["ready_utc"] = utc()
        self.save()
        self.event("session_ready", window=self.state["window"], audio=self.state["audio"])

    def handle(self, request: dict[str, Any]) -> dict[str, Any]:
        assert self.window is not None
        action = request.get("action")
        self.event("request", request=request)
        if action == "stop":
            self.stop_requested = True
            self.window.release()
            return {"stopping": True}
        if action == "release":
            self.window.release()
            return self.window.status()
        if action == "input":
            result = self.window.apply(request)
            self.state["window"] = result
            self.save()
            self.event("xtest_dispatched", state=result)
            return result
        if action == "focus":
            return self.window.focus()
        if action == "blur":
            return self.window.blur()
        if action == "status":
            return {"window": self.window.status(), "audio": owned_sink(
                self.host_env, self.sink_name, self.processes["game"].pid),
                    "recording": self.recording[1] if self.recording else None,
                    "status": self.state["status"]}
        if action == "screenshot":
            result = screenshot(self.directory, request["name"], self.env, self.window.status())
            self.event("screenshot_saved", **result)
            return result
        if action == "record":
            if self.recording is not None:
                raise RuntimeError("Recording already active")
            audio = owned_sink(self.host_env, self.sink_name, self.processes["game"].pid,
                               require_stream=True)
            self.recording = start_recording(self.directory, request["name"], self.env,
                                             self.window.status(), audio, float(request["seconds"]))
            self.state["recording"] = self.recording[1]
            self.state["processes"]["recording"] = process_identity(self.recording[0].pid)
            self.save()
            return self.recording[1]
        if action == "record-stop":
            if self.recording is None:
                raise RuntimeError("No active recording")
            result = finish_recording(*self.recording, interrupt=True)
            self.recording = None
            self.state.pop("recording", None)
            self.save()
            self.event("recording_finished", path=result["path"], exit_code=result["exit_code"])
            return result
        raise ValueError(f"Unknown action: {action}")

    def serve(self) -> None:
        assert self.server is not None and self.window is not None
        last_health = 0.0
        while not self.stop_requested:
            for name, process in self.processes.items():
                if process.poll() is not None:
                    self.event("process_exited", name=name, exit_code=process.returncode)
                    if name == "game" and process.returncode == 0:
                        self.stop_requested = True
                        break
                    raise RuntimeError(f"Owned {name} exited unexpectedly: {process.returncode}")
            if self.stop_requested:
                break
            if self.window.watchdog():
                self.event("key_lease_expired_all_released")
            if self.recording and self.recording[0].poll() is not None:
                result = finish_recording(*self.recording)
                self.recording = None
                self.state.pop("recording", None)
                self.save()
                self.event("recording_finished", path=result["path"], exit_code=result["exit_code"])
            if time.monotonic() - last_health >= 1.0:
                window = self.window.status()
                if self.recording:
                    expected = self.recording[1]["window"]
                    if any(window[key] != expected[key] for key in ("window_id", "width", "height")):
                        raise RuntimeError("Game capture target changed geometry during recording")
                    owned_sink(self.host_env, self.sink_name, self.processes["game"].pid,
                               require_stream=True)
                if (self.window.keys or self.window.buttons) and not window["focused"]:
                    self.window.release()
                    self.event("focus_lost_all_keys_released")
                last_health = time.monotonic()
            try:
                client, _ = self.server.accept()
            except socket.timeout:
                continue
            with client:
                client.settimeout(15)
                try:
                    data = b""
                    while b"\n" not in data:
                        block = client.recv(8192)
                        if not block:
                            raise ValueError("Incomplete command")
                        data += block
                        if len(data) > 65536:
                            raise ValueError("Command too large")
                    request = json.loads(data.split(b"\n", 1)[0])
                    response = {"ok": True, "result": self.handle(request)}
                except Exception as error:
                    self.window.release()
                    self.event("command_failed_all_keys_released", error=str(error))
                    response = {"ok": False, "error": str(error)}
                try:
                    client.sendall(json.dumps(response).encode() + b"\n")
                except (BrokenPipeError, ConnectionResetError):
                    self.window.release()

    def cleanup(self) -> None:
        errors = []
        self.event("cleanup_started")
        if self.window is not None:
            try:
                self.window.release()
                self.event("cleanup_keys_released")
                time.sleep(0.12)
            except Exception as error:
                errors.append(f"key release: {error}")
        if self.recording:
            try:
                finish_recording(*self.recording, interrupt=True)
            except Exception as error:
                errors.append(f"recording: {error}")
        if self.window is not None:
            try:
                self.window.close()
            except Exception as error:
                errors.append(f"X connection: {error}")
        for name in ("game", "xwayland"):
            process = self.processes.get(name)
            if process is not None and process.poll() is None:
                # Popen owns this exact PID and it has not been reaped/reused.
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait(timeout=3)
            if process is not None:
                self.state["processes"][name]["exit_code"] = process.returncode
        if self.sink_module is not None:
            try:
                if unload_owned_sink(self.host_env, self.sink_name, self.sink_module):
                    self.event("owned_sink_unloaded", module=self.sink_module, sink=self.sink_name)
            except Exception as error:
                errors.append(f"sink: {error}")
        if self.server is not None:
            self.server.close()
        if self.runtime is not None:
            for name in ("control.sock", "Xauthority"):
                try:
                    (self.runtime / name).unlink(missing_ok=True)
                except OSError as error:
                    errors.append(f"private {name}: {error}")
            try:
                self.runtime.rmdir()
            except OSError as error:
                errors.append(f"private directory: {error}")
        if self.gpu_lock is not None:
            self.gpu_lock.close()
        try:
            self.state["defaults_after"] = audio_defaults(self.host_env)
            self.state["host_defaults_unchanged"] = self.state.get("defaults_before") == self.state["defaults_after"]
        except Exception as error:
            errors.append(f"audio defaults: {error}")
        self.state["cleanup_errors"] = errors
        self.state["ended_utc"] = utc()
        self.state["status"] = "failed" if self.state.get("error") or errors else "stopped"
        self.save()
        self.event("cleanup_finished", errors=errors, defaults_unchanged=self.state.get("host_defaults_unchanged"))


def supervise(directory: Path) -> int:
    session = NativeSession(directory)
    def stop(_signum: int, _frame: Any) -> None:
        session.stop_requested = True
    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    try:
        session.save()
        session.setup()
        session.serve()
    except Exception as error:
        session.state["error"] = str(error)
        session.event("session_failed", error=str(error))
    finally:
        session.cleanup()
    return 1 if session.state["status"] == "failed" else 0
