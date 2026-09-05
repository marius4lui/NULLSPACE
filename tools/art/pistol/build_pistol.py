#!/usr/bin/env python3
"""Original compact pistol, gloved hands, pickup case and casing. No imported content.

Blender 5.2.1 --background --factory-startup --python tools/art/pistol/build_pistol.py
Metric source: Blender +Y muzzle, +Z up; exported Godot -Z muzzle, +Y up.
"""
from pathlib import Path
import json
import math
import shutil
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "art/source/blender/pistol"
EXPORT = ROOT / "art/exported/pistol"
RUNTIME = ROOT / "game/assets/pistol"
for folder in (SOURCE, EXPORT, RUNTIME):
    folder.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.context.scene.unit_settings.system = "METRIC"
bpy.context.scene.unit_settings.scale_length = 1.0
parts = {}


def material(name, color, metal=0.0, rough=0.6):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = (*color, 1)
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Roughness"].default_value = rough
    return mat


steel = material("Blued satin steel", (0.095, 0.105, 0.11), 0.82, 0.34)
edge = material("Burnished edge steel", (0.22, 0.24, 0.25), 0.87, 0.32)
polymer = material("Graphite polymer", (0.037, 0.043, 0.038), 0.0, 0.83)
rubber = material("Grip inset", (0.018, 0.021, 0.018), 0.0, 0.93)
dark = material("Recesses", (0.007, 0.009, 0.007), 0.25, 0.72)
brass = material("Spent brass", (0.52, 0.32, 0.085), 0.78, 0.35)
cloth = material("Washed charcoal gloves", (0.026, 0.034, 0.030), 0.0, 0.96)
seam = material("Glove seams", (0.065, 0.080, 0.060), 0.0, 0.95)
cuff = material("Ochre work jacket", (0.24, 0.235, 0.19), 0.0, 0.96)
white = material("Aged sight paint", (0.61, 0.66, 0.46), 0.0, 0.7)
case_mat = material("Old utility case", (0.13, 0.16, 0.12), 0.35, 0.7)


def finish(obj, group, mat, bevel=0.001):
    obj.data.materials.append(mat)
    if bevel:
        modifier = obj.modifiers.new("Manufactured edge radius", "BEVEL")
        modifier.width = bevel
        modifier.segments = 3
        modifier.affect = "EDGES"
        modifier = obj.modifiers.new("Face weighted normals", "WEIGHTED_NORMAL")
        modifier.keep_sharp = True
    parts.setdefault(group, []).append(obj)
    return obj


