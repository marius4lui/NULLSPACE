# Decisions

## D001 — Goal and authority, 2026-09-04

THRESHOLD is a persisted active goal; complete original prompt archived verbatim in GOAL_CONTRACT.md. Root orchestrates only. No acceptance criterion has been weakened. Design remains pre-freeze pending A–I research.

## D002 — Model and capacity, 2026-09-04

Runtime tool contract supports four concurrent agents including root. Run at most three worker agents and queue waves, instead of inventing extra capacity. Use explicit Astra/max spawn overrides. Official configuration reference supports agents.default_subagent_model, agents.default_subagent_reasoning_effort and agents.max_concurrent_threads_per_session (excluding primary). Project configuration sets three workers. Source: https://learn.chatgpt.com/docs/config-file/config-reference . Astra official model page advertises max: https://developers.openai.com/api/docs/models/gpt-6-astra . Local global config was Astra/low; current root turn metadata is Astra/ultra. Project defaults cannot be claimed to retroactively change an active turn. Track this distinction honestly.

## D003 — Hardware evidence, 2026-09-04

Fedora 44, x86-64, Ryzen 5 7535HS six cores/twelve threads, 30 GiB RAM, 659 GiB free. Vulkan RADV exposes Radeon 660M with Mesa 26.1.8; PCI labels Rembrandt 680M. Use runtime device identity in benchmarks. This is not RTX2060/RX6600-class discrete hardware. Target hardware verification remains open.

## D004 — Research originality watch, 2026-09-04

Research A reports current Wikidot Level 0 title overlaps working title THRESHOLD and includes blackouts/red rooms. Preserve user concept/title but do not copy that page's text, imagery, named lore rules or entity designs. Independent original architecture, assets and mechanics; license researcher to assess provenance needs.
