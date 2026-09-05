#!/usr/bin/env python3
"""Extend the original editable M4 room into the compact two-circuit game.

No asset-pack content, random maze or replacement project. Existing materials,
metric wall/cove/ceiling/fixture recipes and the authored central room are reused.
"""
from pathlib import Path
import importlib.util
import json
import math
import random
import shutil
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location("original_environment", Path(__file__).with_name("build_environment.py"))
kit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(kit)
bpy.ops.wm.open_mainfile(filepath=str(kit.SOURCE / "nullspace_environment_m4.blend"))
kit.MATERIALS = {name: bpy.data.materials[name] for name in
                 ("wallpaper", "carpet", "ceiling", "painted_metal", "baseboard", "diffuser", "fixture_detail")}
manifest = {"revision": "short-map-1", "origin": "Original M4 extended with authored connected rooms",
            "rooms": [], "fixtures": [], "collision_boxes": [], "doors": []}
old_manifest = json.loads((kit.EXPORT / "environment_manifest.json").read_text())
manifest["fixtures"] = old_manifest["fixtures"]
for fixture in manifest["fixtures"]:
    fixture["room"] = "office_core"
    if fixture["id"] in ("m4_f05", "m4_f06", "m4_f09"):
        fixture["circuit"] = "office"
        fixture["unpowered"] = "OFF"

library = bpy.data.collections["01_EDITABLE_ModularArchitecture"]
old_room = bpy.data.collections["02_EDITABLE_M4_AuthoredRoom"]
groups = {}
objects_by_room = {}
rng = random.Random(51689)


def room(name, bounds, height=2.72, fixtures=(), style="office"):
    group = kit.collection("GAME_" + name)
    groups[name] = group
    objects_by_room[name] = []
    x0, x1, y0, y1 = bounds
    width, depth = x1 - x0, y1 - y0
    parts = objects_by_room[name]
    parts.append(kit.box(name + "_Floor", ((x0 + x1)/2, (y0+y1)/2, -.042),
                         (width, depth, .084), "carpet", group, 0))
    cells = {tuple(item[:2]): item for item in fixtures}
    nx, ny = round(width / 1.22), round(depth / .61)
    for ix in range(nx):
        for iy in range(ny):
            x, y = x0 + (ix + .5) * 1.22, y0 + (iy + .5) * .61
            if (ix, iy) in cells:
                item = cells[ix, iy]
                data = {"id": f"{name}_{ix}_{iy}", "variant": "fixture_prismatic", "position": [x, height-.016, -y],
                        "state": item[2], "room": name, "warmth": .035, "shadow": False}
                if len(item) > 3:
                    data.update(circuit=item[3], unpowered=item[4])
                manifest["fixtures"].append(data)
                continue
            tile = kit.tile(f"{name}_Tile_{ix}_{iy}", 1.197, .587, group)
            tile.location = (x, y, height - .008)
            tile.rotation_euler.z = math.pi if (ix + iy) % 3 == 0 else 0
            tint = rng.uniform(.91, 1)
            for color in tile.data.color_attributes["AgeTint"].data:
                color.color = (tint, tint-.003, tint-.008, 1)
            parts.append(tile)
    for iy in range(ny + 1):
        grid = kit.grid_runner(f"{name}_Cross_{iy}", width, group)
        grid.location = (x0, y0 + iy * .61, height - .014)
        parts.append(grid)
    for ix in range(nx + 1):
        grid = kit.grid_runner(f"{name}_Main_{ix}", depth, group)
        grid.location = (x0 + ix * 1.22, y0, height - .01)
        grid.rotation_euler.z = math.pi / 2
        parts.append(grid)
    manifest["rooms"].append({"id": name, "asset": f"short_{name}.gltf", "bounds": [x0, x1, -y1, -y0],
                              "height": height, "style": style})
    return parts


def wall(owner, name, a, b, height=2.72):
    dx, dy = b[0]-a[0], b[1]-a[1]
    temporary = kit.collection("TEMP_" + name)
    parts = kit.wall(name, math.hypot(dx, dy), temporary, height=height)
    objects_by_room[owner].extend(kit.duplicate(parts, groups[owner], name, (a[0], a[1], 0), math.atan2(dy, dx)))
    for obj in parts: bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.collections.remove(temporary)


def column(owner, x, y, width=.61):
    temporary = kit.collection("TEMP_column")
    parts = kit.column_module(owner + "_Column", width, temporary)
    objects_by_room[owner].extend(kit.duplicate(parts, groups[owner], "Column", (x, y, 0)))
    for obj in parts: bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.collections.remove(temporary)


def door(id, x, y, yaw=0):
    manifest["doors"].append({"id": id, "position": [x, 0, -y], "yaw": yaw})


