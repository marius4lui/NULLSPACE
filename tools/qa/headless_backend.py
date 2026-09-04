"""Owned, inputless Weston process; never a nested host-seat or DRM backend."""
from __future__ import annotations

import os
from pathlib import Path
import socket
import stat
import struct
import time
from typing import Any, Callable

from qa_common import resolve_executable, run, sha256


def start_headless(binary: str, runtime: Path, directory: Path, env: dict[str, str],
                   width: int, height: int, spawn: Callable[..., Any]) -> dict[str, Any]:
    executable = resolve_executable(binary)
    wayland_runtime = runtime / "wayland-runtime"
    wayland_runtime.mkdir(mode=0o700)
    compositor_env = env.copy()
    for key in ("DISPLAY", "WAYLAND_DISPLAY", "WAYLAND_SOCKET", "XAUTHORITY", "XDG_SEAT",
                "XDG_SESSION_ID", "DBUS_SESSION_BUS_ADDRESS", "WESTON_CONFIG_FILE"):
        compositor_env.pop(key, None)
    compositor_env["XDG_RUNTIME_DIR"] = str(wayland_runtime)
    # --no-config prevents host configuration; caches remain in this run.
    for suffix in ("data", "config", "cache", "state"):
        path = directory / "profile" / ("compositor-" + suffix)
        path.mkdir(parents=True, mode=0o700)
        compositor_env["XDG_" + suffix.upper() + "_HOME"] = str(path)
    # Supports Fedora's signed RPMs unpacked in a user-local prefix, or /usr.
    # The overrides apply to Weston only, never the game/Xwayland process.
    library = executable.parent.parent / "lib64"
    modules = sorted((library / "libweston-15").glob("*.so")) + sorted((library / "weston").glob("*.so"))
    if not modules:
        raise RuntimeError("Expected Weston 15 modules next to executable; see docs/NATIVE_QA.md")
    compositor_env["LD_LIBRARY_PATH"] = f"{library}:{library / 'weston'}"
    compositor_env["WESTON_MODULE_MAP"] = ";".join(f"{path.name}={path}" for path in modules) + ";"
    version = run([str(executable), "--version"], env=compositor_env)
    if version != "weston 15.0.1":
        raise RuntimeError(f"Unverified Weston version: {version}; expected weston 15.0.1")
    command = [str(executable), "--backend=headless", "--renderer=gl", "--fake-seat",
               "--no-config", "--socket=wayland-private", f"--width={width}", f"--height={height}",
               "--refresh-rate=60000", "--idle-time=0", "--shell=kiosk-shell.so"]
    process = spawn("weston", command, compositor_env)
    endpoint = wayland_runtime / "wayland-private"
    deadline = time.monotonic() + 15
    while not endpoint.exists():
        if process.poll() is not None:
            raise RuntimeError("Inputless Weston exited before readiness; inspect weston.log")
        if time.monotonic() >= deadline:
            raise RuntimeError("Inputless Weston socket readiness timeout")
        time.sleep(0.05)
    info = endpoint.lstat()
    if not stat.S_ISSOCK(info.st_mode) or info.st_uid != os.getuid():
        raise RuntimeError("Private Wayland socket type/owner mismatch")
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.connect(str(endpoint))
        peer = struct.unpack("3i", client.getsockopt(socket.SOL_SOCKET, socket.SO_PEERCRED, 12))
    if peer[0] != process.pid or peer[1] != os.getuid():
        raise RuntimeError("Private Wayland socket peer is not the owned Weston PID/UID")
    descriptors = []
    for path in Path(f"/proc/{process.pid}/fd").iterdir():
        try:
            target = os.readlink(path)
        except FileNotFoundError:
            continue
        if target.startswith("/dev/input/") or target.startswith("/dev/dri/card"):
            raise RuntimeError("Inputless compositor unexpectedly opened a physical input/display device")
        if target.startswith("/dev/"):
            descriptors.append(target)
    return {"backend": "weston_headless_gl_fake_seat", "version": version,
            "executable": str(executable), "executable_sha256": sha256(executable),
            "command": command, "runtime": str(wayland_runtime), "socket": str(endpoint),
            "socket_peer": {"pid": peer[0], "uid": peer[1], "gid": peer[2]},
            "device_descriptors": sorted(set(descriptors)), "host_parent_display": None,
            "module_hashes": {str(path): sha256(path) for path in modules},
            "meaning": "Headless backend has no physical input/output or parent compositor; fake seat is protocol compatibility only."}


def cleanup_wayland_runtime(runtime: Path) -> None:
    """Only known files in our exact private child directory; never recursive."""
    child = runtime / "wayland-runtime"
    if not child.exists():
        return
    if child.is_symlink() or child.stat().st_uid != os.getuid():
        raise RuntimeError("Unexpected private Wayland runtime owner/symlink")
    for name in ("wayland-private", "wayland-private.lock"):
        (child / name).unlink(missing_ok=True)
    if (child / "dbus-1").exists():
        (child / "dbus-1").rmdir()
    child.rmdir()
