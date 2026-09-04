#!/usr/bin/env python3
"""Build original metric NULLSPACE architecture, editable masters and glTF assets.

Run: blender --background --factory-startup --python tools/art/environment/build_environment.py
Optional -- --render renders a source-review still using CPU Cycles.
"""

from __future__ import annotations

import hashlib
import json
import math
import os
from pathlib import Path
import random
import shutil
import sys

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "art/source/blender/architecture"
EXPORT = ROOT / "art/exported/environment"
RUNTIME = ROOT / "game/assets/environment"
TEXTURES = ROOT / "art/source/textures/environment"
EVIDENCE = ROOT / "evidence/environment/m4"
SEED = 41073
REVISION = "environment-kit-1.0"
HEIGHT = 2.72
MATERIALS: dict[str, bpy.types.Material] = {}
ATLAS_REGIONS: dict[str, int] = {"fastener": 0, "recess": 1, "reflector": 2, "ceramic": 3,
                                "lamp_phosphor": 4, "lamp_unpowered": 5}
MODULES: dict[str, list[bpy.types.Object]] = {}
METADATA: dict = {"revision": REVISION, "seed": SEED, "meters_per_unit": 1.0, "modules": {}, "fixtures": []}


def collection(name: str) -> bpy.types.Collection:
    result = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(result)
    return result


def material(name: str, base: tuple | None = None, metal: float = 0.0,
             rough: float = 0.7, emission: float = 0.0) -> bpy.types.Material:
    result = bpy.data.materials.new(name)
    if not result.node_tree:
        result.use_nodes = True
    nodes = result.node_tree.nodes
    principled = nodes.get("Principled BSDF")
    principled.inputs["Roughness"].default_value = rough
    principled.inputs["Metallic"].default_value = metal
    if base:
        principled.inputs["Base Color"].default_value = (*base, 1)
        result.diffuse_color = (*base, 1)
    else:
        for role in ("basecolor", "normal", "orm"):
            tex = nodes.new("ShaderNodeTexImage")
            tex.name = f"{name}_{role}"
            tex.image = bpy.data.images.load(str(TEXTURES / name / f"{name}_{role}.png"), check_existing=True)
            tex.interpolation = "Linear"
            if role != "basecolor":
                tex.image.colorspace_settings.name = "Non-Color"
            if role == "basecolor":
                attribute = nodes.new("ShaderNodeVertexColor")
                attribute.layer_name = "AgeTint"
                multiply = nodes.new("ShaderNodeMixRGB")
                multiply.blend_type = "MULTIPLY"
                multiply.inputs["Fac"].default_value = 1.0
                result.node_tree.links.new(tex.outputs["Color"], multiply.inputs[1])
                result.node_tree.links.new(attribute.outputs["Color"], multiply.inputs[2])
                result.node_tree.links.new(multiply.outputs["Color"], principled.inputs["Base Color"])
            elif role == "normal":
                normal = nodes.new("ShaderNodeNormalMap")
                normal.inputs["Strength"].default_value = 0.8
                result.node_tree.links.new(tex.outputs["Color"], normal.inputs["Color"])
                result.node_tree.links.new(normal.outputs["Normal"], principled.inputs["Normal"])
            else:
                separate = nodes.new("ShaderNodeSeparateColor")
                result.node_tree.links.new(tex.outputs["Color"], separate.inputs["Color"])
                result.node_tree.links.new(separate.outputs["Green"], principled.inputs["Roughness"])
                result.node_tree.links.new(separate.outputs["Blue"], principled.inputs["Metallic"])
    if emission:
        principled.inputs["Emission Color"].default_value = (*base, 1)
        principled.inputs["Emission Strength"].default_value = emission
    MATERIALS[name] = result
    return result


def uv_project(obj: bpy.types.Object, meters: float = 2.44) -> None:
    mesh = obj.data
    uv = mesh.uv_layers.new(name="UVMap")
    for polygon in mesh.polygons:
        normal = polygon.normal
        dominant = max(range(3), key=lambda index: abs(normal[index]))
        for loop_index in polygon.loop_indices:
            position = mesh.vertices[mesh.loops[loop_index].vertex_index].co
            if dominant == 2:
                result = (position.x / meters, position.y / meters)
            elif dominant == 1:
                result = (position.x / meters, position.z / meters)
            else:
                result = (position.y / meters, position.z / meters)
            uv.data[loop_index].uv = result


