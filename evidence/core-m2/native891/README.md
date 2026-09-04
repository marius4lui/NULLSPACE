# Corrected M2 native self-validation

Operator: `/root/core_m2`, GPT-6 Astra/max, the core implementer. **The exercised diagnostic scenarios passed this bounded self-check. This is not independent whole-M2 acceptance, a production UI review, or game completion.**

Source is frozen at `891344e0dd986373e9a9e6d38bf513bc7fda93ab`; clean evidence-only checkout tip at launch was `7923b80f818e5cd72981be4d5773bd5333f979b0`. No `game/**` or interface-document changes occurred during/after the run. The callback fix already has separate logical review PASS `da1e1f465e34504310c255a618d192f54710da6a` (256 guarded checks, three logical schedules and the unchanged independent45-check probe). That review does not substitute for native operation.

## Build, isolation and actual operation

- Linux export: `/tmp/nullspace-callback-build.VyQfbM/linux/nullspace.x86_64`, SHA256 `f6a37cbddebaa902a4cfaf6ff78017908b17bc8fe0e6a47ade2acbe0d05192f0`. Clean-source build records are in `../callback-boundaries/`.
- Godot `4.7.2.stable.official.ed1daf0bf`. The application's actual `RenderingServer.get_current_rendering_method()` reports `forward_plus` in `telemetry.jsonl`; `game-renderer-maps.txt` records the owned process loading `libvulkan_radeon.so`. The runner pins the RADV ICD; its actual Vulkan query identifies Radeon660M, Mesa26.1.8, integrated GPU. This 2D diagnostic is not a production performance benchmark.
- Reviewed runner checkout `a98fede470155ef40a69791450ca418a4a570aa0`, source `bb6fb09`, no local changes. Private inputless Weston15.0.1 headless/fake-seat → owned authenticated Xwayland → direct export. No host physical input, microphone or desktop capture. The runtime renderer, process lineage, compositor descriptors and raw input source records are preserved.
- Run `/tmp/nullspace-m2-native891-01`, ready `2026-09-04T22:32:50.597Z`, explicitly stopped `22:42:19.806Z`. All operating input came from this agent through ordinary XTEST keys, captured mouse motion and menu pointer actions, adaptively selected after inspecting the current output. No `Input.action_press`, fixture prover, campaign route automation or second operator drove the export.
- Fresh disposable XDG profile under this run; the user's real save/preferences were not accessed. Only intentional checkpoint/settings copies and application logs were copied into evidence. The profile, Pulse cookie, private Xauthority and caches are not included.

The packed executable is outside Git, so the runner's `game_git`/source-hash fields are intentionally null/empty. The explicit executable SHA256 above binds the run to the documented clean-source cross-export; this is not misreported as a source-tree launch.

Reproduction launch (choose a new run path; wait for the shared GPU handoff):

```bash
python3 /home/marius/Projekte/Dev/NULLSPACE-worktrees/native-seatfix/tools/qa/native.py start \
  --run-dir /tmp/nullspace-m2-native-NEW \
  --cwd /home/marius/Projekte/Dev/NULLSPACE-worktrees/project-skeleton \
  --method adaptive_native --width 1920 --height 1080 -- \
  /tmp/nullspace-callback-build.VyQfbM/linux/nullspace.x86_64 \
  --display-driver x11 --rendering-method forward_plus --rendering-driver vulkan \
  --audio-driver PulseAudio --resolution 1920x1080 --windowed --disable-vsync --max-fps 60
```

## Opened original-resolution observations

Every numbered native PNG **01–33** was opened at its original1920×1080 resolution. Names and individual capture times/hashes are in adjacent sidecars. The image is an explicitly temporary default-font diagnostic, with no production scene/art/weapon/creature/audio. No quality score is assigned.

| Actual scenario / controls | Observed result and artifacts |
|---|---|
| Quiet title, then Tab | Initial raw input counts were empty; no application actions occurred. Continue is disabled with a missing-save message. One Tab visibly skips it to Settings. `01`, `02`. |
| Settings by keyboard and pointer | Changed VSync off, sensitivity2.0, invert-Y on, bob0, shake0, reduced flashes on. Separate Ctrl+A/numeric-entry commands edited fields. Tab followed focus down the scroll container to the lower switch and Apply. Apply reported success; reopening UI retained the values. All17 preferences exist in the saved envelope. `03`–`08`, `intentional-save-evidence/settings-applied.json`. UI reopening is **not a cold-start persistence test**. |
| New session, W/mouse/LMB/R/F/E | Initial counters/position/look all zero. W held0.8s produces displacement(0,−0.800). Relative mouse(120,40) with saved sensitivity/invert gives(0.480,−0.160) radians. Exactly one fire edge and reload edge; F enables flashlight; E commits circuit=true. `09`, `10`. These are input counters, not implemented locomotion or gunshots. |
| Held controls across pause/resume | W+LMB pressed before Escape; both remain held in sidecars11–13. Explicit Return resumes. Position stays(0,−1.150), fire2 and reload1 in two captures0.97s apart. Release then a fresh click gives fire3. `11`–`14`. |
| Actual focus loss/return | Runner `blur` focuses only the private X root. Settled game enters PAUSED. Across59 frame samples, time stays70.4833333333306, tick4229, epoch1, including both focused=false and focused=true after `focus`. Focus return does not resume; only subsequent Return does. `15`–`17`, `telemetry-summary.json`. |
| Committed restore vs live state | After refocus/Resume, F changes live flashlight to false without saving, D/mouse/fire change counters/position. Holding W+LMB across F9 simulated death and Return restart restores circuit=true/flashlight=true; fire/reload/look/displacement reset to zero and remain zero while held. Release/fresh click then yields fire1. Clock restores17.45s/tick0 in epoch2. Committed ammo remains pistol owned/chamber1/magazine5/reserve6, shotgun unowned/0/0/0; this does not validate actual weapon reload mechanics. `18`–`22`. |
| Distinct backup recovery | Second E commits circuit=false/time65.9333 while backup retains circuit=true/time17.45. Both original envelopes were copied first. Only the disposable primary was intentionally truncated. Controls refreshes title; it reports recovery and enables Continue. Actual Continue restores the distinct backup's true circuit/flashlight, zero counters and epoch3/time17.45. Good backup SHA256 remains `94a8659ddb10f6fb93b294204380a6506c940a8fb56056c95c947fc355fa71b8`. `23`–`26`, intentional save copies. |
| **Both copies corrupt** | After also truncating the disposable backup, title clearly reports that both copies contain invalid/incomplete JSON and disables Continue. Actual explicit New diagnostic session succeeds with a fresh valid initial checkpoint and epoch4. `27`, `28`, `new-after-double-corruption.json`. |
| Diagnostic ending and credits | F10 commits only the fixture's synthetic completed state and opens its explicit “did not play or complete NULLSPACE” ending notice. Return shows completed-session message/disabled Continue. A new diagnostic session is allowed; Credits notice operated. `29`–`31`, completed envelope. No campaign route was played. |
| Unsupported future version | In a newer valid disposable checkpoint, changed only envelope content_version from1 to100001, leaving a valid older backup. Title disables Continue and explains unsupported version. Actual New Game is refused and returns to MENU; epoch5/tick11/time0.183333 remain unchanged. Primary before/after SHA256 is `7b1ac71c563bd762f14bb04a8ebd2bb33fc7c8a44acdcb68477dd5baa7ac0ef4`; valid backup also compares byte-identical. `32`, `33`, `future-before-attempt.json`, `future-after-attempt.json`, `backup-before-future.json`. |

