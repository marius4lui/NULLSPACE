# Performance

Primary host: Fedora44 laptop, Ryzen5 7535HS6c/12t,30GiB RAM, integrated Radeon660M reported by RADV, Mesa26.1.8. No other-hardware claims.

Record actual resolution/render scale/profile/VSync/FPS cap/Godot/source and warm exploration/encounter frame times. Two profiles: laptop-first and enhanced. Responsiveness/readable fluorescents over expensive effects.

Historical room472df44 at1920×1080 warmGPU p50/p95 approximately92.14/94.93ms, rendering CPU.384/.627ms. Diagnostic SSIL/SSAO/shadow/TAA reductions showed substantial cost. This predates3D texture import fixes and is not current-game performance. Full former record archived.

Integrated room/player measurement (not full-game performance): source 1bb40ac, native-export-03, Linux export, 1920×1080 window / 1440×810 internal, low profile, SSAO/SSIL off, two shadowed fixtures, FXAA, 60 FPS cap. Five initial 5-second actual monotonic frame windows: p50 16.654–16.663ms, p95 16.793–16.848ms; GPU last samples 10.897–11.732ms. Logs in evidence/section/solo-a/. No extrapolation to combat/full map or other hardware. Earlier native-01 delta-based frame samples are not accepted as actual frame-time measurement.

fee2059 export also operated at 1280×720 / 960×540 internal after correcting actual window/viewport resizing. Image is softer at this internal resolution; 1920×1080 is the current default. Performance gates remain open until actual map/encounters exist.
