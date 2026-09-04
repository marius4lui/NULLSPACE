# Native QA runner

`tools/qa/native.py` supervises one isolated Xwayland game session. Controlled runs use a private **inputless Weston headless compositor**, not the desktop's physical seat. It supports real XTEST keyboard/button/captured-relative-mouse input, game-window PNGs, and real-time 60 fps video with a game-only 48 kHz stereo monitor. The diagnostic fixture lives in `tools/qa/fixtures/input_render_audio`; none of it belongs to `game/` or a production export.

This establishes native operation and capture infrastructure. It does not pass any release visual, audio, gun-feel, horror, campaign, native Windows, or discrete-GPU performance gate. The fixture is an instrumented diagnostic with deliberately simple original geometry and synthesized test tones.

## Requirements and boundaries

Host: Fedora 44, Xwayland 24.1.13, Python 3.14/PythonXlib 0.33, FFmpeg 8.1.2 with x11grab/Pulse/libx264/FLAC, PipeWire 1.6.8, Godot 4.7.2.stable.official.ed1daf0bf, Mesa 26.1.8 RADV, integrated Radeon 660M. NumPy 2.4.6 is used only by the media analyzer. The corrected controlled backend additionally requires Weston 15.0.1. Exact run results and limitations are recorded in `evidence/native-seatfix/`, not inferred from these requirements.

The runner requires the host's `XDG_RUNTIME_DIR` for its GPU lease and existing Pulse server. Controlled runs create their own mode-0700 Wayland runtime and launch only `weston --backend=headless --renderer=gl --fake-seat --no-config --shell=kiosk-shell.so`. Weston receives no host DISPLAY, WAYLAND_DISPLAY, WAYLAND_SOCKET, session ID or D-Bus address. Its kernel socket peer must match the exact owned PID/UID, and its inspected device descriptors must not include physical input or DRM card devices. The fake seat supplies compatibility protocol objects, not a host input producer. Weston and the application still use real hardware rendering; check actual logs, not just flags.

Xwayland creates a rootful surface **inside that inputless compositor**; “rootful” means a complete X root window, not root privileges. It chooses an unused display through `-displayfd`. TCP is disabled. X11 local sockets require a random MIT cookie in a mode-0600 authority file within the mode-0700 private runtime. The XI2 connection's kernel peer must match the exact owned Xwayland PID/UID. No cookie is written to arguments, logs, or Git. No `-ac`, host-grab, input portal, uinput, microphone, desktop source, or global audio-default changes are used. The game is given an intentionally nonexistent private Wayland endpoint, so X11 failure cannot fall back to the host compositor.

The target must be a direct executable, not a shell wrapper that forks the actual game. The runner binds the top-level window's `_NET_WM_PID` to the launched PID, verifies X11 focus, rejects foreign mapped windows, and verifies audio streams on its unique sink belong to the launched PID. The selected Vulkan ICD defaults to `/usr/share/vulkan/icd.d/radeon_icd.x86_64.json`; `vulkaninfo` must identify RADV without a CPU Vulkan device. Actual game renderer selection is also checked in `game.log` and fixture events. This ICD proof alone does not certify an arbitrary application used Forward+.

A process-held `nullspace-qa-gpu.lock` in the original host runtime serializes native sessions, independent of their private runtimes. Coordinate one named reviewer/operator at a time. The read-only XI2 guard verifies core/XTEST device identities and expected inputless protocol proxies before launching the game. It negotiates XI2.2 to receive source IDs even during captured input, records raw source events, and invalidates/stops controlled runs on non-XTEST sources, hierarchy changes or device-enable/property drift. It does not disable any host or private device. A same-UID client deliberately obtaining the cookie and injecting XTEST is outside this provenance boundary; correlate the request journal with actual application events. A successful CLI dispatch does not establish application behavior.

Fedora user-local Weston bootstrap used signed distribution RPMs because passwordless system installation was unavailable. No password prompt or system install occurred. Download only x86_64 from the official repositories, verify every signature/digest with `rpm -K`, and extract into a new user-owned prefix, never `/` or an existing installation. The tested prefix is `/home/marius/.local/share/nullspace/toolchains/weston-15.0.1-fedora44`; `--weston /absolute/prefix/usr/bin/weston` overrides it. The helper confines relocated library/module paths to the compositor process. The package archive identities are retained with correction evidence.

