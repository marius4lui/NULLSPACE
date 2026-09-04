"""Blender-only editable asset/export diagnostic. Never used as production game art."""

from __future__ import annotations

import argparse
import hashlib
import json
from math import tau
from pathlib import Path
import struct
import sys

import bpy


def canonicalize_diagnostic_glb(path: Path) -> None:
    """Remove sub-micrometer bevel UV roundoff from this diagnostic's FLOAT accessors."""
    data = path.read_bytes()
    json_length = struct.unpack_from("<I", data, 12)[0]
    document = json.loads(data[20:20 + json_length])
    binary_header = 20 + json_length
    binary_length, binary_type = struct.unpack_from("<I4s", data, binary_header)
    if binary_type != b"BIN\x00":
        raise RuntimeError("Expected self-contained GLB binary chunk")
    binary = bytearray(data[binary_header + 8:binary_header + 8 + binary_length])
    components = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}
    for accessor in document["accessors"]:
        if accessor["componentType"] != 5126:
            continue
        view = document["bufferViews"][accessor["bufferView"]]
        width = components[accessor["type"]]
        base = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
        stride = view.get("byteStride", width * 4)
        values: list[tuple[float, ...]] = []
        for index in range(accessor["count"]):
            offset = base + index * stride
            rounded = tuple(round(value, 6) for value in struct.unpack_from(f"<{width}f", binary, offset))
            struct.pack_into(f"<{width}f", binary, offset, *rounded)
            values.append(struct.unpack_from(f"<{width}f", binary, offset))
        if "min" in accessor:
            accessor["min"] = [min(value[column] for value in values) for column in range(width)]
            accessor["max"] = [max(value[column] for value in values) for column in range(width)]
    serialized = json.dumps(document, sort_keys=True, separators=(",", ":")).encode()
    serialized += b" " * (-len(serialized) % 4)
    length = 12 + 8 + len(serialized) + 8 + len(binary)
    path.write_bytes(struct.pack("<4sII", b"glTF", 2, length)
                     + struct.pack("<I4s", len(serialized), b"JSON") + serialized
                     + struct.pack("<I4s", len(binary), b"BIN\x00") + binary)


def material(name: str, color: tuple[float, float, float, float], roughness: float) -> bpy.types.Material:
    result = bpy.data.materials.new(name)
    result.diffuse_color = color
    shader = result.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = color
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = 0.15
    return result


def build(output: Path) -> None:
    if bpy.app.version[:3] != (5, 2, 1):
        raise RuntimeError(f"Expected Blender 5.2.1; got {bpy.app.version_string}")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene.render.fps = 30
    scene.frame_start = 1
    scene.frame_end = 121
    root = bpy.data.objects.new("BootstrapTurntable", None)
    scene.collection.objects.link(root)
    palette = [
        material("DiagnosticRed", (0.68, 0.055, 0.025, 1.0), 0.28),
        material("DiagnosticGreen", (0.045, 0.55, 0.22, 1.0), 0.5),
        material("DiagnosticBlue", (0.025, 0.21, 0.8, 1.0), 0.7),
    ]
    for index, surface in enumerate(palette):
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, index * 0.15, 0.35 + index * 0.55))
        obj = bpy.context.object
        obj.name = f"BootstrapBevel_{index}"
        obj.dimensions = (1.8 - 0.4 * index, 0.85, 0.5)
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        obj.data.materials.append(surface)
        bevel = obj.modifiers.new("DiagnosticBevel", "BEVEL")
        bevel.width = 0.06
        bevel.segments = 3
        bpy.ops.object.modifier_apply(modifier=bevel.name)
        triangulate = obj.modifiers.new("StableTriangles", "TRIANGULATE")
        bpy.ops.object.modifier_apply(modifier=triangulate.name)
        obj.parent = root
    for frame, angle in ((1, 0.0), (61, tau / 2.0), (121, tau)):
        root.rotation_euler.z = angle
        root.keyframe_insert(data_path="rotation_euler", frame=frame)
    if root.animation_data and root.animation_data.action:
        root.animation_data.action.name = "BootstrapRotation"
    scene.frame_set(1)
    output.mkdir(parents=True, exist_ok=True)
    source = output / "bootstrap.blend"
    exported = output / "bootstrap.glb"
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    bpy.ops.export_scene.gltf(filepath=str(exported), export_format="GLB", export_animations=True)
    canonicalize_diagnostic_glb(exported)
    meshes = [obj for obj in scene.objects if obj.type == "MESH"]
    report = {
        "purpose": "M0 toolchain diagnostic only; no production asset or visual quality claim",
        "blender_version": bpy.app.version_string,
        "generator_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        "units": "meters", "mesh_objects": len(meshes),
        "glb_float_precision": "6 decimal places; deterministic diagnostic-only post-export canonicalization",
        "triangles": sum(len(obj.data.polygons) for obj in meshes),
        "materials": [surface.name for surface in palette],
        "animations": [action.name for action in bpy.data.actions],
        "files": {path.name: hashlib.sha256(path.read_bytes()).hexdigest()
                  for path in (source, exported)},
        "provenance": "Original diagnostic geometry and material parameters generated by this script.",
    }
    (output / "source-manifest.json").write_text(json.dumps(report, indent=2) + "\n")
    print("NULLSPACE_BLENDER_DIAGNOSTIC " + json.dumps(report, sort_keys=True))


if __name__ == "__main__":
    arguments = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    build(parser.parse_args(arguments).output.resolve())