def mesh_object(name: str, verts: list, faces: list, mat: str,
                group: bpy.types.Collection, bevel: float = 0.0,
                uv_meters: float = 2.44) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(f"{name}_editable_mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    age = mesh.color_attributes.new(name="AgeTint", type="FLOAT_COLOR", domain="CORNER")
    for corner in age.data:
        corner.color = (1, 1, 1, 1)
    obj = bpy.data.objects.new(name, mesh)
    group.objects.link(obj)
    mesh.materials.append(MATERIALS["fixture_detail"] if mat in ATLAS_REGIONS else MATERIALS[mat])
    uv_project(obj, uv_meters)
    if mat in ATLAS_REGIONS:
        atlas_region(obj, mat)
    if bevel:
        modifier = obj.modifiers.new("Manufactured edge radius", "BEVEL")
        modifier.width = bevel
        modifier.segments = 3
        modifier.limit_method = "ANGLE"
        modifier.affect = "EDGES"
        modifier.harden_normals = True
        weighted = obj.modifiers.new("Face-weighted corner normals", "WEIGHTED_NORMAL")
        weighted.keep_sharp = True
        weighted.weight = 50
        for polygon in mesh.polygons:
            polygon.use_smooth = True
    obj["authoring_recipe"] = REVISION
    obj["source_seed"] = SEED
    return obj


def atlas_region(obj: bpy.types.Object, material_name: str) -> None:
    row, column = divmod(ATLAS_REGIONS[material_name], 2)
    obj["atlas_region"] = material_name
    uv = obj.data.uv_layers[0].data
    for polygon in obj.data.polygons:
        values = [uv[index].uv.copy() for index in polygon.loop_indices]
        minimum = Vector((min(value.x for value in values), min(value.y for value in values)))
        maximum = Vector((max(value.x for value in values), max(value.y for value in values)))
        span = maximum - minimum
        for loop_index in polygon.loop_indices:
            point = uv[loop_index].uv - minimum
            u = point.x / max(span.x, 0.000001)
            v = point.y / max(span.y, 0.000001)
            uv[loop_index].uv = ((column + 0.20 + u * 0.60) / 2,
                                1.0 - (row + 0.20 + v * 0.60) / 4)


def box(name: str, center: tuple, dimensions: tuple, mat: str, group: bpy.types.Collection,
        bevel: float = 0.004, uv_meters: float = 2.44) -> bpy.types.Object:
    x, y, z = center
    a, b, c = (dimension * 0.5 for dimension in dimensions)
    verts = [(x - a, y - b, z - c), (x + a, y - b, z - c), (x + a, y + b, z - c), (x - a, y + b, z - c),
             (x - a, y - b, z + c), (x + a, y - b, z + c), (x + a, y + b, z + c), (x - a, y + b, z + c)]
    faces = [(0, 3, 2, 1), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7), (4, 5, 6, 7)]
    safe_bevel = min(bevel, min(dimensions) * 0.24)
    return mesh_object(name, verts, faces, mat, group, safe_bevel, uv_meters)


def extrusion(name: str, length: float, profile: list[tuple[float, float]], mat: str,
              group: bpy.types.Collection, bevel: float = 0.0015) -> bpy.types.Object:
    verts = [(0, y, z) for y, z in profile] + [(length, y, z) for y, z in profile]
    count = len(profile)
    faces = [tuple(reversed(range(count))), tuple(range(count, count * 2))]
    faces.extend((index, (index + 1) % count, (index + 1) % count + count, index + count) for index in range(count))
    return mesh_object(name, verts, faces, mat, group, bevel, 1.22)


def cylinder(name: str, center: tuple, radius: float, length: float, mat: str,
             group: bpy.types.Collection, sides: int = 16, axis: str = "X") -> bpy.types.Object:
    verts = []
    for end in (-0.5, 0.5):
        for index in range(sides):
            theta = index * math.tau / sides
            coord = (length * end, radius * math.cos(theta), radius * math.sin(theta))
            if axis == "Z":
                coord = (coord[1], coord[2], coord[0])
            verts.append(tuple(center[i] + coord[i] for i in range(3)))
    faces = [tuple(reversed(range(sides))), tuple(range(sides, sides * 2))]
    faces.extend((i, (i + 1) % sides, (i + 1) % sides + sides, i + sides) for i in range(sides))
    return mesh_object(name, verts, faces, mat, group, 0.0007, 1.22)


def cove_base(name: str, length: float, side: float, group: bpy.types.Collection) -> bpy.types.Object:
    # A real coved floor return, straight face, and softly rolled 3mm upper edge.
    profile = [(0.082, 0.001), (0.104, 0.001), (0.104, 0.004), (0.093, 0.009),
               (0.087, 0.02), (0.086, 0.035), (0.086, 0.098), (0.085, 0.105),
               (0.082, 0.108), (0.080, 0.105), (0.080, 0.001)]
    if side < 0:
        profile = [(-y, z) for y, z in reversed(profile)]
    return extrusion(name, length, profile, "baseboard", group, 0.0008)


