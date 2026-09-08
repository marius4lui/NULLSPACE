# Status

## Android implementation — 2026-09-08

- Active branch feat/short-game, fast-forwarded to current checkout 71a53e8 before Android changes. main and other worktrees preserved. Solo, no agents.
- Implementing approved complete Android APK plan. Existing ten map entries reused; first-play duration/content and audio acceptance remain open.
- Added touch overlay/InputGate integration, additive preferences, mobile profiles, lifecycle handling and Android export/build script. ETC2 import correction verified. Offline preview APK built and v2/v3 signature verified; final Gradle export blocked on uncached dependencies. User's limited connection: downloads stopped; script now requires explicit --allow-downloads for Gradle.
- Automated 24 touch +258 core +89 existing scene checks and three clock schedules pass. Linux Mobile-renderer title/Start/touch-HUD screenshots inspected; not physical Android evidence. See evidence/android/initial/REPORT.md and tools/android/README.md for precise limits/template issues.
- adb currently lists no attached device. User-owned test phone needs connection for install/play/thermal acceptance; 0/2 Android final runs. No release publication yet.

## Difficulty Room 1 branch

- `feat/difficulty-room1` now offers Easy, Medium, Hard and Nightmare before Start, with Medium as the default. The fixed choice is stored in the existing checkpoint and survives death/restart.
- The same Room 1 varies Listener speed/awareness, existing fixture and sound response, and concrete objectives: one switch; two switches; three plus a safety latch; or three plus one marked local fuse.
- Automated actual-scene coverage passes 42/42 for all four modes through ending and death/restart. Existing room/player, pistol, Listener, door, escape and core suites pass (347 checks total), as do 30/60/120 logical clock probes. Linux and Windows exports reproduce successfully with Godot 4.7.2.
- Native exported-game evidence includes complete Easy and Medium endings after death/restart, the complete Hard latch/relay interaction, and Nightmare fuse pickup/readability. Full native Hard/Nightmare endings and listening remain open, so this branch is not release acceptance.

- Current milestone: Full small-map flow operated; observed defects and duration/pacing need work.
- Last known good commit: gameplay f30b31e; raw-beta source/tag v0.1 at83da390 now integrated on public main. Metadata-only beta rebuild passed native menu/Start/movement/pause smoke. Prior unarmed-export-02 completes both switches→exit with one hit and zero ammunition. Not final release acceptance.
- Verified completed systems: Same-scene Start/pickup/combat/doors/two switches/checkpoints/ending operated. Four native Continues pass without engine errors. Controller16, pistol20, Listener12, door15, objective26 and core258 +three clock probes pass. West-leaf fixture correction passes; actual west pursuit, death/restart and zero-ammo checkpoint-to-ending operated in door-detour-native-01.
- Current blockers: First exploration/pacing and audio listening unverified; successful known-route export only54.33 active seconds, NOT10–15 minute evidence. User play feedback requested; GPU previews closed. Direct scene tests wrote normal game save: isolated storage now added, all five suites pass and normal file hashes unchanged on rerun; prior overwritten state not recovered. Old Goal cannot be edited; repo contract governs.
- Current active agents: None; solo implementation integrated to main at user request. Old worktrees preserved; no new gameplay expansion implemented.
- Remaining acceptance failures: Meaningful10–15 minute first game, atmosphere/listening/balance, fresh-rebuilt native launch, armed post-change run and final full runs0/2. One post-change functional unarmed export success exists; not final release acceptance.
- Next integration point: User first-play feedback and armed export/rebuilt-native check when GPU is free. Correct observed gameplay/pacing defects in the same scene; no speculative expansion or padding.
