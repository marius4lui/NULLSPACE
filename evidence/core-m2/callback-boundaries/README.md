# M2 callback-boundary correction — logical candidate only

Owner: `/root/core_m2`, GPT-6 Astra/max. Parent source is `70d2aae1fbd81811db6c8de70faa5d5a78736937`; its failing evidence is retained. This directory accompanies a narrow correction, not independent review, native acceptance, or whole-M2/product completion.

Independent reviewer `/root/bootstrap_m0` found two failures in review commit `710af25f5fa63632b3da6971d2abfdd674335448`: a failed barrier arrival could return a synchronously retried generation's success, and the initial LOADING callback could accept `complete_load(-1)` before any checkpoint/epoch staging. The same sentinel guard was missing from `fail_load`.

## Correction and regressions

`RestoreBarrier._finish` now preserves the originating call's detached receipt before emitting `completed`. Ordinary synchronous retries remain allowed; their current `outcome()` cannot replace the older caller's result, and signal/caller mutation cannot change the stored result. Both GameFlow acknowledgements require a positive matching issued generation. Initial LOADING notifications still precede storage; the positive token is delivered by `load_started` after clock initialization.

The 228 existing logical checks remain. Added 28 checks cover failure-to-success and success-to-failure synchronous retries, cancellation starting a pending replacement, stale cancellation/readiness, subscriber/caller result mutation, and New/Continue × complete/fail callbacks trying sentinel, zero, negative and guessed unissued generations. Valid staged tokens remain usable exactly once. Save schema v1, storage/settings, shared clock, participants and production scope are unchanged.

## Observed execution

Godot `4.7.2.stable.official.ed1daf0bf`, headless, fresh isolated XDG profiles; no native input or performance assertion.

- `reviewer-before.{json,log}`: owner ran the unchanged external reviewer helper against clean source `70d2aae`; 45 checks, 2 failures, exit1, no engine/script errors. JSON records actual runtime commit and nine source hashes.
- `guards-before.log`: new owner regressions against unchanged production source; 256 checks, 17 explicit assertion failures, exit1. These `push_error` lines are the test assertions, not silently accepted exceptions. The wrapper correctly stops before schedule probes.
- `guards-after.log`: all 256 checks pass, exit0, zero engine/script errors. All three `guards-after-rate-*.log` probes pass with 60 physics steps and 1.0 simulation second at fixed 30/60/120 logical render schedules.
- `reviewer-after.{json,log}`: owner rerun of the same external helper; 45 checks pass, exit0, zero engine/script errors. This ran with the correction uncommitted atop `70d2aae`; therefore the recorded runtime commit is the parent, while the actual changed GameFlow/barrier SHA256 values identify the corrected source. It is not an independent rereview.

Reproduction: `bash game/tests/core/run.sh /home/marius/.local/share/nullspace/toolchains/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 /absolute/new/log`. The external independent helper remains reviewer-owned at `review-core-clock/evidence/reviews/core-clock/clock_probe.tscn`, commit `710af25`; its README/report provides the direct command. Owner repetitions use this project's `--path game`, that absolute scene path, new output paths, and disposable case/profile directories.

Next required evidence: clean exact-source import/cross-exports, corrected exported native diagnostic operation, and separate exact-source reviewer rerun. Native cold-start persisted settings, audio listening, native Windows, production physical restoration, campaign coordination and target-GPU measurements remain unverified. Previous contaminated native runs are not rehabilitated by this fix.