```sh
dnf --repo=fedora --repo=updates download --arch=x86_64 --resolve \
  --destdir /absolute/new/rpm-directory weston.x86_64
rpm -K /absolute/new/rpm-directory/*.rpm
```

Weston's primary documentation describes the [inputless headless backend and renderer selection](https://wayland.pages.freedesktop.org/weston/toc/running-weston.html). The [XI2 protocol](https://www.x.org/releases/X11R7.7/doc/inputproto/XI2proto.txt) specifies device hierarchy, enabled state and raw source IDs; [XTEST](https://www.x.org/releases/X11R7.7/doc/xextproto/xtest.html) synthesizes server input, not application action shortcuts. Installed Python-Xlib and XI2 protocol headers determine the concrete API/encoding.

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

Substitute an absolute `--path` for another worktree, or supply a Linux export executable directly. `--cwd` selects its working directory. `--method adaptive_native` records an adaptively operated review using the same inputless backend. Physical human operation requires **both** `--method manual_native --allow-physical-input`, deliberately using the host Wayland compositor's physical seat with a private X server. Controlled methods reject that flag, and manual mode without the flag is rejected. A manual run is not an XTEST-only provenance claim. A method label alone does not establish independence or experiential observation.

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

Keys/buttons remain held between commands, with a default 10-second lease, configurable 0.1–30 seconds. `--hold` waits 0–10 seconds but cannot extend the lease. Taps/clicks normally last at least 80 ms; safety cancellation can release earlier. `--release` releases all runner-held input afterward. A separate safety thread targets a 50 ms tick during capture, audio queries, input holds and IPC waits. It checks lease/focus and XI2 provenance. Xlib threading is enabled before opening connections, GameWindow uses a shared reentrant lock, and holds wait outside that lock. A stop signal cancels a long wait. Cleanup stops/joins the safety thread before closing its X connections. The tick is not a hard real-time guarantee: use observed application release latency in the native fault evidence.

Accepted command clients have a **500 ms total** newline deadline, not a timeout renewed by each received byte. Incomplete/drip-fed JSON cannot suspend the safety thread. Malformed commands and client write failures release input. Native fault tests explicitly measure releases during partial IPC, drip feeding, a slow screenshot, and a hold longer than its lease.

## Capture and cleanup

```sh
python3 tools/qa/native.py record --run-dir evidence/native-qa/example-01 --name session.mkv --seconds 10
python3 tools/qa/native.py status --run-dir evidence/native-qa/example-01
python3 tools/qa/native.py record-stop --run-dir evidence/native-qa/example-01
python3 tools/qa/native.py stop --run-dir evidence/native-qa/example-01
```

Recording starts asynchronously, finishes at its requested duration, and receives an FFprobe/hash sidecar. Omit `record-stop` when allowing it to finish. FFmpeg captures the verified **window ID**, never the host root window. It records only `<unique_sink>.monitor`, encodes libx264 ultrafast/CRF18/yuv420p and FLAC, and writes a Matroska container. Geometry/unmap/ownership changes are failures. A60fps encoded stream can duplicate images; application frame telemetry is separate evidence. Live x11grab snapshots can capture presentation updates; prefer application `frame_post_draw` viewport captures for exact visual comparisons where available.

Each run has `profile/data`, `profile/config`, `profile/cache`, and `profile/state` via isolated XDG variables. Controlled runs also use a private runtime for game/compositor IPC, with an explicit Pulse connection to the original server and only the named game sink/monitor. `HOME` is never replaced. The named Pulse sink is not connected to host speakers, and no microphone is opened. Profile caches are excluded from Git; preserve intentional save/config evidence separately when needed.

`stop` first releases input, finalizes recording, terminates owned game/Xwayland/Weston process handles in that order, removes only the owned sink after validating its exact name+module ID, and deletes known private runtime credentials/sockets. Unknown runtime files are retained with a cleanup error, never recursively removed. Run evidence/profiles remain. Host audio defaults are compared, never forcibly restored over user changes. Do not call a run clean if `cleanup_errors` is nonempty.

If the supervisor itself is killed with SIGKILL, use the exact run's recovery command:

```sh
python3 tools/qa/native.py recover --run-dir evidence/native-qa/example-01
```

