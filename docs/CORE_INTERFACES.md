# M2 core interfaces

This is a technical foundation, not a playable game or any product acceptance pass. Godot 4.7.2 stable, Forward+, typed GDScript. The boot screen is an explicitly temporary diagnostic that uses the engine default font; remove it from the production launch path when the actual UI/campaign is integrated. No gameplay, production assets, audio content or AI is implemented here.

## Ownership and scene integration

Autoload order is SettingsManager, SaveSystem, CheckpointSystem, InputGate, GameFlow, EventHub, Telemetry. Their global names differ from their `Null…` class names to avoid collisions. Numerical hypotheses live in `game/data/default_tuning.tres`; quality budgets in `game/data/quality/*.tres`.

| Interface | Intended consumer / contract |
|---|---|
| `GameFlow.begin_new_game()`, `continue_game()` | Title/death UI. Return `StorageResult`. Valid loads enter LOADING and pause the tree. New Game replaces the single checkpoint only after successful validation and staging. |
| `GameFlow.load_started(snapshot: Dictionary, generation: int)` | One campaign scene owner stages the complete snapshot, resolves/validates anchors, restores every participant, resets Listener fairly and invalidates animation/action callbacks. Acknowledge `complete_load(generation)` only after all consumers are ready. On failure use `fail_load(generation, detail)`. Stale generations are rejected. |
| `GameFlow.pause_game()`, `resume_game()`, `open_settings()`, `close_settings()`, `die()`, `end_campaign()`, `return_to_menu()` | Explicit state transitions. Settings returns to its caller (title or pause). Focus return never auto-resumes. `end_campaign` requires a committed ending snapshot. Completed campaigns cannot Continue. |
| `InputGate.movement_vector()`, `pressed(action)`, `accept_press(event, action)`, `look_delta(mouse_event)` | All gameplay input must pass through this gate. No raw `Input` polling in player/weapons. A two-process-frame capture barrier and release requirement prevent carried keys/clicks. Displacement-based mouse delta is radians, sensitivity/invert applied; never multiply it by delta. |
| `InputGate.generation`, `accepts_generation(generation)`, `invalidated(generation, reason)` | Capture the current generation when accepting a command. Pause/settings/menu/death/load/focus loss invalidate pending commands and presentation callbacks. Consumer cancels its own transient action state; gate does not implement reloads. |
| `CheckpointSystem.commit_snapshot(snapshot)` | Receives one complete state captured at a coherent committed boundary. Returns `StorageResult`; updates its in-memory copy only on successful persistence. Emits `checkpoint_committed`. |
| `CheckpointSystem.current_snapshot()` | Returns a deep copy of last committed/restored state. No mutable shared world state. `restore_requested(snapshot, generation)` feeds GameFlow. Use GameFlow for load initiation. |
| `SaveSystem.save_checkpoint`, `load_checkpoint`, `continue_available` | Storage layer. Does not set up a world, resolve IDs, choose fair physical anchors or resume simulation. |
| `SettingsManager.snapshot`, `get_value`, `apply_settings`, `reload_settings` | Full validated settings document. Writes before runtime apply; I/O/validation failures preserve active settings. Malformed saved preferences report failure and use defaults; a valid backup can recover. |
| `SettingsManager.settings_changed(values)`, `quality_changed(profile)` | Production cameras/motion/lighting/audio/UI subscribe, apply current snapshot on attach, and respect zero motion/flash reductions. `current_quality()` returns the shared read-only tuning Resource. |

PLAYING is the only unpaused state. Load completion while unfocused enters PAUSED, and focus return still requires explicit Resume. GameFlow, settings, telemetry and UI run with `PROCESS_MODE_ALWAYS`; player/world descendants should normally inherit pausable processing. Use signals to clear queued commands, not animation-completion callbacks as gameplay authority.

## Snapshot schema v1

All seven sections are mandatory, unknown fields are rejected, and numeric values are normalized to runtime integer/float types after JSON reading. No object deserialization. No half-completed reload/action/animation, temporary effect, live node reference or immediate monster attack state is saved.

