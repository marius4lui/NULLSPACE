#!/usr/bin/env bash
# Initialize actual autoloads and fail on engine exceptions even if Godot exits zero.
set -euo pipefail
command -v rg >/dev/null

ns_godot=${1:?Usage: run.sh /absolute/path/to/godot [absolute/log/path]}
ns_project=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
ns_log=${2:-$(mktemp /tmp/nullspace-core-tests.XXXXXX.log)}
ns_profile=$(mktemp -d /tmp/nullspace-core-test-profile.XXXXXX)

XDG_DATA_HOME="$ns_profile/data" XDG_CONFIG_HOME="$ns_profile/config" \
XDG_CACHE_HOME="$ns_profile/cache" "$ns_godot" --headless --path "$ns_project" \
	--log-file "$ns_log" res://tests/core/test_runner.tscn

test -s "$ns_log"
if rg -n 'SCRIPT ERROR|^ERROR:' "$ns_log"; then
	printf '%s\n' 'Unexpected engine/script error: logical test run failed.' >&2
	exit 1
fi
printf 'Core logical tests passed; log: %s\n' "$ns_log"
