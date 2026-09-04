#!/usr/bin/env python3
"""Install only the pinned official Linux tools; never substitute versions."""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import fcntl
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import tarfile
import tempfile
import time
from typing import Any
import zipfile


HERE = Path(__file__).resolve().parent


def digest(path: Path, algorithm: str = "sha256") -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, algorithm).hexdigest()


def fetch(url: str, destination: Path, offline: bool, refresh: bool = False) -> None:
    if destination.is_file() and (offline or not refresh):
        return
    if offline:
        raise RuntimeError(f"Offline cache missing: {destination}")
    temporary = destination.with_name(destination.name + ".download")
    subprocess.run(
        ["curl", "--fail", "--location", "--silent", "--show-error", "--retry", "3",
         "--connect-timeout", "20", "--max-time", "3600", "--proto", "=https",
         "--proto-redir", "=https", "--output", str(temporary), url],
        check=True,
    )
    temporary.replace(destination)


def fetch_archive(artifact: dict[str, Any], destination: Path, offline: bool) -> None:
    """Use bounded HTTP ranges for large bundles; authenticate the assembled bytes below."""
    if destination.is_file():
        return
    if offline or artifact["bytes"] < 256 * 1024 * 1024:
        fetch(artifact["url"], destination, offline)
        return
    parts = destination.with_name(destination.name + ".parts")
    parts.mkdir(exist_ok=True)
    chunk_size = 32 * 1024 * 1024
    ranges = [(start, min(start + chunk_size, artifact["bytes"]) - 1)
              for start in range(0, artifact["bytes"], chunk_size)]

    def fetch_range(bounds: tuple[int, int]) -> Path:
        start, end = bounds
        part = parts / f"{start:012d}.part"
        length = end - start + 1
        if part.is_file() and part.stat().st_size == length:
            return part
        partial = part.with_suffix(".download")
        subprocess.run(
            ["curl", "--fail", "--location", "--silent", "--show-error", "--retry", "3",
             "--connect-timeout", "20", "--max-time", "900", "--proto", "=https",
             "--proto-redir", "=https", "--range", f"{start}-{end}",
             "--max-filesize", str(length), "--output", str(partial), artifact["url"]],
            check=True,
        )
        if partial.stat().st_size != length:
            raise RuntimeError(f"Server did not provide requested archive range: {start}-{end}")
        partial.replace(part)
        return part

    with ThreadPoolExecutor(max_workers=6) as workers:
        ordered_parts = list(workers.map(fetch_range, ranges))
    temporary = destination.with_name(destination.name + ".download")
    with temporary.open("wb") as output:
        for part in ordered_parts:
            with part.open("rb") as source:
                shutil.copyfileobj(source, output, length=1024 * 1024)
    temporary.replace(destination)


def verify_archive(artifact: dict[str, Any], cache: Path, offline: bool) -> Path:
    manifest = cache / (artifact["name"] + "-published-checksums.txt")
    fetch(artifact["published_manifest"], manifest, offline, refresh=True)
    matching = [line.split()[0].lower() for line in manifest.read_text().splitlines()
                if len(line.split()) == 2
                and line.split()[1].lstrip("*") == artifact["filename"]]
    if matching != [artifact["published_digest"]]:
        raise RuntimeError(f"{artifact['name']}: official manifest differs from lock")
    archive = cache / artifact["filename"]
    print(f"{artifact['name']}: fetching/verifying {artifact['filename']}", flush=True)
    fetch_archive(artifact, archive, offline)
    if archive.stat().st_size != artifact["bytes"]:
        raise RuntimeError(f"{archive}: archive size differs from lock; kept for diagnosis")
    actual_sha256 = digest(archive)
    actual_published = digest(archive, artifact["published_algorithm"])
    if actual_sha256 != artifact["sha256"] or actual_published != matching[0]:
        raise RuntimeError(f"{archive}: checksum mismatch; kept for diagnosis")
    print(f"{artifact['name']}: VERIFIED sha256={actual_sha256}", flush=True)
    return archive


def file_inventory(directory: Path) -> dict[str, dict[str, str]]:
    inventory: dict[str, dict[str, str]] = {}
    for path in sorted(directory.rglob("*")):
        relative = path.relative_to(directory).as_posix()
        if (relative == ".nullspace-install.json" or "__pycache__" in path.parts
                or path.suffix in {".pyc", ".pyo"}):
            continue
        if path.is_symlink():
            inventory[relative] = {"symlink": os.readlink(path)}
        elif path.is_file():
            inventory[relative] = {"sha256": digest(path)}
    return inventory


def verify_existing(destination: Path, artifact: dict[str, Any]) -> bool:
    if not destination.exists():
        return False
    receipt = destination / ".nullspace-install.json"
    if not receipt.is_file():
        raise RuntimeError(f"Unmanaged directory exists; refusing overwrite: {destination}")
    record = json.loads(receipt.read_text())
    if record.get("archive_sha256") != artifact["sha256"]:
        raise RuntimeError(f"Installed receipt differs from lock: {destination}")
    if file_inventory(destination) != record["files"]:
        raise RuntimeError(f"Installed files changed; refusing silent repair: {destination}")
    return True


