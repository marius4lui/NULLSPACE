# Corrected M4 native comparison — further correction required

Source `472df44cb3d83b7b9124501fa3e3bd3306767ad4`, unchanged during this run. The harness reports the game worktree dirty because the new evidence directory was already untracked, not because production source was edited. Exact scene/script/tool hashes are in `state.json`, and the source checkpoint's `provenance.json` covers the assets. Harness clean `a98fede470155ef40a69791450ca418a4a570aa0`, whose operational source was independently reviewed at `bb6fb09`. This is implementer evidence, not independent acceptance or a game playthrough.

Actual Godot4.7.2.stable.ed1daf0bf, Forward+, Vulkan1.4.354, RADV/Mesa26.1.8, integrated Radeon660M;1920×1080, native X11 inside inputless private Weston/Xwayland, VSync disabled,60fps cap. Started2026-09-04 22:15:37.099UTC; explicit supervisor stop22:25:39.820UTC. `controlled_provenance_valid=true`, `cleanup_errors=[]`, `host_defaults_unchanged=true`. No natural application-exit PASS: the known harness QA-007 natural-window-close race is outside this run; explicit stop was used. No other native processes were operated.

## Opened originals and visual findings

The implementer opened the original1920×1080 external entry capture and direct viewport001, then direct002–013,015,018 and external motion_step1/motion_step2. Original-detail image display was used, without resizing. Additional external/viewport pairs are measured by `analysis.json`; metrics never replace opening the image.

Follow-up evidence inspection before any source correction: opened the original external view3, view7, paper_flashlight and effects_disabled PNGs. Each depicts the same actual scene as its subsequent direct viewport reference; the effects-disabled pair is full-RGB identical, TAA-enabled pairs have small differences recorded without pretending they are exact. Opened four unresized1920×1080 video frames extracted with FFmpeg8.1.2: recentered movement at0.5s/3.0s visibly progresses from entry toward the partition; fixture cycle at1.0s/9.0s visibly changes luminosity. The9s sample is a weak/failing luminous phase, not the OFF still018. Individual video frames corroborate changed capture, not uninterrupted temporal perception or a flicker-quality PASS.

| Still | Actual scenario / observation |
| --- | --- |
|001,002 | Entry and medium offset-room views. Central cove now connects around the corner; deliberate open floor and muted commercial palette remain. Room detail still does not earn an art PASS. |
|003,006 | Vent/paper and close paper. Original quiet print and roll seams read; substrate is still too smooth/uniform. Preserve pattern scale and investigate normal sampling/roughness before adding albedo dirt. |
|004 | Normal fixture close and tegular ceiling. Mineral fissures and individual board variation are visible. Bright emitter clips, but clips/casing are legible; do not dim the room merely to reveal the luminous center. |
|005 | Mitered cove close. Continuous joint without the old missing segment. No obvious z-fighting in this still. |
|007 | Damp/compressed carpet area; broad variation is present. Short-pile material needs later improved sampling assessment. |
|008 | Inspection flashlight on close paper. Still too smooth. This near-frontal flashlight is not an adequate final grazing-angle material proof. |
|009–014 | Same entry pose, cumulative effect diagnostics below. No lighting design change is accepted merely because it is cheaper. |
|015–019 | All-fixture WEAK, INTERMITTENT, FAILING, OFF, NORMAL cycle after restoring SSAO/SSIL/TAA; fixture shadows remain diagnostically disabled. Opened015/018 demonstrate housing/fastener/diffuser detail and powered/off response. State video retained; no continuous temporal or subjective horror score. |
|020,021 | Native mouse/W movement.020 exposes re-capture camera jump.021 follows a reset while already captured and moves as intended. These are an inspection camera, not production player locomotion. |

Wallpaper normal source exists and runtime shader assigns `NORMAL_MAP` and `NORMAL_MAP_DEPTH`. Offline inspection after the run found a concrete import problem: tiled PNG sidecars use `compress/mode=0`, `metadata.vram_texture=false`, `mipmaps/generate=false`, i.e. default2D sampling/storage despite3D anisotropic samplers. Original wallpaper normal8-bit channel rangeR113–142/G119–136, standard deviation1.665/1.621; roughnessG211–239. Missing mip chains and subtle subpixel relief must be corrected/remeasured before inferring the final material needs stronger dirt. This is an identified defect, not a measured explanation for all cost.

