"""Directed anatomical plane refinement on the editable, joint-looped final surface.

This stage displaces the subdivided cage analytically. It creates real costal,
scapular and tendon relief rather than painting shadows onto the albedo.
"""
import math


def bell(value, center, width):
    return math.exp(-((value - center) / width) ** 2)


def refine_anatomy(obj):
    for vertex in obj.data.vertices:
        x, y, z = vertex.co
        lateral = abs(x)
        if 1.16 < z < 1.925 and lateral < .247:
            front = max(0.0, min(1.0, (.012 - y) / .066)) ** 2
            back = max(0.0, min(1.0, (y - .012) / .068)) ** 2
            sternum = bell(x, 0, .021) * bell(z, 1.70, .18)
            ribs = 0.0
            for index, level in enumerate((1.805, 1.747, 1.687, 1.627, 1.567, 1.507)):
                arc = level - .19 * lateral - .023 * bell(lateral, .13, .08)
                ribs += (.012 - index * .00055) * bell(z, arc, .0145)
            rib_side = min(1, max(0, (lateral - .025) / .055)) * min(1, max(0, (.23 - lateral) / .06))
            clavicle = .016 * bell(z, 1.881 - .19 * lateral + .012 * math.sin(lateral * 22), .016)
            fossa = .010 * bell(lateral, .106, .065) * bell(z, 1.821, .038)
            abdomen = .007 * bell(lateral, .072 + (z - 1.30) * .1, .016) * bell(z, 1.375, .13)
            y += front * (-.014 * sternum - ribs * rib_side - clavicle + fossa + abdomen)
            spine = .007 * bell(x, 0, .016) * bell(z, 1.60, .25)
            scapular_line = 1.78 - (lateral - .08) * .80
            scapula = .017 * bell(z, scapular_line, .025) * bell(lateral, .105, .065)
            scapula += .010 * bell(lateral, .15 - (1.82 - z) * .34, .017) * bell(z, 1.77, .08)
            y += back * (spine + scapula)
        if 1.905 < z < 2.025:
            center_x = -.069 * max(0, min(1, (z - 1.91) / .15))
            neck_side = abs(x - center_x)
            cord = bell(neck_side, .036 + (2.0 - z) * .33, .012)
            y -= .008 * cord * max(0, min(1, (.005 - y) / .05)) * bell(z, 1.965, .055)
        if .27 < lateral < .54 and .86 < z < 1.75:
            elbow = bell(z, 1.406, .035)
            vertex.co.x += math.copysign(.0035 * elbow, x)
            front = max(0, min(1, (-y + .018) / .05))
            tendon = .0037 * (bell(lateral, .495 - (z - .94) * .15, .009) + .65 * bell(lateral, .478 - (z - .94) * .15, .006))
            y -= tendon * front * bell(z, 1.11, .21)
        if .455 < lateral < .565 and .689 < z < .826:
            local_x = lateral - .510
            palm = bell(z, .757, .060)
            if y < -.04:
                y += .005 * bell(local_x, .004, .025) * palm
                y -= .004 * bell(local_x, -.026, .015) * palm
            else:
                tendon = sum(bell(local_x, point, .0045) for point in (-.036, -.012, .012, .036))
                y += .0028 * tendon * palm
        vertex.co.y = y
    obj.data.update()
    obj["directed_surface_refinement"] = "Real costal, sternum, clavicle, scapular, sternomastoid and metacarpal relief; retained editable mesh with original quad joint loops."
