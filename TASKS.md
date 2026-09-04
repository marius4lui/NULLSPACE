# Task ledger

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
