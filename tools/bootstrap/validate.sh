#!/usr/bin/env bash
set -euo pipefail
bootstrap_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${bootstrap_dir}/env.sh"
report_dir="${1:-${bootstrap_dir}/../../evidence/logs/bootstrap/validation}"
run_logged() {
  local log_path="$1"
  shift
  "$@" 2>&1 | tee "${log_path}"
  if rg -n 'ERROR:|SCRIPT ERROR:|Parse Error:' "${log_path}"; then
    return 1
  fi
}
mkdir -p "${report_dir}" "${bootstrap_dir}/output/linux" "${bootstrap_dir}/output/windows" \
  "${bootstrap_dir}/diagnostic/generated"
run_logged "${report_dir}/blender.log" "${NULLSPACE_BLENDER}" --background --factory-startup \
  --python-exit-code 1 --python "${bootstrap_dir}/make_diagnostic.py" \
  -- --output "${bootstrap_dir}/output/source"
cp "${bootstrap_dir}/output/source/bootstrap.glb" "${bootstrap_dir}/diagnostic/generated/bootstrap.glb"
python3 "${bootstrap_dir}/verify_glb.py" "${bootstrap_dir}/diagnostic/generated/bootstrap.glb" \
  | tee "${report_dir}/glb-structure.json"
run_logged "${report_dir}/import.log" "${NULLSPACE_GODOT}" --headless --editor \
  --path "${bootstrap_dir}/diagnostic" --import
run_logged "${report_dir}/headless-diagnostic.log" "${NULLSPACE_GODOT}" --headless \
  --path "${bootstrap_dir}/diagnostic"
run_logged "${report_dir}/export-linux.log" "${NULLSPACE_GODOT}" --headless \
  --path "${bootstrap_dir}/diagnostic" --export-release "Linux x86_64" \
  "${bootstrap_dir}/output/linux/nullspace-bootstrap.x86_64"
run_logged "${report_dir}/export-windows.log" "${NULLSPACE_GODOT}" --headless \
  --path "${bootstrap_dir}/diagnostic" --export-release "Windows x86_64" \
  "${bootstrap_dir}/output/windows/nullspace-bootstrap.exe"
sha256sum "${bootstrap_dir}/output/linux/nullspace-bootstrap.x86_64" \
  "${bootstrap_dir}/output/windows/nullspace-bootstrap.exe" | tee "${report_dir}/exports.sha256"
file "${bootstrap_dir}/output/linux/nullspace-bootstrap.x86_64" \
  "${bootstrap_dir}/output/windows/nullspace-bootstrap.exe" | tee "${report_dir}/export-formats.txt"
# A rendered native launch is a separate required step; headless execution never proves Forward+.
