# NULLSPACE game design

FROZEN creative specification, 2026-09-04; research A–I incorporated and independent design-readiness audit PASS at c737443. Complete binding scope: GOAL_CONTRACT.md. This direction never replaces acceptance criteria. Numerical tuning remains adjustable through recorded playtests. Authoritative user-selected game/release name: NULLSPACE.

## Experience and campaign

The player wakes on carpet in an empty commercial building. A dead exit and its service diagram establish three isolated supply relays. Restore them, reach the anomalous phase breaker, then return through changed but learnable architecture to the live exit. Premise communicated through physical signs, sparse original maintenance annotations and machinery; no dialogue/exposition dependency. Armed agency, imperfect information and architectural acoustics underpin survival.

Build 56 distinct authored room spaces. Each has a documented purpose: route choice, landmark, sightline, acoustic contrast, objective, resource risk/reward, spatial revelation or recovery. Room count alone is not quality. No timer-based padding, arbitrary waiting, objective-key glow or minimap. First successful playtime target remains 35–60 minutes, initially tune toward 48; actual play determines route/rhythm revisions.

| Sector | Spaces | Identity and route function | Initial pacing hypothesis |
|---|---:|---|---|
| A Arrival | 8 | Empty reception suite, dead exit/circuit diagram, broad quiet orientation, two stable reference landmarks | 0–5 min, no attack |
| B Grid | 10 | Offset partitions/boxed columns, one carpet repair landmark, relay 1 and useful return loop | 5–12 min |
| C Open Plan | 11 | Broad diagonals, partial-height partitions, isolated columns, distant observation opportunity, relay 2 | 12–22 min |
| D Service | 10 | Lower utility circulation, painted doors, pipes/cabinets, shotgun, tactical door/acoustic decisions, relay 3 | 22–32 min |
| E Blackout | 9 | Failed familiar fixtures and hum withdrawal, learned floor/recess cues, critical flashlight and stereo movement cues | 32–40 min |
| F Red Threshold | 8 | Red oxide frames/faded brown-red maintenance paint, impossible secondary connections, main phase breaker | 40–44 min |
| Return | Existing spaces | Relay-enabled shortcuts and route memory pay off; final pressure followed by clear exit resolution | 44–49 min |

All six belong to one physically continuous commercial shell. Include every mandatory structural variant from the contract; identify each in the level manifest. Author loops and short cuts before decorative art. At least two stable architectural landmarks per sector. Sparse useful props; most rooms empty. No repetitive square-room procedural maze. Three relays each visibly switch a circuit, change machinery/acoustics, alter usable routes, change threat context and save progress. Physical panel opening and switch manipulation remain interruptible; no unavoidable interaction death.

## Player and controls

### Relay state transitions

Each relay is a physical panel: E opens the cabinet, contextual E resets its lever/contact; machinery and visible circuit indicator confirm. No consumable key/fuse hunt. Interactions remain interruptible. Stable status names match the Arrival circuit diagram.

| Relay | Power change | Route change | Threat context and save |
|---|---|---|---|
| B Circulation | Restores selected Grid/Arrival corridor fixtures | Opens Grid-to-Arrival return shutter | Real reset sound can be heard; enables broad authored roaming out of initial dormancy, no secret location; checkpoint |
| C Distribution | Restores Open Plan perimeter and Service approach lighting | Opens lateral Open Plan-to-Service service passage | Longer lit exposure changes real vision; enables distant observation opportunities on authored roam routes; checkpoint |
| D Return Feed | Restores Service return/circuit infrastructure; Blackout remains physically failed | Opens Service-to-Blackout return route | Machinery changes actual sound masking/propagation context; broad authored patrol opportunity changes, no target injection; checkpoint |

Red Threshold access remains physically locked until ALL THREE relay flags are committed. The third completion energizes its access latch regardless of relay order, with clear panel/objective feedback. Main phase breaker in F then powers the Arrival exit and final threshold ground frame. Gate/relay/phase state is saved atomically; no early F bypass or late softlock. Three relay changes are tangible and separately verified.

Grounded 3.4m/s walk, 1.8 crouch, 5.4 sprint; initial acceleration28 and braking40m/s², tuned for responsiveness. No jump unless required by authored traversal; plan level without jumping. Limited stamina; immediate interaction, doors, flashlight and weapons. WASD move, mouse look, left fire, R reload, 1/2 weapon selection, Shift sprint, Ctrl crouch, F flashlight, E interact, Esc pause. Context prompt includes action and target. Configurable FOV/sensitivity/invert, minimal camera motion with full reductions and accessible flashes. Default 88-degree horizontal equivalent; convert explicitly to engine camera convention.

Flashlight has focused beam plus soft spill, no battery mechanic initially. It slightly modifies visual exposure; no stun. First serious hit at full health injures and disorients, leaves a recovery/escape chance; no instant-kill chase. HUD is restrained ammo, tiny interaction prompt, subtle injury/stamina only when needed and optional center dot. Objective text appears on update; circuit state is legible physically at panels.

