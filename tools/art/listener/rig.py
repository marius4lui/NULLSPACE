"""63-bone deform rig and the three bounded M11A source clips."""
from __future__ import annotations

import math
import bpy
from mathutils import Vector
from recipe import FPS


def create_rig(surface: bpy.types.Object) -> bpy.types.Object:
    data = bpy.data.armatures.new("Listener_63_deform")
    rig = bpy.data.objects.new("Listener_Rig", data)
    bpy.context.collection.objects.link(rig)
    bpy.ops.object.select_all(action='DESELECT')
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode='EDIT')
    def bone(name, head, tail, parent=None):
        item = data.edit_bones.new(name)
        item.head, item.tail = head, tail
        item.use_deform = True
        if parent:
            item.parent = data.edit_bones[parent]
        item.align_roll(Vector((0, -1, 0)))
        return item
    bone("root", (0, 0, 0), (0, 0, .20))
    bone("pelvis", (0, 0, 1.10), (0, .01, 1.24), "root")
    bone("spine_01", (0, .01, 1.24), (0, .015, 1.42), "pelvis")
    bone("spine_02", (0, .015, 1.42), (0, .012, 1.60), "spine_01")
    bone("spine_03", (0, .012, 1.60), (0, .010, 1.77), "spine_02")
    bone("chest", (0, .010, 1.77), (0, .008, 1.91), "spine_03")
    bone("neck_01", (0, .008, 1.91), (-.032, -.024, 1.966), "chest")
    bone("neck_02", (-.032, -.024, 1.966), (-.047, -.045, 2.013), "neck_01")
    bone("head", (-.047, -.045, 2.013), (-.069, -.069, 2.278), "neck_02")
    for side in (-1, 1):
        suffix = ".L" if side > 0 else ".R"
        point = lambda x, y, z: (x * side, y, z)
        bone("auricle" + suffix, (-.069 + .036 * side, -.052, 2.12), (-.069 + .128 * side, -.035, 2.227), "head")
        bone("clavicle" + suffix, point(.025, .004, 1.855), point(.268, .004, 1.824), "chest")
        bone("upper_arm" + suffix, point(.268, .004, 1.824), point(.416, .007, 1.406), "clavicle" + suffix)
        bone("upper_arm_twist" + suffix, point(.357, .006, 1.573), point(.416, .007, 1.406), "upper_arm" + suffix)
        bone("forearm" + suffix, point(.416, .007, 1.406), point(.504, -.041, .867), "upper_arm" + suffix)
        bone("forearm_twist" + suffix, point(.469, -.022, 1.083), point(.504, -.041, .867), "forearm" + suffix)
        bone("hand" + suffix, point(.504, -.041, .867), point(.510, -.040, .674), "forearm" + suffix)
        for finger in range(4):
            idx = finger if side > 0 else 3 - finger
            name = ("index", "middle", "ring", "little")[idx]
            x = .510 * side + ((finger * 2 + 1) / 4 - 1) * .049
            length = (.178, .218, .199, .154)[idx]
            start = Vector((x, -.051, .674))
            tip = Vector((x + (finger - 1.5) * .014, -.131, .674 - length))
            parent = "hand" + suffix
            for joint, (a, b) in enumerate(((0, .35), (.35, .65), (.65, 1.0)), 1):
                joint_name = name + f"_{joint:02d}" + suffix
                bone(joint_name, start.lerp(tip, a), start.lerp(tip, b), parent)
                parent = joint_name
        start, tip = Vector(point(.464, -.04, .795)), Vector(point(.401, -.093, .635))
        parent = "hand" + suffix
        for joint, (a, b) in enumerate(((0, .35), (.35, .65), (.65, 1.0)), 1):
            joint_name = "thumb" + f"_{joint:02d}" + suffix
            bone(joint_name, start.lerp(tip, a), start.lerp(tip, b), parent)
            parent = joint_name
        bone("thigh" + suffix, point(.135, .001, 1.105), point(.176, -.023, .580), "pelvis")
        bone("thigh_twist" + suffix, point(.160, -.013, .790), point(.176, -.023, .580), "thigh" + suffix)
        bone("shin" + suffix, point(.176, -.023, .580), point(.186, -.003, .160), "thigh" + suffix)
        bone("foot" + suffix, point(.186, -.003, .160), point(.186, -.175, .055), "shin" + suffix)
        bone("toe" + suffix, point(.186, -.175, .055), point(.186, -.245, .051), "foot" + suffix)
    bpy.ops.object.mode_set(mode='OBJECT')
    data.display_type = 'OCTAHEDRAL'
    rig.show_in_front = True
    modifier = surface.modifiers.new("Listener_skin_4_weights", 'ARMATURE')
    modifier.object = rig
    surface.parent = rig
    rig["facing"] = "Blender -Y / Godot +Z; origin at planted feet"
    rig["deform_bone_count"] = len(data.bones)
    assert len(data.bones) == 63, len(data.bones)
    return rig


