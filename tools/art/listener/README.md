# NULLSPACE Listener source-art candidate

This assignment supplies an original connected deformable creature surface, retained Blender cage and refined mesh, one2K PBR atlas,63 deform bones and three source clips. It does not implement AI, game movement, attacks, collision behavior or the remaining14 animations. M11 and native/independent visual acceptance remain PENDING. No final quality score is implied by asset counts or validators.

The frozen design is a roughly2.3m thin biological Listener with long articulated arms, asymmetric shoulders and a closed layered cranial structure on an off-center neck. This asset uses no copied creature, reference mesh, downloaded texture or generated concept image. Source geometry is an explicit manifold quad-dominant surface with shared shoulder sockets, perineal bridge and hand web topology. Cranial lamellae, anatomical planes and tendons are real geometry. Small tissue variation is baked from original object-space numerical fields; no lighting is painted into albedo.

## Reproduce

From this repository/worktree root, after the separately verified software bootstrap:

```sh
/home/marius/.local/share/nullspace/toolchains/blender-5.2.1/blender --background --factory-startup --threads 2 --python tools/art/listener/build_listener.py
npm ci --prefix tools/art/listener --ignore-scripts --no-audit --no-fund
node tools/art/listener/validate_export.cjs
python3 tools/art/listener/inspect_glb.py
/home/marius/.local/share/nullspace/toolchains/blender-5.2.1/blender --background --threads 2 --python tools/art/listener/validate_source.py
python3 tools/art/listener/prepare_preview.py
/home/marius/.local/share/nullspace/toolchains/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path tools/art/listener/preview --editor --import --quit
python3 tools/art/listener/record_provenance.py
```

Pinned Blender5.2.1 LTS build9e2066aef7ef includes numpy2.3.4 for the original field baker; the host structural inspector uses Python3.14.7/numpy2.4.6. `gltf-validator`2.0.0-dev.3.10 is pinned authoring tooling, not game art. A verified equivalent executable path may replace the local installation convention. Runtime never imports `.blend` or requires Blender.

The editable master is `art/source/blender/listener/listener_master.blend`. `Listener_Surface` retains the continuous original cage and subdivision controls; `Listener_Runtime` is the editable joint-looped refined surface used by source inspection and explicit export. Source review ground/lights/cameras are a labeled, non-exported diagnostic collection. Relative image paths resolve to `art/source/textures/listener`. The deterministic recipe is split into proportions, cage/socket construction, directed anatomical refinement, rig/clip authoring and UV-space tissue baking. Seed61429 is fixed.

The production candidate exports as one self-contained `art/exported/listener/listener.glb`, identically staged to `game/assets/listener`. Its local axes are Blender-Z up/-Y facing, exported to Godot-Y up/+Z facing, with applied positive metre scale and feet origin. Runtime bounds and actual counts are recorded in the manifest and structural evidence, not assumed. The current authored mesh is48,112 triangles, one material,63 bones. Godot's extracted embedded PNGs and intentional `.import`/`.uid` metadata are retained; `.godot` caches are excluded. Automatic LOD generation is intentionally disabled for the hero skin until reduced anatomy/deformation is actually reviewed.

One2K atlas has sRGB basecolor, tangent+Y normal and linear ORM(R=1,G=roughness,B=0). The original16-bit height field and encoding recipe remain available. Normal strength0.7 and matte/satin roughness are deliberate. Blender's small source subsurface response is not asserted as equivalent to Godot's standard material. Native fluorescent/flashlight evaluation remains necessary.

## Rig and clips

The63-bone hierarchy has a root/pelvis/spine/chest chain, two neck joints, head/auricles, clavicles, articulated arms with twist helpers, hands with five three-joint digits, and thighs/shins/feet/toes. Weights are normalized with at most four influences. Root-level runtime skin export avoids inherited-transform ambiguity; Blender's non-parent warning is known because a single explicitly assigned armature modifier is used, with no instances. The exported hierarchy is independently checked by the official Khronos validator.

| Clip | Duration | Intention |
| --- | --- | --- |
| idle |8s| Near-motionless observation and very restrained breath |
| breathing |6s| Thin chest expansion, slight neck response; planted feet |
| listen |9s| Anticipation, distributed neck/head inclination, long attention hold, settling |

All three have matching loop endpoints, sampled at30Hz and no root displacement. Geometry sampling verifies stationary foot vertices and records local deformation, but does not prove motion quality. Future AI/AnimationTree integration must preserve planted contacts and implement all14 remaining contract clips; the manifest lists them explicitly. The capsule in the manifest is a proposed conservative locomotion envelope only; game collision is not implemented here.

## Review

All iteration evidence is under `tools/art/listener/evidence` and linked by `listener_manifest.json`. `ITERATION_LOG.md` preserves initial local FAIL images and subsequent corrections. Source renders are CPU Cycles/2threads/24samples/AgX and are never substituted for Godot or independent review. Use the verified QA-owned native harness only after explicit GPU handoff; do not launch unleased competing native previews during performance validation.

The isolated Forward+ preview loads committed runtime data, not authoring files. Keys1–5 select body/head/hand/back/ground review positions;6–8 select idle/breathing/listen;Space pauses;Right advances one animation frame;A/D rotate the diagnostic turntable;P saves native PNG+timing/pose metadata;Esc quits. `NULLSPACE_LISTENER_CAPTURE_DIR` chooses an optional output directory. Accepted diagnostic key events are traced without logging arbitrary typed text. These controls are not the game's controls, and scripted diagnostic operation is not independent experiential campaign play.

Mandatory next checks: original-resolution native medium/close surface/silhouette, close joint deformation and clip transitions, normal/service/blackout/flashlight/red lighting, authored door/ceiling clearance, frame/memory cost, then separate adversarial review. M4 corrected native room review has priority over this secondary source-art task.