# Keep the actual authored centre room; open its former capped continuations.
groups["office_core"] = kit.collection("GAME_office_core")
selected = [obj for obj in old_room.objects if not obj.name.startswith(
    ("NorthBlindTurn", "EastBlindTurn", "EntryBack", "WestBoundary"))]
objects_by_room["office_core"] = kit.duplicate(selected, groups["office_core"], "ReusedM4")
manifest["rooms"].append({"id": "office_core", "asset": "short_office_core.gltf", "bounds": [-6.1, 9.76, -18.3, 2.44],
                          "height": 2.72, "style": "office", "meaningful_spaces": "offset lobby / divided office / column room"})
wall("office_core", "WestFrontRetained", (-6.1, 0), (-6.1, 9.76))
wall("office_core", "WestRearRetained", (-6.1, 12.2), (-6.1, 14.64))

# Quiet arrival and a short physical exit vestibule. The known exit remains visible.
room("arrival", (-1.22, 6.1, -8.54, -2.44), fixtures=((1, 2, "NORMAL"), (4, 7, "NORMAL")))
for name, a, b in [("ArrivalWest", (-1.22,-8.54), (-1.22,-2.44)), ("ArrivalEast", (6.1,-8.54),(6.1,-2.44)),
                   ("ArrivalNorthL",(-1.22,-2.44),(1.22,-2.44)), ("ArrivalNorthR",(3.66,-2.44),(6.1,-2.44)),
                   ("ExitSouthL",(-1.22,-8.54),(1.22,-8.54)), ("ExitSouthR",(3.66,-8.54),(6.1,-8.54))]:
    wall("arrival", name, a, b)
room("exit", (1.22,3.66,-10.98,-8.54), fixtures=((0,1,"NORMAL"),))
wall("exit","ExitWest",(1.22,-10.98),(1.22,-8.54))
wall("exit","ExitEast",(3.66,-10.98),(3.66,-8.54))
wall("exit","ExitBack",(1.22,-10.98),(3.66,-10.98))

# Office loop: the familiar central room can be revisited from a second orientation.
room("west_return",(-8.54,-6.1,9.76,18.3), fixtures=((0,4,"WEAK"),(1,11,"NORMAL")))
wall("west_return","ReturnWest",(-8.54,9.76),(-8.54,18.3))
wall("west_return","ReturnSouth",(-8.54,9.76),(-6.1,9.76))
wall("west_return","ReturnEast",(-6.1,14.64),(-6.1,18.3))
room("archive",(-8.54,-3.66,18.3,25.62),fixtures=((1,3,"NORMAL"),(2,9,"NORMAL","office","WEAK")))
wall("archive","ArchiveWest",(-8.54,18.3),(-8.54,25.62))
wall("archive","ArchiveNorth",(-8.54,25.62),(-3.66,25.62))
wall("archive","ArchiveSouth",(-6.1,18.3),(-3.66,18.3))
wall("archive","ArchiveDivideS",(-3.66,18.3),(-3.66,20.74))
wall("archive","ArchiveDivideN",(-3.66,23.18),(-3.66,25.62))
column("archive",-6.65,22.65)
room("office_switch",(-3.66,1.22,18.3,25.62),fixtures=((1,3,"NORMAL"),(2,9,"NORMAL","office","OFF")))
wall("office_switch","OfficeNorth",(-3.66,25.62),(1.22,25.62))
wall("office_switch","OfficeEast",(1.22,18.3),(1.22,25.62))
wall("office_switch","OfficeSouth",(-1.22,18.3),(1.22,18.3))
wall("office_switch","OfficeScreen",(-1.22,21.96),(1.22,21.96))

# Service loop: two paths into a dark region, not a locked combat corridor.
room("service",(9.76,17.08,4.88,12.2),height=2.48,fixtures=((1,2,"NORMAL"),(4,8,"WEAK")),style="service")
for name,a,b in [("ServiceWestS",(9.76,4.88),(9.76,7.32)),("ServiceWestN",(9.76,9.76),(9.76,12.2)),
                 ("ServiceSouth",(9.76,4.88),(17.08,4.88)),("ServiceEastS",(17.08,4.88),(17.08,7.32)),
                 ("ServiceEastN",(17.08,9.76),(17.08,12.2)),("ServiceNorthL",(9.76,12.2),(13.42,12.2)),
                 ("ServiceNorthR",(15.86,12.2),(17.08,12.2))]: wall("service",name,a,b,2.48)
