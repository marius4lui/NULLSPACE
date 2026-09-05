#!/usr/bin/env python3
"""Original double service door. Editable bevelled panels, edge bands, bars and hinges."""
from pathlib import Path
import json
import shutil
import bpy

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "art/source/blender/doors"
EXPORT = ROOT / "art/exported/doors"
RUNTIME = ROOT / "game/assets/doors"
for directory in (SOURCE, EXPORT, RUNTIME): directory.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.scene.unit_settings.system = "METRIC"


def material(name, color, roughness, metal=0):
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*color, 1)
    result.use_nodes = True
    node = result.node_tree.nodes.get("Principled BSDF")
    node.inputs["Base Color"].default_value = (*color, 1)
    node.inputs["Roughness"].default_value = roughness
    node.inputs["Metallic"].default_value = metal
    return result


paint = material("Aged grey-green enamel", (.205, .225, .186), .62, .12)
edge = material("Worn edge band", (.16, .17, .14), .47, .35)
steel = material("Brushed hardware", (.29, .31, .285), .4, .85)
dark = material("Hinge recess", (.038, .042, .034), .85)
leaf, frame = [], []


def box(group, name, position, size, mat, bevel=.006):
    bpy.ops.mesh.primitive_cube_add(size=1, location=position)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    modifier = obj.modifiers.new("Rolled manufactured edges", "BEVEL")
    modifier.width = min(bevel, min(size) / 4)
    modifier.segments = 3
    normals = obj.modifiers.new("Weighted faces", "WEIGHTED_NORMAL")
    normals.keep_sharp = True
    group.append(obj)
    return obj


box(leaf, "Flush laminate panel", (.572, 0, 1.207), (1.144, .065, 2.414), paint)
for x in (.007, 1.137): box(leaf, "Folded edge", (x, 0, 1.207), (.014, .073, 2.414), edge, .002)
box(leaf, "CenterAstragal", (1.15, -.044, 1.207), (.04, .025, 2.414), edge, .002)
for side in (-1, 1):
    box(leaf, "Kick plate", (.572, side * .035, .19), (1.105, .008, .30), steel, .002)
    for x in (.085, 1.055):
        box(leaf, "Push bar mount", (x, side * .062, 1.10), (.08, .052, .085), edge)
    box(leaf, "Push bar", (.57, side * .092, 1.10), (.99, .037, .043), steel)
    box(leaf, "Small inspection plate", (.865, side * .036, 1.53), (.16, .009, .085), steel, .002)
    for z in (.25, 1.16, 2.12):
        box(leaf, "Hinge knuckle", (.015, side * .043, z), (.028, .031, .10), steel)
for x in (-1.21, 1.21):
    box(frame, "Steel jamb", (x, 0, 1.225), (.09, .20, 2.45), paint)
    box(frame, "Weather seal", (x + (.045 if x < 0 else -.045), -.025, 1.225), (.012, .08, 2.45), dark, .001)
box(frame, "Header", (0, 0, 2.475), (2.51, .20, .10), paint)

bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "service_door.blend"), compress=True)
for name, objects in (("door_leaf", leaf), ("door_frame", frame)):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects: obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(filepath=str(EXPORT / f"{name}.glb"), export_format="GLB", use_selection=True,
                             export_apply=True, export_yup=True, export_animations=False)
    shutil.copy2(EXPORT / f"{name}.glb", RUNTIME / f"{name}.glb")
(EXPORT / "provenance.json").write_text(json.dumps({"origin": "Original metric Blender modelling; no external content",
    "opening": [2.32, 2.43], "leaf_width": 1.144, "source": "tools/art/build_door.py"}, indent=2) + "\n")
