# THRESHOLD — Immutable Goal Contract

Status: initial archival copy; becomes immutable at design freeze. The text below is the complete original user instruction, preserved verbatim. Implementation notes and decisions live elsewhere and cannot weaken this contract.

/goal Build from an empty repository a complete, polished, release-ready single-player first-person Backrooms survival-shooter, including all code, environments, original 3D assets, materials, textures, animation, creature AI, weapons, VFX, UI, audio, level design, builds, testing, optimization, documentation, screenshots and release artifacts. Continue autonomously without stopping until every Definition-of-Done and Quality Gate in this contract has passed, the entire game has been played from beginning to end successfully in at least two independent final validation runs, no P0/P1 defect remains, and a fresh-clone reproducible release build exists.

# ============================================================
# 0. THIS IS A CODEX GOAL, NOT A NORMAL CHAT TASK
# ============================================================

Treat the entire instruction as one durable Codex GOAL.

Immediately verify that Codex Goals are enabled.

If goals are not enabled, enable them yourself using the supported Codex configuration or command, then set this entire objective as the active /goal.

Do not treat completion of an individual milestone, implementation task, branch, asset, test suite, prototype or vertical slice as completion of the GOAL.

The GOAL is complete ONLY when the final playable game satisfies ALL acceptance conditions in this document.

Do not voluntarily terminate work because:
- a prototype works,
- the game launches,
- the core loop exists,
- tests pass,
- a reviewer says "looks good",
- assets exist,
- one playthrough succeeds,
- the token/context window is becoming large,
- a subagent completed its assignment,
- progress is substantial,
- the result is "good enough",
- improvements appear diminishing,
- or you believe the user might be satisfied.

If the GOAL is not objectively complete:
JOB IS NOT DONE.
Continue.

# ============================================================
# 1. ROOT AGENT ROLE — CRITICAL
# ============================================================

The root/main agent is the EXECUTIVE PRODUCER, TECHNICAL DIRECTOR and ORCHESTRATOR.

THE ROOT AGENT MUST NOT IMPLEMENT THE GAME.

The root agent is prohibited from directly writing or editing:
- gameplay source code
- shaders
- Godot scene implementation
- weapon implementation
- AI implementation
- environment implementation
- gameplay scripts
- animation scripts
- asset-generation scripts
- production meshes
- production textures
- production audio
- production UI
- tests that implement game behavior

The root agent MAY:
- inspect everything
- research
- reason
- plan
- define acceptance criteria
- create orchestration documents
- create Codex agent configuration
- create AGENTS.md
- create/update GOAL_CONTRACT.md
- create/update STATUS.md
- create/update TASKS.md
- create/update DECISIONS.md
- invoke build/test/play commands
- use Computer Use
- launch Godot
- launch builds
- inspect screenshots/video
- inspect profiler output
- inspect logs
- operate Git
- create worktrees
- assign tasks
- review reports
- request corrections
- coordinate integrations

ALL implementation work must be performed by delegated GPT-6 Astra subagents.

This rule is intentional.

The root agent's context must remain focused on:
1. the immutable goal,
2. current verified state,
3. unresolved defects,
4. quality decisions,
5. orchestration.

Do not pollute the root context with unnecessary build logs, exploratory output or raw implementation detail.

# ============================================================
# 2. MODEL POLICY
# ============================================================

Use GPT-6 Astra for the root agent.

Use GPT-6 Astra for EVERY subagent.

Use the maximum supported reasoning effort for GPT-6 Astra:
model_reasoning_effort = "max"

Do not silently downgrade any agent to a cheaper/faster/weaker model.

This applies to:
- researchers
- programmers
- artists
- Blender agents
- gameplay agents
- reviewers
- QA agents
- performance agents
- integration agents
- audio agents
- debugging agents
- release agents
- agents spawned by subagents

Subagents must inherit:
model = "gpt-6-astra"
reasoning = "max"

Create or update project Codex configuration so this is the default.

Determine the highest valid concurrency supported by the current Codex environment and use it.

DO NOT invent an unsupported numeric concurrency setting.

Inspect the currently supported Codex configuration first, then configure the highest practical supported concurrency.

Parallelism rule:

If at any point work can be parallelized by delegating tasks to another agent, whether you are the root agent or a subagent, delegate it when this can improve quality or save time.

However:

DO NOT allow independent write-heavy agents to modify the same files simultaneously.

Use separate Git worktrees/branches for independent implementation.

Use dedicated integration agents to merge completed work.

Read-heavy research, auditing, visual inspection, benchmark analysis, design review and QA SHOULD use aggressive parallelism.

# ============================================================
# 3. PERSISTENT STATE / ANTI-DRIFT SYSTEM
# ============================================================

Long-running sessions must not lose the original objective after compaction.

Before production begins, create:

/GOAL_CONTRACT.md
/QUALITY_GATES.md
/ARCHITECTURE.md
/ART_DIRECTION.md
/GAME_DESIGN.md
/STATUS.md
/TASKS.md
/DECISIONS.md
/ISSUES.md
/PLAYTEST_LOG.md
/PERFORMANCE.md
/RELEASE_CHECKLIST.md
/evidence/
/evidence/screenshots/
/evidence/video/
/evidence/logs/
/evidence/profiling/
/evidence/playtests/

GOAL_CONTRACT.md and QUALITY_GATES.md become immutable after the initial design freeze.

Only change them if an actual unavoidable technical contradiction is discovered.

Never weaken acceptance criteria merely to declare completion.

After:
- context compaction,
- resumed GOAL,
- root-agent handoff,
- major merge,
- crash,
- long pause,
- or any moment where project state is uncertain,

the FIRST action is:

1. inspect active /goal,
2. reread GOAL_CONTRACT.md,
3. reread QUALITY_GATES.md,
4. reread STATUS.md,
5. reread ISSUES.md,
6. inspect git status/history,
7. continue from verified state.