def cove_corner(name: str, group: bpy.types.Collection) -> bpy.types.Object:
    """Mitered outside90 corner: fills the wall-center-to-outside-face returns."""
    profile = [(0.082, 0.001), (0.104, 0.001), (0.104, 0.004), (0.093, 0.009),
               (0.087, 0.02), (0.086, 0.035), (0.086, 0.098), (0.085, 0.105),
               (0.082, 0.108), (0.080, 0.105), (0.080, 0.001)]
    verts = []
    for distance, height in profile:
        verts.extend([(0, -distance, height), (distance, -distance, height), (distance, 0, height)])
    faces = []
    for index in range(len(profile)):
        following = (index + 1) % len(profile)
        for span in (0, 1):
            faces.append((index * 3 + span, index * 3 + span + 1, following * 3 + span + 1, following * 3 + span))
    faces.append(tuple(index * 3 for index in reversed(range(len(profile)))))
    faces.append(tuple(index * 3 + 2 for index in range(len(profile))))
    return mesh_object(name, verts, faces, "baseboard", group, 0.00015, 1.22)


def wall(name: str, length: float, group: bpy.types.Collection,
         height: float = HEIGHT, portal: float = 0.0) -> list[bpy.types.Object]:
    pieces = []
    if portal:
        pier = (length - portal) / 2
        for left in (0, length - pier):
            pieces.append(box(f"{name}_Pier", (left + pier / 2, 0, height / 2), (pier, 0.16, height), "wallpaper", group, 0.005))
            for side in (-1, 1):
                base = cove_base(f"{name}_Cove", pier, side, group)
                base.location.x = left
                pieces.append(base)
        pieces.append(box(f"{name}_Lintel", (length / 2, 0, (2.45 + height) / 2), (portal + 0.012, 0.16, height - 2.45), "wallpaper", group, 0.005))
        # Papered returns are supported by a small painted corner bead, not floating trim.
        for x in (pier, length - pier):
            pieces.append(box(f"{name}_JambBead", (x, -0.084, 1.226), (0.018, 0.012, 2.452), "painted_metal", group, 0.002, 1.22))
        pieces.append(box(f"{name}_HeaderBead", (length / 2, -0.084, 2.449), (portal + 0.02, 0.012, 0.016), "painted_metal", group, 0.002, 1.22))
    else:
        pieces.append(box(f"{name}_PaperedShell", (length / 2, 0, height / 2), (length, 0.16, height), "wallpaper", group, 0.005))
        pieces.extend(cove_base(f"{name}_Cove", length, side, group) for side in (-1, 1))
    return pieces


def tile(name: str, width: float, depth: float, group: bpy.types.Collection) -> bpy.types.Object:
    # Tegular board: dropped face, stepped bearing lip and full-thickness edge.
    verts = []
    for inset, z in ((0.008, 0.0), (0.0, 0.006), (0.0, 0.024)):
        verts.extend([(-width / 2 + inset, -depth / 2 + inset, z),
                      (width / 2 - inset, -depth / 2 + inset, z),
                      (width / 2 - inset, depth / 2 - inset, z),
                      (-width / 2 + inset, depth / 2 - inset, z)])
    faces = [(3, 2, 1, 0), (8, 9, 10, 11)]
    for layer in (0, 4):
        faces.extend((layer + i, layer + (i + 1) % 4, layer + (i + 1) % 4 + 4, layer + i + 4) for i in range(4))
    return mesh_object(name, verts, faces, "ceiling", group, 0.0012, 1.22)


def grid_runner(name: str, length: float, group: bpy.types.Collection) -> bpy.types.Object:
    profile = [(-0.012, 0.0), (0.012, 0.0), (0.012, 0.003), (0.002, 0.003),
               (0.002, 0.036), (-0.002, 0.036), (-0.002, 0.003), (-0.012, 0.003)]
    return extrusion(name, length, profile, "painted_metal", group, 0.0007)


def column_module(name: str, width: float, group: bpy.types.Collection) -> list[bpy.types.Object]:
    pieces = [box(f"{name}_WrappedPier", (0, 0, HEIGHT / 2), (width, width, HEIGHT), "wallpaper", group, 0.009)]
    for rotation in range(4):
        base = cove_base(f"{name}_Cove", width + 0.015, 1, group)
        angle = rotation * math.pi / 2
        base.location = Vector((-width / 2 - 0.0075, width / 2 - 0.08, 0))
        base.location.rotate(__import__("mathutils").Euler((0, 0, angle)))
        base.rotation_euler.z = angle
        pieces.append(base)
    return pieces