def extract(archive: Path, staging: Path) -> None:
    if zipfile.is_zipfile(archive):
        with zipfile.ZipFile(archive) as bundle:
            for item in bundle.infolist():
                target = (staging / item.filename).resolve()
                if not target.is_relative_to(staging.resolve()):
                    raise RuntimeError(f"Unsafe zip member: {item.filename}")
            bundle.extractall(staging)
            for item in bundle.infolist():
                mode = (item.external_attr >> 16) & 0o777
                if mode and not item.is_dir():
                    (staging / item.filename).chmod(mode)
    else:
        with tarfile.open(archive) as bundle:
            bundle.extractall(staging, filter="data")


def install_archive(artifact: dict[str, Any], archive: Path, root: Path,
                    template_root: Path) -> Path:
    parent = template_root if artifact["name"] == "templates" else root
    destination = parent / artifact["directory"]
    if verify_existing(destination, artifact):
        print(f"{artifact['name']}: existing install integrity VERIFIED", flush=True)
        return destination
    parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".nullspace-extract-", dir=parent) as temporary:
        staging = Path(temporary)
        extract(archive, staging)
        extracted = staging / artifact["archive_prefix"]
        if artifact["executable"]:
            binary = extracted / artifact["executable"]
            if not binary.is_file():
                raise RuntimeError(f"Required executable missing: {binary}")
            binary.chmod(binary.stat().st_mode | 0o111)
        else:
            marker = (extracted / "version.txt").read_text().strip()
            if marker != artifact["version"]:
                raise RuntimeError(f"Template version mismatch: {marker}")
        receipt = {"schema": 1, "archive_sha256": artifact["sha256"],
                   "archive_url": artifact["url"], "files": file_inventory(extracted)}
        (extracted / ".nullspace-install.json").write_text(json.dumps(receipt, indent=2) + "\n")
        if extracted == staging:
            # Rename into a sibling first so TemporaryDirectory owns only its empty staging path.
            destination.mkdir()
            for child in tuple(staging.iterdir()):
                child.rename(destination / child.name)
        else:
            extracted.rename(destination)
    print(f"{artifact['name']}: installed {destination}", flush=True)
    return destination


def version(artifact: dict[str, Any], destination: Path) -> dict[str, str]:
    if artifact["executable"] is None:
        value = (destination / "version.txt").read_text().strip()
        return {"version": value, "path": str(destination)}
    binary = destination / artifact["executable"]
    result = subprocess.run([str(binary), "--version"], check=True,
                            capture_output=True, text=True, timeout=30)
    value = result.stdout.strip()
    if artifact["name"] == "godot":
        valid = value.startswith("4.7.2.stable.official.")
    else:
        valid = value.splitlines()[0] == "Blender 5.2.1 LTS"
    if not valid:
        raise RuntimeError(f"Actual executable version mismatch: {value}")
    print(f"{artifact['name']}: actual version {value.splitlines()[0]}", flush=True)
    return {"version": value, "path": str(binary), "binary_sha256": digest(binary)}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    data_home = Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share")))
    parser.add_argument("--root", type=Path, default=data_home / "nullspace/toolchains")
    parser.add_argument("--template-root", type=Path, default=data_home / "godot/export_templates")
    parser.add_argument("--offline", action="store_true", help="Use already verified download cache")
    parser.add_argument("--report", type=Path, help="Write machine-readable installed-version evidence")
    args = parser.parse_args()
    if platform.system() != "Linux" or platform.machine() != "x86_64":
        raise RuntimeError("This lock supports Linux x86_64 only")
    for program in ("curl", "git", "ffmpeg", "magick", "rg", "file"):
        if shutil.which(program) is None:
            raise RuntimeError(f"Required utility missing: {program}; use Fedora packages, never Snap")
    root = args.root.expanduser().resolve()
    template_root = args.template_root.expanduser().resolve()
    root.mkdir(parents=True, exist_ok=True)
    cache = root / "downloads"
    cache.mkdir(exist_ok=True)
    lock = json.loads((HERE / "toolchain.lock.json").read_text())
    started = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    with (root / ".bootstrap.lock").open("a+") as lock_file:
        fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
        artifacts = lock["artifacts"]
        report: dict[str, Any] = {"schema": 1, "started_utc": started,
                                  "lock_sha256": digest(HERE / "toolchain.lock.json"),
                                  "platform": platform.platform(), "artifacts": {}}
        with ThreadPoolExecutor(max_workers=3) as workers:
            pending = {workers.submit(verify_archive, artifact, cache, args.offline): artifact
                       for artifact in artifacts}
            failures: list[str] = []
            for completed in as_completed(pending):
                artifact = pending[completed]
                try:
                    archive = completed.result()
                    destination = install_archive(artifact, archive, root, template_root)
                    report["artifacts"][artifact["name"]] = version(artifact, destination) | {
                        "archive_sha256": digest(archive), "archive_bytes": archive.stat().st_size,
                        "published_algorithm": artifact["published_algorithm"],
                        "published_digest": artifact["published_digest"]}
                except Exception as error:
                    failures.append(f"{artifact['name']}: {error}")
                    print(f"FAILED {failures[-1]}", flush=True)
        report["finished_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        if args.report:
            args.report.parent.mkdir(parents=True, exist_ok=True)
            args.report.write_text(json.dumps(report, indent=2) + "\n")
        if failures:
            raise RuntimeError("; ".join(failures))
        print("Pinned toolchain verification complete. No game or release gate is implied.", flush=True)


if __name__ == "__main__":
    main()
