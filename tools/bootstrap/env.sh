# Source from Bash: source tools/bootstrap/env.sh
# Exact binaries are exposed without changing HOME or XDG data paths.
NULLSPACE_TOOLCHAIN_ROOT="${NULLSPACE_TOOLCHAIN_ROOT:-${XDG_DATA_HOME:-${HOME}/.local/share}/nullspace/toolchains}"
export NULLSPACE_TOOLCHAIN_ROOT
export NULLSPACE_GODOT="${NULLSPACE_TOOLCHAIN_ROOT}/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64"
export NULLSPACE_BLENDER="${NULLSPACE_TOOLCHAIN_ROOT}/blender-5.2.1/blender"