def fixture(name: str, exposed: bool, group: bpy.types.Collection) -> list[bpy.types.Object]:
    pieces = []
    # Fixture underside is local z=0. Body recesses above the ceiling grid.
    pieces.append(box(f"{name}_FoldedHousing", (0, 0, 0.047), (1.206, 0.596, 0.087), "painted_metal", group, 0.01, 1.22))
    pieces.append(box(f"{name}_Reflector", (0, 0, 0.001), (1.142, 0.532, 0.012), "reflector", group, 0.013, 1.22))
    for side in (-1, 1):
        pieces.append(box(f"{name}_FrameLong", (0, side * 0.283, -0.013), (1.205, 0.027, 0.032), "painted_metal", group, 0.003, 1.22))
        pieces.append(box(f"{name}_FrameEnd", (side * 0.588, 0, -0.013), (0.027, 0.55, 0.032), "painted_metal", group, 0.003, 1.22))
        for row in (-1, 1):
            pieces.append(cylinder(f"{name}_Tube", (0, row * 0.137, -0.025), 0.019, 1.082, "lamp_phosphor", group, 16))
            pieces.append(box(f"{name}_CeramicSocket", (side * 0.542, row * 0.137, -0.008), (0.046, 0.063, 0.075), "ceramic", group, 0.008, 1.22))
        pieces.append(cylinder(f"{name}_HingePin", (side * 0.40, 0.28, -0.02), 0.0045, 0.054, "fastener", group, 12))
    if not exposed:
        pieces.append(box(f"{name}_PrismaticDiffuser", (0, 0, -0.035), (1.139, 0.514, 0.013), "diffuser", group, 0.004, 0.61))
    for x in (-0.558, 0.558):
        for y in (-0.263, 0.263):
            pieces.append(cylinder(f"{name}_RecessedScrew", (x, y, -0.031), 0.0058, 0.003, "fastener", group, 12, "Z"))
            pieces.append(box(f"{name}_ScrewSlot", (x, y, -0.033), (0.007, 0.0013, 0.0008), "recess", group, 0.0002, 1.22))
    return pieces


def vent(name: str, group: bpy.types.Collection) -> list[bpy.types.Object]:
    pieces = [box(f"{name}_Recess", (0, 0.009, 0), (0.535, 0.043, 0.275), "recess", group, 0.006, 1.22)]
    for side in (-1, 1):
        pieces.append(box(f"{name}_SideFlange", (side * 0.284, -0.006, 0), (0.039, 0.026, 0.327), "painted_metal", group, 0.007, 1.22))
        pieces.append(box(f"{name}_EndFlange", (0, -0.006, side * 0.146), (0.541, 0.026, 0.035), "painted_metal", group, 0.004, 1.22))
    for index in range(9):
        blade = box(f"{name}_FoldedLouver", (0, 0, 0), (0.531, 0.031, 0.008), "painted_metal", group, 0.002, 1.22)
        blade.location = (0, -0.016, -0.118 + index * 0.0295)
        blade.rotation_euler.x = math.radians(-26)
        pieces.append(blade)
    for x in (-0.285, 0.285):
        fastener = cylinder(f"{name}_Fastener", (x, 0, 0), 0.006, 0.003, "fastener", group, 12, "Z")
        fastener.rotation_euler.x = math.pi / 2
        fastener.location.y = -0.023
        pieces.append(fastener)
    return pieces


def duplicate(objects: list[bpy.types.Object], group: bpy.types.Collection, prefix: str,
              position: tuple = (0, 0, 0), angle: float = 0) -> list[bpy.types.Object]:
    result = []
    rotation = __import__("mathutils").Euler((0, 0, angle))
    for source in objects:
        obj = source.copy()
        obj.data = source.data
        obj.name = f"{prefix}_{source.name}"
        group.objects.link(obj)
        location = source.location.copy()
        location.rotate(rotation)
        obj.location = location + Vector(position)
        obj.rotation_euler.z += angle
        result.append(obj)
    return result


