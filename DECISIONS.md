# Decisions

## D008 — Resumed runtime and usage revalidation

Previous goal turn made concrete progress: research/design/contract freeze and isolated implementation worktrees. Initial toolchain/project-skeleton workers then terminated with account usage-limit errors; no implementation files or installed binaries existed at resumed inspection. No live worker/process handle remained. Fresh usage tool now reports0% used and no reached-limit flag, so retry normal Astra/max assignments; no reset credit redeemed or credits purchased. Current runtime explicitly advertises5 total slots; configure4 spawned workers. Earlier D007 inference that root counted inside config was unproven: completed threads remained in roster and runtime config may not change live. Supersede that interpretation with current documented4-worker/5-total capacity, preserving error history.

## D007 — Runtime concurrency correction, 2026-09-04

Official reference described max_concurrent_threads_per_session as excluding primary, so initial value3 intended root+3. Actual runtime twice rejected a third worker at value3 while root+2 workers ran. Runtime tool explicitly advertises4 total slots. Set supported value4 to match that actual enforced total and probe third-worker launch. Do not exceed4 total or launch nested untracked sessions. This corrects config to observed runtime behavior, not invented concurrency.

## D006 — Design freeze, 2026-09-04

All9 independent research assignments complete and archived. Independent design_contract_audit initially failed5 documentation/specification omissions, all corrected; rereview PASS at c737443110d558ff4863b9ec202368bbe83f88b1. Freeze GOAL_CONTRACT.md and QUALITY_GATES.md without lowered criteria, and freeze GAME_DESIGN/ART_DIRECTION creative scope. Numeric tuning remains empirical. Production begins only now, delegated to isolated Astra/max workers. Actual game/release gates remain unpassed. No high-level concept reopening absent evidenced unavoidable contradiction.

## D005 — User-named NULLSPACE, 2026-09-04

User explicitly directed “nenne das game NULLSPACE”. Adopt NULLSPACE for the game, production UI, builds and current documentation. THRESHOLD is only original working-title history; retain original archived prompt verbatim with this amendment. No other scope or quality criterion changes. Legal research will record known title overlap honestly, without silently substituting another name or blocking private production.

## D001 — Goal and authority, 2026-09-04

THRESHOLD is a persisted active goal; complete original prompt archived verbatim in GOAL_CONTRACT.md. Root orchestrates only. No acceptance criterion has been weakened. Design remains pre-freeze pending A–I research.

## D002 — Model and capacity, 2026-09-04

Runtime tool contract supports four concurrent agents including root. Run at most three worker agents and queue waves, instead of inventing extra capacity. Use explicit Astra/max spawn overrides. Official configuration reference supports agents.default_subagent_model, agents.default_subagent_reasoning_effort and agents.max_concurrent_threads_per_session (excluding primary). Project configuration sets three workers. Source: https://learn.chatgpt.com/docs/config-file/config-reference . Astra official model page advertises max: https://developers.openai.com/api/docs/models/gpt-6-astra . Local global config was Astra/low; current root turn metadata is Astra/ultra. Project defaults cannot be claimed to retroactively change an active turn. Track this distinction honestly.

## D003 — Hardware evidence, 2026-09-04

Fedora 44, x86-64, Ryzen 5 7535HS six cores/twelve threads, 30 GiB RAM, 659 GiB free. Vulkan RADV exposes Radeon 660M with Mesa 26.1.8; PCI labels Rembrandt 680M. Use runtime device identity in benchmarks. This is not RTX2060/RX6600-class discrete hardware. Target hardware verification remains open.

## D004 — Research originality watch, 2026-09-04

Research A reports current Wikidot Level 0 title overlaps working title THRESHOLD and includes blackouts/red rooms. Preserve user concept/title but do not copy that page's text, imagery, named lore rules or entity designs. Independent original architecture, assets and mechanics; license researcher to assess provenance needs.