STATUS.md must contain only:
- current milestone,
- last known good commit,
- verified completed systems,
- current blockers,
- current active agents,
- remaining acceptance failures,
- next integration point.

Keep it concise.

Never infer completion from old conversation history when repository evidence can be inspected.

# ============================================================
# 4. AUTONOMY / ENVIRONMENT BOOTSTRAP
# ============================================================

The user should not have to set up the project.

Inspect the host OS, architecture, available GPU, RAM, disk, package manager and installed tools.

Install missing development dependencies yourself.

Target production toolchain:

GAME ENGINE
Godot 4.7.2 stable

3D / ANIMATION
Blender 5.2.x LTS, preferably latest 5.2 maintenance release available on the machine

SUPPORTING TOOLS
Git
Python 3
FFmpeg
ImageMagick
SoX or equivalent audio processing utility
appropriate archive tools
Godot export templates
GPU/graphics inspection utilities where useful

Install other open-source development tools when they materially improve the result.

Do not install random dependencies without reason.

Do not download ready-made game-content asset packs.

The final game must not depend on:
- Unity Asset Store assets
- Unreal Marketplace assets
- Sketchfab ripped assets
- other Backrooms games' assets
- copyrighted film/game textures
- copyrighted monster models
- copyrighted weapon models
- downloaded proprietary sound packs

Development software and libraries are allowed.

All production visual assets must be original to this project.

Prefer:
- Blender procedural modeling
- Blender Python automation
- procedural materials
- generated PBR textures
- original mesh work
- generated vector UI
- generated decals
- generated particles
- image generation tools if available and appropriate

All generated material must be transformed into production-ready game assets, not merely pasted concept art.

Audio should also be created specifically for this project using synthesis, procedural layering, processing and generated source material wherever possible.

Do not use an external content asset merely because creating one is inconvenient.

# ============================================================
# 5. REPOSITORY / VERSION CONTROL RULES
# ============================================================

Initialize Git immediately.

Main branch must always represent an integrated known-good state.

Every major write-heavy subagent task gets its own worktree/branch.

Naming convention examples:

agent/world-architecture
agent/player-controller
agent/pistol
agent/shotgun
agent/monster-ai
agent/monster-art
agent/monster-animation
agent/environment-art
agent/lighting
agent/audio
agent/ui
agent/qa-fix-###
agent/performance
agent/release

Each implementation agent must:
- inspect its assignment
- implement
- build
- run relevant tests
- run the actual game where applicable
- inspect visual/behavioral output
- iterate until its local acceptance criteria pass
- commit
- return concise evidence to the parent

An Integration Agent merges finished branches sequentially.

After every merge:
- build
- smoke test
- regression test
- launch actual game
- inspect changed behavior

Never integrate multiple unverified feature branches blindly.

# ============================================================
# 6. FIRST ACTION: SPAWN RESEARCH/DESIGN TEAM
# ============================================================

Before production code begins, spawn parallel GPT-6 Astra max-reasoning agents for:

A. Backrooms visual/lore research
B. survival-horror game-design research
C. first-person shooter game-feel research
D. predator/stalker enemy AI research
E. Godot 4.7.2 rendering/navigation/performance research
F. Blender procedural game-asset pipeline research
G. audio/horror sound-design research
H. game QA/autonomous visual-validation methodology
I. legal/license review to ensure no production asset is copied from another property

They must research current sources online where available.

Their goal is not to broaden scope infinitely.

They must return concise recommendations relevant to THIS game.

The root then freezes GAME_DESIGN.md and ART_DIRECTION.md.

After design freeze, stop debating the high-level game concept and build it.

# ============================================================
# 7. PRODUCT DEFINITION
# ============================================================

Working title:
"THRESHOLD"

Genre:
single-player first-person survival horror / tactical shooter

Target:
PC

Primary exports:
Windows x86-64
Linux x86-64 if the build environment supports it

Engine:
Godot 4.7.2 stable

Renderer:
Forward+

Perspective:
first-person

Target full playtime:
approximately 35–60 minutes for a first successful playthrough

This is a COMPLETE SHORT GAME.

It is NOT:
- a tech demo
- a collection of disconnected mechanics
- an empty greybox
- a walking simulator
- a shooting gallery
- a wave shooter
- a puzzle compilation
- an asset-flip
- a generic Backrooms clone

# ============================================================
# 8. CREATIVE PILLARS
# ============================================================

The player must experience four feelings simultaneously:

1. I am deeply lost.
2. I may not actually be alone.
3. I have a weapon, but firing it may make things worse.
4. I can survive by understanding the space and the creature.

HORROR comes primarily from:
- architecture
- isolation
- uncertainty
- acoustics
- impossible space
- anticipation
- the monster's intelligence

NOT primarily from:
- jumpscares
- loud sting sounds
- random screaming
- instant-kill chase sequences
- excessive gore
- darkness everywhere

The monster must be rare enough that absence itself becomes frightening.

The environment must remain compelling when the monster is nowhere nearby.

# ============================================================
# 9. BACKROOMS ART DIRECTION
# ============================================================

Use the recognizable conceptual language of Level 0, but create every production asset originally.

Core visual language:

- low commercial drop ceilings
- stained acoustic ceiling tiles
- aging fluorescent fixtures
- washed-out off-yellow wallpaper
- dirty beige/yellow carpet
- subtle carpet moisture
- baseboards
- oddly placed structural columns
- inconsistent corridor widths
- inexplicable openings
- repeating architectural motifs
- slight scale inconsistencies
- spaces that appear familiar but architecturally wrong

DO NOT make the entire screen saturated neon yellow.

Colors should feel aged and physical:
cream
nicotine yellow
mustard
beige
brown
grey-green shadows

