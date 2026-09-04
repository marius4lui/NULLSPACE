#!/usr/bin/env python3
"""Hash public run artifacts; credentials and per-run profiles are excluded."""
from __future__ import annotations

import argparse
from pathlib import Path
import json

from qa_common import git_identity, sha256, utc, write_json


def manifest(directory: Path) -> dict:
    state = json.loads((directory / "state.json").read_text())
    if state["status"] not in ("stopped", "failed"):
        raise RuntimeError("Finalize evidence only after the session stops")
    allowed = {".json", ".jsonl", ".png", ".mkv", ".wav", ".ogg", ".log", ".txt", ".md"}
    artifacts = {}
    for path in sorted(directory.iterdir()):
        if path.is_file() and path.suffix in allowed and path.name not in ("manifest.json", "supervisor.log", "flash-frame-stats.txt"):
            artifacts[path.name] = {"sha256": sha256(path), "bytes": path.stat().st_size}
    result = {"schema": 1, "packaged_utc": utc(), "package_git": git_identity(Path(__file__).resolve().parents[2]),
              "runtime_provenance": "state.json; game.log; fixture-events.jsonl when present",
              "artifacts": artifacts, "profile_and_credentials": "excluded",
              "meaning": "Artifact hashes establish identity; they do not assert review, hearing or quality."}
    write_json(directory / "manifest.json", result)
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(manifest(args.run_dir.resolve()), indent=2))