## Warm effect isolation

Pose1, inspection flashlight OFF, 11 fixtures; no recorder during009–014. Each effect/pose reset clears samples and excludes the first3s.009–013 each measure approximately8s total, leaving5s sampled. Already-warm001 at233s application runtime corroborates the baseline. These are cumulative conditions, not independent additive benchmark guarantees. Engine frame interval and viewport GPU queries are separate. CPU values are rendering setup, not whole-game CPU cost.

| Still | SSIL | SSAO | Fixture shadows | TAA | Frame p50 / p95 ms | GPU p50 / p95 ms | Render CPU p50 ms | Samples |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|009 | on | on |4 | on |96.665 /96.806 |94.038 /96.697 |0.383 |53 |
|010 | off | on |4 | on |87.970 /91.828 |86.030 /89.012 |0.426 |57 |
|011 | off | off |4 | on |59.259 /59.524 |57.480 /58.782 |0.374 |84 |
|012 | off | off |0 | on |47.619 /48.148 |45.930 /46.853 |0.346 |105 |
|013 | off | off |0 | off |44.444 /49.777 |42.773 /46.183 |0.375 |111 |

29 draws/177742 submitted primitives, reported video memory536477352bytes in baseline. SSAO produces the largest measured cumulative GPU delta here, and remaining42.77ms is still expensive. This is a GPU-bound issue, not merely startup/VSync and not a discrete-target certification. Follow-up needs explicit3D texture import, MSAA/render-scale and material/light contribution diagnostics. No volumetric fog/probe/GI bake is enabled in this room.

Read-only Linux AMD sensors, immediately before22:23:03.467UTC external effects-disabled capture: `/sys/class/drm/card1/device/gpu_busy_percent`100; `pp_dpm_sclk`1900MHz active; `pp_dpm_mclk`2400MHz active; performance policyauto. `hwmon4/freq1_input`1900000000Hz, `temp1_input`77000m°C (edge77°C), `power1_input`29427000µW (PPT29.427W), voltage905mV/1050mV. These are one observed condition, not a thermal trend or a power-limit test. No clock/power/host setting was changed.

## Controls, recordings, limitations

Full supervisor request journal and accepted-controls-only application trace retained. First Escape+1 call held both for8s, producing expected key repeats; subsequent taps and settling waits were separated. Fixed poses changed correctly with no unsolicited camera drift while released. Re-capturing by click and immediately moving generated application delta(960,425), not the requested(100,-15); first motion result020 is a FAIL. The later reset while already captured followed by(100,-15) yielded exactly that delta and expected yaw0.275883/pitch0.015286. W produced position(1.9372935,1.6408359,-3.5441172) from(2.7,1.640306,-0.85). No foreign raw source was identified; do not attribute this preview timing defect to physical-seat contamination.

`fixture_states.mkv`12s, `controlled_movement.mkv`10s (failed recapture), `controlled_movement_recentered.mkv`8s retained with FFprobe/checksums. They include only this game window and its named audio sink; the preview has no audio content. Recorded60fps encoding is not60fps rendered motion. No audio listening or uninterrupted temporal experiential PASS is claimed.

The final D strafe and22nd P request were sent immediately before stop; that capture did not complete. There are21 complete PNG/JSON pairs. No22nd result is claimed. Future native review must wait for capture completion before shutdown. Loose board contact needs a dedicated lateral view;003 only partly shows it. No collision coverage/whole-room traversal PASS from the bounded movements.

Result: local M4 acceptance remains FAIL/PENDING for wallpaper surface response and GPU cost, plus diagnostic re-capture correction. Corrected cove and ceiling detail are corroborated by opened native views, but whole M4 still requires the next exact-source native iteration and separate adversarial acceptance. GPU handed explicitly to core_m2 after verified cleanup.
