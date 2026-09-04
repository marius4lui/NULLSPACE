"""Measured source/pose invariants, explicitly not experiential animation review."""
from __future__ import annotations
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import json
import bpy
import numpy as np
from recipe import SOURCE, EVIDENCE
from build_listener import topology


def evaluated_points(obj):
    evaluated = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    mesh = evaluated.to_mesh()
    coordinates = np.empty(len(mesh.vertices) * 3, dtype=np.float64)
    mesh.vertices.foreach_get('co', coordinates)
    evaluated.to_mesh_clear()
    return coordinates.reshape(-1, 3)


def main():
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE / 'listener_master.blend'))
    scene, rig, surface = bpy.context.scene, bpy.data.objects['Listener_Rig'], bpy.data.objects['Listener_Runtime']
    rig.animation_data.action = bpy.data.actions['idle']
    scene.frame_set(0)
    reference = evaluated_points(surface)
    foot_mask = (reference[:, 2] < .045) & (np.abs(reference[:, 0]) < .29)
    all_weights = [sum(g.weight for g in vertex.groups) for vertex in surface.data.vertices]
    missing_images = [image.filepath for image in bpy.data.images if image.source == 'FILE' and not Path(bpy.path.abspath(image.filepath)).is_file()]
    failures = []
    if missing_images:
        failures.append('missing source image')
    maximum_influences = max(len(vertex.groups) for vertex in surface.data.vertices)
    if maximum_influences > 4 or max(abs(total - 1) for total in all_weights) > 1e-5:
        failures.append('invalid source weights')
    pose_records = {}
    mesh = surface.data
    mesh.calc_loop_triangles()
    triangles = np.array([triangle.vertices[:] for triangle in mesh.loop_triangles])
    reference_cross = np.cross(reference[triangles[:, 1]] - reference[triangles[:, 0]], reference[triangles[:, 2]] - reference[triangles[:, 0]])
    ref_area = np.linalg.norm(reference_cross, axis=1)
    nondegenerate = ref_area > 1e-11
    for name in ('idle', 'breathing', 'listen'):
        action = bpy.data.actions[name]
        rig.animation_data.action = action
        frames = int(action.frame_range[1])
        maximum_foot_drift = 0.0
        min_ratio, max_ratio, min_normal_dot = 1.0, 1.0, 1.0
        worst_contraction = {}
        for frame in range(0, frames + 1, 10):
            scene.frame_set(frame)
            posed = evaluated_points(surface)
            maximum_foot_drift = max(maximum_foot_drift, float(np.linalg.norm(posed[foot_mask] - reference[foot_mask], axis=1).max()))
            cross = np.cross(posed[triangles[:, 1]] - posed[triangles[:, 0]], posed[triangles[:, 2]] - posed[triangles[:, 0]])
            area = np.linalg.norm(cross, axis=1)
            ratios = area[nondegenerate] / ref_area[nondegenerate]
            dots = np.sum(cross[nondegenerate] * reference_cross[nondegenerate], axis=1) / np.maximum(1e-20, area[nondegenerate] * ref_area[nondegenerate])
            min_ratio = min(min_ratio, float(ratios.min()))
            if float(ratios.min()) == min_ratio:
                index = np.nonzero(nondegenerate)[0][int(np.argmin(ratios))]
                worst_contraction = {'frame': frame, 'triangle': int(index), 'rest_area_m2': float(ref_area[index] * .5),
                    'centroid_m': reference[triangles[index]].mean(axis=0).tolist()}
            max_ratio = max(max_ratio, float(ratios.max()))
            min_normal_dot = min(min_normal_dot, float(dots.min()))
        pose_records[name] = {'sample_step_frames': 10, 'max_foot_surface_drift_m': maximum_foot_drift,
            'min_triangle_area_ratio': min_ratio, 'max_triangle_area_ratio': max_ratio,
            'minimum_rest_pose_normal_dot': min_normal_dot, 'worst_contraction': worst_contraction}
        if maximum_foot_drift > .0001 or min_ratio < .5 or max_ratio > 1.5 or min_normal_dot < .5:
            failures.append('pose invariant ' + name)
    record = {'schema': 1, 'result': 'FAIL' if failures else 'PASS', 'software': bpy.app.version_string,
        'source_topology': topology(surface), 'source_images_missing': missing_images, 'maximum_influences': maximum_influences,
        'source_foot_support_vertices': int(foot_mask.sum()), 'pose_invariants': pose_records, 'failures': failures,
        'limitation': 'Sampled geometry invariants only. Native motion/contact/blending and independent art review remain required.'}
    (EVIDENCE / 'source_pose_invariants.json').write_text(json.dumps(record, indent=2) + '\n')
    print(json.dumps(record, indent=2))
    if failures:
        raise RuntimeError('Source invariant failures')


if __name__ == '__main__':
    main()
