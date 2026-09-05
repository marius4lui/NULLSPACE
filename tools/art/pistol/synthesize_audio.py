#!/usr/bin/env python3
"""Deterministic original weapon Foley and indoor impulse layers; no recordings/packs.

numpy is already part of the original texture toolchain. Wave metrics are not listening.
"""
from pathlib import Path
import json
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[3]
SOURCE = ROOT / "art/source/audio/pistol"
RUNTIME = ROOT / "game/assets/audio/pistol"
SOURCE.mkdir(parents=True, exist_ok=True)
RUNTIME.mkdir(parents=True, exist_ok=True)
RATE = 48000
rng = np.random.default_rng(842917)
report = {"rate": RATE, "origin": "Original seeded synthesis; no downloaded audio", "files": {}}


def noise(seconds, decay, high=0.0):
    count = int(seconds * RATE)
    raw = rng.normal(0, 1, count)
    if high:
        raw -= np.convolve(raw, np.ones(int(high)) / high, mode="same")
    return raw * np.exp(-np.arange(count) / RATE * decay)


def tone(seconds, freq, decay):
    t = np.arange(int(seconds * RATE)) / RATE
    return np.sin(t * np.pi * 2 * freq) * np.exp(-t * decay)


def write(name, samples, peak):
    # Short edge fades and DC removal; preserve relative layer dynamics, no hard clipping.
    samples = samples - np.mean(samples)
    samples[:24] *= np.linspace(0, 1, 24)
    samples[-480:] *= np.linspace(1, 0, 480)
    samples *= peak / max(1e-9, np.max(np.abs(samples)))
    pcm = (samples * 32767).astype("<i2")
    for folder in (SOURCE, RUNTIME):
        with wave.open(str(folder / (name + ".wav")), "wb") as output:
            output.setparams((1, 2, RATE, len(pcm), "NONE", "not compressed"))
            output.writeframes(pcm.tobytes())
    report["files"][name] = {"seconds": len(pcm) / RATE, "peak": float(np.max(np.abs(samples))),
                             "rms": float(np.sqrt(np.mean(samples**2))), "dc": float(np.mean(samples))}


for variation in range(3):
    length = 1.15
    t = np.arange(int(length * RATE)) / RATE
    blast = noise(length, 53 + variation * 3, 12) * 0.8
    blast += tone(length, 89 + variation * 6, 36) * 0.9
    blast += tone(length, 164 + variation * 9, 65) * 0.35
    # Early corridor reflections then a decaying filtered indoor tail.
    tail = np.convolve(noise(length, 7), np.ones(13) / 13, mode="same") * (1 - np.exp(-t * 45)) * 0.19
    for delay, gain in ((0.021, 0.27), (0.046, 0.18), (0.091, 0.10), (0.153, 0.065)):
        offset = int(delay * RATE)
        tail[offset:] += blast[:-offset] * gain
    write(f"pistol_{variation}", blast + tail, 0.89)

for name, frequency, duration, gain in (("empty", 1150, 0.13, 0.24), ("mag_out", 480, 0.24, 0.34),
                                         ("mag_in", 720, 0.27, 0.42), ("slide", 1650, 0.3, 0.43),
                                         ("pickup", 360, 0.3, 0.26), ("casing", 2200, 0.22, 0.22)):
    click = noise(duration, 90, 7) * 0.5 + tone(duration, frequency, 45) * 0.22
    click += tone(duration, frequency * 1.37, 75) * 0.10
    if name in ("mag_in", "slide"):
        offset = int(0.087 * RATE)
        click[offset:] += noise(duration, 120, 5)[:-offset] * 0.5
    write(name, click, gain)
write("plaster", np.convolve(noise(0.4, 28), np.ones(7) / 7, mode="same") + tone(0.4, 230, 42) * 0.13, 0.32)
write("metal", noise(0.55, 60, 8) * 0.3 + tone(0.55, 1670, 16) * 0.12 + tone(0.55, 2860, 25) * 0.07, 0.4)
(SOURCE / "synthesis.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report))
