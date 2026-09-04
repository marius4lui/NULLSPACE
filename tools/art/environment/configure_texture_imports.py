#!/usr/bin/env python3
"""Apply/check the owned 3D PNG policy without regenerating Godot UIDs.

This is a mechanical import-sidecar rewrite, not a source-image transformation.
Godot must reimport afterward; verify_texture_imports.gd checks actual resources.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[3]
TEXTURES = ROOT / "game/assets/environment/textures"


def read_value(text: str, key: str) -> str:
    match = re.search(rf"(?m)^{re.escape(key)}=(.*)$", text)
    if match is None:
        raise ValueError(f"Missing existing import field {key!r}")
    return match.group(1)


def policy(name: str) -> dict[str, str]:
    normal = name.endswith("_normal.png")
    orm = name.endswith("_orm.png")
    color = name.endswith(("_basecolor.png", "_emission.png"))
    normal_name = name.removesuffix("_orm.png") + "_normal.png"
    # Explicit preset matches Godot4.7.2 ResourceImporterTexture enum definitions.
    # BC7 for subtle RGB color/packed data; BC5/RGTC for tangent-space normals.
    return {
        "compress/mode": "2",
        "compress/high_quality": "false" if normal else "true",
        "compress/normal_map": "1" if normal else "2",
        "compress/channel_pack": "0" if color else "1",
        "mipmaps/generate": "true",
        "mipmaps/limit": "-1",
        "roughness/mode": "3" if orm else "1",
        "roughness/src_normal": f'"res://assets/environment/textures/{normal_name}"' if orm else '""',
        "process/fix_alpha_border": "false",
        "process/premult_alpha": "false",
        "process/normal_map_invert_y": "false",
        "process/channel_remap/red": "0", "process/channel_remap/green": "1",
        "process/channel_remap/blue": "2", "process/channel_remap/alpha": "3",
        "process/hdr_as_srgb": "false",
        "process/size_limit": "0",
        "detect_3d/compress_to": "0",
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--apply", action="store_true")
    mode.add_argument("--check", action="store_true")
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    records: list[dict] = []
    mismatch = 0
    for source in sorted(TEXTURES.glob("*.png")):
        sidecar = Path(str(source) + ".import")
        before = sidecar.read_text()
        uid = read_value(before, "uid")
        expected = policy(source.name)
        current = {key: read_value(before, key) for key in expected}
        differences = {key: {"before": current[key], "expected": value} for key, value in expected.items() if current[key] != value}
        mismatch += bool(differences)
        if args.apply and differences:
            updated = before
            for key, value in expected.items():
                updated, count = re.subn(rf"(?m)^{re.escape(key)}=.*$", lambda _: f"{key}={value}", updated)
                if count != 1:
                    raise ValueError(f"Expected exactly one field {key!r} in {sidecar}")
            assert read_value(updated, "uid") == uid
            sidecar.write_text(updated)
        records.append({"source": str(source.relative_to(ROOT)), "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
                        "uid_preserved": uid, "sidecar_before_sha256": hashlib.sha256(before.encode()).hexdigest(),
                        "differences": differences, "policy": expected,
                        "source_color": source.name.endswith(("_basecolor.png", "_emission.png")),
                        "normal_convention": "+Y; unchanged RG channels" if source.name.endswith("_normal.png") else None})
    result = {"schema": 1, "mode": "apply" if args.apply else "check", "textures": len(records), "mismatched_before": mismatch,
              "result": "SIDECARS_UPDATED_REIMPORT_REQUIRED" if args.apply else ("POLICY_MATCHES" if mismatch == 0 else "POLICY_MISMATCH"),
              "note": "Actual VRAM formats/mipmaps/content must be verified after Godot reimport. No visual/performance PASS from this policy check.",
              "primary_source": "https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/editor/import/resource_importer_texture.cpp",
              "records": records}
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({key: result[key] for key in ["mode", "textures", "mismatched_before", "result"]}))
    if args.check and mismatch:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
