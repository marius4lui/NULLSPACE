# Listener death — bounded implementation and validation

Task authority: user's attached goal-objective.md, 2026-09-05. This task adds the
Listener death sequence, death screen and independent blood/intensity settings to
the existing section. It does not claim to resolve the raw beta's prior duration,
first-player pacing, listening or complete-game acceptance gaps.

Base: origin/main 2c1f97d2408d3bd75bc02729c58618d0afb3ef0e. Own worktree:
/home/marius/Projekte/Dev/NULLSPACE-worktrees/listener-death, feat/listener-death.
One agent, no delegation. Other worktrees/processes/preferences preserved.

## Batches (maximum 20; final five reserved for playtests/corrections/delivery)

1. Inspect current contract/gates/status/issues/Git and player, enemy, settings,
   checkpoint and existing death screen; create requested branch from fetched main.
2. Select concrete GameFlow DYING integration and collision-tested camera ownership;
   inspect original rig, clips, audio and isolated native QA tools.
3. Add additive settings and original 2.6-second death_grab to existing 63-bone rig;
   rebuild with existing Blender recipe, retaining editable source and GLB.
4. Implement concrete death controller, guarded cause, world pause, volume sweep,
   local fallback, bounded original blood effect, same menu, skip/reset integration.
5. Add isolated actual-scene regression fixture and import successfully. Correct
   Escape dispatch so the sequence receives it after the minimum duration.
6. Headless death matrix: 175 checks, no failures. Two attempted native starts
   refused before launching: another task owns the GPU lease. Those are NOT runs.
7. Existing core/scene regression and export verification. Existing
   immediate-DEAD scene expectations need to await the new real fade; retained
   checks and original failure logs, no suppressed assertions.
   Core258 + three schedules, player17/pistol20/Listener12/door15/escape26 pass.
   f5ed159 Linux/Windows cross-exports succeed in export-03.log. Earlier isolated
   export attempts lacked the existing templates; explicit version symlink in
   the temporary QA profile corrected the environment, no installs/host changes.
8. Imported rig measurements at six clip times. The first inspector sampled
   before AnimationPlayer was ready and returned rest poses (retained). Corrected
   inspector awaits tree readiness: hands extend from z=.041 to .968, right hand
   y=1.646 to1.165 on final strike; feet stay planted. No visual acceptance inferred.
9. Native03 actual Forward+/RADV660M matrix175 passes, clean shutdown. Capture
   request raced audio initialization and was refused, so this first run has NO
   video. Native04 corrected readiness-gated capture:175 passes and34.5s video.
   Native-edges-01:58 passes, actual wall/closed+open door/facing-away cases/video.
10. Opened temporal contact sheets from both videos. Found oversized regular blood
    droplet pattern, reaching arm entering side wall despite clear camera, and a
    red-tinted full fade even with blood disabled. Fixed all three: smaller varied
    droplets, separate original .85s death_local clip plus arm-volume clearance,
    alpha-composited black fade whose red contribution depends solely on blood.
    Also guard the single shove segment and use local death for crouched victims;
    reset transient Listener attack/perception/search fields explicitly.
11. Final source320c014 targeted physics: matrix175, actual wall/door/crouch78,
    Listener12 and doors15 all pass.
12. Repeated native matrix175 and wall/door/crouch78 with final captures. Opened
    temporal contact sheets and inspected corrected blood-off fade/local arm pose.
    Fixed one additional menu-camera reset: restore only after a recorded death
    pose (11dcf11); targeted edge suite now79 passes. Rebuilt both exports. Replay
    now waits for actual Start restoration before dispatching movement.
13. Final Linux export completes fresh Start, both switches and exit (route02).
    Second attempt dies at the office door: blind replay can close a door the
    Listener already opened. Retained failure; adapt OS inputs to observed door.
14. Actual export death screen: keyboard checkpoint restart, movement, pause,
    Main menu and Settings. Toggle blood/intensity off and motion/flashes on with
    keyboard, Apply; retain saved envelope and opened screenshots. Launch a new
    process using only that task-owned isolated profile.
15. Confirm persisted values in new-process boot telemetry and reopened Settings.
    Initial route04 attempt overshoots an already-open doorway; corrected replay
    timing only, no gameplay change. Actual Main menu -> fresh Start -> both
    switches -> exit succeeds, with no death/restore during that fresh campaign.
    Quit via UI; all owned sessions stopped with no cleanup errors.
16. Re-read objective and current Git/contracts after interruption. Copy portable
    task telemetry, exclude shader/save profiles from Git, directly hash final
    binaries, audit cleanup, update this requirement/evidence report and status.
