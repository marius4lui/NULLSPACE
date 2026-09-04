# Performance

No game benchmarks yet. Target remains 1080p 60 FPS high on approximately RTX 2060/RX6600 with modern six-core CPU. Host: Ryzen 5 7535HS, 30 GiB RAM, integrated Radeon 660M/RADV Mesa 26.1.8. Report host measurements honestly; do not extrapolate as measured discrete-target performance. Presets LOW/MEDIUM/HIGH/ULTRA required. Capture representative traversal, chase, combat, multiple-light and final sequence frame distributions/memory/draw calls/audio/AI/navigation cost.

## M4 isolated room diagnostic — 2026-09-05 local

No integrated-campaign or target-hardware result. Original-room source472df44, evidence9f438b2 in the environment-art worktree at `evidence/environment/m4/native-m4-02/IMPLEMENTER_REVIEW.md`. Actual1920x1080 Godot4.7.2 Forward+/Vulkan/RADV, isolated native session, VSync off,60fps cap. Warm samples start after each condition's first3 seconds; no recorder during the effect-isolation samples. CPU below is viewport rendering setup, not full-game CPU time. Conditions are cumulative, not independent additive savings.

| Condition | Viewport GPU p50/p95 ms | Render CPU p50 ms | Frame p50/p95 ms |
|---|---:|---:|---:|
| Baseline room |94.038/96.697|0.383|96.665/96.806|
| SSIL disabled |86.030/89.012|0.426|87.970/91.828|
| SSAO also disabled |57.480/58.782|0.374|59.259/59.524|
| Four fixture shadows also disabled |45.930/46.853|0.346|47.619/48.148|
| TAA also disabled |42.773/46.183|0.375|44.444/49.777|

Baseline29 draw calls,177742 submitted primitives,536477352 reported video-memory bytes. A separate233-second warm sample corroborates92.14/94.93ms viewport GPU against0.384/0.627ms rendering CPU. This is an actual warm GPU cost issue, not merely an import/startup delay. Preserve the room's normal fluorescent readability; disabling these effects diagnostically does not accept their removal from production.

Subsequent source inspection found23 textures imported with2D defaults, no mips and no VRAM compression. Agent correctione01fdb0 verifies actual BC5 normal/BC7 other resources with full mip chains and46837008 stored-image bytes; source PNG pixels and UIDs unchanged. That number is compressed texture-resource size, **not measured live VRAM reduction or frame-time improvement**. Native same-pose before/after, grazing paper/carpet response and bounded MSAA/render-scale/material/light diagnostics remain pending. No target-discrete performance score has been assigned.
