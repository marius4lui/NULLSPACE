#!/usr/bin/env python3
"""Make the isolated preview point at the owned runtime assets, without copying sources."""
from pathlib import Path

root = Path(__file__).resolve().parents[3]
preview = root / "tools/art/environment/preview"
for relative, source in (("assets/environment", root / "game/assets/environment"), ("environment", root / "game/environment")):
    target = preview / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.is_symlink() and not target.exists():
        target.symlink_to(source, target_is_directory=True)
    elif target.resolve() != source.resolve():
        raise RuntimeError(f"Refusing to replace unrelated preview path: {target}")
print(f"M4_PREVIEW_STAGED {preview}")
