# Task ledger

## ACTIVE OVERRIDE — integrated playable section, 2026-09-05

User-authorized STRATEGY_CHANGE_2026-09-05.md supersedes the old milestone/interface queue below. Preserve its history, not its blocking order. Immediate coherent task A: merge existing room/core in an isolated working candidate and implement a concrete Player + section scene for movement, collision, flashlight, interaction and pause. Independent reviewer/integrator reviews actual same-scene operation as one block before Main promotion. B adds pistol; C simple fair Listener; D relay/exit/death/restart; E laptop play and targeted fixes. No further standalone preview/website/framework work. Old whole-M2/room-perfect micro-handoffs and cloned-profile infrastructure are deferred unless a reproduced defect blocks A. Two active workers normally suffice; all implementation Astra/max.

## Research before production

| ID | Assignment | Status |
|---|---|---|
| A | Backrooms visual/lore/original architectural language | complete: evidence/research/A-C-design-research.md |
| B | Survival horror design and pacing | complete: evidence/research/A-C-design-research.md |
| C | FPS game feel and weapon/controller validation | complete: evidence/research/A-C-design-research.md |
| D | Predator/stalker AI, evidence, acoustics, fairness | complete: evidence/research/D-F-technical-research.md |
| E | Exact Godot 4.7.2 availability/render/navigation/performance | complete: evidence/research/D-F-technical-research.md |
| F | Exact Blender 5.2 LTS and procedural production asset pipeline | complete: evidence/research/D-F-technical-research.md |
| G | Original audio/horror/spatial acoustics | complete: evidence/research/G-H-audio-qa-research.md |
| H | Autonomous actual-play/visual/audio QA methodology | complete: evidence/research/G-H-audio-qa-research.md |
| I | Originality/provenance/legal/license research | complete: evidence/research/I-license-originality-research.md |

## Production sequence

M0 environment/toolchain; M1 research/freeze; M2 skeleton; M3 controller; M4 production room; M5 weapons; M6 perception/navigation; M7 full AI; M8 intentional full greybox; M9 objectives; M10 environment art; M11 creature rig/animation; M12 audio; M13 light/VFX; M14 UI/settings/save; M15 full playthrough; M16 gameplay tuning; M17 horror tuning; M18 visual polish; M19 optimize; M20 independent QA; M21 release candidate; M22 final dual validation. Checkpoints, never stopping conditions.

Root assigns bounded branches/worktrees and file ownership before implementation. Dedicated integration role owns merges. Every failed review yields an issue and correction task. No production acceptance yet.

## Active implementation contracts

| Task / agent | Branch and worktree suffix | Exclusive ownership | Local acceptance |
|---|---|---|---|
| M0 / bootstrap_m0 | agent/toolchain / toolchain | tools/bootstrap, docs/TOOLCHAIN, bootstrap evidence, shared host tool install | Pinned verified Godot4.7.2+Blender5.2.1+templates, idempotent setup, actual diagnostic imports/Blender export/Linux run/Windows cross-export, native RADV smoke |
| M2 / core_m2 | agent/project-skeleton / project-skeleton | game/project.godot, core, data, scenes/bootstrap, tests/core, export presets, audio bus layout, docs/CORE_INTERFACES | Typed decoupled flow/settings/save/checkpoint/telemetry foundations, corruption+roundtrip checks, actual temporary menu/settings/save interaction and opened captures |
| Native QA / qa_native | agent/native-qa / native-qa | tools/qa, docs/NATIVE_QA, fixture+evidence | Isolated game-only Xwayland/Pulse sink, real mouse/keyboard input,10s60fps stereo capture, full-res inspection/sync/signals, owned-resource cleanup |
| M4 / environment_m4 | agent/environment-art / environment-art | tools/art/environment, source architecture+environment textures, art/exported/environment, game/assets/environment, game/environment, standalone preview | Original editable Blender/PBR modules and credible production room, actual Godot close/medium full-resolution inspection and corrections, provenance/reimport/stats/frame evidence |

All implementation worktrees under /home/marius/Projekte/Dev/NULLSPACE-worktrees. Shared tool binaries are /home/marius/.local/share/nullspace/toolchains/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 and blender-5.2.1/blender (only usable after bootstrap confirms). Each agent commits its own files; root never implements. Reserve next free slot for independent review/integration rather than blindly merging. Native QA and M0 fixtures are explicitly diagnostic, not production/final quality evidence.

## Current corrections and next bounded assignments

Priority correction QA-003: qa_native owns agent/qa-native-seatfix in native-seatfix worktree, based76a9b64; original native branch frozen. Repeated unsolicited accepted input blocks controlled evidence. Final mechanism uses private inputless compositor plus XTEST with exact ownership/cleanup and repeated proof; no host device mutation. bootstrap_m0 independently audits/rereviews. M0 tipb647a1e is independently reviewed by core_m2, partial report2dbdd1a; final native check pending.

Current dependency work: direct XI2 physical-slave disable caused an evidenced Xwayland24.1.13 crash. Bounded inputless Weston feasibility probe completed atd258166 in agent/native-backend-probe; actual hardware/private input/temporal sample demonstrated, snapshot reliability explicitly not accepted. QA-005 corrected-source candidateec4194a reads fresh owned Composite pixmaps; exact proofs/review pending. bootstrap_m0 independently reviews native and audits immutable core storage. M0 review ownership2dbdd1a transferred from core_m2 to qa_native for final independent fresh-export native operation after GPU handoff; neither reviewer implemented M0.

