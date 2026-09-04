# Next production assignments

Orchestration acceptance contracts, not implementation or scope changes. Frozen goal/design/art/gates remain authoritative. Assign a named Astra/max owner and isolated `agent/…` worktree before writing. No parallel source ownership; dependencies may not be represented as accepted before independent review and sequential integration.

## M3 — grounded player foundation

Ownership: `game/player/`, player-owned tuning resources/scenes and `game/tests/player/`; diagnostic-only controls/geometry stay outside production launch. Consume reviewed core interfaces without editing core, weapons, AI or production UI. Request changes from the owning agent if an interface cannot meet the contract.

Deliver collision-aware CharacterBody locomotion, walk/crouch/sprint/stamina, posture clearance, camera/look/settings, flashlight beam/spill, interaction targeting and health/death hooks. No jump, ADS or battery mechanic unless frozen-design conditional permission is justified. These are not final weapon handling or full game acceptance.

Required evidence:

- Real native controls show approximately3.4/1.8/5.4m/s, normalized diagonal movement and responsive acceleration/braking; compare displacement against time rather than frame count.
- Wall corners, narrow doors, low ceilings and legal slopes do not snag, tunnel or force standing through solid geometry. Crouch can stay blocked without camera/body disagreement.
- Stamina depletes/replenishes consistently; exhausted sprint transitions safely; pausing/loading does not advance player simulation or emit footsteps.
- All gameplay controls consume InputGate. Capture/focus loss, pause/menu/settings/death/load and held-click/key resume cannot leak movement/actions. Mouse displacement is frame-rate-independent and sensitivity/invert apply once.
- Recalculate the88° horizontal-equivalent default with aspect. FOV/sensitivity/invert, head-bob and shake reductions apply live and after reload; zero motion removes the corresponding additive movement.
- Flashlight has readable focused beam and soft spill, respects wall occlusion, is not a monster stun and exposes only a visual-exposure contribution for perception. Show fluorescent and dark diagnostic conditions without implying final art.
- Interaction is range/LOS constrained, context follows the actual target, and an action cannot operate through a wall or run twice because of repeat events. Door/relay owner remains separate.
- First serious hit at full health permits escape; subsequent death invalidates actions and uses GameFlow. Checkpoint participant restores living health/stamina/light state at an externally validated anchor.
- Native temporal captures at30/60/120Hz where hardware permits, collision/state tests, error-free import/export and independent non-implementer play review. State unavailable frame-rate evidence honestly.

No final-feeling claim until controls are actually operated and temporal response reviewed; no acceptance from movement constants alone.

## M6 — evidence-driven creature/navigation vertical slice

Ownership: `game/ai/`, `game/world/room_graph/`, `game/world/doors/`, their tuning resources and `game/tests/ai/`. Do not edit player/core or Listener production assets. Diagnostic representation must be visibly labelled and excluded from release art paths.

Deliver a small authored connected scenario with real occluding walls, junctions, at least two routes and tactical door state. Implement room/portal acoustic propagation, visual sensing, dated uncertain observations, decaying evidence memory, utility/HFSM intent and safe local navigation. Full pacing/animation integration belongs to subsequent bounded assignments; preserve their interfaces.

Required evidence:

- Only perception/acoustic adapters access observation truth. Planner/memory receive no player reference, live transform or raw unattenuated sound. Intent records evidence IDs/reason; no new observation renews itself.
- Vision respects distance, FOV, real LOS, posture, motion and approximate exposure. Occluded player means no new visual evidence; flashlight slightly modifies exposure, never grants wall sight.
- Room/portal sound uses positive path costs, age/type/intensity and closed-door attenuation. Multiple routes do not duplicate one sound into repeated certainty. User audio-volume settings cannot alter gameplay hearing.
- Hearing produces an estimated region/position with uncertainty. A gunshot then quiet relocation sends the creature to the credible old evidence, never the new hidden position.
- Visual loss leads to last credible location and plausible junction/adjacent-room search with listening pauses. Absolute evidence strength decays independently of normalized candidate probabilities; search ends when evidence expires.
- Paired runs with identical observations and different hidden-player routes produce equivalent decisions until actual new evidence. This is a mandatory anti-cheat test, not optional debugging.
- One authoritative door state controls collision/LOS/acoustics/navigation. Closed openable doors are tactical actions, locked doors unavailable; no automatic nav edge bridges through a closed wall or door. Creature opens before physically crossing, with state-appropriate timing hooks.
- Stagger interrupts permitted actions, invalidates stale callbacks and recovers navigation; attacks require range, LOS and readable windup/recovery. Standard first hit is not an instant kill.
- Repeated contract scenarios: wall occlusion; adjacent pistol; fire then relocate; nearby sprint; distant crouch; break chase LOS; route change during search; closed door; gunshot during stalk; stagger/recovery.
- Native operation of the scenario and independent actual review must corroborate telemetry and tests. Debug cone, evidence/search targets and portal graph exist only in development; actual hidden-player truth must not guide an independent reviewer live.

## Sequential integration and review ownership

The integration agent accepts one independently reviewed feature at a time, preserves frozen hashes and root governance updates, then builds, runs relevant regression tests, launches native and inspects changed behavior before taking another branch. A failure stops that integration and opens a correction task. M0/native infrastructure must be usable; core M2 is the first runtime foundation. M3 and M6 can proceed concurrently once their shared reviewed interfaces are available. M4 remains a separate art/performance acceptance, not a precondition for logical AI work.

Reviewers must not have implemented the reviewed feature. Root cannot take over an implementation task to shorten a queue. A retained worker may change roles on a new isolated assignment, but never independently approve its own feature. Candidate dependency or diagnostic export is never a release.
