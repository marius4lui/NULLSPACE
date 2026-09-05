#!/usr/bin/env python3
"""Add ONLY locomotion/attack/stagger to the existing original master; no remodelling.

Feet use an explicit planted/swing path and a baked two-bone IK solve. Original master,
skin, weights and idle/listen/breathing actions remain available unchanged.
"""
from pathlib import Path
import json
import math
import shutil
import bpy
from mathutils import Vector, Quaternion

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "art/source/blender/listener"
EXPORT = ROOT / "art/exported/listener"
RUNTIME = ROOT / "game/assets/listener"
bpy.ops.wm.open_mainfile(filepath=str(SOURCE / "listener_master.blend"))
scene = bpy.context.scene
rig = bpy.data.objects["Listener_Rig"]
mesh = bpy.data.objects["Listener_Runtime"]
scene.render.fps = 30
records = {}


def reset():
    rig.animation_data.action = None
    for bone in rig.pose.bones:
        bone.rotation_mode = "XYZ"
        bone.rotation_euler = (0, 0, 0)
        bone.location = (0, 0, 0)
        bone.scale = (1, 1, 1)


def world_rotation(name, x=0, y=0, z=0):
    rest = rig.data.bones[name].matrix_local.to_quaternion()
    turn = Quaternion(Vector((0, 0, 1)), z) @ Quaternion(Vector((0, 1, 0)), y) @ Quaternion(Vector((1, 0, 0)), x)
    rig.pose.bones[name].rotation_euler = (rest.inverted() @ turn @ rest).to_euler("XYZ")


def root_offset(z):
    rig.pose.bones["root"].location = rig.data.bones["root"].matrix_local.to_3x3().inverted() @ Vector((0, 0, z))


