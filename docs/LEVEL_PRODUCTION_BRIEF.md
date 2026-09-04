# Authored level production brief — M8/M9 handoff

Root design/orchestration document, not a generated level or implementation. This elaborates the frozen56-space/six-sector design without changing its mechanics, scope or acceptance criteria. GAME_DESIGN.md, ART_DIRECTION.md and the full contract remain authoritative. Room IDs are proposed stable manifest identities; the assigned world architect must validate physical layout, collision, sightlines and acoustics before committing implementation. No gameplay duration, horror score or route safety is established by this document.

## Spatial program

Each row identifies a meaningful room space, not a requirement for an identical square module. Connectors may bend within a space; count spaces by perceptible architectural identity rather than by every door. Combine original wall/ceiling/floor modules into deliberately different proportions, openings and compositions. Most spaces contain no movable prop. Structural cues, distant openings and lighting carry navigation.

| ID | Space and architectural variant | Intended player experience / stable information |
|---|---|---|
| A01 | Arrival carpet recess; shallow divided room | Wake low to carpet, then see an empty lit opening. No immediate creature attack or tutorial weapon discharge. |
| A02 | Broad orientation room with one offset column | First long, quiet view; column-to-opening alignment is a stable reference on return. |
| A03 | Dead exit vestibule and isolator | Clearly readable physical circuit diagram, dead exit and grounded frame. Final escape occurs here, not at a new unexplained door. |
| A04 | Wide straight commercial corridor | Establish ordinary fluorescent rhythm and footsteps; readable far end, no obligatory prop. |
| A05 | Offset vestibule bypass | Second legitimate approach to A03. Door and occluding bend later permit an unarmed escape without a reaction-time trap. |
| A06 | Split opening / return junction | Stable paired openings; the Grid return shutter is visible while unpowered. |
| A07 | Empty double-back suite | First mild uncertainty about orientation, but no spatial mutation on first exposure. |
| A08 | Narrow-to-wide transition | Clear transition into Grid using ceiling runner direction rather than a giant sector label. |
| B01 | Short stepped-width corridor | Repeats Arrival's materials at a different proportion; retain a clear return sightline. |
| B02 | Open boxed-column room | Uneven column spacing gives a reliable local landmark and two route choices. |
| B03 | Offset three-way intersection | Oblique doorway views hide room extents without hiding all useful information. |
| B04 | Narrow corridor with a shallow recess | Compression before the first physical relay; do not make it a forced attack funnel. |
| B05 | Circulation relay room | Cabinet opening/reset, truthful circuit feedback, escape route from the panel and committed checkpoint. |
| B06 | Double-back room | Reconnects toward a previously glimpsed opening; familiarity comes from actual geometry initially. |
| B07 | Divided office room / carpet repair | Sparse repaired carpet band is the second stable Grid landmark, not a glowing route stripe. |
| B08 | Long exposed hall | Preview the change to Open Plan. A sightline is meaningful even with no creature present. |
| B09 | Return shutter passage | Relay B opens the useful A06 shortcut, with visible mechanism and no collision/nav gap. |
| B10 | Four-way/opening cluster transition | Two perceptible approaches into the same Open Plan entrance, not four identical empty exits. |
| C01 | Low entry opening into broad space | First exposure contrast; light and distant partitions reveal scale. |
| C02 | Open column field | Long diagonal view; quiet observation opportunity uses real creature approach routes. |
| C03 | Asymmetric peripheral junction | A stable missing ceiling-board recess identifies the return route; no collectible inside it. |
| C04 | Wide corridor with offset terminus | A moving silhouette can break sight naturally; no scripted compulsory chase. |
| C05 | Divided office island | Short occluded crossing lets a careful player reduce exposure. |
| C06 | Broad relay approach room | Physical service routing makes the panel location comprehensible without an objective arrow. |
| C07 | Distribution relay bay | Accessible panel, more than one escape direction, restored perimeter lighting and checkpoint. |
| C08 | Perimeter return room | Reconnect to a sightline seen on the outward route; restored lights change actual visibility. |
| C09 | Long hall with isolated off-axis column | Alternate observation/stalking distance; avoid a creature exhibition stage. |
| C10 | Lateral service passage | Distribution relay opens a shorter approach to D04, visible beforehand as an unavailable route. |
| C11 | Maintenance transition | Familiar wallpaper gives way to utilitarian backing infrastructure, not an unrelated industrial map. |
| D01 | Compressed service entry | Lower ceiling and new mechanical texture establish transition. |
| D02 | Utility T intersection | Painted door return landmark; door state audibly and physically matters. |
| D03 | Maintenance storage recess | Logically placed shotgun and limited supply; readable handling space, no attack forced during equip. |
| D04 | Side service connection | Meets C10 shortcut and joins the same local loop; no impossible one-sided latch behavior. |
| D05 | Narrow pipe corridor | Pipe rhythm and intermittent sound mask some distant detail while preserving useful local cues. |
| D06 | Cabinet approach / offset junction | Clear view of infrastructure and two potential approaches; no hallway full of loot cabinets. |
| D07 | Return Feed breaker room | Physical reset, machinery response, distinct return-route opening and checkpoint. |
| D08 | Low-ceiling transition room | Primary way toward Blackout remains traversable; failing hum prepares the coming absence. |
| D09 | Door-separated double-back | Tactical closing/reopening and alternate routes; creature must eventually negotiate an openable door. |
| D10 | Powered return passage | Return Feed opens the E05 shortcut; door, graph, acoustic loss and collision share authority. |
| E01 | Blackout boundary room | Familiar hum drops away; do not compensate by boosting threats or all remaining audio. |
| E02 | Narrow dark corridor | Floor edge and remembered ceiling pattern remain navigable with the flashlight. |
| E03 | Dark open-column room | Flashlight reveals only a useful portion at a time; no random unreadable branching. |
| E04 | Offset junction / permanent wall recess | Stable tactile-scale architectural cue; not a flashing emergency arrow. |
| E05 | Service return opening | Rejoins D10 when powered. Its frame remains identifiable from either approach. |
| E06 | Wide, mostly unlit crossing | An exposed choice contrasting E02; main return path stays geometrically stable. |
| E07 | Low divided room | Quiet breathing/handling and localized distant movement become salient. |
| E08 | Shallow dead-end side room with return loop | Optional respite/resource risk slot, not a required obscure puzzle or guaranteed monster-proof zone. |
| E09 | Threshold approach / physical access latch | All three committed relays required. Show missing circuit names accurately if any are absent. |
| F01 | Desaturated red-brown entry frame | Rare palette anomaly in the same building; no arcade-red flood or automatic chase. |
| F02 | Offset red intersection | Permanent uneven header is a return landmark despite secondary anomalies. |
| F03 | Long hall with an irregular secondary opening | Optional impossible-orientation connection; primary route never depends on the anomaly firing. |
| F04 | Marginally overlong empty room | Quiet spatial doubt; scale alteration only out of view, empty and outside active escape routes. |
| F05 | Main phase breaker room | Phase powers the known exit and frame, opens return access, saves coherently and communicates return. |
| F06 | Breaker return chamber | Short recovery/assessment space with an obvious physical onward connection, not an arbitrary waiting timer. |
| F07 | Irregular secondary loop | Supports a rare out-of-sight connection change and real alternate pursuit route; rollback on unsafe conditions. |
| F08 | Return opening / deep red-brown lintel | Recognizable second Threshold landmark and phase-enabled shortcut toward E06. |