The environment must look like a forgotten late-20th-century commercial building rather than a theme park decorated as "The Backrooms."

The floor should show:
- compression
- darker damp regions
- subtle fiber variation
- occasional stains

Wallpaper should show:
- small pattern variation
- seam lines
- fading
- occasional bubbles
- very subtle discoloration

Ceiling should show:
- tile variation
- slightly misaligned panels
- occasional missing panel
- ballast grime
- fixture differences

Do not clutter every room.

Most rooms should contain NOTHING.

Sparse objects gain significance.

Potential rare props:
- lone office chair
- abandoned folding table
- maintenance cart
- breaker box
- wall vent
- displaced ceiling panel
- discarded cup
- obsolete telephone
- small sign
- unplugged floor fan

Prop density must remain intentionally low.

# ============================================================
# 10. LEVEL STRUCTURE
# ============================================================

Build one seamless major environment divided psychologically into six sectors.

SECTOR A — ARRIVAL

Purpose:
establish isolation.

No immediate attack.

Player wakes on the carpet.

Fluorescent hum dominates.

The game gives enough quiet time for the player to understand that the environment itself is wrong.

The creature may produce one extremely ambiguous distant indication but must not immediately appear.

SECTOR B — GRID

Classic segmented Level-0 architecture.

Repeating rooms and pillars.

Introduces player navigation, subtle landmarks and the first power-routing objective.

The player begins finding evidence that the geometry is inconsistent.

SECTOR C — OPEN PLAN

Larger spaces.

Long sightlines.

Sparse partitions.

This creates fear through exposure instead of darkness.

The monster can occasionally be seen far away here.

Seeing it must not automatically trigger a chase.

SECTOR D — SERVICE

Narrower utility spaces integrated behind the Level-0 facade.

Breaker infrastructure.

Pipes.

Electrical cabinets.

Lower ceilings.

Stronger mechanical noises.

More opportunities for tactical door use and sound distraction.

SECTOR E — BLACKOUT

A Level-0 blackout region.

Most fluorescent fixtures fail.

The ambient fluorescent hum largely disappears.

That absence must feel disturbing because the player has learned to depend on the hum.

Flashlight becomes critical.

Navigation is harder but not random or unfair.

Sound localization becomes much more important.

SECTOR F — RED THRESHOLD

Rare architectural anomaly.

Desaturated deep red/brown rather than arcade-red.

Space becomes increasingly impossible.

Some corridors reconnect incorrectly.

The final power/exit sequence takes place here.

The player is allowed to use everything learned about:
- sound
- doors
- line of sight
- weapons
- monster behavior

# ============================================================
# 11. LEVEL DESIGN RULES
# ============================================================

Build approximately 45–70 meaningful interconnected room spaces using a larger set of modular structural pieces.

Use enough modular variants that obvious tile repetition is difficult to notice.

At minimum design original variants for:

- straight corridor
- narrow corridor
- wide corridor
- T intersection
- four-way intersection
- offset intersection
- open column room
- divided office room
- dead-end room
- double-back room
- low-ceiling room
- long exposed hall
- maintenance transition
- breaker room
- blackout room
- red anomaly room
- transitional staircase/ramp if used
- irregular architectural anomaly

The final level must NOT feel like a procedural maze generator made of obvious identical squares.

Use intentional:
- rhythm
- landmarks
- negative space
- visual composition
- sightlines
- loops
- shortcuts
- safe-ish zones
- risk/reward spaces

The player should become partially familiar with the environment without ever becoming completely certain.

# ============================================================
# 12. IMPOSSIBLE GEOMETRY
# ============================================================

Implement subtle Backrooms spatial anomalies.

Examples:

A corridor can return to a room from an impossible orientation.

A doorway previously passed may lead somewhere slightly different later.

A wall pattern may subtly change.

A column may disappear after leaving and returning.

A room may become marginally longer.

A fluorescent fixture pattern may change.

A dead end may later contain another corridor.

These changes must happen only when:
- outside player line of sight,
- physically safe,
- no visible pop occurs,
- navigation remains valid.

Never use spatial shifting so frequently that it becomes a gimmick.

The player should periodically wonder whether they remembered the room incorrectly.

# ============================================================
# 13. PLAYER CONTROLLER
# ============================================================

Movement must feel grounded, responsive and physical.

Starting tuning targets:

Walk:
~3.4 m/s

Crouch:
~1.8 m/s

Sprint:
~5.4 m/s

Acceleration:
fast enough for responsive control, but not instantaneous arcade movement

Jump:
do not include bunny-hopping.
Only include a modest jump if required by level interaction.

Camera:
subtle walking motion
subtle breathing
small acceleration response
small landing response
no excessive head bob

Field of view:
configurable
default approximately 85–90 horizontal-equivalent depending on Godot convention

Mouse sensitivity:
configurable

Add:
- sprint stamina
- crouching
- footsteps
- flashlight
- interaction
- doors
- pickups
- damage
- death
- respawn/checkpoint
- weapon handling

No complex inventory grid.

Keep controls immediate.

# ============================================================
# 14. PLAYER EXPERIENCE / HUD
# ============================================================

HUD must be minimal.

No RPG health bars.

No floating enemy UI.

No damage numbers.

No enemy health bar.

No minimap.

No giant objective arrows through walls.

Use:
- tiny contextual interaction prompt
- restrained ammo display
- subtle health feedback
- subtle stamina feedback when necessary
- objective text only when updated
- optional small center dot

Important information should be communicated through:
- animation
- sound
- lighting
- environment
- weapon state

Create proper:
- title screen
- Continue
- New Game
- Settings
- Controls
- Accessibility
- Credits
- Quit
- Pause menu
- death/restart state
- ending state

# ============================================================
# 15. OBJECTIVE / GAME LOOP
# ============================================================