The first blur screenshot15 was taken immediately after the OS focus change and still shows the preceding gameplay frame. It is retained, not used as settled-state evidence. Screenshot16 plus subsequent application telemetry establishes the actual paused response. Expected identical images12/13 and20/21 are bounded held-input checks, corroborated by later changed14/22 and the held-key sidecars, not assumptions about generic capture freshness.

## Video/audio and file inspection

Both `10-controls-temporal.mkv` and `18-restore-temporal.mkv` finalized with recorder exit0. A separate FFprobe invocation counted600 frames each at1920×1080/60fps,10.0s, with48kHz stereo FLAC. Encoded60fps is not a target-GPU performance claim. Audio sample analysis reports exactly zero amplitude, expected because the skeleton has no audio content; no sound was heard or perceptually reviewed.

Opened full-resolution extracted frames: controls8.0s and restore0.5/1.5/3.3/4.5/8.0/9.0s. Restore frames show live flashlight=false/fire3 → moving displacement0.883/fire4 → DEAD → restoredzero counters/flashlight=true → freshfire1. This is temporal state corroboration from native recording, **not continuous video/experiential review**.

An initial multi-image preview appeared to overlap some text. That was not reproduced in the saved-file checks: separate OCR reads the expected text at1.5/8/9s, the re-opened9s original is intact, and the whole settled8s/9s decoded images differ by at most7/255 per channel (mean0.000166 normalized). OCR and comparison artifacts are retained. No source or harness defect is inferred from that unconfirmed preview impression, and no general recording-quality certification is claimed.

## Provenance, cleanup and limits

`supervisor-events.jsonl` contains every request/dispatch and322 raw XI2 records, all source IDs4/5, zero non-XTEST records; aggregate key/button presses and releases balance. Application accepted-fire counts are exactly1,2,3,4,5 in epoch1 then1 after the intentional reload in epoch2, matching this operator's six gameplay presses. No unexpected accepted action was observed. The application's default `unverified_os_input` label was not overwritten; the independent runner journal supplies the bounded OS provenance.

Explicit `native.py stop` released keys, finalized media, stopped the owned game (expected SIGTERM/exit−15, **not a natural exit0**), Xwayland and Weston (both0), and removed its exact sink. `state.json`: stopped, cleanup_errors=[], controlled_provenance_valid=true, host_defaults_unchanged=true. Exact supervisor/game/Weston/Xwayland/recorder PIDs were checked absent afterward. GPU was handed directly to `/root/bootstrap_m0` for the independent exit-runner review. No unknown process was signalled.

Both application logs contain zero SCRIPT ERROR/engine ERROR lines. The known minimal-X-server XIM warning remains. Operator-only corrections were a first combined Ctrl+A/click that left sensitivity unchanged (repeated correctly before Apply), a read from the wrong preferences subdirectory (corrected), and an `apply_patch` form rejected before any checkpoint mutation (replaced by a valid scoped update). They were not game crashes or hidden accepted exceptions.

Unexercised/separate gates: natural Quit on this corrected M2 export (old runner exit race deliberately avoided), native cold-start preference loading (runner creates fresh profiles), exact focus loss inside the diagnostic's one-deferred-frame load (logical regression only), non-default resolution/fullscreen and remaining settings' native application, production camera/bob/shake/flash effects, real health/weapon/AI/world/campaign restoration, continuous experiential review, audio listening, native Windows, filesystem power-loss durability and target discrete-GPU performance. No profile reuse/seed race or unreviewed harness bypass was used. Whole-M2 independent native review and integration remain required.

Only artifact copies/this report were written during packaging. `SHA256SUMS` covers the public evidence; it excludes itself. Run `sha256sum -c SHA256SUMS` from this directory. Sidecar paths intentionally retain the original disposable run location.
