"""Bake original object-space tissue fields into one padded 2K PBR atlas."""
from __future__ import annotations

import json
import struct
import zlib
import bpy
import numpy as np
from recipe import TEXTURES, SEED, TEXTURE_SIZE


def write_png(path, array):
    array = np.asarray(array)
    depth = 16 if array.dtype == np.uint16 else 8
    channels = 1 if array.ndim == 2 else array.shape[2]
    color_type = {1: 0, 3: 2, 4: 6}[channels]
    height, width = array.shape[:2]
    if depth == 16:
        array = array.astype('>u2')
    raw = b''.join(b'\0' + array[row].tobytes() for row in range(height))
    def chunk(name, payload):
        return struct.pack('>I', len(payload)) + name + payload + struct.pack('>I', zlib.crc32(name + payload) & 0xffffffff)
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, depth, color_type, 0, 0, 0)) +
        chunk(b'IDAT', zlib.compress(raw, 7)) + chunk(b'IEND', b''))


def positions_at_uv(obj, size):
    mesh = obj.data
    mesh.calc_loop_triangles()
    uvs = mesh.uv_layers.active.data
    position = np.zeros((size, size, 3), dtype=np.float32)
    covered = np.zeros((size, size), dtype=bool)
    for tri in mesh.loop_triangles:
        uv = np.array([uvs[i].uv[:] for i in tri.loops], dtype=np.float32)
        xy = uv * (size - 1)
        xy[:, 1] = size - 1 - xy[:, 1]
        minimum = np.maximum(0, np.floor(xy.min(axis=0)).astype(int))
        maximum = np.minimum(size - 1, np.ceil(xy.max(axis=0)).astype(int))
        if np.any(maximum < minimum):
            continue
        xx, yy = np.meshgrid(np.arange(minimum[0], maximum[0] + 1), np.arange(minimum[1], maximum[1] + 1))
        a, b, c = xy
        den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(den) < 1e-9:
            continue
        w0 = ((b[1] - c[1]) * (xx - c[0]) + (c[0] - b[0]) * (yy - c[1])) / den
        w1 = ((c[1] - a[1]) * (xx - c[0]) + (a[0] - c[0]) * (yy - c[1])) / den
        w2 = 1 - w0 - w1
        mask = (w0 >= -.001) & (w1 >= -.001) & (w2 >= -.001)
        points = np.array([mesh.vertices[i].co[:] for i in tri.vertices], dtype=np.float32)
        patch = w0[..., None] * points[0] + w1[..., None] * points[1] + w2[..., None] * points[2]
        area = np.s_[minimum[1]:maximum[1] + 1, minimum[0]:maximum[0] + 1]
        position[area][mask] = patch[mask]
        covered[area][mask] = True
    return position, covered


def noise3(points, frequency, seed):
    xyz = points * frequency
    cell = np.floor(xyz).astype(np.int32)
    frac = xyz - cell
    frac = frac * frac * (3 - 2 * frac)
    result = np.zeros(len(points), dtype=np.float32)
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                with np.errstate(over='ignore'):
                    hashed = ((cell[:, 0] + dx).astype(np.uint32) * np.uint32(73856093) ^
                        (cell[:, 1] + dy).astype(np.uint32) * np.uint32(19349663) ^
                        (cell[:, 2] + dz).astype(np.uint32) * np.uint32(83492791) ^ np.uint32(seed))
                    hashed ^= hashed >> 13
                    hashed *= np.uint32(1274126177)
                    hashed ^= hashed >> 16
                value = (hashed.astype(np.float64) / 4294967295.0).astype(np.float32)
                weight = (frac[:, 0] if dx else 1 - frac[:, 0]) * (frac[:, 1] if dy else 1 - frac[:, 1]) * (frac[:, 2] if dz else 1 - frac[:, 2])
                result += value * weight
    return result


def pad(values, mask, iterations=16):
    values = values.copy()
    mask = mask.copy()
    for _ in range(iterations):
        next_values = np.zeros_like(values)
        count = np.zeros(mask.shape, dtype=np.float32)
        for axis, direction in ((0, -1), (0, 1), (1, -1), (1, 1)):
            neighbor = np.roll(mask, direction, axis)
            next_values += np.roll(values, direction, axis) * neighbor[..., None]
            count += neighbor
        edge = (~mask) & (count > 0)
        values[edge] = next_values[edge] / count[edge, None]
        mask |= edge
    return values, mask