## Proposed connectivity, not baked coordinates

Chains below mean consecutive bidirectional adjacency; commas separate extra connections. Validate a physically plausible ordinary floor plan before adding any impossible connection. The author may bend or widen connectors and revise adjacency after documented greybox evidence, but must preserve all relay/exit/zero-ammo/loop purposes. No random graph generation. Keep room, portal, stable anchor and circuit identities distinct.

| Area | Ordinary connections | Gated additions |
|---|---|---|
| Arrival | A01–A02–A04–A06–A07–A08; A02–A03–A05–A06 | A06–B09 after Circulation |
| Grid | A08–B01–B02–B03–B04–B05–B06–B07–B08–B10–C01; B02–B07; B03–B08; B05–B09 | Same Circulation shutter; never lock its B05 approach behind its own relay |
| Open Plan | C01–C02–C03–C04–C05–C06–C08–C09–C11–D01; C06–C07–C08; C03–C10–C08 | C10–D04 after Distribution |
| Service | D01–D02–D03–D05–D06–D08–E01; D02–D04–D05; D06–D07–D09–D08; D09–D10 | D10–E05 after Return Feed |
| Blackout | E01–E02–E03–E04–E06–E07–E09; E02–E05–E06; E04–E08–E07 | E09–F01 after all three relays |
| Threshold | F01–F02–F03–F04–F05–F06–F08–F02; F03–F07–F06 | F08–E06 only after phase; no reverse bypass into F before all relays |