room("service_bypass",(17.08,21.96,4.88,12.2),height=2.48,fixtures=((2,2,"NORMAL"),(1,9,"NORMAL","service","OFF")),style="service")
for name,a,b in [("BypassSouth",(17.08,4.88),(21.96,4.88)),("BypassEast",(21.96,4.88),(21.96,12.2)),
                 ("BypassNorthL",(17.08,12.2),(18.3,12.2)),("BypassNorthR",(20.74,12.2),(21.96,12.2)),
                 ("BypassScreen",(19.52,8.54),(21.96,8.54))]: wall("service_bypass",name,a,b,2.48)
room("blackout",(12.2,17.08,12.2,20.74),height=2.48,fixtures=((1,3,"OFF"),(2,10,"OFF")),style="blackout")
wall("blackout","BlackoutWest",(12.2,12.2),(12.2,20.74),2.48)
wall("blackout","BlackoutNorth",(12.2,20.74),(17.08,20.74),2.48)
wall("blackout","BlackoutDivideS",(17.08,12.2),(17.08,17.08),2.48)
wall("blackout","BlackoutDivideN",(17.08,19.52),(17.08,20.74),2.48)
column("blackout",14.70,16.75,.61)
room("service_switch",(17.08,21.96,12.2,20.74),height=2.48,fixtures=((1,3,"OFF"),(2,10,"NORMAL","service","OFF")),style="blackout")
wall("service_switch","SwitchEast",(21.96,12.2),(21.96,20.74),2.48)
wall("service_switch","SwitchNorth",(17.08,20.74),(21.96,20.74),2.48)

# Only useful sparse hardware: original vent mesh and metre-built utility pipe runs.
for owner,x,y in (("service",16.97,10.6),("service_bypass",21.85,6.1)):
    temporary = kit.collection("TEMP_vent")
    parts = kit.vent(owner+"Vent",temporary)
    objects_by_room[owner].extend(kit.duplicate(parts,groups[owner],"WallVent",(x,y,.78),-math.pi/2))
    for obj in parts: bpy.data.objects.remove(obj,do_unlink=True)
    bpy.data.collections.remove(temporary)
    for z in (2.12,2.26):
        objects_by_room[owner].append(kit.cylinder(owner+"Pipe",(x-1.2,y,z),.035,2.44,"painted_metal",groups[owner]))

door("office_door",-2.44,14.64)
door("west_door",-6.1,10.98,math.pi/2)
door("service_door",9.76,8.54,math.pi/2)
door("blackout_door",14.64,12.2)
door("bypass_door",17.08,8.54,math.pi/2)
door("exit_door",2.44,-8.54)

# Close visible transom gaps at the new 2.72m-ceiling doorways. The lower service
# ceiling meets the 2.525m frame; its corridor side still needs a return/header.
for owner, name, center, size in (
    ("arrival", "Exit_Lintel", (2.44, -8.54, 2.615), (2.46, .16, .21)),
    ("west_return", "WestDoor_Lintel", (-6.1, 10.98, 2.615), (.16, 2.46, .21)),
    ("office_core", "ServiceDoor_Lintel", (9.76, 8.54, 2.615), (.16, 2.46, .21)),
):
    objects_by_room[owner].append(kit.box(name, center, size, "wallpaper", groups[owner], .004))

# Produce ordinary optimized room assets and simple authored collision, not runtime primitives.
bpy.context.view_layer.update()
for name, parts in objects_by_room.items():
    for obj in parts:
        if any(token in obj.name for token in ("PaperedShell","_Pier","_Lintel","_Header","WrappedPier","Carpet","_Floor")):
            corners = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
            minimum = Vector([min(c[i] for c in corners) for i in range(3)])
            maximum = Vector([max(c[i] for c in corners) for i in range(3)])
            center, size = (minimum+maximum)/2, maximum-minimum
            manifest["collision_boxes"].append({"name":obj.name,"room":name,
                "center":[center.x,center.z,-center.y],"size":[size.x,size.z,size.y]})
    kit.export(parts,"short_"+name,"Authored compact campaign room, original shared material kit")
    for suffix in (".gltf",".bin"):
        shutil.copy2(kit.EXPORT/("short_"+name+suffix),kit.RUNTIME/("short_"+name+suffix))

for group in (library, old_room, bpy.data.collections.get("03_SOURCE_FixturesAndLighting")):
    if group:
        group.hide_render = True
        group.hide_viewport = True
bpy.ops.wm.save_as_mainfile(filepath=str(kit.SOURCE/"nullspace_short_map.blend"),compress=True)
for folder in (kit.EXPORT,kit.RUNTIME):
    (folder/"short_map.json").write_text(json.dumps(manifest,indent=2)+"\n")
print("NULLSPACE_SHORT_MAP",json.dumps({"assets":len(manifest["rooms"]),"fixtures":len(manifest["fixtures"]),
    "colliders":len(manifest["collision_boxes"]),"doors":len(manifest["doors"])}))
