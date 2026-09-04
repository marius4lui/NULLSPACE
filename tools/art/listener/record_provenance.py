"""Hash original authoring/runtime files and intentional import metadata."""
from __future__ import annotations
import hashlib
import json
import subprocess
from recipe import ROOT, EXPORT, RUNTIME

records = []
for relative in ('tools/art/listener', 'art/source/blender/listener', 'art/source/textures/listener', 'art/exported/listener', 'game/assets/listener'):
    for path in sorted((ROOT / relative).rglob('*')):
        if not path.is_file() or path.is_symlink():
            continue
        parts = path.relative_to(ROOT).parts
        if any(part in ('node_modules', '.godot', '__pycache__', 'captures', 'evidence') for part in parts):
            continue
        if path.suffix in ('.blend1', '.blend2') or path.name == 'provenance.json':
            continue
        with path.open('rb') as stream:
            checksum = hashlib.file_digest(stream, 'sha256').hexdigest()
        records.append({'path': str(path.relative_to(ROOT)), 'bytes': path.stat().st_size, 'sha256': checksum})
result = {'schema': 1, 'creator': 'NULLSPACE delegated original Listener art production, GPT-6 Astra',
    'base_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
    'seed': 61429, 'external_content_inputs': [], 'licensing': 'Original project content; distribution license remains repository-owner decision. Tooling is not third-party game content.',
    'reproduction': 'Deterministic proportion/cage/sculpt/texture/rig/clip recipes and explicit GLB export. Blender container byte identity is not asserted.',
    'evidence_root': 'tools/art/listener/evidence', 'status': 'Bounded source candidate; native and independent acceptance PENDING; M11 incomplete', 'files': records}
payload = json.dumps(result, indent=2) + '\n'
(EXPORT / 'provenance.json').write_text(payload)
(RUNTIME / 'provenance.json').write_text(payload)
print('LISTENER_PROVENANCE_OK', len(records))
