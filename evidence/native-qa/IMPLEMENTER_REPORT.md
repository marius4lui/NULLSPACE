# Isolated native QA implementation report — 2026-09-04

Scope: `tools/qa/**`, `docs/NATIVE_QA.md`, this evidence directory. Implementer/operator `/root/qa_native`, GPT-6 Astra/max. No production `game/` files or root-owned status/issue registers changed. This report is **implementer evidence, not independent acceptance**.

Source packaging commit: `f3da72c33de8dc34fe98a67fc0af424f797439e9`, branch `agent/native-qa`, worktree `/home/marius/Projekte/Dev/NULLSPACE-worktrees/native-qa`. The actual dev04 run occurred while the implementation was uncommitted on baseline `4f96c7921878c93e9d465103b53d9f53d467cce9`; its state correctly records dirty Git status. Subsequent packaging added source-hash manifests, private-root blur/focus, bounded menu pointer, and a status/auto-exit race correction. Independent review must exercise the packaged commit and these additions before integration. No clean-commit runtime claim is made for dev04.

## Implemented and exercised

Private rootful Xwayland starts with automatic free display allocation, local-only X sockets, mode0600 cookie authority under a mode0700 runtime directory, real RADV ICD, and one GPU lease. The supervisor launches a direct owned executable and verifies the mapped window `_NET_WM_PID`, XTEST extension and X11 focus. A unique Pulse null sink routes the game audio; capture verifies the stream PID before opening only that sink's stereo monitor. Host default devices remain unchanged.

PNG capture targets the game window ID at its native1920×1080 dimensions. Recording uses real-time x11grab60fps plus Pulse48kHz stereo, libx264 ultrafast/CRF18 and FLAC/MKV. Per-run XDG data/config/cache/state profiles are separate; native IPC runtime and host HOME remain intact. Supervisor events, application events, command/build/GPU metadata, FFprobe sidecars and hashes make the method reviewable. Runtime credentials and profile caches are excluded from Git.

The runner releases its held inputs on explicit release, lease expiry, invalid command, focus loss, shutdown and ordinary errors. It finalizes the recorder and removes only its own processes, sink/module, authority and control socket. Recovery validates PID start-time/session/group identities and the exact sink owner; it does not kill by name or broad group. Recovery of the two initial orphan sinks and normal dev04 cleanup are evidenced below.

## Controlled proof: fixture-dev-04

Exact launch command is in `fixture-dev-04/launch.json`; setup/teardown and hardware are in `state.json`. Godot4.7.2.stable.official.ed1daf0bf executable SHA256 `8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e`. `game.log` proves Vulkan1.4.354 Forward+ on AMD Radeon660M RADV REMBRANDT, Mesa26.1.8. Xwayland24.1.13, FFmpeg8.1.2, PipeWire1.6.8, native1920×1080. Explicit `--disable-vsync --max-fps 60` is an environment diagnostic setting, not a product performance result.

`input-verification.json` records **14 passed application-observation checks**:

- Menu/Enter transitions to captured play.
- Simultaneous W+D+Shift, movement and accepted fire; exact captured relative mouse120,-25 produces yaw-0.360/pitch0.075 and a visibly changed view.
- Explicit release clears all observed movement keys.
- Pause rejects held movement/click while showing the physical key state; resume recaptures and accepts a new input.
- Tab menu rejects motion/fire; Enter returns to captured play.
- Expired lease releases W; an invalid command while D is held rejects the command and releases D.
- The fixture reports actual X11/RADV rather than a headless input shortcut.

The sequence makes exactly three accepted shots. Final captured mouse total is60,-15. The proof is **scripted diagnostic execution**, not independent adaptive play. Application frame samples during the control sequence report60FPS, and generator skip count stays129 throughout; startup underruns before the proof are explicitly present in the raw telemetry.

`media-verification.json` records **8 objective media checks**:1920×1080;60/1 stream;600 encoded frames over10seconds;48kHz stereo; dominant quiet frequencies440Hz left/660Hz right; nonzero/unclipped signal; three visible/audio pulse pairs; and sync within150ms. Measured audio-minus-video offsets are55,55,58ms. Per-channel sample peaks are0.34497/0.34470; RMS approximately0.05818. This measures capture/signal integrity, not perceived sound, gun feel, motion smoothness or target-GPU performance. The codec can duplicate frames; encoded cadence alone is not rendered cadence.

Opened at **original1920×1080** by the implementer:

| Artifact | Actual observation |
|---|---|
| `01-menu.png` | Menu, uncaptured pointer, zero shots, centered diagnostic lane |
| `02-moved.png` | Playing/captured, one shot, position2.25/1.80/5.98, camera shifted right/rotated, exact relative120,-25 |
| `03-paused.png` | Paused/uncaptured with two shots; same position and camera after blocked movement/click |
| `04-final.png` | Playing/captured, three shots, changed final position2.07/1.80/5.18 and mouse60,-15; transient label presentation overlap visible in the snapshot, so no claim of frame-atomic capture |
| `05-shot-frame.png` | Original-resolution frame extracted at0.9seconds from the MKV: first shot, changed view, white sync patch visible |

The geometry and overlay clearly label themselves diagnostic, not production. No art/lighting/material/animation scores are assigned. No continuous video was experienced as a native video modality. The PNG/frame observations corroborate the logged state changes only.

Run stopped2026-09-04T20:49:36.934Z, as recorded in `state.json`. Cleanup reports `status=stopped`, `cleanup_errors=[]`, `host_defaults_unchanged=true`. Private authority/socket/runtime directory and owned null sink were removed. Data/profile/evidence files were retained.

Audio capability artifacts: `fixture-stereo.wav` and `fixture-stereo.ogg`, both derived only from the recorded game monitor. Root attempted the actual Ogg AudioContent input and reported the tool response: `audio content omitted because you do not support audio input`. Therefore **root listening is unavailable in this runtime**. The implementer also does not claim listening. Audio/horror/experiential gates remain open.

## Failures, corrections, and exclusions

| Run / finding | Evidence and disposition |
|---|---|
| dev01 initial native experiment | Initial original PNGs and application events prove the basic input/capture path, but later16 shots and extra movement were not dispatched by the declared operator. Root/core/bootstrap/environment all denied issuing those controls. Physical user input through the visible rootful surface is plausible but unattributed. Entire run excluded from controlled acceptance; preserved for provenance. |
| dev01/dev02 sink cleanup | PipeWire `pactl` JSON module entries omit `index`; initial cleanup failed before unload. Fixed to verify unique sink name plus its reliable `owner_module`. `recovery.json` in both runs records removal of only the exact owned sink and unchanged host defaults. |
| dev02 early ready race | Mapped Godot window preceded fixture `_ready`; initial proof had no fixture events yet. Proof now waits for observed fixture state and the owned audio stream. |
| dev02 obscured VSync | Actual fixture telemetry fell to1FPS; valid Return was delivered after the too-early assertion and audio underflowed. No-vsync plus60FPS cap restored the controlled dev04 loop. Projects that reapply VSync must use their actual isolated Settings UI. |
| dev03 concurrent launch | Correctly rejected because core_m2 held the GPU lease. No game/Xwayland/sink was started by this attempt. |
| Bootstrap reuse exit race | Bootstrap independently operated its own diagnostic and reported clean stop/default preservation; one `status` raced an auto-exit and saw connection reset. Final CLI waits briefly for the terminal state before returning a connection-close error. |

The runtime does not prevent physical input from reaching the rootful game surface and cannot prove that all received input originated in XTEST. Declared ownership, request logs and application event agreement are required; contaminated runs are discarded. The isolation guarantees concern the display/capture target, audio source, profile and owned resource lifetime.

## Handoff and remaining checks

Command reference: `docs/NATIVE_QA.md`. Primary API: `start`, `status`, `input`, `focus`, `blur`, `release`, `screenshot`, `record`, `record-stop`, `stop`, `recover`; `manifest.py` hashes retained public evidence. `--pointer X Y` supports menu clicks within the owned window. `blur` focuses only the isolated X root and automatically releases held input; a subsequent `input` restores game focus.

After this report's source commit, reviewer should rerun the fixture, inspect original images, verify matching source hashes/command identity, exercise private-root blur/menu pointer and wrong-target/bounds rejection, verify denied unauthenticated access/no TCP listener, and test ordinary shutdown plus deliberate supervisor-death recovery. These are independent adversarial checks, not waived criteria. Core and bootstrap reuse demonstrate useful operation but are not a full independent harness acceptance review.

Known environment limits: integrated660M cannot establish the target RTX2060/RX6600 discrete result; native Windows absent; XIM warning/IME composition unverified; real audio listening unavailable to root; continuous temporal experiential review unverified. Synchronous bounded commands can delay lease polling. Production profile restart/lineage orchestration remains the caller's responsibility. No goal/release gate is marked complete here.