M2 source68ce558 retains80 independently clean guarded checks. Core owner now implements the bounded shared clock/restore prerequisite specified in docs/NEXT_PRODUCTION_ACCEPTANCE.md after its read-only review found four integration omissions. Ownership remains core/time/persistence contracts, GameFlow/Telemetry/event epochs/autoload/docs/tests/evidence only; no player/AI/campaign implementation. Preserve old evidence, create a new exact candidate and repeat import/tests/exports/native before independent review. Save schema remains v1; participant-specific anchor context prevents hidden player-coordinate leakage.

Independent art work during native blocker: environment_m4 must first freeze corrected M4 with explicit pending native/performance acceptance, then owns agent/monster-art worktree for bounded M11A original Listener mesh/UV/material/rig and idle/breathing/listen clips. Ownership `tools/art/listener`, corresponding source Blender/textures/listener, exported/listener and game/assets/listener; standalone preview only, no core/AI/game project edits. All17clips and independent native visual/deformation review remain required for M11; three clips/source render never complete it. M4 native corrections regain priority when harness is safe.

1. Separate adversarial reviews use retained workers after new-worker creation was refused: qa_native finishes M0 in transferred agent/review-toolchain; bootstrap_m0 reviews native in agent/review-native and bounded core storage in agent/review-core-storage. Neither reviews its own feature. Native continued FAIL ef5fde7 and storage FAIL3815bdd require exact corrective rereviews. Inspect exact sources/evidence, reproduce and open full-resolution captures. No self-grading or product/auditory scores.
2. Dedicated integration agent: sequentially merge only reviewer-accepted branches onto current main; after each merge perform relevant build/logical regression/native launch and inspect artifacts. Preserve root governance changes and frozen hashes. Stop on a failing merge; do not stack unverified changes.
3. M3 player controller after accepted M2: own `game/player/`, controller Resources/scenes and targeted isolated test level; implement grounded collision/crouch/stamina/camera/flashlight/interaction contracts against InputGate. Real native control comparisons, pause/focus safety and observer review; do not own core or production weapon files.
4. M6 perception/acoustics/navigation after accepted M2: own `game/ai/`, `game/world/room_graph/`, `game/world/doors/` and dedicated scenarios; prove observation-only evidence, portal attenuation/door actions, LOS loss/search decay and hidden-route invariance before full monster pacing. Diagnostic art remains out of production paths.
5. M5 original weapon pipeline follows stable controller/event/socket contracts. M11A original Listener source work is already explicitly assigned above; remaining clips/runtime integration still pending. No unscheduled features.

Native follow-up: independent M0 normal Escape exposed QA-007 after the bounded bb6fb09 explicit-stop/signal/capture PASS. qa_native owns new agent/qa-native-exit froma98fede for natural owned-window/process-exit lifecycle only, with tests/docs/evidence. No blanket BadWindow ignore or foreign-input weakening; require actual naturalexit0 and independent bootstrap review. Preserve M0 native-final-01 failure. M4 proceeds with validated explicitstop; M0 acceptance/integration wait correction. Cold-start native settings QA-006 remains explicit later coverage, not hidden profile reuse.

Current exact candidates, 2026-09-05: core clock70d2aae independently failed two reentrant/sentinel edges; owner correction891344e independently passed da1e1f4 (256 guards,45 adversarial conditions,three schedules), evidence tip7923b80. Whole-M2 native review still required. QA007 sourcef34e03e is in self-proof before bootstrap review. M4 evidence9f438b2 preserves actual472df44 room inspection and warm GPU/effect isolation; owner now corrects explicit3D VRAM/mipmap/color-versus-data imports, preserving texture UIDs/normal convention, then separately addresses diagnostic recapture. Native before/after and independent visual/performance review remain required. Preserve externally authored README/image commit8de0eb8 during integration; no new publishing action is assigned.

Root level-design handoffcdee4da adds `docs/LEVEL_PRODUCTION_BRIEF.md`, elaborating56 named spaces, purposes and proposed ordinary/gated adjacencies without implementing geometry or revising the frozen design. qa_native independently audits it during the GPU wait in new agent/review-level-brief, owning only review evidence. No level implementation or quality acceptance from graph checks. Priority returns to independent M0 after corrected harness acceptance.

Latest accepted bounded reviews: QA007 exactfb3a09d PASS2f10706, root193hashes/source/current-image corroboration and22offlinechecks; M0 independent final02 now running. Corrected level brief092859e PASSd2da321 after original2358157FAIL. Core self-native actual33screens/error-path/focus/checkpoint checks complete, packaging; independent whole-M2 now assigned bootstrap in agent/review-core-native, evidence-only ownership plus reviewed diagnostic helpers. Explicit cloned-private-profile same-PID exec check approved with source/destination hash and actual executable identity; no live-profile race or host data. M4 importse01fdb0 plus standalone previewe70fec5 passed50 headless diagnostic checks, actual same-pose/native review remains pending. Core prepares M3 interface plan read-only until accepted integrated foundation.
