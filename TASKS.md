# Task ledger

Solo feat/short-game, current GOAL_CONTRACT.md.

| Delivery | Playable result | Reuse/missing work and check |
|---|---|---|
| Integrated core — active | Walk/light/interact/pause; pistol pickup/fire/reload; Listener/door encounter and evasion. | Reuse core/room/Player/Listener. Implement coordinator/pistol/FSM/doors. Build/operate/inspect, targeted collision/ammo/fairness checks. |
| Complete escape | Two switches, connected8–12spaces, return/ending/credits, death/checkpoint/Continue. | Extend same scene, existing save binding. Check both orders, zero-ammo escape and complete flow. |
| Atmosphere/polish | Meaningful10–15minute run, coherent light/sound, responsive laptop play/settings. | Original materials/clips, actual observed fixes, two profiles. Record duration/frame times, honest auditory limits/user assistance. |
| Tested export | Reproducible tested Linux release, Windows cross-export if possible. | Fresh checkout, actual export and two final full successful runs after last gameplay change, instructions/evidence. |

Completed intermediate block: original room + Player + concrete coordinator. Movement/collision/crouch/flashlight/local light switch/pause and checkpoint restore operated in the Linux build. See evidence/section/solo-a/; not a complete game.

Immediate block: one original pistol in that same scene. Afterwards the player can find/pick it up, fire one shot per press, reload, run out of ammunition and see/hear shot/impact feedback. Reuse InputGate, SimulationClock, EventHub, tested storage and original room. Missing: pistol asset, concrete weapon state, pickup, effects/audio and small save binding. Check actual controls, ammo conservation, pause/reload interruption, walls, save/restore and visual output; no new weapon framework.
