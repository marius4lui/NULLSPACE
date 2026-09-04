"""Continuous quad cage: explicit sockets/webs, not intersecting primitive limbs."""
from __future__ import annotations

import math
import bpy
import bmesh
from mathutils import Vector
from recipe import TORSO, HEAD, ARM, LEG


class Cage:
    def __init__(self) -> None:
        self.vertices: list[tuple[float, float, float]] = []
        self.weights: list[dict[str, float]] = []
        self.faces: list[tuple[int, ...]] = []
        self.parts: list[str] = []
        self.seams: set[tuple[int, int]] = set()

    def vertex(self, point, weights=None) -> int:
        self.vertices.append(tuple(point))
        self.weights.append(weights or {})
        return len(self.vertices) - 1

    def face(self, indices, part: str) -> None:
        self.faces.append(tuple(indices))
        self.parts.append(part)

    def seam(self, a: int, b: int) -> None:
        self.seams.add(tuple(sorted((a, b))))

    def bridge(self, a, b, part: str, close_seam=True) -> None:
        assert len(a) == len(b), (len(a), len(b), part)
        for i in range(len(a)):
            j = (i + 1) % len(a)
            self.face((a[i], a[j], b[j], b[i]), part)
        if close_seam:
            self.seam(a[0], b[0])

    def cap(self, ring, point, part, weights) -> None:
        center = self.vertex(point, weights)
        for i in range(len(ring)):
            self.face((ring[i], ring[(i + 1) % len(ring)], center), part)

    def boundary(self, ring) -> None:
        for i in range(len(ring)):
            self.seam(ring[i], ring[(i + 1) % len(ring)])

    def align(self, reference, candidate):
        points = [Vector(self.vertices[i]) for i in reference]
        best = None
        for seq in (candidate, list(reversed(candidate))):
            for shift in range(len(seq)):
                order = seq[shift:] + seq[:shift]
                cost = sum((p - Vector(self.vertices[j])).length_squared for p, j in zip(points, order))
                if best is None or cost < best[0]:
                    best = (cost, order)
        return best[1]


def blend(a: dict, b: dict, factor: float) -> dict:
    factor = max(0.0, min(1.0, factor))
    return {name: a.get(name, 0) * (1 - factor) + b.get(name, 0) * factor for name in a.keys() | b.keys()}


def chain_weights(value: float, anchors: list[tuple[float, str]]) -> dict:
    anchors = sorted(anchors)
    if value <= anchors[0][0]:
        return {anchors[0][1]: 1.0}
    for (lo, left), (hi, right) in zip(anchors, anchors[1:]):
        if value <= hi:
            t = (value - lo) / (hi - lo)
            t = t * t * (3 - 2 * t)
            return {left: 1 - t, right: t}
    return {anchors[-1][1]: 1.0}


def body_weights(z, x=0.0) -> dict:
    result = chain_weights(z, [(1.14, "pelvis"), (1.32, "spine_01"), (1.49, "spine_02"),
        (1.68, "spine_03"), (1.85, "chest"), (1.94, "neck_01"), (1.98, "neck_02"), (2.03, "head")])
    if 1.65 < z < 1.94:
        amount = min(.76, max(0.0, (abs(x) - .125) / .13)) * math.sin(math.pi * (z - 1.65) / .29)
        result = blend(result, {"clavicle.L" if x > 0 else "clavicle.R": 1.0}, amount)
    return result


def ellipse(cage: Cage, center, ru, rv, count, weights, tangent=None) -> list[int]:
    center = Vector(center)
    tangent = Vector(tangent or (0, 0, -1)).normalized()
    u = Vector((1, 0, 0))
    u = (u - tangent * u.dot(tangent)).normalized()
    v = tangent.cross(u).normalized()
    return [cage.vertex(center + u * (ru * math.cos(i * math.tau / count)) +
        v * (rv * math.sin(i * math.tau / count)), weights) for i in range(count)]


def socket(rings, row0, row1, sector0, sectors, count):
    return ([rings[row0][(sector0 + k) % count] for k in range(sectors + 1)] +
        [rings[r][(sector0 + sectors) % count] for r in range(row0 + 1, row1 + 1)] +
        [rings[row1][(sector0 + k) % count] for k in range(sectors - 1, -1, -1)] +
        [rings[r][sector0 % count] for r in range(row1 - 1, row0, -1)])


