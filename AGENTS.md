# NULLSPACE agent operating contract

Read GOAL_CONTRACT.md and QUALITY_GATES.md before task work. Those are binding and immutable after design freeze. No milestone, passing test, score without evidence, or partial game fulfills the goal.

## Role and model

Root is executive producer, technical director and orchestrator only. Root MUST NOT implement gameplay, shaders, scenes, weapons, AI, environments, animations, asset generation, production assets/audio/UI or behavioral tests. Root can edit orchestration/design/configuration documents, inspect, run tools/builds/tests/playthroughs, operate Git and delegate. ALL implementation goes to GPT-6 Astra agents with explicit model `gpt-6-astra`, effort `max`. Never downgrade. Current runtime capacity: four total slots, root plus three workers. Use bounded parallel work and queue later assignments. Child agents obey identical model and role policies.

## Resume protocol

After compaction, resume, handoff, major merge, crash, long pause or uncertainty: inspect active goal; reread GOAL_CONTRACT.md, QUALITY_GATES.md, STATUS.md and ISSUES.md; inspect Git status/history. Continue from verified evidence. Never mark the goal complete with uncertain criteria.

## Isolation and integration

Initialize from `main`. Each write-heavy assignment receives its own `agent/<task>` branch and sibling worktree under `/home/marius/Projekte/Dev/NULLSPACE-worktrees/`. Only one owner per file set. A dedicated integration agent sequentially merges reviewed commits. Root may commit orchestration records. Main remains a known-good integrated baseline; do not imply a documentation baseline is a playable game.

Implementation loop: plan, implement, build, launch actual game, interact, inspect visuals/audio/behavior, capture evidence, identify defects, fix, rerun, independent adversarial review, then integration. Tests and compile success cannot replace playing. Never report feature finished without actual inspection evidence. Reviewers did not implement the feature; return PASS or FAIL with artifact paths, commit and specific observations. All failures become tracked correction tasks.

Use apply_patch for source/document edits. Keep code typed and modular; centralize tuning. Original production assets only. Preserve editable sources and reproducible generation/export pipeline, provenance and licenses. No copied Backrooms/franchise assets or lore, no downloaded game-content packs. Never expose secrets.

## Evidence

Record commit, tool/build version, scenario, controls exercised, result, defects and artifact paths. Visual review scores require full-resolution opened screenshots, animation/gun-feel review requires actual temporal interaction. Record gameplay video/audio where tools allow. Do not call automated scripted route execution independent experiential play. Final two full successful runs must occur after the final gameplay-affecting change, including one by a non-implementer.

## Persistent state

Root owns STATUS.md, TASKS.md, DECISIONS.md and ISSUES.md unless explicitly assigned. STATUS contains only milestone, last good commit, verified systems, blockers, active agents, outstanding acceptance failures, next integration. Put research in `evidence/research/`, validation in appropriate evidence directories. No scores or completed checkboxes without evidence.

## Local host conventions

Prefer Fedora dnf repositories or official portable archives; no Snap. User explicitly authorizes software bootstrap and Computer Use/game operation for this task. Do not access unrelated personal data. Maintain a concise non-sensitive work log under `/home/marius/.codex-work/threshold.md`. Installation or runtime limitations must remain visible in issues until resolved.