def apply_for_export(objects: list[bpy.types.Object], export_name: str) -> list[bpy.types.Object]:
    scratch = collection(f"EXPORT_{export_name}")
    result = []
    depsgraph = bpy.context.evaluated_depsgraph_get()
    for source in objects:
        evaluated = source.evaluated_get(depsgraph)
        mesh = bpy.data.meshes.new_from_object(evaluated, preserve_all_data_layers=True, depsgraph=depsgraph)
        obj = bpy.data.objects.new(source.name, mesh)
        scratch.objects.link(obj)
        obj.matrix_world = source.matrix_world.copy()
        result.append(obj)
    # Spatially local batches, one surface per material, retain actual modeled detail.
    bpy.ops.object.select_all(action="DESELECT")
    for obj in result:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = result[0]
    if len(result) > 1:
        bpy.ops.object.join()
    merged = bpy.context.object
    merged.name = export_name
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    # UV0 is dimensionally tiled. UV2 is distinct and packed for optional invariant bake.
    merged.data.uv_layers.new(name="UV2")
    merged.data.uv_layers.active_index = 1
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.012)
    bpy.ops.object.mode_set(mode="OBJECT")
    merged.data.uv_layers.active_index = 0
    triangulate = merged.modifiers.new("Explicit export triangulation", "TRIANGULATE")
    triangulate.quad_method = "FIXED"
    triangulate.ngon_method = "CLIP"
    bpy.ops.object.modifier_apply(modifier=triangulate.name)
    # Bevel interpolation can collapse UVs on submillimeter screw/cylinder corners.
    # Preserve the atlas swatch and assign a small face island to those triangles.
    uv = merged.data.uv_layers[0].data
    repaired = 0
    for polygon in merged.data.polygons:
        indices = list(polygon.loop_indices)
        a, b, c = (uv[index].uv.copy() for index in indices)
        area = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
        if abs(area) < 1e-12:
            center = (a + b + c) / 3
            for index, offset in zip(indices, ((-0.0001, -0.0001), (0.0001, -0.0001), (0.0, 0.0001))):
                uv[index].uv = center + Vector(offset)
            repaired += 1
    if repaired:
        print(f"UV_MICRO_ISLAND_REPAIR {export_name} {repaired} beveled triangles")
    return [merged]


