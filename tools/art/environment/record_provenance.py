#!/usr/bin/env python3
"""Record explicit original source/export/runtime hashes without engine caches."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[3]
OUTPUT = ROOT / "art/exported/environment/provenance.json"


def digest(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def main() -> None:
    records = []
    roots = ("tools/art/environment", "art/source/blender/architecture", "art/source/textures/environment",
             "art/exported/environment", "game/assets/environment", "game/environment")
    for relative in roots:
        for path in sorted((ROOT / relative).rglob("*")):
            if not path.is_file() or path.is_symlink():
                continue
            parts = path.relative_to(ROOT).parts
            if any(part in ("node_modules", ".godot", "__pycache__", "captures") for part in parts):
                continue
            if path.name in ("provenance.json",) or path.suffix in (".blend1", ".blend2"):
                continue
            records.append({"path": str(path.relative_to(ROOT)), "bytes": path.stat().st_size, "sha256": digest(path)})
    record = {
        "schema": 1,
        "asset_family": "NULLSPACE original environment foundation and M4 reference room",
        "recipe_seed": 41073,
        "creator": "Delegated NULLSPACE environment-art production agent, GPT-6 Astra",
        "content_inputs": "Original procedural geometry, mathematical textures and directed composition only; no external game-content assets.",
        "source_pipeline": ["generate_textures.py", "build_environment.py", "validate_exports.cjs", "record_provenance.py"],
        "software": {"Blender": "5.2.1 LTS / 9e2066aef7ef", "Godot": "4.7.2 stable / ed1daf0bf",
                     "Python": "3.14.7 (host)", "numpy": "2.4.6 (host)", "Pillow": "12.3.0", "Khronos glTF validator": "2.0.0-dev.3.10"},
        "source_reproduction": "Pinned recipes reproduce material and mesh exports. Blender master byte identity is not asserted; editable sources are retained.",
        "runtime_reproduction": "Explicit glTF/binary/PNG files plus intentional Godot .import and .uid metadata are retained; engine .godot cache is excluded.",
        "licensing": "Original project content; distribution license is the repository owner's decision. Listed software dependencies are authoring tooling, not third-party art.",
        "base_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        "files": records,
    }
    OUTPUT.write_text(json.dumps(record, indent=2) + "\n")
    (ROOT / "game/assets/environment/provenance.json").write_bytes(OUTPUT.read_bytes())
    print(f"PROVENANCE_OK {len(records)} explicitly hashed original source/runtime files")


if __name__ == "__main__":
    main()
