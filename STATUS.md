# Status

Listener death task (feat/listener-death): implemented and tested in the existing
section. Guarded2.6s grab/local fallback, independent persisted blood/intensity,
reduced-motion override and existing death menu/reset. Core258 plus scheduling,
scene90, death175 and edge79 checks pass; rendered matrix/edge videos inspected.
Final Linux export11dcf11 has two successful fresh-start functional runs after
the last gameplay change (54.15/54.02s). Windows cross-export only; no heard-audio
or10–15min first-play claim. [Evidence and batch record](evidence/listener-death/REPORT.md).
Branch push/PR is the remaining delivery step at batch16/20; main is preserved.

The following records describe the raw-beta baseline before this scoped task;
their broader first-play, pacing and listening gaps remain open:

- Current milestone: Full small-map flow operated; observed defects and duration/pacing need work.
- Last known good commit: gameplay f30b31e; raw-beta source/tag v0.1 at83da390 now integrated on public main. Metadata-only beta rebuild passed native menu/Start/movement/pause smoke. Prior unarmed-export-02 completes both switches→exit with one hit and zero ammunition. Not final release acceptance.
- Verified completed systems: Same-scene Start/pickup/combat/doors/two switches/checkpoints/ending operated. Four native Continues pass without engine errors. Controller16, pistol20, Listener12, door15, objective26 and core258 +three clock probes pass. West-leaf fixture correction passes; actual west pursuit, death/restart and zero-ammo checkpoint-to-ending operated in door-detour-native-01.
- Current blockers: First exploration/pacing and audio listening unverified; successful known-route export only54.33 active seconds, NOT10–15 minute evidence. User play feedback requested; GPU previews closed. Direct scene tests wrote normal game save: isolated storage now added, all five suites pass and normal file hashes unchanged on rerun; prior overwritten state not recovered. Old Goal cannot be edited; repo contract governs.
- Current active agents: None; solo implementation integrated to main at user request. Old worktrees preserved; no new gameplay expansion implemented.
- Remaining acceptance failures: Meaningful10–15 minute first game, atmosphere/listening/balance, fresh-rebuilt native launch, armed post-change run and final full runs0/2. One post-change functional unarmed export success exists; not final release acceptance.
- Next integration point: User first-play feedback and armed export/rebuilt-native check when GPU is free. Correct observed gameplay/pacing defects in the same scene; no speculative expansion or padding.