def export(objects: list[bpy.types.Object], name: str, role: str) -> None:
    baked = apply_for_export(objects, name)
    merged = baked[0]
    mesh = merged.data
    counts = {"vertices": len(mesh.vertices), "triangles": len(mesh.polygons),
              "materials": len(set(p.material_index for p in mesh.polygons)), "uv_layers": len(mesh.uv_layers),
              "dimensions_m": [round(value, 4) for value in merged.dimensions], "role": role}
    path = EXPORT / f"{name}.gltf"
    # glTF separate uses one shared adjacent texture folder rather than one embedded copy per module.
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLTF_SEPARATE", use_selection=True,
                              export_texcoords=True, export_normals=True, export_tangents=True,
                              export_materials="EXPORT", export_image_format="AUTO", export_texture_dir="textures",
                              export_animations=False, export_extras=True, export_yup=True,
                              export_vertex_color="NAME", export_vertex_color_name="AgeTint")
    counts["sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
    METADATA["modules"][name] = counts
    scratch = merged.users_collection[0]
    bpy.data.objects.remove(merged, do_unlink=True)
    bpy.data.collections.remove(scratch)
    print(f"EXPORTED {name} {counts}")


def build_room(group: bpy.types.Collection, source_fixture_group: bpy.types.Collection) -> list[bpy.types.Object]:
    room = []
    floor = box("M4_ContinuousCarpet", (0, 7.32, -0.042), (12.2, 14.64, 0.084), "carpet", group, 0)
    room.append(floor)

    def run_wall(name: str, start: tuple, length: float, angle: float = 0, portal: float = 0) -> None:
        temp = collection(f"TEMP_{name}")
        objects = wall(name, length, temp, portal=portal)
        room.extend(duplicate(objects, group, name, start, angle))
        for obj in objects:
            bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.collections.remove(temp)

    run_wall("SouthBlank", (-6.1, 0, 0), 7.32)
    run_wall("SouthReturn", (3.66, 0, 0), 2.44)
    room.append(box("ArrivalOpening_Header", (2.44, 0, 2.585), (2.46, 0.16, 0.27), "wallpaper", group, 0.006))
    run_wall("WestBoundary", (-6.1, 0, 0), 14.64, math.pi / 2)
    run_wall("NorthPortal", (-6.1, 14.64, 0), 7.32, portal=2.44)
    run_wall("NorthBlank", (1.22, 14.64, 0), 4.88)
    run_wall("EastFront", (6.1, 0, 0), 7.32, math.pi / 2)
    run_wall("EastRear", (6.1, 9.76, 0), 4.88, math.pi / 2)
    room.append(box("EastOpening_Header", (6.1, 8.54, 2.585), (0.16, 2.46, 0.27), "wallpaper", group, 0.006))
    # Offset full-height partitions and nonuniform columns define the sightlines.
    run_wall("OffsetPartition", (-3.66, 6.1, 0), 4.27)
    run_wall("OffsetReturn", (0.61, 6.1, 0), 2.44, math.pi / 2)
    room.extend(duplicate(MODULES["cove_corner_090"], group, "OffsetMiter", (0.61, 6.1, 0)))
    room.extend(duplicate(MODULES["column_061"], group, "FrontOffsetColumn", (-2.79, 3.40, 0)))
    room.extend(duplicate(MODULES["column_086"], group, "FarColumn", (3.80, 11.04, 0)))

    # Visible continuations are complete construction with a turn, not holes into void.
    room.append(box("NorthContinuationCarpet", (-2.44, 16.47, -0.042), (2.44, 3.66, 0.084), "carpet", group, 0))
    run_wall("NorthLeftReturn", (-3.66, 14.64, 0), 3.66, math.pi / 2)
    run_wall("NorthRightReturn", (-1.22, 14.64, 0), 3.66, math.pi / 2)
    run_wall("NorthBlindTurn", (-3.66, 18.3, 0), 2.44)
    room.append(box("EastContinuationCarpet", (7.93, 8.54, -0.042), (3.66, 2.44, 0.084), "carpet", group, 0))
    run_wall("EastLeftReturn", (6.1, 7.32, 0), 3.66)
    run_wall("EastRightReturn", (6.1, 9.76, 0), 3.66)
    run_wall("EastBlindTurn", (9.76, 7.32, 0), 2.44, math.pi / 2)
    # Entrance return gives a reviewer real nearby wall corners and avoids a free edge.
    room.append(box("EntryCarpet", (2.44, -1.22, -0.042), (2.44, 2.44, 0.084), "carpet", group, 0))
    run_wall("EntryLeftReturn", (1.22, -2.44, 0), 2.44, math.pi / 2)
    run_wall("EntryRightReturn", (3.66, -2.44, 0), 2.44, math.pi / 2)
    run_wall("EntryBack", (1.22, -2.44, 0), 2.44)

    fixture_cells = {(7, 2): "NORMAL", (3, 3): "NORMAL", (1, 7): "WEAK", (7, 7): "NORMAL",
                     (4, 10): "NORMAL", (8, 12): "NORMAL", (2, 14): "NORMAL", (6, 17): "NORMAL",
                     (1, 19): "OFF", (8, 21): "NORMAL", (4, 22): "NORMAL"}
    rng = random.Random(SEED)
    for column in range(10):
        for row in range(24):
            x, y = -6.1 + (column + 0.5) * 1.22, (row + 0.5) * 0.61
            if (column, row) in fixture_cells:
                variant = "fixture_exposed" if (column, row) == (1, 19) else "fixture_prismatic"
                state = fixture_cells[(column, row)]
                fixture_id = f"m4_f{len(METADATA['fixtures']):02d}"
                METADATA["fixtures"].append({"id": fixture_id, "variant": variant, "position": [x, HEIGHT - 0.016, -y],
                                              "state": state, "shadow": (column, row) in ((7, 2), (3, 3), (7, 7), (2, 14)),
                                              "warmth": 0.11 if state == "WEAK" else rng.uniform(0.0, 0.07)})
                source_parts = duplicate(MODULES[variant], source_fixture_group, fixture_id, (x, y, HEIGHT - 0.016))
                if state == "OFF":
                    for part in source_parts:
                        if part.get("atlas_region") == "lamp_phosphor":
                            part.data = part.data.copy()
                            # Shift identical guarded UV footprint to the unpowered swatch.
                            for loop in part.data.uv_layers[0].data:
                                loop.uv.x += 0.5
                light_data = bpy.data.lights.new(f"{fixture_id}_SOURCE_LIGHT", "AREA")
                light_data.energy = 95 if state == "NORMAL" else (35 if state == "WEAK" else 0)
                light_data.color = (1.0, 0.955, 0.79)
                light_data.shape = "RECTANGLE"
                light_data.size = 1.04
                light_data.size_y = 0.44
                light = bpy.data.objects.new(light_data.name, light_data)
                source_fixture_group.objects.link(light)
                light.location = (x, y, HEIGHT - 0.09)
                continue
            board = tile(f"M4_AcousticBoard_{column:02d}_{row:02d}", 1.197, 0.587, group)
            board.location = (x, y, HEIGHT - 0.008 + rng.uniform(-0.001, 0.001))
            board.rotation_euler.z = math.pi if (column + row) % 3 == 0 else 0
            age = 0.90 + rng.random() * 0.10
            warm_age = rng.random() * 0.010
            for corner in board.data.color_attributes["AgeTint"].data:
                corner.color = (age, age - warm_age * 0.5, age - warm_age, 1.0)
            if (column, row) == (2, 18):
                board.rotation_euler.x = 0.012
            room.append(board)
    for row in range(25):
        runner = grid_runner(f"M4_GridCross_{row:02d}", 12.2, group)
        runner.location = (-6.1, row * 0.61, HEIGHT - 0.014)
        room.append(runner)
    for column in range(11):
        runner = grid_runner(f"M4_GridMain_{column:02d}", 14.64, group)
        runner.location = (-6.1 + column * 1.22, 0, HEIGHT - 0.01)
        runner.rotation_euler.z = math.pi / 2
        room.append(runner)
    # Complete return ceilings also receive detail at the same density.
    for name, cx, cy, width, depth in (("North", -2.44, 16.47, 2.44, 3.66), ("East", 7.93, 8.54, 3.66, 2.44), ("Entry", 2.44, -1.22, 2.44, 2.44)):
        nx, ny = round(width / 1.22), round(depth / 0.61)
        for ix in range(nx):
            for iy in range(ny):
                board = tile(f"{name}_Board_{ix}_{iy}", 1.197, 0.587, group)
                board.location = (cx - width / 2 + (ix + 0.5) * 1.22, cy - depth / 2 + (iy + 0.5) * 0.61, HEIGHT - 0.008)
                room.append(board)
        for iy in range(ny + 1):
            runner = grid_runner(f"{name}_Cross_{iy}", width, group)
            runner.location = (cx - width / 2, cy - depth / 2 + iy * 0.61, HEIGHT - 0.014)
            room.append(runner)
        for ix in range(nx + 1):
            runner = grid_runner(f"{name}_Main_{ix}", depth, group)
            runner.location = (cx - width / 2 + ix * 1.22, cy - depth / 2, HEIGHT - 0.01)
            runner.rotation_euler.z = math.pi / 2
            room.append(runner)
    room.extend(duplicate(MODULES["wall_vent"], group, "WestLowVent", (-6.013, 10.8, 0.72), math.pi / 2))
    # One displaced tile is an architectural clue; the rest of the room stays empty.
    displaced = tile("DisplacedAcousticTile", 1.197, 0.587, group)
    displaced.location = (-5.98, 11.92, 0.294)
    displaced.rotation_euler = (math.radians(84), 0, math.radians(94))
    room.append(displaced)
    return room


def source_camera(group: bpy.types.Collection) -> None:
    camera_data = bpy.data.cameras.new("M4_SourceReview_55deg")
    camera = bpy.data.objects.new("M4_SourceReview_55deg", camera_data)
    group.objects.link(camera)
    camera.location = (2.7, 0.85, 1.64)
    direction = Vector((-1.1, 8.8, 1.56)) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    camera_data.lens = 22
    bpy.context.scene.camera = camera


def main() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for group in list(bpy.data.collections):
        if group.name == "Collection":
            bpy.data.collections.remove(group)
    for directory in (SOURCE, EXPORT, RUNTIME, EVIDENCE):
        directory.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    for name in ("wallpaper", "carpet", "ceiling", "painted_metal", "baseboard", "diffuser", "fixture_detail"):
        material(name)
    atlas_material = MATERIALS["fixture_detail"]
    atlas_emission = atlas_material.node_tree.nodes.new("ShaderNodeTexImage")
    atlas_emission.image = bpy.data.images.load(str(TEXTURES / "fixture_detail/fixture_detail_emission.png"))
    atlas_bsdf = atlas_material.node_tree.nodes.get("Principled BSDF")
    atlas_material.node_tree.links.new(atlas_emission.outputs["Color"], atlas_bsdf.inputs["Emission Color"])
    atlas_bsdf.inputs["Emission Strength"].default_value = 2.4
    diffuser_bsdf = MATERIALS["diffuser"].node_tree.nodes.get("Principled BSDF")
    diffuser_bsdf.inputs["Emission Color"].default_value = (0.82, 0.80, 0.66, 1)
    diffuser_bsdf.inputs["Emission Strength"].default_value = 1.5
    library = collection("01_EDITABLE_ModularArchitecture")
    for length in (0.61, 1.22, 2.44, 3.66):
        name = f"wall_{round(length * 100):03d}"
        MODULES[name] = wall(name, length, library)
    MODULES["wall_portal_366"] = wall("wall_portal_366", 3.66, library, portal=2.44)
    MODULES["wall_portal_244"] = wall("wall_portal_244", 2.44, library, portal=1.22)
    MODULES["wall_low_244"] = wall("wall_low_244", 2.44, library, height=2.48)
    MODULES["column_061"] = column_module("column_061", 0.61, library)
    MODULES["column_086"] = column_module("column_086", 0.86, library)
    MODULES["ceiling_board_122"] = [tile("ceiling_board_122", 1.197, 0.587, library)]
    MODULES["ceiling_grid_122"] = [grid_runner("ceiling_grid_122", 1.22, library)]
    MODULES["ceiling_grid_244"] = [grid_runner("ceiling_grid_244", 2.44, library)]
    MODULES["cove_corner_090"] = [cove_corner("cove_corner_090", library)]
    MODULES["floor_carpet_244"] = [box("floor_carpet_244", (1.22, 1.22, -0.04), (2.44, 2.44, 0.08), "carpet", library, 0)]
    MODULES["fixture_prismatic"] = fixture("fixture_prismatic", False, library)
    MODULES["fixture_exposed"] = fixture("fixture_exposed", True, library)
    MODULES["wall_vent"] = vent("wall_vent", library)
    for name, objects in MODULES.items():
        export(objects, name, "modular architecture / original fixture")
    room_group = collection("02_EDITABLE_M4_AuthoredRoom")
    source_fixtures = collection("03_SOURCE_FixturesAndLighting")
    room = build_room(room_group, source_fixtures)
    export(room, "room_m4_architecture", "authored reference room, shared surfaces, fixtures instanced at runtime")
    bpy.context.view_layer.update()
    collision = []
    for obj in room:
        if any(word in obj.name for word in ("PaperedShell", "_Pier", "_Lintel", "_Header", "WrappedPier", "Carpet")):
            corners = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
            minimum = Vector(tuple(min(corner[i] for corner in corners) for i in range(3)))
            maximum = Vector(tuple(max(corner[i] for corner in corners) for i in range(3)))
            center = (minimum + maximum) * 0.5
            size = maximum - minimum
            collision.append({"name": obj.name, "center": [center.x, center.z, -center.y], "size": [size.x, size.z, size.y]})
    METADATA["collision_boxes"] = collision
    # A separate stripped collision mesh exports no visible surface materials.
    # Runtime collision is generated from the collision manifest, never ornamental bevels.
    METADATA["room"] = {"id": "M4_REFERENCE", "bounds_blender_m": [-6.1, 6.1, 0, 14.64, 0, HEIGHT],
                        "ceiling_height_m": HEIGHT, "grid_m": [1.22, 0.61], "minimum_opening_height_m": 2.45,
                        "materials": "Shared meter-UV PBR; tiled microdetail and original world-space room macro mask.",
                        "role": "Art validation composition; does not claim a campaign room graph or player systems.",
                        "portal_anchors_godot": [[2.44, 0, 0], [-2.44, 0, -14.64], [6.1, 0, -8.54]]}
    METADATA["tool"] = {"blender": bpy.app.version_string, "binary": bpy.app.binary_path, "python": sys.version}
    METADATA["provenance"] = "Original authored mathematical geometry and project-created textures. No external game content, image generation, asset packs or franchise text. Recipe and editable modifiers retained."
    (EXPORT / "environment_manifest.json").write_text(json.dumps(METADATA, indent=2) + "\n")
    source_camera(source_fixtures)
    # Library originals overlap at origin by design and must be hidden in room view.
    library.hide_render = True
    library.hide_viewport = True
    if not scene.world.node_tree:
        scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.10, 0.11, 0.085, 1)
    scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.14
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 32
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 1600
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "AgX"
    for image in bpy.data.images:
        if image.filepath and image.source == "FILE":
            image.filepath = "//" + os.path.relpath(bpy.path.abspath(image.filepath), SOURCE)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "nullspace_environment_m4.blend"))
    for path in EXPORT.rglob("*"):
        if path.is_file():
            destination = RUNTIME / path.relative_to(EXPORT)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, destination)
    if "--render" in sys.argv:
        scene.render.filepath = str(EVIDENCE / "blender_source_room.png")
        bpy.ops.render.render(write_still=True)
    print(f"ENVIRONMENT_PIPELINE_OK modules={len(MODULES)} room={len(room)} original master retained")


if __name__ == "__main__":
    main()