def box(name, center, size, group, mat, bevel=0.001, rotation=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if rotation:
        obj.rotation_euler = rotation
    return finish(obj, group, mat, bevel)


def profile(name, yz, half_width, group, mat, bevel=0.0015):
    verts = [(x, y, z) for x in (-half_width, half_width) for y, z in yz]
    count = len(yz)
    faces = [tuple(reversed(range(count))), tuple(range(count, count * 2))]
    faces += [(i, (i + 1) % count, (i + 1) % count + count, i + count) for i in range(count)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return finish(obj, group, mat, bevel)


def ring(name, center, radius, inner, length, group, mat):
    count = 24
    verts = [(center[0] + r * math.cos(i * math.tau / count), center[1] + y,
              center[2] + r * math.sin(i * math.tau / count))
             for y, r in ((-length / 2, radius), (length / 2, radius),
                          (length / 2, inner), (-length / 2, inner)) for i in range(count)]
    faces = []
    for row in range(4):
        for i in range(count):
            faces.append((row * count + i, row * count + (i + 1) % count,
                          ((row + 1) % 4) * count + (i + 1) % count,
                          ((row + 1) % 4) * count + i))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    return finish(obj, group, mat, 0.0004)


def segment(name, start, end, width, group, mat):
    midpoint = (Vector(start) + Vector(end)) / 2
    direction = Vector(end) - Vector(start)
    if group in ("RightHand", "LeftHand"):
        # Soft tailored volumes instead of the visibly faceted block fingers from native-01.
        rings = [(-0.5, 0.10), (-0.46, 0.65), (-0.32, 1), (0.32, 1), (0.46, 0.65), (0.5, 0.10)]
        length = direction.length + width * 0.4
        verts = [(math.cos(i * math.tau / 16) * width * 0.5 * radius,
                  math.sin(i * math.tau / 16) * width * 0.43 * radius, along * length)
                 for along, radius in rings for i in range(16)]
        faces = [(r * 16 + i, r * 16 + (i + 1) % 16,
                  (r + 1) * 16 + (i + 1) % 16, (r + 1) * 16 + i)
                 for r in range(len(rings) - 1) for i in range(16)]
        faces += [tuple(reversed(range(16))), tuple(range(80, 96))]
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(verts, [], faces)
        mesh.update()
        for face in mesh.polygons:
            face.use_smooth = True
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        obj.location = midpoint
        obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
        return finish(obj, group, mat, 0)
    obj = box(name, midpoint, (width, width * 0.84, direction.length + width * 0.3),
              group, mat, width * 0.35)
    obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    return obj


# Upper assembly. A narrow distinct top rail, open barrel mouth and rear sight gap.
box("Slide", (0, 0.043, 0.10), (0.032, 0.196, 0.031), "Slide", steel, 0.003)
box("Top flat", (0, 0.046, 0.116), (0.024, 0.174, 0.003), "Slide", steel, 0.0007)
box("Ejection recess", (0.0162, 0.035, 0.103), (0.0008, 0.028, 0.015), "Slide", dark, 0.001)
box("Chamber face", (0.0168, 0.037, 0.101), (0.0008, 0.023, 0.008), "Slide", edge, 0.0005)
for side in (-1, 1):
    for i in range(8):
        box("Rear slide serration", (side * 0.0162, -0.036 + i * 0.0032, 0.103),
            (0.0013, 0.001, 0.022), "Slide", dark, 0.0002)
    box("Rear sight wing", (side * 0.0065, -0.043, 0.122), (0.006, 0.009, 0.006), "Slide", dark)
    box("Rear sight paint", (side * 0.0065, -0.0478, 0.122), (0.002, 0.0006, 0.002), "Slide", white, 0.0003)
box("Front sight", (0, 0.119, 0.123), (0.004, 0.009, 0.007), "Slide", dark)
box("Front sight dot", (0, 0.1139, 0.123), (0.0022, 0.0006, 0.003), "Slide", white, 0.0003)
ring("Muzzle crown", (0, 0.142, 0.101), 0.008, 0.0053, 0.005, "Frame", edge)
ring("Bore", (0, 0.135, 0.101), 0.0053, 0.0048, 0.018, "Frame", dark)
box("Recoil guide", (0, 0.136, 0.083), (0.008, 0.011, 0.007), "Frame", dark, 0.003)
profile("Lower receiver", [(-0.056, 0.088), (0.137, 0.084), (0.13, 0.068), (0.023, 0.06),
                          (-0.005, 0.069), (-0.05, 0.065)], 0.015, "Frame", polymer)
profile("Angled grip", [(-0.052, 0.078), (0.005, 0.068), (-0.003, -0.041),
                       (-0.05, -0.042), (-0.068, 0.028)], 0.0155, "Frame", polymer, 0.003)
for side in (-1, 1):
    box("Grip panel", (side * 0.0158, -0.029, 0.014), (0.002, 0.038, 0.079), "Frame", rubber, 0.001)
    for i in range(13):
        box("Grip molded texture", (side * 0.0171, -0.03, -0.019 + i * 0.005),
            (0.0007, 0.031, 0.0011), "Frame", polymer, 0.0002)
box("Magazine heel", (0, -0.027, -0.043), (0.034, 0.046, 0.006), "Magazine", polymer, 0.0014)
box("Magazine body", (0, -0.026, -0.003), (0.022, 0.034, 0.078), "Magazine", steel)
# Guard is an actual open loop, not a solid box.
segment("Guard front", (0, 0.059, 0.07), (0, 0.058, 0.034), 0.007, "Frame", polymer)
segment("Guard bottom", (0, 0.058, 0.034), (0, 0.0, 0.035), 0.007, "Frame", polymer)
segment("Trigger", (0, 0.022, 0.068), (0, 0.033, 0.042), 0.004, "Frame", edge)
box("Slide stop", (-0.0165, -0.013, 0.080), (0.003, 0.027, 0.004), "Frame", edge)
box("Magazine catch", (-0.017, -0.006, 0.060), (0.003, 0.007, 0.007), "Frame", dark)

# Gloved firing hand. Authored contact pose; segmented mesh fingers follow the grip.
segment("Right palm", (0.010, -0.065, -0.017), (0.010, -0.058, 0.041), 0.062, "RightHand", cloth)
segment("Right wrist", (0.028, -0.06, -0.018), (0.055, -0.16, -0.039), 0.045, "RightHand", cloth)
segment("Right sleeve", (0.055, -0.15, -0.039), (0.085, -0.32, -0.072), 0.066, "RightHand", cuff)
for i in range(3):
    z = 0.027 - i * 0.019
    segment("Finger knuckle", (0.037, -0.005, z), (0.015, 0.014, z), 0.015, "RightHand", cloth)
    segment("Finger curl", (0.015, 0.014, z), (-0.016, 0.004, z), 0.014, "RightHand", cloth)
    segment("Finger seam", (0.034, 0.001, z + 0.006), (0.013, 0.018, z + 0.006), 0.002, "RightHand", seam)
segment("Trigger finger", (0.032, -0.013, 0.055), (0.025, 0.036, 0.054), 0.014, "RightHand", cloth)
segment("Trigger fingertip", (0.025, 0.036, 0.054), (0.005, 0.038, 0.052), 0.012, "RightHand", cloth)
segment("Right thumb", (0.023, -0.06, 0.039), (-0.02, -0.013, 0.057), 0.017, "RightHand", cloth)
# Support hand wraps under/front of firing hand and drops during reload.
segment("Support palm", (-0.042, -0.03, 0.010), (-0.038, 0.008, 0.019), 0.043, "LeftHand", cloth)
segment("Support wrist", (-0.043, -0.035, -0.008), (-0.088, -0.15, -0.056), 0.044, "LeftHand", cloth)
segment("Support sleeve", (-0.088, -0.14, -0.056), (-0.15, -0.31, -0.08), 0.065, "LeftHand", cuff)
for i in range(3):
    z = 0.02 - i * 0.017
    segment("Support finger", (-0.04, 0.014, z), (0.003, 0.025, z), 0.014, "LeftHand", cloth)
segment("Support thumb", (-0.036, -0.021, 0.032), (-0.024, 0.023, 0.060), 0.016, "LeftHand", cloth)

# A small physical utility case carries the pickup; untextured placeholders are not used.
box("Case body", (0, 0, 0.035), (0.37, 0.25, 0.07), "Case", case_mat, 0.016)
box("Case lid seam", (0, 0, 0.061), (0.372, 0.252, 0.004), "Case", dark, 0.008)
for x in (-0.12, 0.12):
    box("Case clasp", (x, -0.127, 0.050), (0.025, 0.01, 0.037), "Case", edge, 0.002)
segment("Case handle", (-0.056, -0.15, 0.032), (0.056, -0.15, 0.032), 0.014, "Case", polymer)
for x in (-0.056, 0.056):
    segment("Handle mount", (x, -0.125, 0.032), (x, -0.15, 0.032), 0.014, "Case", polymer)
ring("Casing wall", (0, 0, 0), 0.0048, 0.0042, 0.018, "Casing", brass)
box("Casing primer", (0, -0.009, 0), (0.006, 0.001, 0.006), "Casing", edge, 0.0025)


def join_group(name):
    bpy.ops.object.select_all(action="DESELECT")
    for obj in parts[name]:
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        for modifier in list(obj.modifiers):
            bpy.ops.object.modifier_apply(modifier=modifier.name)
    bpy.context.view_layer.objects.active = parts[name][0]
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    # Unique editable UVs, even though the compact kit uses physical material finishes.
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(island_margin=0.015)
    bpy.ops.object.mode_set(mode="OBJECT")
    return obj


objects = {name: join_group(name) for name in parts}
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "nullspace_pistol.blend"))
for filename, names in {"pistol": ["Frame", "Slide", "Magazine", "RightHand", "LeftHand"],
                        "pistol_case": ["Case"], "pistol_casing": ["Casing"]}.items():
    bpy.ops.object.select_all(action="DESELECT")
    for name in names:
        objects[name].select_set(True)
    target = EXPORT / (filename + ".glb")
    bpy.ops.export_scene.gltf(filepath=str(target), export_format="GLB", use_selection=True,
                             export_yup=True, export_animations=False, export_apply=True)
    shutil.copy2(target, RUNTIME / target.name)
summary = {"source": "Original scripted Blender mesh by NULLSPACE project; no external assets",
           "blender": bpy.app.version_string, "units": "metres", "muzzle_godot": [0, 0.101, -0.147],
           "nodes": {name: {"vertices": len(obj.data.vertices), "polygons": len(obj.data.polygons)}
                     for name, obj in objects.items()}}
(EXPORT / "provenance.json").write_text(json.dumps(summary, indent=2) + "\n")
print("NULLSPACE_PISTOL_ASSET", json.dumps(summary))
