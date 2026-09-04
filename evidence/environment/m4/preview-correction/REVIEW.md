# Scoped M4 inspection-viewer correction

Parent source: `e01fdb0` (explicit texture-import correction). Historical native comparison remains frozen in `../native-m4-02/` at art source `472df44`, evidence commit `9f438b2`. This checkpoint changes only standalone inspection conveniences, their documentation and provenance. Production core/player/InputGate, room geometry, shaders, light tuning and PNG source pixels are untouched.

## What changed

- Mouse accumulation is disabled in this standalone viewer. Entering capture starts a two-process-frame settling guard for look and horizontal movement; a captured click does not intentionally recapture. Native motion traces now record exact deltas, whether look applied, and settling state. A `capture_ready` transition marks the end of the guard. This targets the recapture jump retained in native-m4-02; actual native correction is still **pending**, not proved by headless checks.
- P capture requests are serialized. A request while capture is pending is explicitly rejected. Operators must wait for the completed PNG/JSON and `M4_CAPTURE ... result=0` before stopping; the prior run's incomplete22nd request is not retroactively counted.
- Reversible render diagnostics are separated into `preview_render_diagnostics.gd`: MSAA, render scale, uniform architecture material, direct fixture lights, glow, SSIL, SSAO, original shadow mask and TAA. F4 retains geometry but may affect batching as well as material cost. No diagnostic option is a production preset or a proposed final appearance.
- Metadata includes all these options, individual fixture states, flashlight, camera preset and actual environment fog/GI flags plus room probe counts. Startup still uses the original mix of eleven fixtures: one WEAK, one OFF, nine NORMAL; ten visible direct lights, four configured shadows.
- Existing poses1–8 are unchanged. Pose9 adds paper viewed obliquely along the wall; pose0 adds a lateral view of the displaced board. These are inspection shortcuts, not gameplay/independent experiential navigation.

## Executed checks

Exact Godot `4.7.2.stable.official.ed1daf0bf` (`ed1daf0bf001b61586d9930840f2f1394092c079`). Both commands run headlessly in the owned environment-art worktree, with no native session or GPU lease:

```sh
/home/marius/.local/share/nullspace/toolchains/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path tools/art/environment/preview --editor --import --quit --log-file /home/marius/Projekte/Dev/NULLSPACE-worktrees/environment-art/evidence/environment/m4/preview-correction/import.log
NULLSPACE_PREVIEW_DIAGNOSTIC_REPORT=/home/marius/Projekte/Dev/NULLSPACE-worktrees/environment-art/evidence/environment/m4/preview-correction/logical_checks.json /home/marius/.local/share/nullspace/toolchains/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path tools/art/environment/preview --script res://verify_preview_diagnostics.gd --log-file /home/marius/Projekte/Dev/NULLSPACE-worktrees/environment-art/evidence/environment/m4/preview-correction/logical_checks.log
```

Importer exits0 with no script errors. Final verifier exits0:50 checks, zero failures (`logical_checks.json`, full `logical_checks.log`). Checks cover initial/recapture settling scheduling, every reversible diagnostic returning to identical recorded baseline, scale cycle, unchanged default materials, eleven authored fixtures/ten active direct lights, original four shadows, absent fog/GI and ten finite camera presets. Headless display does not provide real capture/focus semantics; these checks deliberately do not establish native event timing or large-delta suppression.

The first verifier exits1 only because its assertion expected eleven *visible* direct lights, contradicting the existing authored OFF fixture. That expectation was corrected to eleven instances and ten visible lights. Its report/log remain as `logical_checks_initial.json` and `logical_checks_initial.log`. No art or lighting was changed to satisfy it.

## Required next native comparison

Use the accepted QA harness and a new exclusive run directory after explicit GPU handoff. Capture external current Composite PNGs then settled frame-post-draw references; open originals. Repeat old poses1/2/5/6/7/8 and add9, with near-frontal/oblique diagnostic flashlight as labeled. Check cove continuity, understated paper relief/roughness, ceiling variation, damp fiber and fixture emitter-atlas boundaries at ordinary distance. Keep the default authored fixture mix until baseline performance sampling is finished. Inspect displaced-board floor/wall support from pose0.

At pose1, warm each change before collecting CPU/GPU/frame quantiles. Preserve a new fully enabled baseline and independently isolate MSAA, render scale, architecture material/batching and direct lights; repeat the prior cumulative SSIL/SSAO/shadow/TAA sequence for comparison. Record actual settings and draw counts, no target-GPU extrapolation. Diagnostic all-effects-off images are not final art candidates.

For native recapture, explicitly release, reset the view, click, wait for `capture_ready`, then apply one known mouse delta and bounded movement. Correlate raw XTEST request/accepted delta/applied trace/camera change and inspect the resulting current images. Repeat release/capture without unintended look. Use supported explicit harness stop; do not claim natural application-exit validation from the old harness source.

No M4/material/performance score or independent acceptance is assigned here.
