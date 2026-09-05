# Room 1 difficulty evidence

Scope: `feat/difficulty-room1`, exported with Godot 4.7.2. Native sessions used the isolated inputless Weston/Xwayland harness and XTEST input. They do not establish heard audio or subjective feel.

## Automated actual-scene checks

- Difficulty suite: 42/42. Each mode starts the real Room 1 scene, persists its selection, applies Listener/light/atmosphere values, exposes its exact task objects, reaches its valid exit state, dies, restores a solvable checkpoint and commits an ending.
- Existing suites: room/player 16/16, pistol 20/20, Listener 12/12, doors 15/15, escape 26/26 and core 258/258.
- Shared-clock logical probes pass at requested 30, 60 and 120 render schedules. These are not native FPS claims.
- Linux and Windows release exports completed. Final hashes before commit: Linux `3bc6b480897358699853a6a8df0658c99c7a01cdbc474926e7691078e5cd7df9`; Windows `dcc1b70b764fc0a1e25378aa3ceb363327b8e21752393cb8ef8f041a478ba4e5`.

## Native exported-game checks

- `native-easy-01`: retained failed run that exposed the old schema rejecting Easy's legitimate one-switch ending. The defect was corrected and covered.
- `native-easy-03`: Easy selected; brighter Room 1, battery-free flashlight, office door/cabinet/switch, 75% Listener chase speed, death, office checkpoint restart, return and `escape_complete`/`ENDING` at 67.67 simulation seconds.
- `native-medium-08`: retained partial Medium run that reached both objective routes but was caught before activating Service B.
- `native-medium-final-01`: Medium selected in the final Linux export; Service B activated at 28.75 seconds and Office A at 71.72 seconds. A death at 73.63 seconds followed by an Office checkpoint restore retained Medium and both relays, and the returned exit produced `escape_complete`/`ENDING` at 185.12 simulation seconds. The ending image, stopped-session manifest and full telemetry are retained.
- `native-hard-01`: Hard selected; darker 0.82 fixture multiplier and 1.15 Listener multiplier applied. Emergency C safety latch, cabinet and switch completed at 11.18 simulation seconds.
- `native-hard-final-02`: final export retained Hard through three death/checkpoint cycles and again completed Emergency C's latch, cabinet and relay at 55.27 simulation seconds. The adaptive controller then failed to clear the Service door before another death, so no full Hard ending is claimed.
- `native-nightmare-01`: Nightmare selected; 0.68 fixture multiplier and 1.28 Listener multiplier applied. Service and bypass doors opened, the marked fuse was visibly present and then disappeared on pickup. This run found and motivated correction of the stale post-pickup pause hint.
- `native-nightmare-02`: rebuilt Linux export emitted `fuse_collected` after native pickup. Its still-stale displayed objective exposed the missing menu refresh; the subsequent correction is covered by the 42-check actual-scene suite and final rebuilt hashes above, not claimed as another native visual pass.

## Limits

Easy and Medium have full native start-to-ending runs on the final feature behavior, each including death/checkpoint recovery. Hard and Nightmare finish through the actual-scene automated test but not through full native input runs; the final Hard attempt reconfirmed its unique interaction and persistence but not its ending. Audio streams and configured intensity were exercised, but no listening claim is made. Native Windows validation was unavailable. The PR remains draft while the Hard/Nightmare native endings are open.
