#!/usr/bin/env bash
# Reproduce the current game export from checked-in production assets; no Blender required.
set -euo pipefail
nullspace_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$nullspace_root"
nullspace_godot="${NULLSPACE_GODOT_BIN:-godot}"
nullspace_platform="${1:-linux}"
case "$nullspace_platform" in linux|windows|all) ;; *) echo 'Usage: bash tools/build.sh [linux|windows|all]' >&2; exit 2 ;; esac
nullspace_version="$("$nullspace_godot" --version)"
case "$nullspace_version" in 4.7.2.stable*) ;; *) echo "Godot 4.7.2 stable required; found $nullspace_version" >&2; exit 2 ;; esac
"$nullspace_godot" --headless --editor --path game --import --quit
for nullspace_target in linux windows; do
  if [[ "$nullspace_platform" != all && "$nullspace_platform" != "$nullspace_target" ]]; then continue; fi
  mkdir -p "build/$nullspace_target"
  if [[ "$nullspace_target" == linux ]]; then
    nullspace_preset='Linux x86_64'
    nullspace_binary='nullspace.x86_64'
  else
    nullspace_preset='Windows x86_64'
    nullspace_binary='NULLSPACE.exe'
  fi
  "$nullspace_godot" --headless --path game --export-release "$nullspace_preset" "$nullspace_root/build/$nullspace_target/$nullspace_binary"
  cp docs/PLAYTEST.md "build/$nullspace_target/README.md"
  cp CREDITS.md LICENSES.md RELEASE_NOTES.md game/licenses/GODOT_THIRD_PARTY.txt "build/$nullspace_target/"
  {
    git rev-parse HEAD
    git diff --quiet -- game tools/art || printf 'Working tree contains uncommitted runtime/art changes.\n'
    printf 'Engine: %s\nPreset: %s\n' "$nullspace_version" "$nullspace_preset"
  } > "build/$nullspace_target/BUILD_INFO.txt"
  (cd "build/$nullspace_target" && sha256sum "$nullspace_binary" > SHA256SUMS)
done
