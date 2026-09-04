# NULLSPACE architecture

Research A–I incorporated; independent freeze audit corrections prepared. Required engine Godot4.7.2 stable, Forward+, typed modular GDScript and tunable Resources. No implementation exists yet. Delegated implementers own code/scenes/tests.

## Runtime ownership

One persistent game session and campaign scene with six sector scenes, stable room IDs and persistent room/portal topology. Keep all structural geometry loaded initially; streaming only after evidence justifies it. Shared graph provides architecture, acoustic paths and strategic routes; it must not leak hidden player information into creature decisions.

| Owner | Responsibility and authority |
|---|---|
| GameFlow / SaveSystem / CheckpointSystem | Menu/play/death/end transitions, versioned coherent snapshots, safe transactional save, controlled checkpoint spawn |
| PlayerController / PlayerHealth / InteractionSystem | Collision locomotion, camera input, injury, targeting interactables, input ownership |
| WeaponController / WeaponData / AmmoSystem | Exclusive action state, idempotent reload commit points, accepted ShotEvent and one ammo/hit resolution |
| SoundEventSystem / RoomAcoustics | Gameplay sound event with time/type/intensity/source, portal distance+door losses, uncertain evidence delivered to hearing |
| MonsterPerception / MonsterMemory | LOS/exposure/posture/motion and hearing observations; aged uncertainty/confidence, no omniscient transform access |
| MonsterPlanner / MonsterNavigation / MonsterCombat | Utility/HFSM goals from observations; path+door operation; collision-safe attack/stagger/retreat |
| ThreatDirector | Tension history, health/ammo/objective/death context, region/ambient/quiet influences; no secret target injection |
| DoorController / BreakerObjective / LevelState | Physical interaction, light/route/acoustic changes, objective and safe persistent state |
| SpatialAnomalySystem | Authored safe out-of-sight graph/geometry transactions with validation and rollback |
| LightingController / AudioDirector | Nearby fixture budgets, circuit state, occlusion, eight audio buses and spatial ambience |
| UIController / SettingsManager | Minimal HUD, complete menu/accessibility controls, persistent preferences and input gating |
| Telemetry / DebugTools | Recorded gameplay/performance/events/scenario traces, explicit build metadata; debug only overlays disabled in release |

## Event and observation boundaries

Player actions produce one canonical event per accepted action. ShotEvent carries weapon/origin/direction/hit results/action identity; presentation subscribes, cannot independently charge ammo or damage. SoundEvent contains position/intensity/type/time/room/source identity; propagation transforms it into uncertain observation rather than permanent tracking. Acoustic and navigation topology use one door-state authority. Observation-only creature planner inputs are enforceable through interfaces and tests. Director influence never adds exact player target coordinates.

Save snapshots include schema/build compatibility, objective/relay flags, relevant topology/circuit state, health, chamber/magazine/reserve, ownership, pickup consumption and safe checkpoint. Never serialize half-completed animation callbacks. Load reconstructs coherent committed gameplay state and invalidates stale action generations. Temporary visual effects and creature immediate attack state do not survive checkpoint; monster resets fairly.

## Rendering and navigation constraints

Use six sector LightmapGI volumes at most (engine supports eight simultaneous). Bake only invariant light; runtime-switchable circuits/blackout fixtures cannot leave baked emission. Dynamic direct lighting/shadows near player plus fixture emission at range. Start High budget24 relevant dynamic direct lights and4 shadowed including flashlight; benchmark alternatives before introducing AreaLight3D broadly. CPU static occlusion from simplified walls/slabs, spatially local batches. Closed-door occluder disabled when opening begins, restored only fully shut. Moving actors/anomaly geometry excluded from baked static occlusion.

Offline navigation bake from simplified source collision. Explicit controlled door/anomaly links; prevent automatic edge bridging bypasses. Openable closed doors remain tactical route actions, while locked/unavailable routes disable connectivity. Creature opens/passes only after clearance; nav links do not perform physical traversal. Path targets change only after meaningful goal/topology changes, not every frame. Movement/attack safety each physics tick, perception around10Hz, planning around5Hz as initial targets.

## Art/build separation

Repository runtime project will live in `game/`; editable authoring assets live outside its import tree under `art/source/`. Explicit original glTF/GLB/PBR/audio exports copied or staged into `game/assets/` by a documented delegated pipeline. No hidden Blender dependency during fresh game import. `tools/art/` houses deterministic versioned generators, bake/export profiles and manifests. Preserve generated sources and validate source-to-runtime hashes. Godot wrapper scenes own configuration around imported meshes, never mutate imported resources directly.

Original Blender masters in architecture/props/weapons/listener collections, meter units/applied positive scales/predictable floor origins. Consistent exported bone/action/socket names. Bake shader data to basecolor/normal/ORM; retain controls/modifier masters separately. AnimationTree presentation blends independently from gameplay action authority. Structural static collision simplified; hidden primitives allowed as collision only. Runtime shaders and build scripts are implementation and must be delegated.

## Initial engineering budgets

High target1080p60Hz, aim GPU<=14ms and CPU<=8ms separately, typical visible geometry<=1M triangles/worst<=2M, draw calls typical<=700/investigate>1200, GPU allocations initially<=2.5GiB including lightmaps<=384MiB. These are starting budgets, not performance claims. Pools cap impacts/casings/decals/particles/audio and retire distant/sleeping effects. Prewarm actual effects/materials in loading to reduce first-use pipeline hitch. Final Vulkan shader-baked exports require rendered GPU session; --headless does not bake shaders. Native Windows runtime validation remains separate from cross-export success.

## Verification architecture

Native QA uses isolated rootful Xwayland with private authority/local socket, verified game-only window capture and named Pulse null-sink monitor, without changing global defaults or capturing desktop/microphone. XTEST controls must demonstrably produce real captured mouse/keyboard behavior. Supervisor tracks owned resources and releases keys on failure. Viewport screenshots after frame_post_draw retain native resolution/frame/camera metadata. Passive telemetry records UTC/monotonic/simulation/frame, input provenance/focus/pause, all contract metrics and distinct CPU/GPU/frame costs. Hidden AI truth is post-run evidence, not live reviewer guidance. No audio-heard or continuous-video judgment is inferred from capture/metrics/attachments; actual modality remains an open verification requirement. Detailed method: evidence/research/G-H-audio-qa-research.md.

Creature memory decays evidence strength separately from normalized candidate probabilities. One event never renews/refines itself; no hidden-target distance bias. Intent includes evidence IDs/reason. Shared door state updates collision/sight/portal sound/navigation coherently. Positive-cost propagation prevents loops. Audio playback portal direction/attenuation and uncertain AI hearing are separate consumers. All8 contract buses explicit; user mix never changes gameplay hearing. Original48kHz stems/recipes and named voice budgets. Stereo amplitude panning is not HRTF.

Implement deterministic scenario entry points, telemetry and reproducible seeds for diagnostic runs, without shipping developer overlays. Automated tests cover logical invariants/AI evidence/action interruption/save/topology; actual native gameplay covers visuals/audio/gun feel/pacing and integration. Record build/hash/preset/device, scenario input, events and screenshots/video. Independent reviewer of a feature cannot be its implementer. Fresh clone build and final dual full runs happen after final gameplay-affecting commit, with no debug cheats counted as campaign success.
