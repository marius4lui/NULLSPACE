# NULLSPACE environment foundation

This folder owns deterministic original environment authoring and its isolated art preview. It does not implement the production player, campaign graph, audio or objectives. M4 acceptance requires native visual review; asset validation alone is not a quality pass.

Run from the repository root:

```sh
python3 tools/art/environment/generate_textures.py
/home/marius/.local/share/nullspace/toolchains/blender-5.2.1/blender --background --factory-startup --python tools/art/environment/build_environment.py
npm ci --prefix tools/art/environment --ignore-scripts --no-audit --no-fund
node tools/art/environment/validate_exports.cjs
python3 tools/art/environment/prepare_preview.py
python3 tools/art/environment/configure_texture_imports.py --apply
/home/marius/.local/share/nullspace/toolchains/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path tools/art/environment/preview --editor --import --quit
python3 tools/art/environment/configure_texture_imports.py --check
NULLSPACE_TEXTURE_IMPORT_REPORT=/absolute/evidence/imported-resources.json /home/marius/.local/share/nullspace/toolchains/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --headless --path tools/art/environment/preview --script res://verify_texture_imports.gd
```

The exact Blender executable is a local bootstrap installation convention. Any verified Blender5.2.1 executable can run the same recipe. Host dependencies recorded by the material manifest: Python3.14.7, numpy2.4.6, Pillow12.3.0. Khronos glTF-Validator2.0.0-dev.3.10 is pinned by the local package lock and is authoring tooling only. It is not shipped in the game.

The pipeline keeps editable Blender objects, non-destructive bevel/normal modifiers, named collections, original16-bit height sources and material recipes. Runtime uses explicit glTF/binary/PNG files and never imports `.blend`. Blender image paths are relative to the master. Random seed41073 is fixed. Source and runtime PBR staging hashes are validated. No downloaded game content or generated concept image is used.

Material sources live under `art/source/textures/environment`; the editable master is `art/source/blender/architecture/nullspace_environment_m4.blend`. Separate glTF files and shared images are under `art/exported/environment`, staged identically into `game/assets/environment`.

| Module family | Physical specification | Origin / snapping |
| --- | --- | --- |
| Papered walls | 0.61/1.22/2.44/3.66m spans,160mm structure,2.72m height; rolled cove base | Left endpoint at floor, centered wall thickness |
| Opening walls | 3.66m wall with2.44m opening;2.44m wall with1.22m opening;2.45m clear height | Same wall endpoint; centered opening |
| Low service wall | 2.44m span,2.48m height | Same wall endpoint |
| Wrapped columns | 0.61m and0.86m,2.72m height; radius9mm corners and cove | Floor center |
| Ceiling board | 1.197x0.587m board for1.22x0.61m lattice;24mm stepped tegular edge | Center of underside |
| Ceiling runners | 1.22/2.44m lengths;24mm visible flange,36mm spine | Left endpoint at flange underside |
| Cove corner | Profiled and mitered outside90-degree continuation | Floor at wall centerline intersection |
| Carpet slab | 2.44x2.44m,80mm physical subfloor | Floor corner; top at0 |
| Fluorescent housings | Original recessed prismatic or exposed twin-tube variants;1.206x0.596m | Ceiling center; glTF unit axes converted to Godot |
| Louvered grille | Original607mm commercial grille with nine folded louvers and two fasteners | Center; normal faces local Blender-Y / Godot+Z |

The M4 room deliberately combines a12.2x14.64m shell, offset full-height partition, two nonuniformly placed columns, three complete architectural continuations, one wall vent and one displaced board. The board/stain area provides a sparse clue; most floor area is empty. This composition is not a campaign graph or a full set of all56 room designs. The kit can compose later narrow/wide/T/four-way/offset/open/divided/low service variants.

Wallpaper and carpet use2K maps over2.44m; mineral board and coated metal use1K over1.22m; small rubber/diffuser/fixture atlas use512px. UV0 preserves physical scale; UV2 is independently packed for any later invariant light bake. The room-specific1K macro mask only changes broad moisture/traffic/dye response; it never substitutes for tiled close-view detail. Normal maps use tangent+Y. ORM is R=AO,G=roughness,B=metallic. No baked lighting is put into base color.

Texture import is explicit, not dependent on Godot's runtime/editor3D detection. `configure_texture_imports.py` mechanically preserves existing UIDs while setting full mip chains and desktop VRAM compression: BC7 for subtle color/packed data, BC5/RGTC for normals. ORM roughness filtering uses green and its corresponding normal. Base/emission remain sRGB through material/sampler intent; normal/ORM/macro remain linear, with no Y inversion or channel permutation. All authored PNGs are unchanged by import. The verification script loads actual stored images and checks formats, mip counts, UIDs and sampled compression error; writing flags alone is not acceptance. Native visual and same-pose timing review must follow. A newly introduced texture needs its first Godot `.import` generated and retained before the explicit policy can be applied; missing metadata fails instead of inventing a UID.

Imported fixture material parts are consolidated into three surfaces for the prismatic model and two for the exposed model. A guarded512px atlas carries original steel/recess/ceramic/reflector/phosphor swatches. Emission is restricted to its phosphor cell. Runtime creates distinct state material copies without mutating imported materials. Four fixture shadows are selected by the reference manifest; the circuit/quality owner can call `set_direct_light_active` to enforce its own budget. NORMAL,WEAK,INTERMITTENT,FAILING,OFF states and `reduce_flashes` are supported. No hum asset or audio claim is supplied by this environment assignment.

For an isolated native review, use the QA-owned `tools/qa/native.py` harness after its owner hands over the GPU. Create a new run directory, pass `--method adaptive_native`, and launch the preview with `--display-driver x11 --rendering-driver vulkan --disable-vsync --max-fps 60 --resolution 1920x1080 --windowed`. An optional `NULLSPACE_M4_CAPTURE_DIR` chooses the direct viewport capture destination.

Preview controls: WASD/mouse, Shift faster, Escape releases capture, click recaptures; F toggles an inspection flashlight;1–8 select fixed review camera poses (entry, wide room, vent, damp carpet, column, fixture, cove corner, close paper);P saves an original-resolution PNG plus frame/camera/renderer/measurement metadata;L cycles all fixture states. F7/F8 toggle SSIL/SSAO, F9 disables fixture shadows, and F10 toggles TAA for rendering diagnostics. Each change/pose resets the measurement window; samples begin after3 seconds. CPU rendering setup and viewport GPU cost are measured separately from frame interval. These conveniences are labeled art diagnostics and never count as independent experiential campaign play. The production project uses its own controls.

The reference environment uses Forward+, restrained SSAO/SSIL, neutral ambient light and bounded direct fixtures. Its measurements describe the available integrated Radeon660M host only. There is no discrete-target claim and no baked switchable illumination. Full-resolution opened native images, temporal interaction evidence, source render and specific defects belong in `evidence/environment/m4/` before requesting independent acceptance.

Primary tooling references: [Blender glTF export](https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html), [Godot spatial shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html), [Godot environment properties](https://docs.godotengine.org/en/stable/classes/class_environment.html), [Khronos validator](https://github.com/KhronosGroup/glTF-Validator).