The player must restore power to an unstable exit system.

The exit initially exists but is dead.

A nearby maintenance panel clearly establishes that several independent circuits are offline.

Primary objective:

Locate and activate THREE remote relay/breaker stations.

After each station:
- environmental behavior changes
- some lights regain power
- some old pathways become usable
- the monster's behavioral situation changes
- an autosave/checkpoint occurs

After the third:
the Red Threshold sector becomes accessible.

The final sequence requires activating the main phase breaker and returning to the exit.

Do not reduce objectives to glowing collectible keys.

Breaker interactions should be physical:
- open panel
- manipulate switches
- possibly insert/reset a component
- hear machinery respond
- see environmental lighting change

Keep interaction intuitive.

No obscure adventure-game puzzle logic.

# ============================================================
# 16. THE MONSTER — ORIGINAL CREATURE
# ============================================================

Create an original creature specifically for this game.

Working internal name:
THE LISTENER

Do not copy:
- Kane Pixels' creature
- a Backrooms Wiki entity
- SCP designs
- existing horror game monsters

Silhouette:

approximately 2.2–2.4 m tall

unnaturally thin but structurally believable

long arms

slightly asymmetric shoulders

head shape that is recognizably biological but difficult to read

no cartoon mouth

no giant glowing eyes

skin/material should react subtly to fluorescent light

movement alternates between:
- almost motionless observation
- deliberate walking
- abrupt acceleration

It must look disturbing even standing still.

Create an original Blender model.

Create:
- production mesh
- UVs
- materials
- skeleton
- rig
- collision representation
- animations

Required animation set includes at minimum:

idle
breathing
listen
slow walk
stalk walk
turn
chase/run
door interaction
investigate
search
flinch front
flinch side
heavy stagger
attack
recovery
retreat/injured movement
final sequence animation

Transitions must not snap obviously.

# ============================================================
# 17. MONSTER AI — MOST IMPORTANT SYSTEM
# ============================================================

This is the highest-priority gameplay system.

Do NOT implement a simplistic:

if player_visible:
    run_at_player

system.

Use a layered architecture combining:

LOCAL NAVIGATION
+
PERCEPTION
+
BELIEF/MEMORY
+
BEHAVIOR/UTILITY OR GOAL PLANNING
+
PACING DIRECTOR

The creature must reason from imperfect evidence.

Potential behavioral states:

DORMANT
ROAM
LISTEN
INVESTIGATE
OBSERVE
STALK
INTERCEPT
CHASE
SEARCH
ATTACK
STAGGER
RETREAT
RECOVER

The exact implementation architecture may use:
- utility AI
- behavior tree
- GOAP
- hierarchical state machine
- hybrid architecture

Choose the architecture after the dedicated AI research agent evaluates it.

The observable result matters more than the label.

# ============================================================
# 18. MONSTER PERCEPTION
# ============================================================

VISION

Vision must consider:
- distance
- field of view
- line of sight
- player posture
- player movement
- approximate light exposure

Seeing a stationary crouched player at the edge of a dark room should be harder than seeing a sprinting player under a fluorescent fixture.

The creature must NOT see through walls.

The creature must NOT permanently know the player's transform.

HEARING

Create a real gameplay sound-event system.

Actions emit sound events with:
- source position
- intensity
- type
- timestamp

Examples:

crouched movement:
very quiet

walking:
quiet

sprinting:
medium

opening/closing door:
medium

slamming door:
high

object impact:
high

pistol shot:
very high

shotgun shot:
extreme

Sound propagation must account approximately for architecture.

Use room/portal topology or navigable acoustic distance rather than naive infinite Euclidean hearing when practical.

Closed doors should attenuate sound.

Multiple walls should reduce certainty.

A heard sound provides an estimated region/position to investigate.

It does NOT grant permanent perfect tracking.

# ============================================================
# 19. MONSTER MEMORY / SEARCH
# ============================================================

Maintain evidence records including:

- last directly seen position
- last heard location
- evidence confidence
- evidence age
- player travel direction estimate
- recent doors used
- recent loud events

When visual contact is lost:

the monster goes to the last credible location.

Then it searches plausible nearby spaces.

Search behavior must include:
- nearby junctions
- adjacent rooms
- likely escape routes
- last-used door areas
- short pauses to listen

Search must eventually decay.

If no evidence remains:
return to lower-threat behavior.

Do not let it orbit the player's hidden location magically.

# ============================================================
# 20. STALKING BEHAVIOR
# ============================================================

The creature should not always attack when it detects the player.

Sometimes it should:

- watch from the end of a corridor
- partially hide behind a wall
- move away when clearly observed
- approach slowly
- disappear through another route
- inspect a location near the player
- remain audible but unseen

These events must emerge from AI and controlled encounter design rather than constant scripted jumpscares.

The player should often ask:

"Did it see me?"

That uncertainty is central to the game.

# ============================================================
# 21. FAIRNESS RULES
# ============================================================

Monster AI may be dangerous.

It may not cheat.

Forbidden:

- teleporting directly behind the player
- spawning inside the current room
- knowing exact player coordinates without evidence
- attacking through walls
- permanently tracking after losing sight
- impossible acceleration with no animation
- unavoidable instant kills
- silent arrival directly beside player
- scripted death because player chose the "wrong" unmarked corridor

Standard difficulty should permit recovery from most mistakes.

The first monster hit should normally injure and disorient rather than instantly kill.

A second serious hit may kill.

# ============================================================
# 22. HORROR PACING DIRECTOR
# ============================================================

Create a higher-level tension director separate from local monster intelligence.

The director tracks approximately:

- time since last sighting
- time since chase
- player health
- ammunition
- objective progress
- recent monster proximity
- current sector
- recent deaths

The director can influence:
- monster roaming region
- likelihood of distant encounter opportunities
- ambient events
- environmental sound frequency
- temporary quiet periods

