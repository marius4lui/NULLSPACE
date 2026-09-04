#!/usr/bin/env bash
# Initialize actual autoloads and fail on engine exceptions even if Godot exits zero.
set -euo pipefail
command -v rg >/dev/null
command -v timeout >/dev/null

ns_godot=${1:?Usage: run.sh /absolute/path/to/godot [absolute/log/path]}
ns_project=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
ns_log=${2:-$(mktemp /tmp/nullspace-core-tests.XXXXXX.log)}
ns_profile=$(mktemp -d /tmp/nullspace-core-test-profile.XXXXXX)

XDG_DATA_HOME="$ns_profile/data" XDG_CONFIG_HOME="$ns_profile/config" \
XDG_CACHE_HOME="$ns_profile/cache" timeout --kill-after=5s 45s "$ns_godot" --headless --path "$ns_project" \
	--log-file "$ns_log" res://tests/core/test_runner.tscn

test -s "$ns_log"
if rg -n 'SCRIPT ERROR|^ERROR:' "$ns_log"; then
	printf '%s\n' 'Unexpected engine/script error: logical test run failed.' >&2
	exit 1
fi
rg -q '"suite": "M2 core"' "$ns_log"
rg -q '"failures": \[\]' "$ns_log"

# Change render scheduling while keeping actual physics at 60Hz. Isolated profiles
# also prevent the synthetic rate scenario from replacing any other checkpoint.
for ns_rate in 30 60 120; do
	ns_rate_profile=$(mktemp -d /tmp/nullspace-clock-rate-profile.XXXXXX)
	ns_rate_log="${ns_log%.log}-rate-${ns_rate}.log"
	XDG_DATA_HOME="$ns_rate_profile/data" XDG_CONFIG_HOME="$ns_rate_profile/config" \
	XDG_CACHE_HOME="$ns_rate_profile/cache" timeout --kill-after=5s 45s "$ns_godot" --headless --path "$ns_project" \
		--fixed-fps "$ns_rate" --log-file "$ns_rate_log" res://tests/core/clock_rate_probe.tscn
	test -s "$ns_rate_log"
	if rg -n 'SCRIPT ERROR|^ERROR:' "$ns_rate_log"; then
		printf '%s\n' 'Unexpected clock-rate probe engine/script error.' >&2
		exit 1
	fi
	rg -q '"passed":true' "$ns_rate_log"
done
printf 'Core logical and clock-schedule tests passed; log: %s\n' "$ns_log"