All three relay rooms remain reachable before their own switch is activated. The expected first-time order is B, C, D, but persistent logic must tolerate other orders. Side-route gates are useful shortcuts, not disposable keys. A player reaching E09 early receives accurate circuit status and can walk back, not become trapped. The final return can use F08→E06→E05→D10, the Distribution passage and the Circulation shutter; those connections must remain intelligible in both directions.

Do not attach an anomaly to a required gate, panel anchor, checkpoint spawn, sole escape route or the isolator. Candidate secondary changes: a Grid side room's ceiling/column after it is vacated, the F03/F07 orientation connection, and F04's unoccupied depth. The world owner selects a small final set and proves off-screen safety, occupancy, graph consistency and rollback. No teleport behind the player, visible popping or repeated compulsive reshuffling.

## Encounter, resources and fairness reservations

Arrival remains attack-free during introduction. Listener roaming begins through the real Circulation relay event and broad director policy, not a hidden-coordinate injection. Open Plan's long views support uncertain observation; Service supports door and noise decisions; Blackout removes familiar acoustic layers; Threshold applies learned skills. Exact encounter timings and resource positions must be tuned from real runs, not filled to a quota.

Reserve optional resource-risk slots at B07, C09, D03 and E08; the resource owner chooses the sparse final distribution within the frozen initial ammunition hypothesis. These are placement options, not four mandatory new loot drops. Do not scatter supplies through every relay room. Starting carried pistol supply and Service shotgun availability must agree with the weapon/save owners.

Every relay and phase interaction must permit interruption and have meaningful retreat space. Checkpoint validation needs a safe player anchor, fair separated Listener region, coherent gates/lights and an unobstructed route away; a stable anchor name alone proves none of those conditions. Quiet transitions can host additional fair autosaves within the frozen replay-time targets. Do not respawn the creature in the current room or reveal the hidden player to it.

A03's final isolator needs two genuinely playable approaches through A02 and A05. Demonstrate both an armed conductor-strip neutralization and an unarmed door/LOS separation escape. The player must understand the isolator using the same interaction language as prior relays. No new resource, puzzle UI, boss health race or unavoidable player electrical damage.

## World-agent handoff and independent greybox review

Before implementing M8, assign one world architect an isolated worktree and exclusive world/sector/manifest ownership; M6 retains door/acoustics authority and M9 retains objective/coordinator authority. The architecture agent must propose an actual scaled plan and inspect key sightlines. This document supplies intentions, not permission for competing systems or direct edits to another owner's files.

Required greybox evidence before decorative expansion:

- All56 distinct spaces exist, connect and serve their stated purposes; minimum structural variants are traceable. A room tally is not a level-quality score.
- Walk the ordinary full route, all three relay orders relevant to gate logic, shortcut returns and zero-ammo ending path with real collision and controls. Logical reachability complements actual traversal, never replaces it.
- Measure first-time and learned traversal, objective discovery, backtracking, resource pressure, chase/search distribution and checkpoint repetition. Do not force35–60 minutes with speed restrictions, artificial waits or repeated empty laps.
- Open full-resolution composition views for each sector and temporal evidence of intersections, door use, relay manipulation and return navigation. Reviewer does not receive a live hidden-monster overlay.
- Probe dead ends, doors closing during passage, crouched clearance, save/load on each side of gates, anomaly refusal under visibility/occupancy and safe rollback. Failure opens a correction task.
- Independent review identifies repetitive room proportions, ambiguous required paths, sightline monotony, unfair panel exposure and pointless traversal before M10 art multiplication. Architecture/audio/landmarks are the first tools for boredom; extra monster appearances are not the default fix.

No M8/M9 acceptance, playthrough success or performance score is implied until implemented, actually operated, independently reviewed and sequentially integrated.
