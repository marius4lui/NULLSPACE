# NULLSPACE art direction

FROZEN art direction, 2026-09-04; research A–I incorporated and independent design-readiness audit PASS at c737443. Binding detailed requirements in GOAL_CONTRACT.md. All production art/audio original with editable source and provenance. Create commercial credibility through materials, proportions and restrained imperfections, then disturb spatial continuity.

## Palette and architecture

Wall surfaces pale cream and faded nicotine beige; carpet brown-grey/mustard-beige; ceiling dirty off-white; baseboards brown; shadows slightly grey-green. Fluorescent illumination provides much of the yellow cast. Red Threshold introduces desaturated red oxide and dark brown, not arcade red. No globally saturated filter or crushed blacks in normally lit sectors. Keep camera postprocessing subtle and optional where it affects comfort.

Primary ceiling lattice approximately0.61x1.22m, occasional square subdivisions, mineral-fiber fissures/stains, thin recessed/exposed grid and fixture variants. Ceiling height around2.6m normally, controlled lower service soffits compatible with creature clearance. Walls thick, credible baseboards and beveled panel/jamb edges. Architecture kit covers every contract straight/narrow/wide/intersection/offset/open-column/divided/dead-end/double-back/low/long/service/breaker/blackout/red/anomaly variant; compose irregular spaces from modules rather than reuse complete identical rooms.

Wallpaper tile pattern is original and quiet: woven small-scale geometric motif, seams, fading, subtle raised bubbles and discoloration. Carpet shows directional fiber/compression/repair, damp darker flattened areas with slight grazing sheen, occasional stains. Ceiling variation is mostly restrained; missing/misaligned panels and failing fixtures rare. Dirt follows use/air/water, not random grunge everywhere. Most rooms contain no props. Original chair, folding table, cart, cabinet/breaker, vent, cup, telephone, small sign and unplugged fan are sparse landmarks, never clutter blanket.

## Listener design brief

Approximately2.3m tall, thin anatomically connected body, long articulated arms, mildly asymmetric shoulder girdle and biological but unreadable cranial profile. Develop an original closed layered auricular/cranial structure and off-center neck posture; avoid tendril stick-figure silhouette, giant mouth/eyes, copied SCP or franchise anatomy. Skin has matte/satin thin tissue and subtle fluorescent response; no glowing tracking eyes. Near-motionless listening contrasts with purposeful planted steps and legible accelerating chase. No teleport-like motion.

One cohesive deformable original mesh with deliberate elbow/shoulder/hip topology, UVs, rig, collision and documented envelope. Initial50–70 deform bones, normalized four-influence weights. Original17 clips: idle, breathing, listen, slow_walk, stalk_walk, turn, chase_run, door_interaction, investigate, search, flinch_front, flinch_side, heavy_stagger, attack, recovery, retreat_injured, final_sequence. Match foot speed to locomotion and hold contact through blends. Check door/ceiling clearance before polishing. Final death/incapacitation or withdrawal must be physically readable.

## Weapons and hands

Industrial original compact pistol and pump shotgun with coherent fasteners, machining, polymer/painted-metal/rubber response and subtle use. No real manufacturer's trademarks or copied model geometry. Separate pivots for slide/magazine/trigger/bolt/pump/shell and defined muzzle/ejection/grip sockets. Shared articulated original hand/forearm rig, fingers contact grip/trigger/magazine/shell/pump. Mechanical contacts and empty states need close first-person temporal inspection. Lighting must integrate weapon and hands into scene. Excessive cosmetic motion is not a substitute for mechanics.

## Sources, maps and budgets

Pinned Blender5.2.1 LTS; .blend masters with editable controls/modifiers retained. Deterministic Python generation plus bake/validate/export stages. Original maps basecolor, tangent normal(+Y), ORM(R=AO/G=roughness/B=metallic); color/data spaces correct. No baked light in albedo. Stable triangulation before baking/export, consistent UV density/padding, UV2 for actual lightmapped meshes. Start512texels/m with tiling microdetail; use2K where close inspection justifies,1K/512 for small assets; atlas sparse props where useful.

Initial LOD0 targets: structure200–5000 triangles/module, prop300–12000, pistol20–35K, shotgun25–45K, hands20–30K, Listener30–50K. Shared environment materials1–3/module, props1–2, hero weapons2–3, creature1–2. These are budgets to test, not quality proofs. Use reviewed LOD where meaningful; protect hero/skin deformation. Group repeated assets locally for culling. Never ship visible default primitives or flat procedural placeholders as final art.

## Lighting/VFX/audio identity

Fixtures NORMAL/WEAK/INTERMITTENT/FAILING/OFF, rare irregular restrained flicker with flash-reduction setting. Well-lit empty space can be frightening. Blackout preserves familiar construction while most hum and light disappear. Flashlight beam/spill and material response provide grounded reading. Brief weapon flash, dust/plaster/metal/carpet impacts, original bullet marks, finite casing sounds. No heavy VHS/grain/chromatic filter, excessive bloom or constant volumetric fog.

Original synthesized audio is a production asset pipeline alongside art; all stems/recipes retained. Six spatial ballast families, HVAC, mechanical room tone and remote ambiguous impacts. Creature/player/weapon movement audible with direction/distance. Blackout removes hum without gain compensation. Use48kHz lossless sources, separate dry/mechanical/room layers, initial32 voice budget and measured headroom. No downloaded impulse responses. Production/listening requirements: evidence/research/G-H-audio-qa-research.md.

## Original typography and UI

Create a restrained readable original project font with editable glyph outlines, spacing/kerning, full shipped-character coverage and reproducible export. Original NULLSPACE wordmark/cursor/boot image/icons and menu/HUD/sign artwork; source under art/source/ui, exports through asset manifest. Explicit Theme; inspect missing-glyph/system fallbacks so no default or third-party font renders in production. Font-building/rendering software is tooling, not supplied glyph art. Record source/recipe/version/hash/creator/review for every visual UI asset. Quiet spacing, clear keyboard/mouse focus, readable contrast and complete accessibility settings; no placeholder final UI. Exact engine/software notices remain shipped separately.

## Acceptance

Inspect close first-person surfaces, full weapon action cycles and Listener movement under normal fluorescent, service, blackout, flashlight and red conditions. Verify scale, seams, normals, missing maps, bevels, silhouette, deformation, contacts and frame cost. Every visual milestone captures the ten contract views at full resolution. Independent scoring>=8 milestone/>=9 final per category, with concrete justification. Anything below threshold is a mandatory correction, never a documentation pass.