The director CANNOT:
- reveal player location to the monster without evidence
- teleport monster into view
- force arbitrary deaths

After a major chase, deliberately create recovery space.

Continuous maximum tension destroys tension.

Use quiet intervals.

# ============================================================
# 23. SHOOTER DESIGN
# ============================================================

This must feel like a real first-person shooter when the player fires.

Do not treat guns as simple raycast debug tools.

Create TWO polished weapons.

WEAPON 1:
compact semi-automatic pistol

Approximate tuning:
12-round magazine
moderate recoil
accurate first shot
fast handling
moderate damage/stagger
very loud relative to footsteps

Required:

equip
idle
sprint pose
ADS if implemented
fire animation
recoil animation
empty state
tactical reload
empty reload
slide behavior
muzzle flash
shell ejection
mechanical animation
impact response
weapon light interaction
original materials
original sound

WEAPON 2:
pump-action shotgun

Approximate tuning:
5–6 shells
individual shell reload
slow firing cycle
very strong close-range stopping/stagger power
extremely loud

Required:

equip
idle
fire
pump
shell eject
incremental reload
reload interruption
muzzle flash
strong recoil
pellet impacts
environment response
original sound
original model/material

# ============================================================
# 24. COMBAT PHILOSOPHY
# ============================================================

The player is armed but not dominant.

The weapon must provide:
AGENCY

without eliminating:
FEAR

Gunshots are tactically expensive because they create enormous sound events.

The monster is physically affected by bullets.

Shots should produce:
- flinch
- stagger
- temporary loss of momentum
- visible wound/state reaction
- behavior changes

But the creature should not become a generic visible-health bullet sponge.

No enemy health bar.

During ordinary play, firearms mainly:
- buy time
- interrupt an attack
- force retreat
- create an escape window

The final sequence may allow the monster to be permanently neutralized under special environmental conditions.

This creates an actual shooter payoff without making the entire game a monster DPS race.

# ============================================================
# 25. GUN FEEL
# ============================================================

Every shot must coordinate:

INPUT
-> weapon motion
-> muzzle flash
-> camera impulse
-> shell behavior
-> projectile/raycast
-> impact
-> sound
-> environmental response

Recoil should use a short impulse and controlled recovery.

Do not randomly jerk the camera excessively.

Animation must preserve responsiveness.

The shot must feel immediate.

Add:
- bullet decals
- wallpaper punctures
- plaster/dust effects
- metal sparks where appropriate
- subtle carpet impact effect
- shell casing sound

Shotgun must feel materially stronger than pistol.

Use layered audio:
- muzzle blast
- mechanical action
- room reflection
- distant tail

Indoor acoustics are critical.

# ============================================================
# 26. AMMUNITION / RESOURCE DESIGN
# ============================================================

Ammo must be scarce but not so scarce that shooting feels forbidden.

The expected successful first playthrough should provide enough ammunition for several meaningful encounters but not enough for indiscriminate firing.

Place ammo logically and sparsely.

Do not litter ammunition boxes everywhere.

A player who shoots constantly should create serious resource pressure.

A careful player should finish with some reserve.

Tune this through playtests rather than assumption.

# ============================================================
# 27. FLASHLIGHT
# ============================================================

Create a high-quality flashlight system.

Features:
- physically plausible beam
- soft spill
- subtle hand/weapon movement
- environmental response
- optional battery mechanic ONLY if testing shows it improves tension

Do not implement an annoying battery mechanic merely because horror games traditionally have one.

Light influences monster visual detection slightly.

Flashlight is not a magical monster stun weapon.

# ============================================================
# 28. DOORS / INTERACTION
# ============================================================

Doors are tactical objects.

Player can:
- open
- close
- optionally push/slam depending on interaction style

Door state affects:
- navigation
- line of sight
- sound attenuation
- monster route

The monster must be capable of interacting with doors.

Different behavior depending on state:
ROAM -> opens normally
INVESTIGATE -> opens cautiously
CHASE -> opens quickly or forces through

Doors cannot permanently trivialize AI.

Interaction must feel physical and responsive.

# ============================================================
# 29. ENVIRONMENTAL AUDIO
# ============================================================

Audio is a first-class gameplay system.

Create separate audio buses for:

Master
Ambience
Fluorescent
Environment
Player
Weapons
Monster
UI

Build environmental sound primarily from original/synthesized material.

Important continuous layer:
fluorescent ballast hum.

Do not use one looping WAV everywhere.

Create multiple subtly different hum layers with spatial variation.

Include:
- electrical buzz
- ballast flutter
- distant mechanical rumble
- HVAC
- occasional pipe noise
- carpet footsteps
- remote unidentifiable impacts
- occasional silence
- monster movement cues

Use spatial audio extensively.

Sound must allow skilled headphone users to infer direction and distance.

# ============================================================
# 30. BLACKOUT AUDIO
# ============================================================

When entering the blackout zone:

remove most familiar fluorescent hum.

Do not simply make everything louder and scarier.

Use absence.

The player should suddenly notice:
- their own breathing
- clothing
- weapon handling
- footsteps
- distant room acoustics

Use this as a major tonal shift.

# ============================================================
# 31. ORIGINAL ASSET PIPELINE
# ============================================================

Create all production art deliberately.

Use Blender 5.2 LTS.

Maintain source files under:

/art/source/blender/
/art/source/textures/
/art/source/audio/
/art/exported/

Create reusable environment asset collections.

Structural assets should have:
- clean scale
- consistent origin
- predictable snapping dimensions
- collision
- reasonable topology
- UVs
- optimized material count

Generate PBR maps where useful:
- base color
- roughness
- normal
- height/detail
- AO when useful

Avoid absurd texture resolution.

