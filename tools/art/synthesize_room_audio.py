#!/usr/bin/env python3
"""Original seeded carpet/body Foley and periodic electrical ambience. No content packs."""
from pathlib import Path
import json
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
RATE = 48000
rng = np.random.default_rng(590612)
folders = [ROOT / "art/source/audio/room", ROOT / "game/assets/audio/room"]
for folder in folders:
    folder.mkdir(parents=True, exist_ok=True)
metrics = {"origin": "Original seeded synthesis", "rate": RATE, "listening": "not verified", "files": {}}


def save(name, audio, peak, loop=False):
    audio -= audio.mean()
    if not loop:
        audio[:96] *= np.linspace(0, 1, 96)
        audio[-960:] *= np.linspace(1, 0, 960)
    audio *= peak / max(np.abs(audio).max(), 1e-9)
    pcm = (audio * 32767).astype("<i2")
    for folder in folders:
        with wave.open(str(folder / f"{name}.wav"), "wb") as output:
            output.setparams((1, 2, RATE, len(pcm), "NONE", "uncompressed"))
            output.writeframes(pcm.tobytes())
    metrics["files"][name] = {"seconds": len(pcm) / RATE, "peak": float(np.abs(audio).max()),
                             "rms": float(np.sqrt(np.mean(audio**2))), "loop": loop}


for variation in range(4):
    t = np.arange(int(.48 * RATE)) / RATE
    grain = np.convolve(rng.normal(size=len(t)), np.ones(18) / 18, mode="same")
    heel = np.sin(2 * np.pi * (88 - t * 26) * t) * np.exp(-t * 38)
    cloth = grain * np.exp(-t * 16) * (1 - np.exp(-t * 180))
    save(f"carpet_{variation}", heel * .28 + cloth * .65, .25)
    t = np.arange(int(.72 * RATE)) / RATE
    grain = np.convolve(rng.normal(size=len(t)), np.ones(10) / 10, mode="same")
    weight = np.sin(2 * np.pi * (62 + variation * 3) * t) * np.exp(-t * 22)
    toe = np.maximum(0, t - .12)
    friction = grain * np.exp(-toe * 13) * (1 - np.exp(-toe * 95))
    save(f"listener_step_{variation}", weight * .35 + friction * .52, .48)

for variation in range(3):
    t = np.arange(6 * RATE) / RATE
    modulation = 1 + .05 * np.sin(2 * np.pi * (variation + 1) / 6 * t)
    hum = (.60 * np.sin(2 * np.pi * 100 * t + variation) + .18 * np.sin(2 * np.pi * 200 * t)
           + .045 * np.sin(2 * np.pi * 450 * t + .6) + .028 * np.sin(2 * np.pi * 650 * t)) * modulation
    save(f"hum_{variation}", hum, .20, loop=True)

# Circular FFT filtering produces seamless air/noise loops, not a repeated WAV click.
for name, seconds, cutoff, peak in (("air", 8, 250, .18), ("listener_breath", 6, 1100, .25)):
    count = seconds * RATE
    frequencies = np.fft.rfftfreq(count, 1 / RATE)
    spectrum = np.fft.rfft(rng.normal(size=count))
    spectrum *= 1 / (1 + (frequencies / cutoff)**4)
    spectrum *= np.minimum(frequencies / 50, 1)
    air = np.fft.irfft(spectrum, n=count)
    if name == "listener_breath":
        t = np.arange(count) / RATE
        air *= .16 + .84 * np.maximum(0, np.sin(2 * np.pi * t / 3))**2
    save(name, air, peak, loop=True)

for name, seconds, base, peak in (("attack", .65, 105, .55), ("hurt", .48, 130, .38),
                                 ("door", .75, 360, .40), ("breaker", .55, 160, .40)):
    t = np.arange(int(seconds * RATE)) / RATE
    noise = np.convolve(rng.normal(size=len(t)), np.ones(12) / 12, mode="same")
    signal = noise * np.exp(-t * 14) + .3 * np.sin(2 * np.pi * (base - t * 20) * t) * np.exp(-t * 10)
    if name == "door":
        signal += .06 * np.sin(2 * np.pi * 720 * t) * np.sin(np.pi * t / seconds)**2
    save(name, signal, peak)
(folders[0] / "synthesis.json").write_text(json.dumps(metrics, indent=2) + "\n")
print(json.dumps(metrics))