def animations(rig: bpy.types.Object) -> dict:
    bpy.context.scene.render.fps = FPS
    rig.animation_data_create()
    records = {}
    for clip, seconds in (("idle", 8.0), ("breathing", 6.0), ("listen", 9.0)):
        action = bpy.data.actions.new(clip)
        action.use_fake_user = True
        rig.animation_data.action = action
        frames = round(seconds * FPS)
        for frame in range(frames + 1):
            t = frame / frames
            wave = math.sin(t * math.tau)
            inhale = .5 - .5 * math.cos(t * math.tau)
            breath = inhale * (.004 if clip == "idle" else .012)
            # Listen has an anticipation, off-centre orientation and a long quiet hold.
            if clip == "listen":
                attack = min(1.0, max(0.0, (t - .12) / .19))
                release = min(1.0, max(0.0, (.96 - t) / .18))
                focus = min(attack * attack * (3 - 2 * attack), release * release * (3 - 2 * release))
            else:
                focus = 0.0
            for pose in rig.pose.bones:
                pose.rotation_mode = 'XYZ'
                pose.location = (0, 0, 0)
                pose.rotation_euler = (0, 0, 0)
                pose.scale = (1, 1, 1)
            rig.pose.bones["chest"].scale = (1 + breath, 1, 1 + breath * 1.5)
            rig.pose.bones["spine_02"].rotation_euler.x = math.radians(.26 * wave)
            rig.pose.bones["spine_03"].rotation_euler.z = math.radians(.16 * wave + .55 * focus)
            rig.pose.bones["neck_01"].rotation_euler.x = math.radians(.40 * inhale + 2.8 * focus)
            rig.pose.bones["neck_01"].rotation_euler.y = math.radians(2.0 * focus)
            rig.pose.bones["neck_01"].rotation_euler.z = math.radians(-2.2 * focus)
            rig.pose.bones["neck_02"].rotation_euler.y = math.radians(4.5 * focus)
            rig.pose.bones["head"].rotation_euler.z = math.radians(-.3 * wave - 4.8 * focus)
            rig.pose.bones["head"].rotation_euler.x = math.radians(-1.2 * focus)
            for side in (".L", ".R"):
                sign = 1 if side == ".L" else -1
                rig.pose.bones["clavicle" + side].rotation_euler.z = math.radians(sign * (.12 * inhale + .8 * focus))
                rig.pose.bones["upper_arm" + side].rotation_euler.x = math.radians(sign * .12 * wave)
                rig.pose.bones["auricle" + side].rotation_euler.y = math.radians(sign * .7 * focus)
                for finger in ("thumb", "index", "middle", "ring", "little"):
                    for joint in (1, 2, 3):
                        name = f"{finger}_{joint:02d}{side}"
                        rig.pose.bones[name].rotation_euler.x = math.radians((.15 * wave + focus * .45) / joint)
            for pose in rig.pose.bones:
                pose.keyframe_insert("location", frame=frame, group=pose.name)
                pose.keyframe_insert("rotation_euler", frame=frame, group=pose.name)
                pose.keyframe_insert("scale", frame=frame, group=pose.name)
        action["loop"] = True
        action["purpose"] = {"idle": "Near-motionless observation with planted feet", "breathing": "Thin chest and neck respiration, no foot drift", "listen": "Anticipate, incline off-centre cranium, long attention hold, settle"}[clip]
        records[clip] = {"seconds": seconds, "frames": frames + 1, "fps": FPS, "loop": True,
            "root_motion_m": 0, "contact": "Both feet planted; pelvis and leg transforms fixed"}
    rig.animation_data.action = bpy.data.actions["idle"]
    bpy.context.scene.frame_set(0)
    return records
