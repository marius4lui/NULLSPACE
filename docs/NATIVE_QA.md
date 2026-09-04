# Native QA runner

`tools/qa/native.py` supervises one isolated Xwayland game session. It supports real XTEST keyboard/button/captured-relative-mouse input, game-window PNGs, and real-time 60 fps video with a game-only 48 kHz stereo monitor. The diagnostic fixture lives in `tools/qa/fixtures/input_render_audio`; none of it belongs to `game/` or a production export.

This establishes native operation and capture infrastructure. It does not pass any release visual, audio, gun-feel, horror, campaign, native Windows, or discrete-GPU performance gate. The fixture is an instrumented diagnostic with deliberately simple original geometry and synthesized test tones.

## Requirements and boundaries

Validated host: Fedora44, Xwayland24.1.13, Python3.14/PythonXlib0.33, FFmpeg8.1.2 with x11grab/Pulse/libx264/FLAC, PipeWire1.6.8, Godot4.7.2.stable.official.ed1daf0bf, Mesa26.1.8 RADV, integrated Radeon660M. NumPy2.4.6 is used only by the media analyzer. No new packages were needed for the harness. M0 owns software installation/version provenance.

The runner must start from a native Wayland session with `XDG_RUNTIME_DIR` and `WAYLAND_DISPLAY`. It creates a rootful Xwayland surface as the current user; “rootful” means a complete X root window, not root privileges. Xwayland chooses an unused display through `-displayfd`. TCP is disabled. X11 local sockets require a random MIT cookie in a mode0600 authority file within a mode0700 private runtime directory. No cookie is written to command arguments, logs, or Git. No `-ac`, host-grab, input portal, uinput, microphone, desktop source, or global audio-default changes are used.

The target must be a direct executable, not a shell wrapper that forks the actual game. The runner binds the top-level window's `_NET_WM_PID` to the launched PID, verifies X11 focus, rejects foreign mapped windows, and verifies audio streams on its unique sink belong to the launched PID. The selected Vulkan ICD defaults to `/usr/share/vulkan/icd.d/radeon_icd.x86_64.json`; `vulkaninfo` must identify RADV without a CPU Vulkan device. Actual game renderer selection is also checked in `game.log` and fixture events. This ICD proof alone does not certify an arbitrary application used Forward+.

A process-held `nullspace-qa-gpu.lock` serializes native sessions. Coordinate one named reviewer/operator at a time. The rootful surface can also receive physical user input, so unexplained input invalidates a scripted proof. The runner records injected requests; fixture/application telemetry must corroborate accepted events. A successful CLI dispatch does not establish application behavior.

## Start and control

Run from the repository. Use a **new absolute evidence directory** for every `start`. Example for the standalone fixture:

```sh
python3 tools/qa/native.py start \
  --run-dir /home/marius/Projekte/Dev/NULLSPACE/evidence/native-qa/example-01 \
  --method scripted_diagnostic \
  -- /home/marius/.local/share/nullspace/toolchains/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 \
  --path tools/qa/fixtures/input_render_audio \
  --display-driver x11 --rendering-method forward_plus --rendering-driver vulkan \
  --audio-driver PulseAudio --resolution 1920x1080 --windowed \
  --disable-vsync --max-fps 60
```

Substitute an absolute `--path` for another worktree, or supply a Linux export executable directly. `--cwd` selects its working directory. `--method adaptive_native` records an adaptively operated review, while `manual_native` records a human-operated run. The label alone does not make it independent or experiential. Always identify the operator and actual observations in the review record.

The start command returns when an owned window is mapped. Godot may still be loading. Inspect a screenshot and wait for the expected application state and the owned `audio.stream_ids` before recording. The fixture proof waits for its own ready/state events and audio stream.

All following examples target the run directory above:

```sh
python3 tools/qa/native.py status --run-dir evidence/native-qa/example-01
python3 tools/qa/native.py screenshot --run-dir evidence/native-qa/example-01 --name before.png
python3 tools/qa/native.py input --run-dir evidence/native-qa/example-01 --tap Return
python3 tools/qa/native.py input --run-dir evidence/native-qa/example-01 \
  --key-down w --key-down d --key-down Shift_L --move 120 -25 --click 1 --hold 0.6 --release
python3 tools/qa/native.py input --run-dir evidence/native-qa/example-01 --tap Escape
python3 tools/qa/native.py input --run-dir evidence/native-qa/example-01 --pointer 960 540 --click 1
python3 tools/qa/native.py release --run-dir evidence/native-qa/example-01
python3 tools/qa/native.py blur --run-dir evidence/native-qa/example-01
python3 tools/qa/native.py focus --run-dir evidence/native-qa/example-01
```

Use X11 key names (`w`, `Shift_L`, `Escape`, `Return`, `space`, `F12`). Down/up/tap/button/click flags repeat to combine controls. `--move DX DY` uses XTEST relative device motion; the proof observes Godot's captured `InputEventMouseMotion.relative`. `--pointer X Y` is absolute within the verified game window for a visible menu pointer; it rejects outside coordinates. Status includes the window-relative pointer location. Nothing uses `SendEvent` or `Input.action_press`.

`blur` releases injected keys and focuses the **private X root** to exercise the application's focus-loss handling. `focus` restores verified game focus. These operations never target the host desktop. The next `input` command also restores game focus by design; use screenshots/status/application telemetry while evaluating a blurred state.