def torso(cage: Cage):
    rings = []
    count = 32
    shoulder_lo = next(i for i, row in enumerate(TORSO) if row[0] == 1.65)
    shoulder_hi = next(i for i, row in enumerate(TORSO) if row[0] == 1.85)
    for z, rx, ry in TORSO + HEAD:
        ring = []
        ring_count = 64 if z > TORSO[-1][0] else 32
        for i in range(ring_count):
            angle = math.tau * i / ring_count
            cx = -.069 * max(0, min(1, (z - 1.91) / .15))
            cy = .012 - .081 * max(0, min(1, (z - 1.94) / .18))
            x, y = rx * math.cos(angle), ry * math.sin(angle)
            if z < 1.94:
                # Rib/serratus envelopes, sternum and scapular planes are geometry.
                chest = math.exp(-((z - 1.63) / .21) ** 4)
                front = max(0.0, -math.sin(angle))
                ridge = .009 * math.cos((z - 1.48) * 72 + abs(x) * 12) * chest
                y -= ridge * front ** 2
                y -= .017 * math.exp(-(x / .023) ** 2) * chest * front
                y += .016 * math.exp(-((abs(x) - .11) / .045) ** 2) * chest * max(0, math.sin(angle))
                clavicle_z = 1.835 - abs(x) * .12
                y -= .018 * math.exp(-((z - clavicle_z) / .027) ** 2) * front ** 2
                y += .011 * math.exp(-((z - 1.40) / .13) ** 2) * front ** 3
                z_point = z + .025 * math.cos(angle) * math.exp(-((z - 1.82) / .14) ** 2)
            else:
                z_point = z
            if z > 2.0:
                # Closed curled lamellae occupy the anterior/lateral skull, not eyes or a mouth.
                # These are connected surface ridges with eccentric, vertically elongated folds.
                rim = 0.0
                for center_angle, center_z, width in ((5.74, 2.154, .67), (3.67, 2.135, .75)):
                    delta = (angle - center_angle + math.pi) % math.tau - math.pi
                    radius = math.sqrt((delta / width) ** 2 + ((z - center_z) / .148) ** 2)
                    # Interrupted helix/antihelix, without an iris-like central ring.
                    opening = max(.0, min(1.0, (delta / width + .76) * 2.5)) if center_angle > 5 else max(.0, min(1.0, (.76 - delta / width) * 2.5))
                    asymmetry = .77 + .23 * math.sin((z - center_z) * 14 + delta * 1.7)
                    rim += .027 * math.exp(-((radius - .82) / .14) ** 2) * opening * asymmetry
                    rim -= .008 * math.exp(-((radius - .59) / .18) ** 2) * opening
                    inner_arc = radius + .13 * delta / width
                    rim += .016 * math.exp(-((inner_arc - .39) / .13) ** 2) * opening * max(0, min(1, (z - center_z + .08) * 9))
                posterior = max(0, math.sin(angle))
                rim += .019 * math.exp(-((z - 2.187 - .043 * math.cos(angle)) / .024) ** 2) * posterior
                x += math.cos(angle) * rim
                y = y * .88 + math.sin(angle) * rim
                y -= .023 * math.exp(-((angle - 4.48 + (z - 2.14) * 1.8) / .23) ** 2) * math.exp(-((z - 2.14) / .14) ** 4)
                z_point -= .14 * x
            weights = body_weights(z, x)
            if z > 2.095:
                side_amount = .42 * min(1, abs(x) / .115) ** 3 * math.exp(-((z - 2.19) / .13) ** 4)
                weights = blend(weights, {"auricle.L" if x > 0 else "auricle.R": 1}, side_amount)
            ring.append(cage.vertex((cx + x, cy + y, z_point), weights))
        rings.append(ring)
    for row in range(len(rings) - 1):
        current_count = len(rings[row])
        if current_count != len(rings[row + 1]):
            for i in range(current_count):
                j = (i + 1) % current_count
                cage.face((rings[row][i], rings[row][j], rings[row + 1][j * 2], rings[row + 1][i * 2 + 1]), "cranium")
                cage.face((rings[row][i], rings[row + 1][i * 2 + 1], rings[row + 1][i * 2]), "cranium")
            cage.boundary(rings[row])
            continue
        for sector in range(current_count):
            if shoulder_lo <= row < shoulder_hi and (sector in list(range(28, 32)) + list(range(0, 4)) or 12 <= sector < 20):
                continue
            nxt = (sector + 1) % current_count
            part = "cranium" if row >= len(TORSO) - 1 else "torso"
            cage.face((rings[row][sector], rings[row][nxt], rings[row + 1][nxt], rings[row + 1][sector]), part)
        cage.seam(rings[row][current_count // 4], rings[row + 1][current_count // 4])
    cage.cap(rings[-1], (-.069, -.069, 2.3), "cranium", {"head": 1.0})
    cage.boundary(rings[len(TORSO) - 1])
    # Extra thoracic loops avoid the shoulder aperture; its clean socket retains 24 vertices.
    arms = {1: socket(rings, shoulder_lo, shoulder_hi, 28, 8, count), -1: socket(rings, shoulder_lo, shoulder_hi, 12, 8, count)}
    for loop in arms.values():
        cage.boundary(loop)
    # A shared seven-vertex perineal bridge makes both legs part of the same closed surface.
    crotch = [cage.vertex((0, .11 - k * .22 / 8, 1.065 + .015 * abs(k - 4) / 4), {"pelvis": 1.0}) for k in range(1, 8)]
    legs = {1: [rings[0][i % 32] for i in range(24, 41)] + crotch,
        -1: [rings[0][i] for i in range(8, 25)] + list(reversed(crotch))}
    for loop in legs.values():
        cage.boundary(loop)
    return arms, legs


def swept(cage: Cage, root, points, side, part, weight_function, count=24):
    previous = root
    ordering = None
    rings = []
    for index, (center, rx, ry) in enumerate(points):
        center = (center[0] * side, center[1], center[2])
        lo = points[max(0, index - 1)][0]
        hi = points[min(len(points) - 1, index + 1)][0]
        tangent = Vector(((hi[0] - lo[0]) * side, hi[1] - lo[1], hi[2] - lo[2]))
        if part.startswith("leg") and index >= 19:
            tangent = Vector((0, 0, -1))
        ring = ellipse(cage, center, rx, ry, count, weight_function(index, center), tangent)
        if part.startswith("leg") and index >= 19:
            for vertex in ring:
                x, y, z = cage.vertices[vertex]
                # A genuine multi-vertex plantar plane supports heel and forefoot together.
                if index >= 24:
                    z = 0.0
                if y < -.16 and z > .041:
                    z += .003 * math.cos((x - .186 * side) * 230)
                cage.vertices[vertex] = (x, y, z)
        if ordering is None:
            aligned = cage.align(previous, ring)
            ordering = [ring.index(item) for item in aligned]
        ring = [ring[j] for j in ordering]
        cage.bridge(previous, ring, part)
        previous = ring
        rings.append(ring)
    return rings


def hand(cage: Cage, root, side):
    suffix = ".L" if side > 0 else ".R"
    base_x = .510 * side
    # A 24-edge rectangular palm section transitions smoothly from the wrist.
    rings = []
    for z, halfwidth, depth in ((.826, .031, .023), (.798, .040, .026), (.758, .049, .026), (.715, .052, .025), (.689, .049, .023)):
        # Rounded rectangle perimeter with 8 across width and 4 across depth.
        coordinates = ([(i, 0) for i in range(9)] + [(8, j) for j in range(1, 5)] +
            [(i, 4) for i in range(7, -1, -1)] + [(0, j) for j in range(3, 0, -1)])
        ring = []
        for i, j in coordinates:
            u, v = i / 4 - 1, j / 2 - 1
            x = base_x + u * halfwidth * (1 - .10 * abs(v) ** 6)
            y = -.04 + v * depth * (1 - .22 * abs(u) ** 6)
            y -= .012 * max(0, (.82 - z) / .14) ** 2
            y += .0035 * max(0, v) * math.cos((u + 1) * 4 * math.pi) * math.exp(-((z - .735) / .06) ** 2)
            ring.append(cage.vertex((x, y, z), {"hand" + suffix: 1.0}))
        rings.append(ring)
    first = cage.align(root, rings[0])
    cage.bridge(root, first, "hand" + suffix)
    cage.boundary(root)
    # Thumb is a real aperture in the palm side, not a mesh intersecting it.
    thumb_start = 20 if side > 0 else 8
    for row in range(len(rings) - 1):
        for i in range(24):
            if row < 2 and thumb_start <= i < thumb_start + 4:
                continue
            cage.face((rings[row][i], rings[row][(i + 1) % 24], rings[row + 1][(i + 1) % 24], rings[row + 1][i]), "hand" + suffix)
        cage.seam(rings[row][0], rings[row + 1][0])
    thumb_root = socket(rings, 0, 2, thumb_start, 4, 24)
    cage.boundary(thumb_root)
    # Four distal web loops share internal web boundaries and the palm perimeter.
    grid = {}
    coordinates = ([(i, 0) for i in range(9)] + [(8, j) for j in range(1, 5)] +
        [(i, 4) for i in range(7, -1, -1)] + [(0, j) for j in range(3, 0, -1)])
    for coordinate, vertex in zip(coordinates, rings[-1]):
        grid[coordinate] = vertex
    for i in (2, 4, 6):
        for j in range(1, 4):
            grid[i, j] = cage.vertex((base_x + (i / 4 - 1) * .049, -.04 + (j / 2 - 1) * .023, .672), {"hand" + suffix: 1})
    for finger in range(4):
        start = finger * 2
        perimeter = ([(i, 0) for i in range(start, start + 3)] + [(start + 2, j) for j in range(1, 5)] +
            [(i, 4) for i in range(start + 1, start - 1, -1)] + [(start, j) for j in range(3, 0, -1)])
        loop = [grid[p] for p in perimeter]
        x = base_x + ((start + 1) / 4 - 1) * .049
        length = (.178, .218, .199, .154)[finger if side > 0 else 3 - finger]
        name = ("index", "middle", "ring", "little")[finger if side > 0 else 3 - finger]
        finger_mesh(cage, loop, (x, -.051, .674), (x + (finger - 1.5) * .014, -.131, .674 - length), .0125, name + suffix)
    thumb_mesh(cage, thumb_root, side)


def finger_mesh(cage, root, start, tip, radius, name):
    start, tip = Vector(start), Vector(tip)
    points = []
    for t in (0, .08, .22, .31, .35, .39, .49, .60, .64, .68, .77, .88, .96):
        center = start.lerp(tip, t)
        center.y = start.y + (tip.y - start.y) * (.22 * t + .78 * t * t)
        center.z += .015 * (t ** 3 - t)
        taper = 1 - .49 * t
        knuckle = 1 + .30 * math.exp(-((t - .35) / .05) ** 2) + .23 * math.exp(-((t - .65) / .05) ** 2)
        if t > .9:
            taper *= .7
        points.append((tuple(center), radius * taper * knuckle, radius * .86 * taper))
    def weights(index, center):
        t = index / (len(points) - 1)
        return chain_weights(t, [(0, "hand" + name[-2:]), (.18, name[:-2] + "_01" + name[-2:]),
            (.49, name[:-2] + "_02" + name[-2:]), (.81, name[:-2] + "_03" + name[-2:])])
    rings = swept(cage, root, points, 1, name, weights, 12)
    cage.cap(rings[-1], tip, name, {name[:-2] + "_03" + name[-2:]: 1})
    cage.boundary(root)


def thumb_mesh(cage, root, side):
    suffix = ".L" if side > 0 else ".R"
    start = (.464 * side, -.040, .795)
    tip = (.401 * side, -.093, .635)
    finger_mesh(cage, root, start, tip, .017, "thumb" + suffix)


def build_cage() -> bpy.types.Object:
    cage = Cage()
    arm_roots, leg_roots = torso(cage)
    for side in (-1, 1):
        suffix = ".L" if side > 0 else ".R"
        def arm_weights(index, center):
            z = center[2]
            return chain_weights(z, [(.84, "hand" + suffix), (.98, "forearm_twist" + suffix),
                (1.30, "forearm" + suffix), (1.46, "upper_arm_twist" + suffix),
                (1.70, "upper_arm" + suffix), (1.85, "clavicle" + suffix)])
        arms = swept(cage, arm_roots[side], ARM, side, "arm" + suffix, arm_weights)
        hand(cage, arms[-1], side)
        def leg_weights(index, center):
            if center[2] < .14:
                return chain_weights(-center[1], [(.04, "foot" + suffix), (.20, "toe" + suffix)])
            return chain_weights(center[2], [(.15, "foot" + suffix), (.30, "shin" + suffix),
                (.58, "shin" + suffix), (.68, "thigh_twist" + suffix), (.90, "thigh" + suffix), (1.10, "pelvis")])
        legs = swept(cage, leg_roots[side], LEG, side, "leg" + suffix, leg_weights)
        cage.cap(legs[-1], (.186 * side, -.100, .000), "leg" + suffix, {"toe" + suffix: 1.0})
    mesh = bpy.data.meshes.new("Listener_connected_quad_cage")
    mesh.from_pydata(cage.vertices, [], cage.faces)
    mesh.update()
    obj = bpy.data.objects.new("Listener_Surface", mesh)
    bpy.context.collection.objects.link(obj)
    for edge in mesh.edges:
        edge.use_seam = tuple(sorted(edge.vertices)) in cage.seams
    for i, weights in enumerate(cage.weights):
        for name, weight in weights.items():
            if weight > .00001:
                group = obj.vertex_groups.get(name) or obj.vertex_groups.new(name=name)
                group.add([i], weight, 'REPLACE')
    # Consistent outward normals and orphan removal; no voxel or intersection union.
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context='VERTS')
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(mesh)
    bm.free()
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.unwrap(method='ANGLE_BASED', margin=.009)
    bpy.ops.uv.average_islands_scale()
    bpy.ops.uv.pack_islands(rotate=True, margin=.012)
    bpy.ops.object.mode_set(mode='OBJECT')
    modifier = obj.modifiers.new("Editable_anatomical_surface", 'SUBSURF')
    modifier.levels = 1
    modifier.render_levels = 1
    obj["original_design"] = "Connected quad cage with explicit shoulder sockets, shared perineal bridge, palm webs and closed cartilage lamellae. No sourced mesh or primitive assembly."
    return obj