for clip, seconds in (("walk", 1.2), ("run", 0.72), ("attack", 1.4), ("stagger", 0.9), ("death_grab", 2.6)):
    reset()
    constraints, helpers, targets = [], [], {}
    for side in (".L", ".R"):
        foot = rig.data.bones["foot" + side]
        goal = bpy.data.objects.new("Foot contact" + side, None)
        pole = bpy.data.objects.new("Forward knee" + side, None)
        scene.collection.objects.link(goal)
        scene.collection.objects.link(pole)
        goal.location = foot.head_local
        goal.rotation_euler = foot.matrix_local.to_euler()
        pole.location = (foot.head_local.x, -2, 0.65)
        helpers += [goal, pole]
        targets[side] = goal
        ik = rig.pose.bones["shin" + side].constraints.new("IK")
        ik.target, ik.pole_target, ik.chain_count = goal, pole, 2
        ik.use_stretch = False
        # Choose the forward-facing knee solution using actual evaluated bone positions.
        root_offset(-0.10)
        candidates = []
        for angle in (0, math.pi, math.pi / 2, -math.pi / 2):
            ik.pole_angle = angle
            bpy.context.view_layer.update()
            candidates.append((rig.pose.bones["shin" + side].head.y, angle))
        ik.pole_angle = min(candidates)[1]
        orient = rig.pose.bones["foot" + side].constraints.new("COPY_ROTATION")
        orient.target = goal
        orient.owner_space = "WORLD"
        orient.target_space = "WORLD"
        constraints += [(rig.pose.bones["shin" + side], ik), (rig.pose.bones["foot" + side], orient)]
    frames = round(seconds * 30)
    baked = []
    for frame in range(frames + 1):
        reset()
        scene.frame_set(frame)
        t = frame / frames
        moving = clip in ("walk", "run")
        running = clip == "run"
        pulse = math.sin(t * math.tau)
        root_offset((-0.12 if running else -0.045) + (0.025 if running else 0.012) * math.cos(t * math.tau * 2) if moving else 0)
        world_rotation("spine_02", x=0.16 if running else 0.025, z=0.025 * pulse if moving else 0)
        for side in (".L", ".R"):
            sign = 1 if side == ".L" else -1
            phase = (t + (0.5 if side == ".R" else 0)) % 1
            position = rig.data.bones["foot" + side].head_local.copy()
            if moving:
                stance = 0.56 if running else 0.61
                stride = 1.34 if running else 0.84
                if phase < stance:
                    position.y += (phase / stance - 0.5) * stride
                else:
                    swing = (phase - stance) / (1 - stance)
                    ease = swing * swing * (3 - 2 * swing)
                    position.y += (0.5 - ease) * stride
                    position.z += math.sin(swing * math.pi) * (0.16 if running else 0.075)
            targets[side].location = position
            world_rotation("upper_arm" + side, x=sign * pulse * (0.55 if running else 0.22))
            world_rotation("forearm" + side, x=-0.6 if running else -0.10)
            world_rotation("hand" + side, x=0.06 * pulse)
        if clip == "attack":
            # Visible anticipation, committed sweep at 0.6s, long recovery; no root lunge.
            wind = min(1, t / 0.27)
            sweep = max(0, min(1, (t - 0.27) / 0.16))
            recover = max(0, min(1, (t - 0.50) / 0.50))
            pose = (1 - recover) * (wind * -0.42 + sweep * 1.20)
            world_rotation("spine_02", x=0.12 * sweep * (1 - recover))
            world_rotation("upper_arm.R", x=-pose, y=0.28 * wind * (1 - recover))
            world_rotation("forearm.R", x=-0.30 * wind * (1 - recover))
            world_rotation("neck_01", x=-0.08 * wind * (1 - recover))
        if clip == "death_grab":
            # Both long arms reach, elbows draw the victim in, then one final
            # committed downward strike and a visible release. Feet stay planted.
            seconds_now = frame / 30
            ease = lambda a, b: (lambda u: u * u * (3 - 2 * u))(max(0, min(1, (seconds_now-a)/(b-a))))
            reach = ease(0, .32)
            pull = ease(.36, 1.05)
            strike = ease(1.30, 1.46)
            release = ease(1.75, 2.40)
            hold = 1 - release
            for side in (".L", ".R"):
                world_rotation("upper_arm" + side, x=(-1.38 * reach + .30 * pull + (.48 * strike if side == ".R" else 0)) * hold)
                world_rotation("forearm" + side, x=(-.10 * reach - .48 * pull) * hold)
                world_rotation("hand" + side, x=.14 * pull * hold)
                for finger in ("index", "middle", "ring", "little", "thumb"):
                    for joint in (1, 2, 3):
                        world_rotation(f"{finger}_{joint:02d}{side}", x=-.30 * pull * hold)
            world_rotation("spine_02", x=(.08 * reach + .13 * strike) * hold)
            world_rotation("neck_01", x=(.08 * pull + .10 * strike) * hold)
        if clip == "stagger":
            hit = min(1, t / 0.12) * (1 - t) ** 2
            world_rotation("spine_02", x=-0.25 * hit, y=0.15 * hit)
            world_rotation("neck_01", x=0.16 * hit)
            world_rotation("upper_arm.L", x=0.3 * hit, y=-0.22 * hit)
            world_rotation("upper_arm.R", x=0.15 * hit, y=0.22 * hit)
        bpy.context.view_layer.update()
        baked.append({bone.name: bone.matrix.copy() for bone in rig.pose.bones})
    for bone, constraint in constraints:
        bone.constraints.remove(constraint)
    for obj in helpers:
        bpy.data.objects.remove(obj, do_unlink=True)
    action = bpy.data.actions.new(clip)
    action.use_fake_user = True
    rig.animation_data.action = action
    for frame, poses in enumerate(baked):
        # Explicit rest-relative basis, not PoseBone.matrix assignment using stale
        # evaluated parent transforms. The latter doubled child rotations in-game.
        for bone in rig.pose.bones:
            parent_pose = poses[bone.parent.name] if bone.parent else None
            parent_rest = bone.parent.bone.matrix_local if bone.parent else None
            local_pose = parent_pose.inverted() @ poses[bone.name] if parent_pose else poses[bone.name]
            local_rest = parent_rest.inverted() @ bone.bone.matrix_local if parent_rest else bone.bone.matrix_local
            bone.matrix_basis = local_rest.inverted() @ local_pose
        for bone in rig.pose.bones:
            bone.keyframe_insert("location", frame=frame, group=bone.name)
            bone.keyframe_insert("rotation_euler", frame=frame, group=bone.name)
            bone.keyframe_insert("scale", frame=frame, group=bone.name)
    records[clip] = {"seconds": seconds, "loop": moving, "source": "baked original contact paths / articulated pose",
                     "validation": "requires actual gameplay motion inspection"}

rig.animation_data.action = bpy.data.actions["idle"]
scene.frame_set(0)
for image in bpy.data.images:
    if image.source == "FILE" and image.filepath:
        image.filepath = bpy.path.relpath(bpy.path.abspath(image.filepath), start=str(SOURCE))
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "listener_gameplay.blend"), compress=True)
bpy.ops.object.select_all(action="DESELECT")
mesh.hide_set(False)
mesh.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(filepath=str(EXPORT / "listener_gameplay.glb"), export_format="GLB", use_selection=True,
    export_yup=True, export_apply=False, export_texcoords=True, export_normals=True,
    export_tangents=True, export_skins=True, export_all_influences=False,
    export_animations=True, export_animation_mode="ACTIONS", export_anim_single_armature=True,
    export_force_sampling=True, export_frame_range=False, export_def_bones=True,
    export_morph=False, export_cameras=False, export_lights=False, export_extras=True)
shutil.copy2(EXPORT / "listener_gameplay.glb", RUNTIME / "listener_gameplay.glb")
(EXPORT / "gameplay_clips.json").write_text(json.dumps(records, indent=2) + "\n")
print("NULLSPACE_GAMEPLAY_CLIPS", json.dumps(records))