Keys/buttons remain held between commands, with a default10-second lease, configurable0.1–30 seconds. `--hold` waits0–10 seconds. Taps/clicks last at least80ms. `--release` releases all runner-held keys/buttons after that command. The supervisor releases them on expiry, lost X11 focus, malformed command, client disconnection, stop, and ordinary errors/signals. Housekeeping normally polls every200ms; synchronous screenshot/command processing can delay a lease check until that bounded command returns. Do not use an unattended held key as a timing guarantee.

## Capture and cleanup

```sh
python3 tools/qa/native.py record --run-dir evidence/native-qa/example-01 --name session.mkv --seconds 10
python3 tools/qa/native.py status --run-dir evidence/native-qa/example-01
python3 tools/qa/native.py record-stop --run-dir evidence/native-qa/example-01
python3 tools/qa/native.py stop --run-dir evidence/native-qa/example-01
```

Recording starts asynchronously, finishes at its requested duration, and receives an FFprobe/hash sidecar. Omit `record-stop` when allowing it to finish. FFmpeg captures the verified **window ID**, never the host root window. It records only `<unique_sink>.monitor`, encodes libx264 ultrafast/CRF18/yuv420p and FLAC, and writes a Matroska container. Geometry/unmap/ownership changes are failures. A60fps encoded stream can duplicate images; application frame telemetry is separate evidence. Live x11grab snapshots can capture presentation updates; prefer application `frame_post_draw` viewport captures for exact visual comparisons where available.

Each run has `profile/data`, `profile/config`, `profile/cache`, and `profile/state` via isolated XDG variables. `XDG_RUNTIME_DIR` remains available for existing IPC; `HOME` is never replaced. The named Pulse sink is not connected to the host speakers, and no host microphone is opened. Per-run profile caches are excluded from Git; keep intentional save/config artifacts and checkpoint lineage separately when a test needs them.

`stop` first releases input, finalizes recording, terminates only owned process handles, removes only the owned sink after validating its exact name+module ID, and deletes private runtime credentials/socket. Run evidence and profiles remain on disk. It records host audio defaults before/after and any cleanup error. Defaults are compared, never forcibly restored over user changes. Do not call a run clean if `cleanup_errors` is nonempty.

If the supervisor itself is killed with SIGKILL, use the exact run's recovery command:

```sh
python3 tools/qa/native.py recover --run-dir evidence/native-qa/example-01
```

Recovery refuses a live supervisor, verifies `/proc` PID/start-time/process-group/session identities before signaling game/Xwayland/recorder PIDs, releases the private server's queried held keys where available, and validates the unique sink owner before removing it. It never kills by process name or broad process group. A recovery report preserves the original failure record. The caller must inspect recovery errors; abrupt kill recovery is not equivalent to a successfully finalized recording.

## Reproduce and inspect the diagnostic

```sh
python3 tools/qa/prove_fixture.py --run-dir evidence/native-qa/example-01
python3 tools/qa/analyze_fixture_media.py --run-dir evidence/native-qa/example-01
python3 tools/qa/native.py stop --run-dir evidence/native-qa/example-01
```

Run `prove_fixture.py` immediately after a fresh fixture launch. It performs native XTEST controls, reads **observed application events**, saves menu/movement/pause/final PNGs, and records10 seconds. It checks simultaneous W+D+Shift; captured relative deltas; changed position/camera; three accepted clicks; pause/menu rejection; resume; explicit release; lease expiry; and release on an invalid command. Its result is named `PASS_SCRIPTED_DIAGNOSTIC`, never “independent playthrough.”

The media analyzer requires1920×1080,600 encoded frames at60fps,48kHz stereo, independently identifiable440Hz-left/660Hz-right quiet tones, nonzero/unclipped signal, and three visual/audio pulses aligned within150ms. This tolerance is a **capture-diagnostic threshold**, not a product gun-feel requirement. The fixture's60ms generator buffer contributes latency. It extracts `fixture-stereo.wav` for an actual listening modality when one is available.

Open the original-resolution PNGs and relevant original-resolution video frames. Record which were opened, what changed, exact commit/executable hash, operator independence, actual method, and remaining defects. Source/scene/hash and screenshot evidence may establish the input/render path; they do not establish subjective audio, continuous temporal experience, or game quality.

## Verified limits and corrections

The implementer report and artifacts are in `evidence/native-qa/IMPLEMENTER_REPORT.md` and `fixture-dev-04/`. The latter is a controlled native proof with all input/media checks passing and clean cleanup. Earlier dev01–03 evidence is retained as failures/diagnostics, not accepted proof.

Observed compositor behavior: with VSync enabled, an obscured rootful Wayland surface can throttle Godot to1FPS and delay application processing despite valid XTEST dispatch. The controlled fixture uses explicit `--disable-vsync --max-fps 60`, which restored60FPS telemetry and stable audio. A project that reapplies VSync at startup can override the CLI choice; operate its real Settings UI and record that isolated preference. This environment workaround must not become a product performance claim.

Godot logs one XIM input-method warning on this minimal X server. Latin keyboard, modifiers, function keys, and captured mouse have worked; IME/text composition remains unverified. Existing `pactl -f json list modules` omits module index on this PipeWire version; cleanup uses the sink's reliable `owner_module` instead. The two initial owned null-sink leftovers were removed with recorded validated recovery and unchanged host defaults.

Root's actual audio capability probe of the captured Ogg returned `audio content omitted because you do not support audio input`. Therefore actual listening is unavailable in the current root runtime; no agent listening PASS is inferred. Continuous-video experiential review is also unverified. Native Windows and target discrete-GPU evidence remain separate open project limitations.
