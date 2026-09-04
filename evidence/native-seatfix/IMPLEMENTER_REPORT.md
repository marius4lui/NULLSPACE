# Native QA correction — implementer evidence

Disposition: corrected infrastructure has two successful exact-clean-source diagnostic runs; **independent acceptance is still required**. This is not a game milestone, experiential playthrough, visual-quality score, audio listening result, or release acceptance.

Owner/operator: `qa_native`, GPT-6 Astra/max. Worktree: `/home/marius/Projekte/Dev/NULLSPACE-worktrees/native-seatfix`, branch `agent/qa-native-seatfix`. All times below are UTC on 2026-09-04; the local date crossed midnight into September 5 during packaging. No production `game/` files were changed.

## Exact source and changes

- Original infrastructure: `f3da72c`, original evidence `76a9b64`. Independent review rejected physical-seat provenance and stalled-client lease safety. The original branch remained frozen.
- `0076de52b233c9269a2f48b936eed55ac4242138`: inputless private Weston backend, authenticated/private XI2 provenance guard, independent safety thread, total IPC deadline, cancellation and owned cleanup/recovery.
- `ec4194a0249af683171c7b296f1e5fa80c59b4d7`: window-local Composite backing-pixmap PNG capture and fixture-only external-snapshot-before-viewport freshness challenge.
- `bb6fb09791c0ec65d5193f9dc045da7b8d16fecf`: test-only correction using a real capture burst spanning the key lease; a single new PNG was faster than the old test assumed. This is the exact clean commit used by both final implementer repeats.

The source is frozen for the separate bootstrap_m0 reviewer. Evidence-only commits after these runs do not change their source hashes. Every run's `state.json` records clean/dirty Git identity, source hashes, executable hash, process identities, private display/runtime, profiles and actual rendering/device metadata. `manifest.json` hashes public artifacts and makes no acceptance assertion.

## What was corrected

Controlled sessions no longer attach Xwayland to the host's physical Wayland seat. They own a mode-0700 runtime and Weston 15.0.1 headless GL compositor with no host parent connection or physical input devices. Weston socket credentials identify its exact PID/UID; inspected device handles were only `/dev/dri/renderD128` and `/dev/null`. Its fake seat creates protocol proxies, not a physical input producer. The game still actually renders Forward+ using Vulkan RADV on the integrated Radeon 660M. An invalid private Wayland endpoint prevents Godot from falling back to the host compositor on X11 failure.

The private XI2 connection verifies the exact Xwayland kernel peer, authority/runtime ownership, eight expected core/XTEST/inputless-proxy devices and their properties. It negotiates XI2.2 and checks raw source IDs even with captured mouse input. Only verified XTEST source IDs 4/5 appeared in the accepted repeats. Unexpected source, hierarchy or relevant property changes invalidate the run. No device is disabled in the final design. A same-UID client deliberately obtaining the private cookie and injecting XTEST is outside this boundary; command/application event correlation remains necessary.

A separate safety thread checks provenance, focus and key leases on a nominal 50 ms tick while the command thread waits on IPC, capture, audio queries or a held-input request. Xlib threading is initialized before connections; shared GameWindow access is guarded by a reentrant lock. Holds wait outside it. SIGTERM cancels the wait. Cleanup joins the safety thread before closing its X connections. This is not a hard-real-time guarantee; actual observed release times are below.

PNG capture redirects only the verified owned game window with XComposite automatic mode. Each screenshot names the current backing pixmap, reads it directly, frees the reference and validates geometry/ownership/pixel layout. It never redirects the root or a root-wide child list. The named pixmap is reacquired on every request because map/resize can replace it. CPU conversion and PNG encoding do not hold the safety lock. Video is separately identified as FFmpeg x11grab of the redirected owned window, with game-only stereo from the unique sink monitor. No host root, desktop, microphone or default audio source is captured or changed.