| Section | Fields |
|---|---|
| `campaign_id` | Exactly `nullspace_campaign_v1`. |
| `session` | Stable `id`, finite nonnegative `elapsed_seconds`. |
| `checkpoint` | Stable `id`, `room_id`, separate `player_anchor` and `monster_anchor`, integer `reset_seed`. Anchors are names, not scene paths. |
| `player` | Positive living `health`, normalized `stamina`, `flashlight_enabled`, `equipped_weapon` (`pistol`, `shotgun`, or empty). |
| `inventory.weapons` | Both `pistol` and `shotgun`, each `{owned, chamber, magazine, reserve}`. Pistol magazine 0–12 plus chamber 0–1. Shotgun **magazine means tube**, 0–5 plus chamber 0–1. Unowned weapons cannot contain loaded ammo or be equipped; reserve may be carried before acquisition. |
| `progress` | `relays.{circulation,distribution,return_feed}`, `phase_breaker`, `exit_isolator`, `ending`, `neutralized_listener`. All booleans. Phase requires all relays; isolator requires phase; final flags require isolator. Red access and exit power derive from these committed flags rather than duplicate independent fields. |
| `world` | `doors` (stable IDs → `open`/`closed`/`locked`), `circuits` and `anomalies` (IDs → committed bool), unique `consumed_pickups` IDs, integer `topology_revision`. Door animation phases cannot be saved. |

Structural validation does not prove a named anchor exists, is collision-safe, is out of sight, or is sufficiently separated. The production campaign owner must validate those facts before acknowledging load. It must also validate level-specific topology/circuit consistency and capture all sections at the same action boundary. The empty initial world maps are intentional M2 data, not an implemented campaign.

Storage lives under `user://saves/checkpoint.json`, with `.backup`, `.tmp`, and `.backup.tmp`. The JSON envelope contains format/content versions, document kind, build ID, UTC timestamp, payload JSON text and its SHA-256. Size is bounded at 2 MiB. Validation and a readback precede same-directory rename replacement; a validated previous copy is preserved first. Corrupt primaries never overwrite good backups. Orphan temp files are ignored. Future versions are rejected without silently loading an older backup or overwriting future data. No automatic schema migration exists yet. SHA-256 detects accidental corruption; it is not an anti-tamper mechanism. Godot's flush/rename is used; physical power-loss durability and native Windows filesystem behavior are not yet validated.

`StorageResult` exposes `ok`, `code`, human-readable `message`, isolated `payload`, and `recovered`. Missing/corrupt/incompatible data must be shown to the player, never silently represented as current saved progress. Version comparison has no arbitrary upper ceiling: any unsupported nonnegative finite integral metadata remains incompatible rather than becoming eligible for old-backup fallback or overwrite.

## Settings and rendering

Persistent schema v1 contains `resolution:[width,height]`, `display_mode` (`windowed`/`fullscreen`), `vsync`, `quality` (`low`/`medium`/`high`/`ultra`), `master_volume`, `ambience_volume`, `effects_volume`, `mouse_sensitivity`, `invert_y`, `horizontal_fov`, `head_bob`, `camera_shake`, `subtitles`, `center_dot`, `reduced_flashes`.

Both `snapshot()` and container-valued `get_value()` results are detached deep copies. Changing a returned resolution array cannot bypass validation or mutate active preferences.

Default horizontal FOV is 88°. A Godot camera using KEEP_HEIGHT needs `SettingsSchema.vertical_fov(horizontal_fov, viewport_aspect)`; recalculate when aspect changes. InputGate applies screen-relative mouse displacement × sensitivity × configured radians/pixel, including invert Y. No gameplay camera exists in this milestone, so no camera, head-bob, shake, subtitle, dot or flash-effect application is claimed yet.

Window mode, window size, VSync, bus gain/mute, rendering resolution, viewport 3D scale and MSAA apply now where a native display exists. Requested resolution persists even if the native usable screen forces a smaller window. Fullscreen uses the desktop video mode and renders internally at the requested resolution; viewport scaling preserves aspect. Headless tests skip DisplayServer operations. Quality profile light/shadow/particle budgets and SSAO/fog are future owner responsibilities, not implemented rendering effects. No preset performance claim is made.

