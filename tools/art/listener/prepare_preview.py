"""Stage an ignored preview link to committed runtime data, not editable Blender."""
from recipe import ROOT, RUNTIME

target = ROOT / "tools/art/listener/preview/assets/listener"
target.parent.mkdir(parents=True, exist_ok=True)
if not target.exists() and not target.is_symlink():
    target.symlink_to(RUNTIME, target_is_directory=True)
elif target.resolve() != RUNTIME.resolve():
    raise RuntimeError(f"Refusing to replace unrelated asset link: {target}")
print("LISTENER_PREVIEW_STAGED")
