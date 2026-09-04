"""Non-exported neutral source-inspection stage; never production environment art."""
import bpy
from mathutils import Vector


def create_stage(scene):
    collection = bpy.data.collections.new("SOURCE_REVIEW_ONLY_not_exported")
    scene.collection.children.link(collection)
    mesh = bpy.data.meshes.new("Diagnostic_floor_mesh")
    mesh.from_pydata([(-100, -100, -.002), (100, -100, -.002), (100, 100, -.002), (-100, 100, -.002)], [], [(0, 1, 2, 3)])
    floor = bpy.data.objects.new("Diagnostic_floor_not_game_content", mesh)
    collection.objects.link(floor)
    material = bpy.data.materials.new("Diagnostic_charcoal")
    material.node_tree.nodes.get("Principled BSDF").inputs["Base Color"].default_value = (.056, .066, .065, 1)
    material.node_tree.nodes.get("Principled BSDF").inputs["Roughness"].default_value = .82
    mesh.materials.append(material)
    scene.world.color = (.13, .13, .13)
    for name, location, power, size, color in (
        ("Review_fluorescent_key", (-2.0, -3.0, 3.5), 340, 2.4, (1.0, .94, .79)),
        ("Review_neutral_fill", (2.8, -1.5, 2.8), 110, 2.0, (.84, .90, 1.0)),
        ("Review_edge_separation", (.5, 2.0, 3.1), 270, 1.7, (.91, .96, 1.0)),
    ):
        data = bpy.data.lights.new(name, 'AREA')
        data.energy, data.shape, data.size, data.color = power, 'DISK', size, color
        obj = bpy.data.objects.new(name, data)
        collection.objects.link(obj)
        obj.location = location
        obj.rotation_euler = (Vector((0, 0, 1.35)) - obj.location).to_track_quat('-Z', 'Y').to_euler()
    cameras = [
        ("review_body_threequarter", (3.3, -5.8, 2.4), (0, 0, 1.2), 62),
        ("review_head_close", (.62, -1.48, 2.31), (-.04, 0, 2.115), 76),
        ("review_body_front", (0, -6.2, 1.7), (0, 0, 1.20), 65),
        ("review_body_back", (-2.5, 5.5, 2.2), (0, 0, 1.20), 61),
        ("review_hand_close", (1.1, -.85, 1.04), (.51, -.04, .67), 58),
    ]
    for name, location, target, lens in cameras:
        data = bpy.data.cameras.new(name)
        data.lens = lens
        camera = bpy.data.objects.new(name, data)
        collection.objects.link(camera)
        camera.location = location
        camera.rotation_euler = (Vector(target) - camera.location).to_track_quat('-Z', 'Y').to_euler()
    scene.camera = bpy.data.objects["review_body_threequarter"]
    scene.render.resolution_x, scene.render.resolution_y = 1200, 1400
    scene.render.resolution_percentage = 100