Use 2K where visually justified.
Use 1K/512 where sufficient.
Atlas small repeated props where useful.

# ============================================================
# 32. ENVIRONMENT ASSET QUALITY
# ============================================================

The final environment must survive close first-person inspection.

No:
- obvious stretched UVs
- default Godot primitives visible as final art
- placeholder checkerboards
- floating walls
- light leaks
- z-fighting
- giant texture pixels
- absurdly sharp perfect corners everywhere

Use:
- bevels where appropriate
- roughness variation
- small surface imperfections
- plausible material response

But avoid turning the Backrooms into a filthy post-apocalyptic ruin.

It should look abandoned and wrong, not destroyed.

# ============================================================
# 33. LIGHTING
# ============================================================

Fluorescent lighting is central to the identity.

Create reusable fixture variants.

States include:

NORMAL
WEAK
INTERMITTENT
FAILING
OFF

Flicker must be irregular and restrained.

Do not make every light constantly flicker.

Lighting should provide:
- readability
- long silhouettes
- exposure changes
- landmarks
- mood

Avoid crushed-black horror-game visuals in normally lit sectors.

Level 0 should often be disturbingly well lit.

Optimize lights intelligently.

For distant rooms, prefer cheaper representation.

Near the player, allow high-quality dynamic response.

Use Godot occlusion culling aggressively where it provides genuine indoor benefit.

# ============================================================
# 34. VFX / POST PROCESS
# ============================================================

Use restrained effects.

Potential:
- slight exposure response
- subtle film grain
- subtle lens imperfections
- restrained chromatic aberration ONLY if nearly invisible
- mild volumetric haze in selected spaces
- impact particles
- muzzle effects
- dust motes selectively

Do not bury the image beneath:
- VHS filters
- extreme bloom
- scanlines
- chromatic aberration
- fake camcorder overlays

This is a first-person game, not automatically a found-footage filter simulator.

# ============================================================
# 35. TECHNICAL ARCHITECTURE
# ============================================================

Use modular, typed GDScript unless a research agent identifies a strong reason to use another supported Godot language.

Keep systems decoupled.

Suggested system boundaries:

GameFlow
SaveSystem
CheckpointSystem
PlayerController
PlayerHealth
InteractionSystem
WeaponController
WeaponData
AmmoSystem
NoiseEmitter
SoundEventSystem
RoomAcoustics
MonsterController
MonsterPerception
MonsterMemory
MonsterPlanner
MonsterNavigation
MonsterCombat
ThreatDirector
DoorController
BreakerObjective
LevelState
SpatialAnomalySystem
LightingController
AudioDirector
UIController
SettingsManager
Telemetry
DebugTools

Do not create giant 2,000-line god scripts.

Use Resources/configuration for tunable data.

Centralize tuning values.

Debug visualization must be available during development for:

- navigation
- monster current state
- monster goal
- visual cone
- perceived sounds
- last-known position
- search targets
- room graph
- player noise intensity

Disable developer visualization in release builds.

# ============================================================
# 36. PERFORMANCE TARGET
# ============================================================

Target:

1080p
60 FPS
high-quality preset
on approximately RTX 2060 / RX 6600-class discrete GPU
and a reasonable modern 6-core CPU

Create:
LOW
MEDIUM
HIGH
ULTRA

quality presets.

Optimize:
- draw calls
- excessive dynamic lights
- shadows
- geometry
- texture memory
- audio voices
- AI update rates
- navigation updates
- particles

Use:
- occlusion culling
- visibility ranges where appropriate
- LOD/HLOD where materially useful
- light activation by nearby sectors/rooms
- sensible collision meshes

Never solve performance by destroying the intended visual identity.

# ============================================================
# 37. SAVE / FAILURE / CHECKPOINTS
# ============================================================

Use autosaves after meaningful objective milestones.

On death:
restart from a recent fair checkpoint.

Do not make the player repeat 20 minutes of empty exploration after one AI mistake.

Checkpoint state must correctly restore:
- breaker progress
- player health
- ammunition state
- weapon ownership
- relevant environment state

Monster state may reset into a fair deterministic/controlled state around the checkpoint rather than spawning directly near player.

# ============================================================
# 38. ACCESSIBILITY / SETTINGS
# ============================================================

Implement proper settings for:

resolution
fullscreen/windowed
VSync
quality preset
master volume
music/ambience volume
effects volume
mouse sensitivity
invert Y
FOV
head bob intensity
camera shake intensity
subtitles if textual audio exists
crosshair preference if applicable

Allow reduction of:
- camera shake
- head bob
- intense flashes

Settings persist.

# ============================================================
# 39. AUTONOMOUS DEVELOPMENT MILESTONES
# ============================================================

Use these as checkpoints, NOT as reasons to stop:

M0
environment and toolchain ready

M1
research + frozen specification

M2
technical project skeleton

M3
final-feeling player locomotion

M4
one production-quality environment room

M5
weapon vertical slice

M6
monster perception/navigation vertical slice

M7
full AI behavior loop

M8
full level greybox

M9
objective loop complete

M10
all original environment art integrated

M11
monster production model/rig/animation integrated

M12
full audio

M13
lighting/VFX pass

M14
UI/settings/save system

M15
first complete start-to-finish playthrough

M16
gameplay tuning

M17
horror pacing tuning

M18
visual polish

M19
performance optimization

M20
independent QA

M21
release candidate

M22
final dual validation

Do not polish M20 while M8 is fundamentally broken.

Keep production order rational.

# ============================================================
# 40. REQUIRED LOOP FOR EVERY FEATURE
# ============================================================

Every meaningful feature follows:

