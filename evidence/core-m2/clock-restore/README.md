# Shared clock and restore contracts — candidate evidence

Implementer: core_m2, Astra/max. Parent source `dca6c73` (separate storage-only independent review PASS at `85dd980`). This extension is not independently accepted, not native-validated yet, and not finished M2/gameplay. Original `68ce558` and storage-fix evidence remain preserved.

Bounded scope: typed shared simulation clock/stamp, participant-specific restore context, RefCounted adapter contract, pure readiness barrier, two event epoch fields, GameFlow initialization ordering, passive Telemetry clock consumption, autoload and core tests/documentation. No player/AI/level/campaign coordinator or production content was implemented. Save schema v1 and the independently reviewed storage/settings implementation are unchanged from the parent.

The shared physics clock freezes in all non-PLAYING states and advances epoch before load participants receive the snapshot. Each context carries at most its own validated anchor: no universal pair of player/monster transforms. The barrier only counts readiness; it does not validate worlds, move actors, save partial state, own a timeout or call GameFlow. Those are explicit future coordinator/participant obligations documented in `docs/CORE_INTERFACES.md`.

## Actual checks

Godot `4.7.2.stable.official.ed1daf0bf`; logical headless execution, not native movement/performance evidence. `tests-final.log` has **228 checks, zero failed assertions and no SCRIPT ERROR/engine ERROR**. This retains the original 80 and storage-hardening 71 checks, then adds 77 clock/barrier/participant checks. They cover all non-playing states, unfocused load completion, clock-before-load-signal ordering, committed time/ammo reload, held input during load, old evidence epochs, missing/delayed/unknown/duplicate/stale barrier reports, null/failure/cancel results, immutable result copies, mismatched contexts, adapter cancellation and late mutation guards. Synthetic participant fakes do not prove actual world/AI restoration.

`tests-final-rate-{30,60,120}.log` records three actual Godot fixed-render-schedule runs. All reached60 physics steps and1.0 simulation second; observed render-frame counts were30/60/120 respectively. `--fixed-fps` disables real-time synchronization: these are scheduler regressions, **not** native 30/60/120 FPS benchmarks.

Initial development failure is retained in `tests-initial.log`: the RefCounted test helper used unqualified Node notification constants, causing a test-script compilation error and preventing its completion. The owned headless test process was identified by exact PID/command and terminated (wrapper exit143). The constants were qualified with `Node.`; `tests-corrected.log` then passed226 checks. Two extra deferred-mutation guard checks brought the final suite to228. The wrapper now additionally requires a complete successful suite report, detects engine errors, and caps each invocation with GNU timeout45s/kill grace5s so a failed test script cannot hang indefinitely. No failing test was disabled.

`import-final.log`, both export logs and `linux-headless.log` contain no engine/script errors. Build and packed-export smoke used a new isolated XDG profile, with a read-only-use symlink to the verified existing4.7.2 export templates. The `set -euo pipefail` build/test/export/run command completed exit0. Actual Linux packed export launched headlessly for3 frames; this is not native acceptance. Tests are excluded from exports.

Milestone binaries (not committed release artifacts):

- `/tmp/nullspace-clock-build.3USUX1/linux/nullspace.x86_64`, SHA256 `b11387528094ee3f4a2522f361954c9b1a518d38f23be28be2367bbcb508fc89`.
- `/tmp/nullspace-clock-build.3USUX1/windows/NULLSPACE.exe`, SHA256 `f0b6129659ee29c03df81bbc5ee6f4dd32bb007df6635e1c607a8d3364e0581b`.

These were built from parent plus this commit's source while evidence was being authored. Reproduce by editor import followed by `bash game/tests/core/run.sh GODOT ABSOLUTE_LOG`, then standard named Linux/Windows release export presets. Native final diagnostic operation, original-resolution capture inspection, correct-harness provenance and independent whole-core review remain pending. Native Windows, power-loss durability, actual campaign anchors/restoration and product quality are not claimed.