Primary API basis: [Weston headless backend](https://wayland.pages.freedesktop.org/weston/toc/running-weston.html), [XI2 protocol](https://www.x.org/releases/X11R7.7/doc/inputproto/XI2proto.txt), [XTEST protocol](https://www.x.org/releases/X11R7.7/doc/xextproto/xtest.html), [XComposite API](https://xorg.freedesktop.org/archive/X11R7.5/doc/man/man3/Xcomposite.3.html). Installed `/usr/share/doc/xorgproto/compositeproto.txt` sections 3.1/10 explicitly describe backing-store replacement and freeing old pixmap names; section 3 permits parent shadow-update lag. Those semantics justify this boundary, but do not uniquely diagnose the earlier intermittent staleness.

## Final implementer repeats

Both runs started with `harness_git.clean=true` at full commit `bb6fb09791c0ec65d5193f9dc045da7b8d16fecf`, distinct private runtimes and isolated XDG profiles. Both used the exact Godot executable SHA256 `8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e`.

| Observed check | proof-05 | proof-06 |
|---|---:|---:|
| UTC start → clean stop | 21:58:25.347 → 21:58:52.270 | 21:58:52.444 → 21:59:18.143 |
| Native application input checks | 14/14 | 14/14 |
| Objective recording checks | 8/8 | 8/8 |
| Post-recording full-image reference pairs | 7/7 exact RGB | 7/7 exact RGB |
| Native safety checks | 15/15 | 15/15 |
| Partial IPC: actual key release after request | 223.821 ms | 213.133 ms |
| Drip IPC: actual key release after request | 249.152 ms | 239.187 ms |
| Capture burst: actual key release after request | 275.017 ms | 232.819 ms |
| Long hold: actual key release after request | 227.718 ms | 238.635 ms |
| Capture burst count/duration | 11 / 0.841 s | 12 / 0.821 s |
| SIGTERM during ten-second hold → cleanup | 320.953 ms | 270.985 ms |
| Recorded audio minus visual pulse onset | 32, 60, 60 ms | 52, 62, 53 ms |
| Cleanup errors / host defaults changed | none / no | none / no |

Each recording contains 600 encoded 1920×1080 frames at 60 fps and 10 seconds of 48 kHz stereo. The quiet channels independently identify 440 Hz left and 660 Hz right. Peaks are 0.344971/0.344696; all three shot flashes and audio pulses are captured, within the unchanged 150 ms diagnostic tolerance. These measurements do not establish rendered 60 fps in an arbitrary game or subjective sound quality. The fixture initially reports cold-load audio underruns; actual captured-media checks and runtime telemetry are retained instead of hiding them.

Each repeat records 176 XI2 raw notifications, all source IDs 4/5. AllDevices selection produces matching master/slave notifications, so 176 does not mean 176 independent user actions. Application key/button/motion events, accepted shots, state samples and supervisor requests provide the attributable timeline. Quiet intervals had no unrequested position/look/shot/mode changes. Cleanup stopped owned game/Xwayland/Weston, released input, unloaded the exact unique sink, removed the private runtime and left host defaults unchanged.

### Actual images opened

Opened at original 1920×1080 resolution, separately for **both** proof-05 and proof-06:

- All seven `freshness-01-baseline.png` through `freshness-07-captured_final.png` and `viewport-007.png`.
- All three `video-shot-1.png`, `video-shot-2.png`, `video-shot-3.png`, extracted without resizing at the measured flash onset plus 50 ms.
- `06-lease-during-capture.png` and the final capture-burst image (`06-lease-burst-10.png` for proof-05, `06-lease-burst-11.png` for proof-06).

The opened freshness images visibly change from playing/shot 3/mouse total 60,-15 to left-turned shot 4/-40,5, then right-turned shot 5/5,-10. Pause and menu show captured=false, resumed play captured=true, and final shot 6/mouse total 95,-20 has another changed camera view. Final positions are 2.43/1.80/5.04 in proof-05 and 2.40/1.80/5.10 in proof-06. Their later actual viewport references match every RGB pixel, including the HUD; the screenshot is always requested before the F12 reference, not after a GPU readback that could force presentation. No animated barcode or continuous UI redraw was added.

The video samples visibly show white synchronization patches and shot counters 1→2→3 with corresponding camera/position changes. Burst first/last images show the actual small leftward movement before key release, not an older final-state frame. These are original-resolution still-image observations, not a claim to have experienced continuous video or gun feel.

Representative artifact paths relative to this report: `proof-05/input-proof.mkv`, `proof-05/fixture-stereo.wav`, `proof-05/fixture-stereo.ogg`, `proof-05/freshness-07-captured_final.png`, and corresponding proof-06 files. All request/state/input/media/safety/freshness logs and PNG sidecars are included in their manifests. Profiles, credentials, Mesa caches and bulk intermediate frame-stat text are excluded from Git.

## Failures retained, not rewritten as passes

1. `development-01` was an uncommitted private XI2-disable experiment. Disabling changed Xwayland proxies into `FloatingSlave`; the first strict attached-device guard refused startup. `development-02` then observed all four private proxies disabled/detached but Xwayland 24.1.13 crashed with SIGSEGV at address 0x28 when the game mapped. Logs and state are retained. The stripped binary did not establish a unique source symbol; this is not a proven upstream root-cause claim. Final source does not use this disabling approach.
2. At clean `0076de5`, proof-01's inspected images were current, but proof-02's `06-lease-during-capture.png` was byte-identical to older `04-final.png` despite changed actual position. Both SHA256 values are `a450577b2d7809297b8617d15847d1994ae0994606258bf52b3c47dbe4d7d5d8`. The old image shows 2.16/1.80/5.16 while later capture-time telemetry shows approximately 2.21/1.80/4.70. All numerical input/media/safety checks had passed; image inspection correctly made **capture acceptance FAIL (QA-005)**. The original artifacts and logs remain intact.
3. Clean proof-03 at `ec4194a` passed input/media and all seven post-recording exact RGB pairs. Its safety test failed because the new PNG completed before the test's required thread-alive observation at a 200 ms lease. Actual key release was 257.941 ms, within the unchanged 450 ms limit. `bb6fb09` replaces that obsolete duration assumption with a genuine capture burst spanning the deadline; it does not lower the release threshold or add a fake delay.
4. Clean proof-04 at `bb6fb09` failed media with actual fixture 4–16 fps, increasing audio underruns, 596 video frames and only one recorded visual pulse. Concurrent project-native previews were observed. Root asked the user, who confirmed ownership and closed them voluntarily; no agent signaled the unknown processes. Quiet repeats on unchanged source subsequently passed. Contention is supported as a contributing explanation, not proved the sole cause. The failure remains recorded and does not certify degraded-load media behavior.

## Reproduce

Run from the exact source checkout, using a new absolute run directory and one coordinated GPU operator. The interface is documented in `docs/NATIVE_QA.md`.

```sh
python3 tools/qa/native.py start --run-dir /absolute/new/run --method scripted_diagnostic -- \
  /home/marius/.local/share/nullspace/toolchains/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 \
  --path tools/qa/fixtures/input_render_audio --display-driver x11 \
  --rendering-method forward_plus --rendering-driver vulkan --audio-driver PulseAudio \
  --resolution 1920x1080 --windowed --disable-vsync --max-fps 60
python3 tools/qa/prove_fixture.py --run-dir /absolute/new/run
python3 tools/qa/analyze_fixture_media.py --run-dir /absolute/new/run
python3 tools/qa/prove_freshness.py --run-dir /absolute/new/run
python3 tools/qa/prove_safety.py --run-dir /absolute/new/run
python3 tools/qa/manifest.py --run-dir /absolute/new/run
```

`prove_safety.py` intentionally ends the owned session by SIGTERM while W is held; otherwise use `native.py stop`. Inspect each result, not just a shell exit code. Seven offline unit checks (`python3 -m unittest discover -s tools/qa/tests -v`) also passed, but do not replace the native proofs.

The source fixture exercises Return, simultaneous W+D+Shift, captured relative mouse 120,-25 then -60,10, left click, Escape pause/resume, Tab menu, explicit release, expired lease and rejected malformed input. Freshness adds seven changed states and F12 references. Safety adds partial/drip IPC, the capture burst, a hold longer than its lease, private-root blur/refocus and SIGTERM cancellation. It does not inject engine actions or call production gameplay methods.

## Bootstrap and remaining limits

The tested environment is Fedora 44, Python 3.14 / Python-Xlib 0.33 / Pillow 12.3.0 / NumPy 2.4.6, Xwayland 24.1.13, Weston 15.0.1, FFmpeg 8.1.2, PipeWire 1.6.8, Mesa 26.1.8 RADV and Godot 4.7.2.stable.official.ed1daf0bf. Signed Fedora RPMs were extracted into a new user-owned Weston prefix because passwordless system install was unavailable. No password prompt, Snap, package install script or system overwrite was used. See `WESTON_PACKAGES.md` for exact verified package hashes and commands. RDP/VNC packages are distribution dependencies only; those backends are not launched.

Root's real AudioContent probe returned `audio content omitted because you do not support audio input`. **Actual listening is unavailable in the current root runtime; no audio was claimed heard.** WAV/Ogg and stereo/sync metrics remain useful but cannot satisfy that experiential gate. Continuous temporal experience, native Windows operation, target discrete-GPU performance and all game-quality/release requirements remain unverified. PNG freshness in this settled diagnostic is not a universal frame-lock guarantee for a moving production scene; correlate production captures with actual viewport/state or temporal evidence. The independent review must decide bounded native-infrastructure PASS/FAIL.