def create_original_skin(obj):
    size = TEXTURE_SIZE
    positions, mask = positions_at_uv(obj, size)
    coverage = int(mask.sum())
    # Object-space continuity is retained across separately packed anatomy islands.
    positions, padded_mask = pad(positions, mask, 16)
    points = positions[padded_mask]
    x, y, z = points.T
    macro = noise3(points, 7, SEED) - .5
    meso = noise3(points, 34, SEED + 9) - .5
    fine = noise3(points, 185, SEED + 21) - .5
    pores = noise3(points, 650, SEED + 41) - .5
    head = np.clip((z - 2.055) / .075, 0, 1)
    joints = np.exp(-((z - 1.40) / .075) ** 2) * np.clip((np.abs(x) - .28) * 9, 0, 1)
    joints += np.exp(-((z - .58) / .065) ** 2) * np.clip((.29 - np.abs(x)) * 11, 0, 1)
    capillary = np.exp(-((np.sin(z * 83 + macro * 10 + x * 39) + np.sin(y * 118 + meso * 3)) / .15) ** 2)
    capillary *= .009 * np.clip(meso + .28, 0, 1)
    color = np.tile(np.array((.422, .383, .349), dtype=np.float32), (len(points), 1))
    color += macro[:, None] * np.array((.180, .171, .186), dtype=np.float32)
    color += meso[:, None] * .047 + fine[:, None] * .028
    color += head[:, None] * np.array((.035, .033, .025), dtype=np.float32)
    color += joints[:, None] * np.array((.008, -.015, -.008), dtype=np.float32)
    color -= capillary[:, None] * np.array((.30, .85, .10), dtype=np.float32)
    height = fine * .00012 + pores * .000040
    crease = (np.sin(z * 510 + meso * 3 + x * 110) ** 16) * joints
    height -= crease * .00010
    rough = np.clip(.66 + macro * .23 + meso * .13 - head * .085 + joints * .025, .47, .83)
    image_color = np.zeros((size, size, 3), dtype=np.float32)
    image_color[padded_mask] = np.clip(color, 0, 1)
    image_height = np.zeros((size, size), dtype=np.float32)
    image_height[padded_mask] = height
    dy, dx = np.gradient(image_height)
    sy = np.linalg.norm(np.gradient(positions, axis=0), axis=2)
    sx = np.linalg.norm(np.gradient(positions, axis=1), axis=2)
    normal = np.stack((-dx / np.maximum(sx, .0003), dy / np.maximum(sy, .0003), np.ones_like(dx)), axis=2)
    normal /= np.linalg.norm(normal, axis=2)[..., None]
    normal[~padded_mask] = (0, 0, 1)
    orm = np.zeros((size, size, 3), dtype=np.float32)
    orm[:, :, 0] = 1
    orm[:, :, 1] = .69
    orm[:, :, 1][padded_mask] = rough
    write_png(TEXTURES / "listener_skin_basecolor.png", np.uint8(np.clip(image_color, 0, 1) * 255 + .5))
    write_png(TEXTURES / "listener_skin_normal.png", np.uint8(np.clip(normal * .5 + .5, 0, 1) * 255 + .5))
    write_png(TEXTURES / "listener_skin_orm.png", np.uint8(np.clip(orm, 0, 1) * 255 + .5))
    write_png(TEXTURES / "listener_skin_height_source.png", np.uint16(np.clip(image_height / .0005 + .5, 0, 1) * 65535 + .5))
    recipe = {"seed": SEED, "size": size, "uv_coverage_pixels": coverage, "uv_padding_pixels": 16,
        "original_fields": "Object-space hashed trilinear tissue noise, low-contrast capillary fields, joint compression creases; no image inputs",
        "height_source_encoding": "16-bit; (value/65535-.5)*0.0005 metres", "channels": "basecolor sRGB; tangent normal +Y; ORM=(1,roughness,0)",
        "justification": "One shared 2K atlas supports close cranial/hand inspection on the complete 2.3m hero creature; no extra material slots."}
    (TEXTURES / "recipe.json").write_text(json.dumps(recipe, indent=2) + "\n")
    material = bpy.data.materials.new("Listener_Original_Thin_Tissue")
    nodes, links = material.node_tree.nodes, material.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = .69
    bsdf.inputs["Subsurface Weight"].default_value = .055
    bsdf.inputs["Subsurface Scale"].default_value = .009
    images = {}
    for field in ("basecolor", "normal", "orm"):
        image = bpy.data.images.load(str(TEXTURES / f"listener_skin_{field}.png"))
        image.colorspace_settings.name = 'sRGB' if field == "basecolor" else 'Non-Color'
        node = nodes.new('ShaderNodeTexImage')
        node.image = image
        node.label = "Original " + field
        images[field] = node
    links.new(images["basecolor"].outputs["Color"], bsdf.inputs["Base Color"])
    normal_node = nodes.new('ShaderNodeNormalMap')
    normal_node.inputs["Strength"].default_value = .70
    links.new(images["normal"].outputs["Color"], normal_node.inputs["Color"])
    links.new(normal_node.outputs["Normal"], bsdf.inputs["Normal"])
    separate = nodes.new('ShaderNodeSeparateColor')
    links.new(images["orm"].outputs["Color"], separate.inputs["Color"])
    links.new(separate.outputs["Green"], bsdf.inputs["Roughness"])
    links.new(separate.outputs["Blue"], bsdf.inputs["Metallic"])
    obj.data.materials.append(material)
    print("LISTENER_ORIGINAL_TEXTURES_OK", coverage)