PLAN
↓
DELEGATE
↓
IMPLEMENT
↓
BUILD
↓
RUN
↓
INTERACT WITH IT
↓
VISUALLY/AUDIBLY INSPECT
↓
COMPARE AGAINST ACCEPTANCE CRITERIA
↓
FIND DEFECTS
↓
FIX
↓
RUN AGAIN
↓
INDEPENDENT REVIEW
↓
MERGE ONLY IF ACCEPTED

Compilation is NOT validation.

A passing test is NOT sufficient proof for:
- visual quality
- gun feel
- animation
- movement
- monster behavior
- horror pacing
- lighting
- audio
- UI

The game must be actually operated.

# ============================================================
# 41. SUBAGENT SELF-VALIDATION
# ============================================================

Before an implementation subagent may report "finished", it must:

1. launch the affected game/build,
2. interact with its feature,
3. inspect the outcome,
4. capture evidence,
5. identify visible/behavioral problems,
6. fix those problems,
7. repeat until its criteria pass.

Evidence may include:

screenshots
short captured gameplay videos
logs
telemetry
profiling output
test output

Save evidence in /evidence/.

A text claim such as:
"looks good"
is not evidence.

# ============================================================
# 42. INDEPENDENT REVIEW
# ============================================================

After an implementation agent finishes, spawn a SEPARATE reviewer agent that did not implement that feature.

Reviewer uses GPT-6 Astra max.

Reviewer is instructed to be adversarial.

It should ask:

- Does it actually work?
- Does it look cheap?
- Does it feel generic?
- Is there visible placeholder content?
- Is gameplay responsive?
- Does the monster cheat?
- Is the horror ruined by repetition?
- Are animations amateurish?
- Is audio spatially useful?
- Are there obvious seams?
- Does the feature regress another system?
- Would this visibly embarrass the project in a trailer?

Reviewer produces:
PASS
or
FAIL

with evidence.

FAIL immediately creates correction tasks.

# ============================================================
# 43. VISUAL QA LOOP
# ============================================================

For each visual milestone:

capture representative screenshots from at least:

1. classic Level-0 corridor
2. large open-plan space
3. maintenance/service space
4. blackout area
5. red threshold
6. close-up weapon
7. monster at medium distance
8. active combat moment
9. breaker/objective interaction
10. final exit area

A visual-review agent must inspect them at full resolution.

It scores:

composition
lighting
material quality
cohesion
Backrooms atmosphere
readability
originality
absence of obvious AI/generated artifacts

Anything below 8/10:
mandatory improvement.

Final release:
no category below 9/10.

# ============================================================
# 44. GAMEPLAY QA LOOP
# ============================================================

Maintain telemetry for playtests.

Track at least:

playthrough duration
deaths
damage taken
shots fired
ammo collected
ammo remaining
monster sightings
chases
average chase duration
monster searches
monster false investigations
time between encounters
objective completion time
frame time
crashes/errors

Use telemetry to tune rather than guess.

# ============================================================
# 45. MONSTER QA SCENARIOS
# ============================================================

Create dedicated AI test scenarios.

At minimum verify:

PLAYER WALKS BEHIND WALL
monster should lose vision.

PLAYER FIRES PISTOL IN ADJACENT AREA
monster should investigate.

PLAYER FIRES THEN RELOCATES QUIETLY
monster should investigate old location, not magically track new location.

PLAYER SPRINTS NEARBY
monster should hear according to propagation.

PLAYER CROUCHES FAR AWAY
monster should usually not hear.

PLAYER BREAKS LINE OF SIGHT DURING CHASE
monster should search last-known route.

PLAYER CHANGES ROUTE DURING SEARCH
monster must not turn directly toward hidden player without evidence.

CLOSED DOOR
must affect sight/sound/navigation.

GUNSHOT DURING STALK
should significantly escalate threat.

MONSTER STAGGER
must interrupt appropriate behavior without breaking navigation.

Repeated tests must prove these behaviors.

# ============================================================
# 46. GUNPLAY QA
# ============================================================

Independent FPS reviewer must test:

input responsiveness
shot timing
recoil
reload timing
sound
impact readability
animation transitions
shell behavior
weapon clipping
ADS if present
sprint transitions
close-wall behavior
monster hit reactions

If firing either weapon feels like a prototype:
FAIL.

# ============================================================
# 47. HORROR QA
# ============================================================

Spawn reviewers who play a meaningful uninterrupted segment.

Ask them to identify:

- moments where tension works
- moments where tension collapses
- monster overexposure
- overly long boring traversal
- cheap jumpscare moments
- confusing objective communication
- unfair deaths
- excessive resource abundance
- excessive resource scarcity
- repetitive rooms
- artificial-looking level generation

Use the findings.

The solution to boredom must NOT automatically be "spawn monster more often."

Improve:
- composition
- environmental variation
- uncertainty
- audio
- spatial anomalies
- objectives

before increasing monster frequency.

# ============================================================
# 48. FULL PLAYTHROUGH LOOP
# ============================================================

Once the game becomes completable:

run actual start-to-finish playthroughs repeatedly.

For every full run:

Record:
- time
- deaths
- blockers
- boring sections
- AI failures
- visual bugs
- audio bugs
- confusing objectives
- performance spikes

Then spawn targeted fix agents.

Then integrate.

Then replay.

Do not stop after one successful run.

# ============================================================
# 49. BUG SEVERITY
# ============================================================

P0:
game cannot launch
save corruption
cannot finish game
crash
hard lock

P1:
major gameplay system broken
monster regularly cheats
major visual corruption
objective can softlock
weapon unusable
checkpoint broken
severe performance collapse

P2:
noticeable quality defect
animation issue
bad encounter
minor AI bug
obvious visual seam
audio imbalance

P3:
small polish issue

FINAL RELEASE MAY HAVE:
zero P0
zero P1

Strongly target:
zero known P2

Do not spend endless hours eliminating microscopic P3 issues after all quality gates are objectively passed.

# ============================================================
# 50. QUALITY SCORING
# ============================================================