17. Delivery: commit final tested replay helper/evidence, push feat/listener-death
    and open a PR against main without merging. Remote verification recorded below
    when complete. Two initial HTTP pushes timed out (408); complete compressed
    MP4 review copies replace large MKVs in Git, with original MKVs kept locally.
    Total planned completion:17/20; final five are13–17.

## Implementation/source provenance

- Existing listener_gameplay model, original textures and 63-bone skeleton reused.
  Edited tools/art/listener/add_gameplay_clips.py supplies all original new clip
  curves (death_grab2.6s and tight-space death_local.85s), baked with the existing
  pipeline into listener_gameplay.blend and GLB.
  No external asset, new rig, extra monster, room or cinematic framework.
- Existing listener_step_0.wav and hurt.wav used at -14/-15 dB and lower pitch on
  the existing effects-controlled Player bus. No new loudness/flash effect.
- Original code-authored twelve small shared-mesh blood droplets and transparent
  edge shader, no persistent decal or particle emitter. Clear on finish and reset.
- Existing v1 settings files accept absent new fields without replacing saved
  preferences. Blood effects and intense animation default on only when absent;
  Reduce motion defaults off. Existing zero bob+shake opts out of the pull too.

## Requirement evidence

All tests below were operated by the same agent. Headless tests are automated
physics/regression checks. Native matrix/edge runs render the real section and
invoke actual enemy attacks after explicitly positioning bodies and lowering
health in fixtures. Export routes use XTEST OS input in an isolated native seat;
they do not inject position, health, objective state or disable the AI. Runtime
telemetry's `unverified_os_input` label is retained; supervisor request logs give
the automation provenance. No human or subjective first-play claim is made.

| Requirement | Result and reviewable evidence |
|---|---|
| Reach, pull, finishing strike, collapse/fade | Existing rig has original `death_grab` (2.6s). Native final matrix's first two complete sequences take2.586/2.581 wall seconds. [Final video](native-final-matrix/death-matrix.mp4), [temporal frames](frames/final-matrix.jpg), [8s review excerpt](listener-death-review.mp4), [imported bone measurements](rig-measurements-02.log). Frames were opened across time, rather than inferring motion from one still. |
| Physical lethal attack, no wall/range trigger | Actual-scene matrix175 checks validates nonlethal/range/occluded attacks and the real lethal caller. Source verifies same Listener, ATTACKING, attack applied and clear attack before selecting the grab. [Matrix log](final-listener_death.log). |
| Safe camera and arms, wall/door fallback | Sphere sweeps guard pull, collapse and shove; arm volume guards reaching pose. Authored archive wall uses local.85s clip; clear open office door permits full2.6s; closed door prevents hit. Facing-away and crouched victims use local fallback. [Native edge video](native-final-edges/death-edges.mp4), [temporal frames](frames/final-edges.jpg), [latest79 checks](final-death_edges-02.log). |
| Exclusive control, once per death, skip/reset | DYING pauses world/input and separately advances death pose. Matrix checks duplicate damage rejection, minimum.65s skip, actual Escape dispatch, repeat death and restored camera, controller, audio, effects and monster transient state. No-checkpoint real Restart button and other-cause calm death also pass. [Native175 checks](native-final-matrix/game.log). |
| Independent blood/intensity combinations | Native matrix exercises on/on, off/on, on/off, off/off plus reduced motion. Blood off removes droplets and red overlay; fade remains black. Blood enabled adds twelve small spatial droplets for.4s and subtle edge film for.55s. Intensity off retains independent blood and uses a calm.85s fade. Final frames/video above. |
| Reduced motion and reduced flashes | Reduce motion overrides intense death; zeroing both existing motion sliders also opts out. Menu explains dependency and independent blood. Death adds no flashing light or strobe; original reduced-flashes preference remains separate. Matrix checks reduction; persisted export settings retain reduced_flashes=true. |
| Existing death menu/input | English UI title YOU DIED, checkpoint restart when valid, Restart otherwise, Main menu; no statistics. [Actual exported death screen](export-route-03/death-menu.png), [keyboard restart then movement](export-route-03/checkpoint-restarted.png). Native fixture also activates fallback Restart without checkpoint. Export return to Main menu and settings operated through actual UI. |
| Additive saved preferences and process persistence | Missing fields default without replacing v1 saved preferences; malformed present values rejected in automated suite. Export UI changed four toggles and Apply, [saved QA envelope](export-route-03/saved-settings.json). New process boot in [route04 result](export-route-04/attached-route-result.json) retains them; [reopened settings](export-route-04/persisted-settings-confirmed.png) inspected. `persisted-settings-new-process.png` captured the title menu too early and is NOT settings proof. |
| Existing regressions | Core258 plus30/60/120 scheduling probes; player17, pistol20, Listener12, door15, escape26 pass. Four existing tests await the newly introduced fade; assertions retained. Initial failures remain in this directory. |
| Original assets/source | [Asset comparison](asset-reuse.json):63 joints unchanged; all seven previous animation channels unchanged. Positions/normals/UV/joints/weights unchanged; exporter tangent maximum difference0.000100002. Editable Blend, generator and exported GLB retained. Existing provenance/licenses remain applicable. |

