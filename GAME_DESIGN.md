# NULLSPACE short-game design

Current user scope2026-09-05: complete10–15minute first escape, roughly8–12connected spaces; no padded waiting or repeated tasks.

Quiet arrival shows dead exit and two-circuit indicator. Nested offices introduce movement, footsteps, flashlight and pistol pickup. Office switch and service/blackout switch are spatially separated and reachable in either order. Their physical interaction produces clear motion/sound/light feedback. Loops and doors offer evasion and return to the original exit after both switches. Short definite ending/credits; no boss, kill or third objective.

Planning spaces: arrival/reception, offset lobby, divided office, column room, supply recess, office switch room, service junction, blackout corridor, service switch room, return passage. Reuse original modules with varied dimensions/landmarks/sightlines. This count does not prove duration; actual first play decides.

Player tuning starts walk3.4/crouch1.8/sprint5.4m/s with stamina, responsive acceleration, safe crouch, modest camera motion, no bunny hopping. E interact, F light, R reload, left mouse fire, Escape pause. Flashlight has no batteries. Minimal prompts/ammo/injury feedback; no minimap/enemy bar.

One compact semi-auto pistol, initially12-round magazine, conserved ammo and coordinated slide/recoil/reload/muzzle/impact/shell/audio. Sparse logical ammo. Hits stagger or prompt retreat; no mandatory kill. Quiet movement, doors and broken sight permit zero-ammo escape. Tune supply with playtests.

Listener reuses original2.3m model/rig. Roam/investigate/chase/search/attack/stagger/retreat FSM; actual nav/LOS and small-map door-aware hearing. Evidence has location/time/confidence, decays, never permanent hidden tracking. Attacks require unobstructed reach and recoverable warning; first hit normally injures. Needed clips only, blended with existing idle/breathe/listen. Quiet arrival/recovery and sparse encounters; no constant chase/jumpscare director.

Meaningful-progress checkpoints store needed state and reset Listener fairly. Valid Continue, death/restart and complete settings/two profiles per contract. Whole-game duration, balance, tension and performance remain unverified until actual play.
