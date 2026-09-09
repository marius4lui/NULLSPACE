# NULLSPACE acceptance gates

Android amendment (user-approved 2026-09-08) takes precedence over Linux-first release: signed ARM64 APK/API31+, all-touch completion, safe-area UI, Back/background/lock/relaunch, same-key upgrade preserving saves/settings, and real-device listening. Standard profile targets 60 FPS with active-game p95 ≤20ms and no recurrent >100ms hitches over a ≥30-minute thermal run. Record exact device/OS/settings. Two successful release-APK runs after the last gameplay change, including zero-ammo escape; unbiased first play must establish 10–15 minutes. No connected device means these gates remain open. Desktop regression is retained, not Android acceptance. Signing keys/passwords must never enter evidence/Git.

Current GOAL_CONTRACT.md replaces the old gates on2026-09-05. No numeric scores or independent-agent reviews. Unverified means open.

| Gate | Required evidence |
|---|---|
| Complete game | Start/explore/pistol/Listener encounter or evasion/two switches/return/ending+credits; death/restart works. |
| Duration | First successful exploration about10–15minutes, recorded, no padding. |
| Controls/combat | Actual look/move/collision/crouch/flashlight/pause and pickup/fire/reload/empty/hit checks; conserved ammo. |
| Fair AI/doors | Walls/doors block vision/attacks; old sound position investigated after quiet relocation; finite search; nav/doors/stagger and zero-ammo escape. |
| Objectives/save | Both switch orders work, exit needs both; checkpoint restores switches/pickups/player/ammo safely; valid Continue/death/restart; no save damage. |
| Presentation/settings | Inspect original rooms/creature/weapon/light/UI, coherent spatial sound/blackout; settings persist; two usable profiles and reduced motion/flashes. |
| Laptop | Actual hardware/resolution/profile/FPS/frame times in exploration/encounter; stable usable response, no known serious defect. |
| Export | Fresh-checkout reproducible Linux release launched/tested. Windows cross-export if possible with native limitation explicit. Instructions/licenses/screens/evidence match. |
| Final runs | Two complete successful exported-game runs AFTER last gameplay change, source/hash/duration/actions/outcome. Same agent/user allowed; automation labelled. |

Tests support actual operation, not replace it. Missing listening/platform checks stay explicit; no manufactured impressions. Existing useful tests remain; failing tests are not disabled.

P0: crash/corruption/hard lock/cannot finish. P1: broken major system, unfair access, objective/checkpoint softlock, severe performance. P2 noticeable quality defect; P3 minor polish. No known P0/P1 at completion.