## Weapons and resource policy

Compact semi-auto pistol uses 12-round magazine plus separate chamber; HUD shows total loaded and reserve with an unambiguous maximum13 when tactically topped up. Pump shotgun uses five-shell tube plus one chamber maximum6. All contract mechanics/animations/audio/VFX/hit reactions required. Pistol tactical/empty reloads differ, slide locks after final discharge. Shotgun inserts individual shells and can interrupt reload safely. Idempotent ammo commit points prevent duplication/loss. Gunfire is instantaneous on accepted action resolution; reload/fire/equip/sprint never create stale callbacks or accidental menu-resume shots. No ADS initially (optional in contract); ready aim must be precise and comfortable.

Initial campaign resource hypothesis: 30 pistol rounds and8 shotgun shells including initial carried supply; optional risk caches add up to6 rounds and2 shells. Start partially loaded; shotgun acquired in Service before its first intended use. These are tuning values, not fixed guarantees; tune against accuracy, meaningful agency and remaining ammunition telemetry. A careful player retains some reserve. Required progression remains possible at zero ammo. Shots cause readable directional flinch, interruptive stagger and retreat opportunities, not a displayed health race. Gunshots transmit strong real sound evidence. Special final powered-environment interaction can permanently neutralize Listener; escape also remains achievable through routing, timing and doors. Final animation must support either outcome.

## Threat and pacing

One Listener, approximately2.3m, original biological design. Layered perception/belief/search/planning with real room navigation and a separate pacing director. Evidence, not hidden player coordinates, governs movement decisions. It may observe, stalk, investigate false sounds, retreat from observation, intercept only a plausible inferred route, chase and eventually lose track. Door use matters but never permanently defeats it. Attack has readable approach/windup/recovery, wall occlusion and fair separation after a hit. No close spawning or behind-player teleport.

Initial 4–6 close encounters per run with distant/ambiguous opportunities between; not a scripted quota. Initial chase20–45s and recovery60–120s after genuine disengagement. Nearby hiding/search counts as pressure. Director may choose general roaming region/ambient opportunities and quiet intervals, never provide a secret target. Distress/deaths/recent chase should reduce immediate renewed pressure. Quiet spaces stay visually/acoustically engaging. A distant sighting does not automatically start a chase.

## Spatial anomalies

Small authored set only: secondary connection returns at odd orientation; empty room deepens; column or ceiling pattern differs; a previously dead side passage opens. Trigger only fully out of sight and outside occupied/active combat volumes, with safe collision and valid navigation/objective access. Preserve learned active escape paths. Stable landmarks allow the player to doubt memory without being lost arbitrarily. Never visibly pop or routinely reshuffle.

## Failure, checkpoints and final sequence

Autosave every relay, phase breaker and selected fair quiet transitions. Restore health/ammo/ownership/progress/relevant world state consistently; Listener resets to a fair known region away from the player. Target normally under2 minutes repeated after death, maximum4 in tuned campaign. Continue appears only for valid saved progress; explain corrupt/missing save gracefully. Required relays and exit cannot softlock. Final phase enables the return exit and a special environmental threat interaction, using the established controls. Clear ending state and credits, then return to menu.

## Frozen exclusions

### Final interaction decision

The phase breaker charges the existing grounded exit frame in Arrival. Return uses learned relay shortcuts. At the exit vestibule, the same E interaction closes the exit isolator and opens the outward escape door. A visibly marked conductor strip is dangerous to the Listener while charged: a weapon-induced heavy stagger on that strip permits the isolator discharge to permanently incapacitate it, with its final_sequence animation and clear electrical/material response. This is one established breaker/door interaction, not a separate boss or puzzle. An unarmed player can lure it using real door noise, break sight along either vestibule loop, close the separating door and operate the isolator while it is outside; escape never requires ammunition or neutralization. The energized strip never causes an unavoidable player death. Both outcomes resolve to one coherent escape/ending/credits flow; record neutralization only as an outcome flag. Encounter must not spawn/teleport the Listener onto the strip or player.

All required menus and persistent settings are mandatory: title/New Game/Continue/Settings/Controls/Accessibility/Credits/Quit, pause/death/end; resolution/window/fullscreen/VSync/four presets/master/ambience/effects/sensitivity/invert/FOV/bob/shake/subtitles/dot/reduced flashes. No voiced narration planned, but subtitle preference persists for any textual audio cue used. Production font/icons/UI are original and audited. Full controls and state restoration are independently exercised.

No multiplayer/co-op, crafting, open world, skill tree, extra creatures/weapons, loot economy, live service, networking or backend. No complex inventory. No gratuitous jump scares or gore. No new optional mechanic unless necessary to meet the original contract and recorded as a scoped decision. Completion requires the full acceptance loop, not this design document.