At every release-candidate review, independent agents score 0–10:

GAMEPLAY
GUN FEEL
MONSTER AI
HORROR/TENSION
LEVEL DESIGN
ART
ANIMATION
LIGHTING
AUDIO
UI/UX
PERFORMANCE
STABILITY
COHESION

Release requirement:

every category >= 9.0

overall mean >= 9.2

No score may be accepted without concrete justification/evidence.

If a score fails:
create tasks,
delegate,
fix,
retest.

# ============================================================
# 51. RELEASE DEFINITION OF DONE
# ============================================================

The GOAL is complete ONLY if ALL of these are true:

The game launches from a release export.

The title menu works.

New Game works.

Continue works after a save exists.

Settings persist.

The player can complete the entire campaign.

All three breaker objectives work.

The final threshold sequence works.

The monster uses actual perception and search behavior.

The monster does not consistently cheat.

Both weapons are complete and polished.

Gunshots affect monster behavior.

Doors affect AI/navigation/acoustics.

Checkpoint restore works.

No placeholder developer geometry remains in visible production areas.

No placeholder UI remains.

No missing textures.

No obvious broken animation.

No game-breaking navigation issue.

No P0 defect.

No P1 defect.

Performance target is substantially met.

Release build contains no major debug spam.

A clean/fresh repository checkout can reproduce the build using documented steps.

At least TWO separate complete final playthroughs have succeeded after the last gameplay-affecting change.

At least ONE of those playthroughs is performed/reviewed by an independent QA agent that did not implement the systems.

Final representative screenshots have passed visual QA.

Final gameplay recording has passed review.

Quality-score requirements pass.

ONLY THEN may /goal be considered complete.

# ============================================================
# 52. RELEASE ARTIFACTS
# ============================================================

Produce:

/build/windows/
/build/linux/ when possible

README.md

README must contain:
- premise
- controls
- system requirements
- how to launch
- how to build
- known limitations if any

Also produce:

ARCHITECTURE.md
GAME_DESIGN.md
ART_DIRECTION.md
CREDITS.md
LICENSES.md
RELEASE_NOTES.md

And:

/evidence/final/

containing representative screenshots and final QA evidence.

Capture a short 60–120 second representative gameplay video if the environment permits.

The video must demonstrate:
- environment
- exploration
- weapon
- monster
- AI interaction
- lighting
- final visual quality

Do not manufacture a trailer that hides obvious defects.

# ============================================================
# 53. WHEN BLOCKED
# ============================================================

Do not immediately ask the user.

First independently attempt reasonable alternatives.

Examples:

Tool missing:
install it.

Package-manager install fails:
try official portable/archive build.

Blender UI automation is unreliable:
use Blender Python/headless generation.

Godot editor interaction is cumbersome:
use scripts/headless import/export where appropriate.

One implementation fails:
spawn an independent debugging agent.

One architecture proves bad:
have agents compare alternatives and migrate.

A visual asset looks bad:
regenerate/rebuild it.

A reviewer fails a feature:
create fix tasks.

Only require user input if progress fundamentally requires:
- private credentials,
- an external paid license decision,
- physical hardware interaction unavailable to the agent,
- or an irreversible consequential choice that genuinely cannot be inferred.

Meanwhile continue all independent work.

# ============================================================
# 54. DO NOT GAME THE ACCEPTANCE CRITERIA
# ============================================================

Never:

- lower quality scores to pass
- disable tests because they fail
- remove a feature solely because it is broken unless the frozen design explicitly permits removing it
- claim visual quality without opening the result
- claim gun feel without playing it
- claim AI quality from unit tests alone
- hide defects from STATUS.md
- mark TODO as completed
- redefine "release" as "prototype"
- replace production assets with primitives near the end
- stop because a milestone was expensive

The purpose of this GOAL is the finished game.

# ============================================================
# 55. KEEP SCOPE FROZEN
# ============================================================

Do not continuously invent new features.

Polish the defined game.

No multiplayer.
No co-op.
No crafting.
No open world.
No skill tree.
No ten additional monsters.
No ten additional weapons.
No procedural loot economy.
No live service.
No multiplayer networking.
No unnecessary backend.

Depth over breadth.

The target is one exceptionally polished 35–60 minute game.

# ============================================================
# 56. FINAL ROOT-AGENT REVIEW
# ============================================================

After all implementation/reviewer agents believe the project is finished:

THE ROOT AGENT must independently:

1. reread GOAL_CONTRACT.md
2. reread QUALITY_GATES.md
3. inspect unresolved issues
4. inspect final commits
5. build release
6. launch release
7. inspect final gameplay
8. inspect final screenshots/video
9. verify final QA results
10. ensure two post-final-change successful playthroughs exist

If any criterion is uncertain:
assume it is NOT yet satisfied.

Spawn an agent to verify it.

If verification fails:
continue the GOAL.

# ============================================================
# 57. START NOW
# ============================================================

Do not respond with a proposal.

Do not merely describe what you intend to build.

Immediately begin execution.

First:

1. Ensure this is the active Codex /goal.
2. Verify root model = GPT-6 Astra at maximum reasoning.
3. Configure all subagents to GPT-6 Astra with maximum reasoning.
4. Determine and configure maximum valid parallel-agent capacity.
5. Inspect machine/environment.
6. Initialize repository.
7. Create persistent GOAL/STATUS/QUALITY files.
8. Spawn the parallel research/design team.
9. Freeze the specification.
10. Spawn environment/toolchain bootstrap agents.
11. Begin production.

Remember:

The root agent is an orchestrator, not an implementer.

Every implementation task goes to subagents.

Every significant implementation must be actually run and inspected.

Every failed review creates another iteration.

The loop continues until the GAME — not merely the code — satisfies the GOAL.

Begin now. implement this as a goal

