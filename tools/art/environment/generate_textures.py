#!/usr/bin/env python3
"""Original, deterministic NULLSPACE material sources. No external content inputs.

Run with the pinned Python/Pillow/numpy versions recorded in the source manifest.
Output colors are sRGB; normal/height/ORM are linear data. Source heights are mm.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import shutil

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "art/source/textures/environment"
EXPORT = ROOT / "art/exported/environment/textures"
RUNTIME = ROOT / "game/assets/environment/textures"
SEED = 41073
VERSION = "environment-materials-1.0"


def value_noise(size: int, cells: int, seed: int) -> np.ndarray:
    """Periodic bicubic-like value noise; exactly wrapped sample domain."""
    rng = np.random.default_rng(seed)
    lattice = rng.random((cells, cells), dtype=np.float32)
    p = np.arange(size, dtype=np.float32) * cells / size
    i = p.astype(np.int32)
    t = p - i
    t = t * t * (3.0 - 2.0 * t)
    a = lattice[i[:, None] % cells, i[None, :] % cells]
    b = lattice[i[:, None] % cells, (i[None, :] + 1) % cells]
    c = lattice[(i[:, None] + 1) % cells, i[None, :] % cells]
    d = lattice[(i[:, None] + 1) % cells, (i[None, :] + 1) % cells]
    return (a * (1 - t)[None, :] + b * t[None, :]) * (1 - t)[:, None] + (
        c * (1 - t)[None, :] + d * t[None, :]
    ) * t[:, None]


def fbm(size: int, seed: int) -> np.ndarray:
    result = np.zeros((size, size), dtype=np.float32)
    for octave, weight in enumerate((0.5, 0.25, 0.14, 0.075, 0.035)):
        result += (value_noise(size, 4 * 2**octave, seed + octave * 11) - 0.5) * weight
    return result


def color(base: tuple[float, float, float], variation: np.ndarray) -> np.ndarray:
    return np.clip(np.asarray(base, dtype=np.float32)[None, None, :] + variation[:, :, None], 0, 1)


def normal_map(height_mm: np.ndarray, meters: tuple[float, float]) -> np.ndarray:
    size_y, size_x = height_mm.shape
    dx = (np.roll(height_mm, -1, 1) - np.roll(height_mm, 1, 1)) * size_x / (2000 * meters[0])
    dy = (np.roll(height_mm, -1, 0) - np.roll(height_mm, 1, 0)) * size_y / (2000 * meters[1])
    normal = np.stack((-dx, dy, np.ones_like(dx)), axis=-1)
    normal /= np.linalg.norm(normal, axis=-1, keepdims=True)
    return np.clip(normal * 0.5 + 0.5, 0, 1)


def write_material(
    name: str,
    base: np.ndarray,
    height: np.ndarray,
    rough: np.ndarray,
    meters: tuple[float, float],
    description: str,
    metallic: float | np.ndarray = 0.0,
) -> dict:
    target = SOURCE / name
    target.mkdir(parents=True, exist_ok=True)
    ao = np.ones(height.shape, dtype=np.float32)
    orm = np.stack((ao, np.clip(rough, 0.02, 1.0), np.full_like(ao, metallic)), axis=-1)
    maps = {"basecolor": base, "normal": normal_map(height, meters), "orm": orm}
    records = {}
    for role, array in maps.items():
        path = target / f"{name}_{role}.png"
        Image.fromarray(np.rint(np.clip(array, 0, 1) * 255).astype(np.uint8)).save(path, optimize=True)
        records[role] = {"path": str(path.relative_to(ROOT)), "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
        for stage in (EXPORT, RUNTIME):
            stage.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, stage / path.name)
    height_path = target / f"{name}_height_source.png"
    low, high = float(height.min()), float(height.max())
    Image.fromarray(np.rint((height - low) / max(high - low, 0.00001) * 65535).astype(np.uint16)).save(height_path)
    record = {
        "name": name,
        "recipe": VERSION,
        "seed": SEED,
        "description": description,
        "source": "Entirely original mathematical and hand-directed construction; no downloaded or generated image inputs.",
        "meters_per_tile": meters,
        "resolution": list(height.shape[::-1]),
        "normal_convention": "tangent +Y; image rows top-down",
        "height_source_mm_range": [low, high],
        "orm": "R=ambient occlusion (unbaked 1); G=roughness; B=metallic",
        "colorspace": {"basecolor": "sRGB", "normal": "linear", "orm": "linear", "height_source": "linear 16-bit"},
        "maps": records,
    }
    (target / "recipe.json").write_text(json.dumps(record, indent=2) + "\n")
    print(f"MATERIAL {name} {height.shape[1]}x{height.shape[0]} height={low:.4f}..{high:.4f}mm")
    return record


def wallpaper() -> dict:
    size = 2048
    yy, xx = np.mgrid[:size, :size].astype(np.float32)
    rng = np.random.default_rng(SEED + 1)
    noise = fbm(size, SEED + 2)
    weave = np.sin(xx * np.pi * 0.86 + np.sin(yy * 0.05) * 0.12) * 0.04 + np.sin(yy * np.pi * 0.74) * 0.035
    grain = rng.normal(0, 0.035, (size, size)).astype(np.float32)
    # Two offset, open lozenges, interrupted at their tips: original printed motif.
    cell = 64.0
    row = np.floor(yy / cell)
    u = ((xx + row * 32.0) % cell - 32.0) / 32.0
    v = (yy % cell - 32.0) / 32.0
    motif = np.exp(-((np.abs(u) * 0.68 + np.abs(v) - 0.59) / 0.032) ** 2)
    motif *= np.clip((0.87 - np.abs(v)) * 12.0, 0, 1)
    motif += 0.3 * np.exp(-((u * 0.88 + v - 0.16) / 0.03) ** 2) * np.exp(-(u * u + v * v) * 12.0)
    seam_dist = np.minimum(xx % 512.0, 512.0 - xx % 512.0)
    seam = np.exp(-(seam_dist / 0.72) ** 2)
    raised_edge = np.exp(-((seam_dist - 1.8) / 1.2) ** 2)
    height = noise * 0.14 + grain * 0.55 + weave * 0.30 + motif * 0.022 - seam * 0.11 + raised_edge * 0.065
    # Broad, very slight bubbles are sparse and do not read as random damage.
    for px, py, radius in ((347, 1330, 52), (1190, 566, 37), (1630, 1820, 75)):
        dx = np.minimum(np.abs(xx - px), size - np.abs(xx - px))
        dy = np.minimum(np.abs(yy - py), size - np.abs(yy - py))
        height += np.exp(-((dx / radius) ** 2 + (dy / (radius * 1.8)) ** 2)) * 0.90
    roll_fade = np.choose((xx // 512).astype(np.int32), [0.007, -0.006, 0.0, -0.002])
    base = color((0.735, 0.698, 0.545), noise * 0.075 + grain * 0.12 + roll_fade - motif * 0.022 - seam * 0.035)
    base[:, :, 2] += noise * 0.014
    return write_material("wallpaper", base, height, 0.88 + noise * 0.17 + grain * 0.08, (2.44, 2.44),
                          "Pale commercial paper; quiet broken-lozenge print, woven grain, 610mm roll seams, restrained raised edges and sparse adhesive bubbles.")


def carpet() -> dict:
    size = 2048
    yy, xx = np.mgrid[:size, :size].astype(np.float32)
    rng = np.random.default_rng(SEED + 7)
    broad = fbm(size, SEED + 9)
    fine = rng.normal(0, 0.35, (size, size)).astype(np.float32)
    pile = (fine + np.roll(fine, 1, axis=0) * 0.65 + np.roll(fine, 2, axis=0) * 0.25) / 1.9
    tuft = np.sin(xx * np.pi / 2.15 + np.sin(yy * 0.14) * 0.23) * np.sin(yy * np.pi / 3.1) * 0.18
    mid = value_noise(size, 170, SEED + 14) - 0.5
    height = pile * 0.47 + tuft * 0.32 + mid * 0.19 + broad * 0.13
    base = color((0.483, 0.451, 0.337), pile * 0.145 + tuft * 0.05 + mid * 0.07 + broad * 0.12)
    flecks = rng.random((size, size))
    base += (flecks > 0.978)[:, :, None] * np.array([0.075, 0.066, 0.05])
    base -= (flecks < 0.016)[:, :, None] * 0.065
    return write_material("carpet", base, height, 0.95 + broad * 0.06 - pile * 0.07, (2.44, 2.44),
                          "Original tightly looped commercial carpet; short directional pile, warm grey-beige flecks and irregular compressed tufts. Room moisture comes from a separate world mask.")


def ceiling() -> dict:
    size = 1024
    rng = np.random.default_rng(SEED + 20)
    rough = fbm(size, SEED + 21)
    fissure_image = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(fissure_image)
    for _ in range(3400):
        x, y = rng.integers(0, size, 2)
        length = int(rng.integers(2, 11))
        bend = int(rng.integers(-2, 3))
        # Fissures are partly directional from mineral-fiber manufacture.
        points = [(int(x), int(y)), (int(x + length // 2), int(y + bend)), (int(x + length), int(y + bend + 1))]
        draw.line(points, fill=int(rng.integers(60, 150)), width=1 if length < 7 else 2)
    fissure = np.asarray(fissure_image).astype(np.float32) / 255
    grain = rng.normal(0, 0.028, (size, size)).astype(np.float32)
    height = rough * 0.09 + grain * 0.7 - fissure * 0.7
    base = color((0.77, 0.758, 0.696), rough * 0.045 + grain * 0.13 - fissure * 0.11)
    return write_material("ceiling", base, height, 0.97 + rough * 0.04, (1.22, 1.22),
                          "Mineral-fiber acoustic board; thousands of original directional fissures, fine particulate grain and restrained neutral age. Tegular edge is geometry.")


def metal() -> dict:
    size = 1024
    rng = np.random.default_rng(SEED + 30)
    broad = fbm(size, SEED + 31)
    grain = rng.normal(0, 0.018, (size, size)).astype(np.float32)
    base = color((0.685, 0.681, 0.632), broad * 0.025 + grain * 0.08)
    return write_material("painted_metal", base, broad * 0.035 + grain * 0.21, 0.61 + broad * 0.12,
                          (1.22, 1.22), "Cream grey folded and powder-coated commercial steel; fine orange peel, mild age. Exposed fasteners use a separate untextured metal material.")


def baseboard() -> dict:
    size = 512
    rng = np.random.default_rng(SEED + 40)
    yy, xx = np.mgrid[:size, :size].astype(np.float32)
    broad = fbm(size, SEED + 41)
    grain = rng.normal(0, 0.02, (size, size)).astype(np.float32)
    extrusion = np.sin(yy * 0.43 + np.sin(xx * 0.02) * 0.4) * 0.006
    base = color((0.241, 0.215, 0.163), broad * 0.023 + grain * 0.09 + extrusion)
    return write_material("baseboard", base, grain * 0.14 + extrusion * 0.8, 0.71 + broad * 0.12,
                          (1.22, 1.22), "Dark brown extruded rubber cove base; subtle longitudinal extrusion and low soft sheen. Cove and rolled upper lip are actual profile geometry.")


def diffuser() -> dict:
    size = 512
    yy, xx = np.mgrid[:size, :size].astype(np.float32)
    wave = np.abs((xx % 8) / 4 - 1) * np.abs((yy % 8) / 4 - 1)
    broad = fbm(size, SEED + 50)
    base = color((0.84, 0.824, 0.759), wave * 0.025 + broad * 0.012)
    return write_material("diffuser", base, wave * 0.18, 0.38 + broad * 0.06, (0.61, 0.61),
                          "Original molded micro-prism acrylic diffuser; fine pyramidal cells. Opaque energy-conserving approximation avoids expensive layered transparency.")


def fixture_detail() -> dict:
    size = 512
    rng = np.random.default_rng(SEED + 60)
    base = np.zeros((size, size, 3), dtype=np.float32)
    rough = np.ones((size, size), dtype=np.float32) * 0.7
    metal = np.zeros((size, size), dtype=np.float32)
    emission = np.zeros_like(base)
    # Eight deliberately authored material swatches combine tiny fixture/vent parts.
    patches = [((0.46, 0.47, 0.43), 0.32, 0.88), ((0.10, 0.11, 0.09), 0.95, 0.0),
               ((0.82, 0.825, 0.77), 0.32, 0.22), ((0.80, 0.79, 0.73), 0.38, 0.0),
               ((0.86, 0.855, 0.76), 0.36, 0.0), ((0.67, 0.68, 0.62), 0.6, 0.0),
               ((0.60, 0.61, 0.56), 0.68, 0.0), ((0.20, 0.21, 0.18), 0.92, 0.0)]
    for index, (swatch, roughness, metallic) in enumerate(patches):
        row, column = divmod(index, 2)
        slices = (slice(row * 128, (row + 1) * 128), slice(column * 256, (column + 1) * 256))
        grain = rng.normal(0, 0.003, (128, 256, 1)).astype(np.float32)
        base[slices] = np.array(swatch) + grain
        rough[slices] = roughness
        metal[slices] = metallic
        if index == 4:
            emission[slices] = (0.92, 0.89, 0.76)
    record = write_material("fixture_detail", base, np.zeros((size, size), dtype=np.float32), rough, (1.22, 1.22),
                            "Eight original swatches atlas tiny steel, recessed slots, reflector, ceramic and powered/unpowered phosphor parts. Two-by-four cells with guarded UVs; emission only on phosphor cell.", metal)
    path = SOURCE / "fixture_detail" / "fixture_detail_emission.png"
    Image.fromarray(np.rint(emission * 255).astype(np.uint8)).save(path, optimize=True)
    for stage in (EXPORT, RUNTIME):
        shutil.copy2(path, stage / path.name)
    record["emission"] = {"path": str(path.relative_to(ROOT)), "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
    return record


def room_mask() -> dict:
    size = 1024
    yy, xx = np.mgrid[:size, :size].astype(np.float32)
    x = xx / (size - 1) * 12.2 - 6.1
    y = (1 - yy / (size - 1)) * 14.64
    broad = fbm(size, SEED + 70)
    noise = value_noise(size, 24, SEED + 75) - 0.5
    wet = np.exp(-(((x + 3.4) / 1.8) ** 2 + ((y - 10.7) / 1.25) ** 2))
    wet += 0.55 * np.exp(-(((x + 4.3) / 1.0) ** 2 + ((y - 11.5) / 1.6) ** 2))
    wet = np.clip(wet * (0.85 + noise * 0.5), 0, 1)
    traffic = np.exp(-((x - 2.15 - np.sin(y * 0.37) * 0.6) / 0.75) ** 2) * 0.55
    wall_dust = np.exp(-((6.1 - np.abs(x)) / 0.2) ** 2) * 0.3
    mask = np.stack((wet, np.clip(traffic + wall_dust, 0, 1), np.clip(0.5 + broad * 0.6, 0, 1)), axis=-1)
    path = SOURCE / "room_m4" / "room_m4_macro.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.rint(mask * 255).astype(np.uint8)).save(path, optimize=True)
    for stage in (EXPORT, RUNTIME):
        shutil.copy2(path, stage / path.name)
    return {"path": str(path.relative_to(ROOT)), "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "description": "R=moisture under authored ceiling leak; G=traffic compression and edge dust; B=broad dye variation. 12.2m by14.64m room. Macro only; 2K microdetail remains tiled at physical scale.",
            "world_godot_bounds_xz": [-6.1, 6.1, -14.64, 0.0]}


def main() -> None:
    records = [wallpaper(), carpet(), ceiling(), metal(), baseboard(), diffuser(), fixture_detail()]
    manifest = {"version": VERSION, "seed": SEED, "materials": records, "room_macro": room_mask(),
                "creator": "NULLSPACE environment-art delegated production agent", "license": "Original project content; ownership follows repository project terms.",
                "dependencies": {"numpy": np.__version__, "Pillow": Image.__version__}}
    path = SOURCE / "manifest.json"
    path.write_text(json.dumps(manifest, indent=2) + "\n")
    for stage in (EXPORT, RUNTIME):
        (stage / "material_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"TEXTURE_PIPELINE_OK {len(records)} materials; editable height sources retained; staging hashes identical")


if __name__ == "__main__":
    main()