## Final exported game runs and performance

Last gameplay source is **11dcf11a6b30c6016f6691f91d86bc81d8c53f5c**. Subsequent
delivery changes affect QA helper/docs/evidence only. Both binaries were rebuilt
from that source, and directly hashed again in batch16: [audit](final-audit.json).
Linux SHA256 `a958b459d16e5c4ec2747564307a406021dbbaafa4b19a3d7a6308400906a31c`;
Windows SHA256 `2fd23ba540436e827ed587558c94eca348656c6c6e3b8d36ffb31c4489adec38`.

Two successful complete functional runs follow the last gameplay change:

| Export evidence | Actual fresh campaign result |
|---|---|
| [route02](export-route-02/route-result.json) | session ec7a630343be4d127fb957fdfc40b686; Start -> both physical switches -> returned exit;54.15 simulation seconds; health45, no pistol/ammo/shots, no death or checkpoint restart. |
| [route04 fresh Start](export-route-04/attached-route-result.json) | session b455f9e93013bc5de8b9b870ea5e7f45, epoch2 in the new preference-persistence process; same complete route54.0167 seconds, health45, no weapon/ammo/shots/death/restore during this campaign. Prior failed campaign remains separately recorded. |

These are fast known-route functional checks, **not evidence of10–15 minute
first-player duration**. That pre-existing whole-game acceptance issue stays open.
The final five batches13–17 cover final playtests, corrections and delivery.

Fedora laptop, Ryzen5 7535HS/Radeon660M RADV, Godot4.7.2 Forward+,1920x1080 window,
Laptop quality75% internal scale, VSync and60 cap. Uncaptured route02's ten5s
windows: p50 16.651–16.665ms, p95 16.967–17.060ms, maximum33.461ms.
Capture has overhead: native final matrix includes a1.161s readiness/settings
window hitch and later window maxima48–71ms; do not describe it as locked60FPS.
Direct death-phase sampled frames are approximately17–23ms; timing itself remains
the measured2.58s above. This is one laptop, not general hardware certification.

## Failures, limits and isolation

- Initial native01/02 launches were refused by another task's GPU lease before
  game launch. Native03 passed but early recording failed before audio readiness;
  native04 fixed capture ordering. All failed attempts are retained.
- Original rendered checks exposed arm/wall clipping, oversized regular droplets
  and blood-off red fade. Source320c014 corrected them and final recordings were
  inspected. Last11dcf11 snapshot guard is covered by79 headless edge checks and
  final export menu/restart/full routes; the unchanged clips/effects retain the
  native320c014 evidence (175 matrix/78 edges), not a falsely relabeled rerun.
- Route01 dispatched movement before Start loaded; route03 died at an already-open
  door after blind replay toggled it; initial route04 overshot its doorway. The
  helper now waits for restore and observes door state, then adjusts input timing.
  Failed route JSONs remain alongside the successful fresh-start result.
- Audio was captured and numerically inspected (mean -41.1dB, peak -11.1dB in
  final matrix; [log](audio-levels.log)); it was **not heard or subjectively judged**.
  Windows cross-export succeeded, with no native Windows host validation.
- Published full-length MP4s are compressed review derivatives (CRF26, AAC128k),
  not the original lossless-audio MKVs. Original MKVs remain locally preserved
  and their capture metadata/logs stay in Git; audio measurements above refer to
  the originals. [Copy hashes and durations](video-copies.json) map both versions.
- All own native sessions are terminal; cleanup errors empty and before/after
  default audio devices identical for launched sessions. No unrelated process
  was stopped. Native profiles and test save/settings folders are isolated;
  shader caches and saves stay local under ignored profile/, while explicit
  telemetry/settings evidence is portable. Route04 deliberately reuses only
  route03's isolated data; its286611 telemetry is copied into route04 here.
- Main's later branding-only commit is outside this branch's base. No main merge,
  whole-game completion, audio listening, account/reset/model change or delegation
  is claimed. PR delivery is the remaining step at the end of batch16.