Exactly eight audio buses: Master, Ambience, Fluorescent, Environment, Player, Weapons, Monster, UI. Fluorescent feeds Ambience, which feeds Master; other buses feed Master. Ambience volume therefore affects ballast hum; effects volume applies to Environment/Player/Weapons/Monster/UI. User mix never affects gameplay sound-event intensity. Zero gain mutes explicitly. There is no production audio content yet.

## Events and telemetry

`ShotEvent` contains accepted action ID/generation, weapon ID, origin/direction, monotonic timestamp, physics tick, and typed `ShotHit[]` (target ID, surface ID, position, normal, pellet count). Only the authoritative weapon owner emits `EventHub.shot_accepted` after one ammo/hit commit. Presentation consumes it; presentation cannot independently charge ammo or damage a target. The M2 diagnostic click counter does not emit ShotEvent because no weapon action actually occurs.

`SoundEvent` carries ID, source/room IDs, type, true source position, intensity, timestamp and simulation time. `EventHub.submit_sound` dispatches only to a registered sound propagator and spatial-audio adapter. No raw-sound broadcast is exposed to AI. `PerceptionObservation` instead carries evidence/listener IDs, modality, estimated region/position/direction, incoming portal, uncertainty, confidence and observation time. No player node/reference/live transform exists in it. Perception, memory and planner consumers must preserve original observation time and cannot consult raw SoundEvent truth. Registration is single-owner; freed adapter Callables become invalid and can be replaced.

`EventHub.objective_committed(objective_id)` and `gameplay_metric(kind,values)` feed passive Telemetry. Metric types: damage, ammo_collected, ammo_remaining, sighting, chase_started/ended, search_started, false_investigation, encounter_started, error. JSONL logs under `user://telemetry` contain UTC/monotonic/simulation/frame times, focus/pause/state, declared input provenance, session ID and event values. Metrics cover play seconds, deaths, damage, shots, ammo, sightings, chase count/total/average completed duration, searches, false investigations, encounter intervals and objective times. Further production aggregation remains tunable. One-second samples currently record frame delta and CPU process/physics monitors. GPU time is explicitly unavailable, never conflated with CPU; crash capture requires external supervisor. Local I/O failure disables logging without controlling gameplay. No network telemetry.

`unverified_os_input` is the runtime input provenance default. The native harness records adaptive/manual/scripted OS input separately. Synthetic logical-test input and scripted routes are never independent experiential play.

## Running and exports

Import: `GODOT --headless --path game --editor --import --quit`.

Logical tests: `bash game/tests/core/run.sh /absolute/path/to/godot /absolute/path/to/log`. The wrapper creates a fresh isolated XDG profile, starts `res://tests/core/test_runner.tscn` with the actual autoload graph, and rejects any unexpected SCRIPT ERROR/engine ERROR even if Godot returns exit0. Each test also creates a separate temporary storage root. `--script` is intentionally not used. The wrapper requires `rg` for the error scan.

Native diagnostic: use the isolated `tools/qa/native.py` supervisor, never a shared player profile. Its per-run XDG environment places this project's `user://` under the run's profile. Ordinary keys/mouse/menu navigation test the real runtime. Commands and captures belong in evidence; this fixture cannot satisfy campaign, gun-feel, atmosphere, art or audio review gates.

Export preset names are `Linux x86_64` and `Windows x86_64`; paths are `build/linux/nullspace.x86_64` and `build/windows/NULLSPACE.exe`, embedded PCK, no signing, standard matching templates. Tests are excluded. The temporary diagnostic remains the boot scene until production integration; these are milestone exports, not release-ready artifacts. Native Windows execution is separate from cross-export success.

Primary API references used: [Godot DirAccess](https://docs.godotengine.org/en/stable/classes/class_diraccess.html), [Viewport](https://docs.godotengine.org/en/stable/classes/class_viewport.html), [Input](https://docs.godotengine.org/en/stable/classes/class_input.html). Frozen architecture/research documents remain authoritative.
