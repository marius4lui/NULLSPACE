"""Deterministic source creation/export. CPU source renders are a separate command."""
from __future__ import annotations

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))

import json
import shutil
import bpy
import bmesh
from mathutils import Vector
from recipe import SOURCE, TEXTURES, EXPORT, RUNTIME, EVIDENCE, SEED, REMAINING_CLIPS
from geometry import build_cage
from rig import create_rig, animations


def topology(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    unseen = set(bm.verts)
    components = 0
    while unseen:
        components += 1
        todo = [unseen.pop()]
        while todo:
            current = todo.pop()
            for edge in current.link_edges:
                other = edge.other_vert(current)
                if other in unseen:
                    unseen.remove(other)
                    todo.append(other)
    result = {"vertices": len(bm.verts), "edges": len(bm.edges), "faces": len(bm.faces),
        "triangles": sum(len(f.verts) - 2 for f in bm.faces), "connected_components": components,
        "nonmanifold_edges": sum(not e.is_manifold for e in bm.edges),
        "wire_edges": sum(e.is_wire for e in bm.edges)}
    bm.free()
    return result


def main():
    for folder in (SOURCE, TEXTURES, EXPORT, RUNTIME, EVIDENCE):
        folder.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    scene = bpy.context.scene
    scene.unit_settings.system = 'METRIC'
    scene.unit_settings.scale_length = 1
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.render.threads_mode = 'FIXED'
    scene.render.threads = 2
    scene.cycles.samples = 24
    scene.view_settings.view_transform = 'AgX'
    surface = build_cage()
    cage_stats = topology(surface)
    assert cage_stats["connected_components"] == 1, cage_stats
    assert cage_stats["nonmanifold_edges"] == 0, cage_stats
    rig = create_rig(surface)
    clips = animations(rig)
    # Preserve editable cage + subdivision master; export a deliberate subdivision result.
    bpy.ops.object.select_all(action='DESELECT')
    surface.select_set(True)
    bpy.context.view_layer.objects.active = surface
    runtime = surface.copy()
    runtime.data = surface.data.copy()
    runtime.name = "Listener_Runtime"
    runtime.parent = None
    bpy.context.collection.objects.link(runtime)
    surface.select_set(False)
    runtime.select_set(True)
    bpy.context.view_layer.objects.active = runtime
    bpy.ops.object.modifier_apply(modifier="Editable_anatomical_surface")
    from sculpt import refine_anatomy
    refine_anatomy(runtime)
    bpy.ops.object.vertex_group_limit_total(limit=4)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)
    stats = topology(runtime)
    print("LISTENER_TOPOLOGY", json.dumps({"cage": cage_stats, "runtime": stats}))
    from texture_bake import create_original_skin
    create_original_skin(runtime)
    surface.data.materials.clear()
    surface.data.materials.append(runtime.data.materials[0])
    surface.hide_render = True
    surface.hide_set(True)
    from stage import create_stage
    create_stage(scene)
    record = {"schema": 1, "asset": "NULLSPACE Listener M11A source candidate", "seed": SEED,
        "software": {"blender": bpy.app.version_string, "build_hash": bpy.app.build_hash.decode()},
        "originality": "Directed connected quad surface, mathematical tissue bakes, explicit 63-bone rig and original 3-clip curves. No external art inputs.",
        "units": "metres", "facing": "Blender -Y; Godot +Z", "cage": cage_stats, "runtime": stats,
        "bones": len(rig.data.bones), "materials": len(runtime.data.materials), "weights": "normalized; maximum four influences",
        "clips": clips, "remaining_required_clips": REMAINING_CLIPS,
        "evidence_root": "tools/art/listener/evidence",
        "acceptance": {"source_render": "ITERATING; initial local FAIL retained", "native_deformation": "PENDING", "independent_review": "PENDING", "M11": "NOT COMPLETE"},
        "collision_envelope": {"type": "upright capsule", "radius": .27, "height": 2.30, "center": [0, 1.15, 0],
            "note": "Conservative locomotion proxy; arms may extend laterally. AI collision integration not included."}}
    (EXPORT / "listener_manifest.json").write_text(json.dumps(record, indent=2) + "\n")
    for image in bpy.data.images:
        if image.source == 'FILE' and image.filepath:
            image.filepath = bpy.path.relpath(image.filepath, start=str(SOURCE))
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "listener_master.blend"), compress=True)
    # Explicit skinned triangles, retained 4 influences; only runtime surface and armature export.
    tri = runtime.modifiers.new("Stable_export_triangles", 'TRIANGULATE')
    bpy.context.view_layer.objects.active = runtime
    bpy.ops.object.modifier_move_up(modifier=tri.name)
    bpy.ops.object.modifier_apply(modifier=tri.name)
    bpy.ops.object.select_all(action='DESELECT')
    runtime.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.gltf(filepath=str(EXPORT / "listener.glb"), export_format='GLB', use_selection=True,
        export_yup=True, export_apply=False, export_texcoords=True, export_normals=True,
        export_tangents=True, export_skins=True, export_all_influences=False,
        export_animations=True, export_animation_mode='ACTIONS', export_anim_single_armature=True,
        export_force_sampling=True, export_frame_range=False, export_def_bones=True,
        export_morph=False, export_cameras=False, export_lights=False, export_extras=True)
    for filename in ("listener.glb", "listener_manifest.json"):
        shutil.copy2(EXPORT / filename, RUNTIME / filename)
    print("LISTENER_SOURCE_EXPORT_OK")


if __name__ == "__main__":
    main()
