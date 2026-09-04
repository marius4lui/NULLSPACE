"""Small support functions shared by the native QA supervisor and CLI."""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import subprocess
from typing import Any
from datetime import datetime, timezone


def utc() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds")


def run(command: list[str], *, env: dict[str, str] | None = None,
        cwd: str | Path | None = None, timeout: float = 15.0) -> str:
    result = subprocess.run(command, env=env, cwd=cwd, check=True, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=timeout)
    return result.stdout.strip()


def write_json(path: Path, data: Any) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    with temporary.open("w", encoding="utf-8") as stream:
        json.dump(data, stream, indent=2, sort_keys=True)
        stream.write("\n")
    temporary.replace(path)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def process_identity(pid: int) -> dict[str, int] | None:
    try:
        # comm can contain spaces and parentheses; fields after the last ')' are stable.
        parts = Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()
        return {"pid": pid, "start_ticks": int(parts[19]),
                "process_group": int(parts[2]), "session": int(parts[3])}
    except (FileNotFoundError, ProcessLookupError):
        return None


def same_process(identity: dict[str, int]) -> bool:
    current = process_identity(identity["pid"])
    return current is not None and all(current[key] == identity[key] for key in current)


def git_identity(cwd: Path) -> dict[str, Any]:
    try:
        return {"commit": run(["git", "rev-parse", "HEAD"], cwd=cwd),
                "clean": not bool(run(["git", "status", "--porcelain"], cwd=cwd)),
                "root": run(["git", "rev-parse", "--show-toplevel"], cwd=cwd)}
    except subprocess.CalledProcessError:
        return {"commit": None, "clean": None, "root": str(cwd)}


def source_hashes(directory: Path) -> dict[str, str]:
    extensions = {".py", ".gd", ".tscn", ".tres", ".godot", ".gdshader", ".gdextension"}
    if not directory.is_dir():
        return {}
    return {str(path.relative_to(directory)): sha256(path)
            for path in sorted(directory.rglob("*"))
            if path.is_file() and path.suffix in extensions
            and not any(part.startswith(".") or part == "__pycache__" for part in path.relative_to(directory).parts)}


def audio_defaults(env: dict[str, str]) -> dict[str, str]:
    return {"sink": run(["pactl", "get-default-sink"], env=env),
            "source": run(["pactl", "get-default-source"], env=env)}


def resolve_executable(value: str) -> Path:
    import shutil
    executable = shutil.which(value)
    if executable is None:
        raise ValueError(f"Executable does not exist or is not executable: {value}")
    return Path(executable).resolve()
