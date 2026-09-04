#!/usr/bin/env python3
"""Objective stereo/frame/sync checks. Does not hear audio or review gun feel."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import subprocess
import wave

import numpy as np

from qa_common import run, sha256, write_json


def analyze(directory: Path) -> dict:
    video = directory / "input-proof.mkv"
    audio = directory / "fixture-stereo.wav"
    probe = json.loads(run(["ffprobe", "-v", "error", "-count_frames", "-show_streams",
                           "-show_format", "-of", "json", str(video)], timeout=30))
    video_stream = next(entry for entry in probe["streams"] if entry["codec_type"] == "video")
    audio_stream = next(entry for entry in probe["streams"] if entry["codec_type"] == "audio")
    if not audio.exists():
        run(["ffmpeg", "-v", "error", "-nostdin", "-i", str(video), "-map", "0:a:0",
             "-c:a", "pcm_s16le", str(audio)], timeout=30)
    with wave.open(str(audio), "rb") as stream:
        rate = stream.getframerate()
        channels = stream.getnchannels()
        samples = np.frombuffer(stream.readframes(stream.getnframes()), dtype="<i2").reshape(-1, channels) / 32768.0
    # Tone power in a quiet 0.2–0.5 s interval distinguishes the actual channels.
    tone_sample = samples[int(rate * 0.2):int(rate * 0.5)]
    frequencies = np.fft.rfftfreq(len(tone_sample), 1.0 / rate)
    spectrum = np.abs(np.fft.rfft(tone_sample * np.hanning(len(tone_sample))[:, None], axis=0))
    dominant = frequencies[np.argmax(spectrum, axis=0)].tolist()
    block_size = int(rate * 0.005)
    envelope = np.sqrt(np.mean(samples[:len(samples) // block_size * block_size].reshape(-1, block_size, channels) ** 2, axis=(1, 2)))
    active = envelope > 0.12
    audio_onsets = np.flatnonzero(active & ~np.r_[False, active[:-1]]) * 0.005 + float(audio_stream.get("start_time", 0.0))
    stats_path = directory / "flash-frame-stats.txt"
    stats = subprocess.run(["ffmpeg", "-hide_banner", "-nostdin", "-loglevel", "info", "-copyts", "-i", str(video),
                            "-an", "-vf", "crop=128:128:1736:56,signalstats,metadata=print:key=lavfi.signalstats.YAVG",
                            "-f", "null", "-"], check=True, text=True, stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, timeout=30).stderr
    stats_path.write_text(stats)
    times = []
    is_white = []
    current_time = None
    for line in stats.splitlines():
        match = re.search(r"pts_time:([0-9.\-]+)", line)
        if match:
            current_time = float(match[1])
        match = re.search(r"lavfi.signalstats.YAVG=([0-9.]+)", line)
        if match and current_time is not None:
            times.append(current_time)
            is_white.append(float(match[1]) > 220.0)
    white = np.array(is_white, dtype=bool)
    video_onsets = np.array(times)[white & ~np.r_[False, white[:-1]]]
    pairs = [{"video_seconds": float(onset), "audio_seconds": float(audio_onsets[np.argmin(abs(audio_onsets - onset))]),
              "audio_minus_video_ms": float((audio_onsets[np.argmin(abs(audio_onsets - onset))] - onset) * 1000)}
             for onset in video_onsets] if len(audio_onsets) else []
    checks = {
        "resolution_1920x1080": video_stream["width"] == 1920 and video_stream["height"] == 1080,
        "60_fps_stream": video_stream["avg_frame_rate"] == "60/1",
        "ten_seconds_600_frames": int(video_stream.get("nb_read_frames", 0)) == 600,
        "48khz_stereo": rate == 48000 and channels == 2,
        "separate_left440_right660": abs(dominant[0] - 440) < 10 and abs(dominant[1] - 660) < 10,
        "nonzero_unclipped_audio": float(np.min(np.sqrt(np.mean(samples ** 2, axis=0)))) > 0.005 and float(np.max(np.abs(samples))) < 0.99,
        "three_recorded_visual_audio_pulses": len(video_onsets) == 3 and len(audio_onsets) == 3,
        "sync_within150ms": len(pairs) == 3 and max(abs(pair["audio_minus_video_ms"]) for pair in pairs) < 150,
    }
    result = {"status": "PASS_OBJECTIVE_MEDIA" if all(checks.values()) else "FAIL",
              "checks": checks, "video": str(video), "video_sha256": sha256(video),
              "audio": str(audio), "audio_sha256": sha256(audio), "channels": channels, "rate": rate,
              "dominant_quiet_frequencies_hz": dominant, "peak_per_channel": np.max(np.abs(samples), axis=0).tolist(),
              "rms_per_channel": np.sqrt(np.mean(samples ** 2, axis=0)).tolist(),
              "video_flash_onsets_seconds": video_onsets.tolist(), "audio_pulse_onsets_seconds": audio_onsets.tolist(),
              "sync_pairs": pairs, "streams": probe["streams"],
              "listening": "unverified", "continuous_video_experiential_review": "unverified",
              "limitation": "Stream cadence and sampled sync establish capture integrity, not actual rendered 60 FPS or experiential quality."}
    write_json(directory / "media-verification.json", result)
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--run-dir", type=Path, required=True)
    args = parser.parse_args()
    report = analyze(args.run_dir.resolve())
    print(json.dumps(report, indent=2))
    raise SystemExit(0 if report["status"] == "PASS_OBJECTIVE_MEDIA" else 1)
