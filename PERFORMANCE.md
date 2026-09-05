# Performance

Primary host: Fedora44 laptop, Ryzen5 7535HS6c/12t,30GiB RAM, integrated Radeon660M reported by RADV, Mesa26.1.8. No other-hardware claims.

Latest targeted correction: fresh-clone b9a9c9f export reproduced311.019ms immediately after its first shot with no capture running. Pre-instancing/sharing the existing shot effect render combinations during scene load removed that large first-shot hitch in two same-route native runs (prewarm-native-01/02): max31.191/32.338ms, p50 16.653ms, p95 17.072/17.067ms at1920×1080 /1440×810 internal, Laptop, VSync off,60cap. Next windows max17.246/17.283ms. No >50ms event. These short samples do not certify complete-map performance. Actual30FPS menu cap separately gave p50~33.33ms/p95~33.7ms, persisted into cold rebuilt executable; changed back to60 through UI. Evidence in solo-e/REPORT.md.

Record actual resolution/render scale/profile/VSync/FPS cap/Godot/source and warm exploration/encounter frame times. Two profiles: laptop-first and enhanced. Responsiveness/readable fluorescents over expensive effects.

Historical room472df44 at1920×1080 warmGPU p50/p95 approximately92.14/94.93ms, rendering CPU.384/.627ms. Diagnostic SSIL/SSAO/shadow/TAA reductions showed substantial cost. This predates3D texture import fixes and is not current-game performance. Full former record archived.

Integrated room/player measurement (not full-game performance): source 1bb40ac, native-export-03, Linux export, 1920×1080 window / 1440×810 internal, low profile, SSAO/SSIL off, two shadowed fixtures, FXAA, 60 FPS cap. Five initial 5-second actual monotonic frame windows: p50 16.654–16.663ms, p95 16.793–16.848ms; GPU last samples 10.897–11.732ms. Logs in evidence/section/solo-a/. No extrapolation to combat/full map or other hardware. Earlier native-01 delta-based frame samples are not accepted as actual frame-time measurement.

fee2059 export also operated at 1280×720 / 960×540 internal after correcting actual window/viewport resizing. Image is softer at this internal resolution; 1920×1080 is the current default. Performance gates remain open until actual map/encounters exist.

2026-09-05 full map solo-e/native-02 (source working block after fee0e04, Godot4.7.2 Forward+/Vulkan/RADV, same laptop, 1920×1080 /1440×810 internal, Laptop, cap60, VSync off): four actual monotonic five-second windows through blackout/service/office/arrival yielded p50 16.640–16.678ms, p95 16.970–17.654ms; last GPU samples7.348–14.560ms,57–358 draw calls. Four >50ms hitches, maximum386.734ms. Includes native screenshots/first use; source native-01 also had up to374.669ms and42–45ms p95 during recorded encounter windows. Capture versus compile/scene cause is not isolated. PERF-001 remains open; measure actual exported uncaptured exploration/combat next. These are not foreign-hardware or stable-complete-game claims.