Recovery refuses a live supervisor, verifies `/proc` PID/start-time/process-group/session identities before signaling game/Xwayland/Weston/recorder PIDs, releases the private server's queried held keys where available, and validates the unique sink owner before removing it. It never kills by process name or broad process group. A recovery report preserves the original failure record. Inspect recovery errors; abrupt recovery is not equivalent to a finalized recording.

## Reproduce and inspect the diagnostic

```sh
python3 tools/qa/prove_fixture.py --run-dir evidence/native-qa/example-01
python3 tools/qa/analyze_fixture_media.py --run-dir evidence/native-qa/example-01
python3 tools/qa/prove_safety.py --run-dir evidence/native-qa/example-01
```

Run `prove_fixture.py` immediately after a fresh fixture launch. It performs native XTEST controls, reads **observed application events**, saves menu/movement/pause/final PNGs, and records10 seconds. It checks simultaneous W+D+Shift; captured relative deltas; changed position/camera; three accepted clicks; pause/menu rejection; resume; explicit release; lease expiry; and release on an invalid command. Its result is named `PASS_SCRIPTED_DIAGNOSTIC`, never “independent playthrough.”

The media analyzer requires1920×1080,600 encoded frames at60fps,48kHz stereo, independently identifiable440Hz-left/660Hz-right quiet tones, nonzero/unclipped signal, and three visual/audio pulses aligned within150ms. This tolerance is a **capture-diagnostic threshold**, not a product gun-feel requirement. The fixture's60ms generator buffer contributes latency. It extracts `fixture-stereo.wav` for an actual listening modality when one is available.

`prove_safety.py` runs after those checks. It compares a quiet interval, verifies compositor/XI2 policy, measures real application key releases during fault conditions, tests private-root blur, and **ends the run with SIGTERM to the verified owned supervisor during a ten-second hold**. It then checks cleanup and raw-source provenance. Run `native.py stop` yourself if not using that deliberate terminal test. Offline `python3 -m unittest discover -s tools/qa/tests -v` uses a fake X window and never counts as native proof.

Open the original-resolution PNGs and relevant original-resolution video frames. Record which were opened, what changed, exact commit/executable hash, operator independence, actual method, and remaining defects. Source/scene/hash and screenshot evidence may establish the input/render path; they do not establish subjective audio, continuous temporal experience, or game quality.

## Verified limits and corrections

The original `evidence/native-qa/IMPLEMENTER_REPORT.md` and dev01–04 artifacts predate the private-seat correction. Even dev04's passing input/media checks do not establish physical-seat isolation. Unrequested accepted inputs later reproduced across multiple operators' sessions; independent review failed that architecture. Correction evidence is retained separately in `evidence/native-seatfix/` and requires independent acceptance.

Correction development-01 proved that XI2 disabling detaches Xwayland devices into FloatingSlave state. Development-02 then disabled all four private proxies successfully but Xwayland 24.1.13 crashed on a native callback when the game mapped. That attempt is a retained failure, not a supported mode. The final approach does not disable devices: input is isolated at the compositor boundary. Separate headless feasibility probes also exposed intermittent stale X11 captures despite 60 FPS application telemetry; only runs with actual opened changed images and recording signal checks can establish capture success.

Observed old host-compositor behavior: with VSync enabled, an obscured rootful surface can throttle Godot to 1 FPS and delay application processing despite valid XTEST dispatch. The fixture uses explicit `--disable-vsync --max-fps 60`. An earlier suspicion that the core project's defaults overrode these CLI flags was withdrawn: its captured telemetry already showed 60 FPS before its Settings UI changed. Record actual settings/timing; do not turn environment workarounds into product performance claims.

Godot logs one XIM input-method warning on this minimal X server. Latin keyboard, modifiers, function keys, and captured mouse have worked; IME/text composition remains unverified. Existing `pactl -f json list modules` omits module index on this PipeWire version; cleanup uses the sink's reliable `owner_module` instead. The two initial owned null-sink leftovers were removed with recorded validated recovery and unchanged host defaults.

Root's actual audio capability probe of the captured Ogg returned `audio content omitted because you do not support audio input`. Therefore actual listening is unavailable in the current root runtime; no agent listening PASS is inferred. Continuous-video experiential review is also unverified. Native Windows and target discrete-GPU evidence remain separate open project limitations.
