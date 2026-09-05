# Integrated room/player — controlled validation, not game completion

2026-09-05, solo root. Original room e70fec5 + secured Player d0c60c1 reused; coordinator/UI and fixes on feat/short-game. Latest source fee2059. Godot 4.7.2 stable official ed1daf0bf, Fedora 44 / Ryzen 5 7535HS / Radeon 660M RADV Mesa 26.1.8. Linux export SHA-256: `2a922b62d6c63bd68a11bafdde7d42589c54446dd618c8286781225a264540c3`.

## Actions and evidence

- `core-final-a.log` + rate-30/60/120: 256 existing logical checks and scheduling probes pass. `room-player-tests.log`: 16 actual headless physics checks pass, covering collision, posture, held-input pause, light/checkpoint, survivable first hit, death and safe restore. Automated, not experiential play.
- `native-01`: actually sent mouse/WASD/Ctrl/Shift/F/E/Escape, inspected original-resolution screenshots, recorded movement/pause. Original partition blocks capsule; crouch lowers viewpoint; light switch changes fixtures; dark room responds to flashlight; pause/title/settings work. No listening claim.
- `native-export-03`: launched release export, walked to and used light switch, toggled flashlight, returned to title and used Continue. Opened `04-continue.png` showing safe Arrival restore with lights off. Settings FOV input actually reached 110, not intended 96; wider view observed. Popup focus errors made this a failed settings check, not blanket PASS.
- `native-export-05`: latest export, 1920×1080 changed to 1280×720 using actual menu. Opened `01-resize-1280.png`, `02-title-1280.png`, `04-switch.png`, `05-flashlight.png`, `06-pause.png`: whole frame/control layout, switch prompt, actual dark checkpoint/beam and pause all visible. Low profile, 75% internal scale. Initial click in `03-switch-1280.png` missed Start; it is a menu image, not gameplay evidence. Corrected using the opened menu coordinates.
- `native-cold-06`: a NEW process of the same export uses the previous QA-only XDG data directory through `/usr/bin/env`. No new harness or user profile. Opened `01-cold-title.png`: stored 1280×720 and enabled Continue. Clicked Continue and opened `02-cold-continue.png`: safe Arrival with lights off restored, matching checkpoint. Wrapper's automatic executable hash identifies env, so the actual game hash is explicitly recorded above. Clean stop; no engine errors beyond known XIM warning.

## Defects found and corrected

- Averaged normals made original switch plate bulge. Flat surface groups corrected it in 15868e2; native export images inspected.
- Original costly SSIL/AO removed from Laptop profile, bounded two fixture shadows; original materials preserved, FXAA added for low-scale edges. Close wallpaper uniformity and low-resolution ceiling aliasing remain quality observations, not invented acceptance.
- Startup window differed from settings and left a black region (`native-export-02`, failed). Aligning defaults fixed initial export but not actual resize.
- OptionButton popup rebuild generated focus connection errors (`native-export-03`, failed). A few concrete cycling choice buttons replace popups in ead5912; no popup errors in subsequent runs.
- Direct DisplayServer resizing left native surface and viewport inconsistent (`native-export-04/03-applied-1280.png`, failed). fee2059 uses Window properties; 05 actual resize/controls retest passes. This follows [Godot's documented Window.size recommendation](https://docs.godotengine.org/en/stable/classes/class_displayserver.html#class-displayserver-method-window-set-size).

## Measurements and limits

Five initial 5s windows in native-export-03: actual monotonic frame p50 16.654–16.663ms, p95 16.793–16.848ms. Last GPU samples 10.897–11.732ms. 1920×1080 / internal 1440×810, low, no SSAO/SSIL, two fixture shadows, 60 FPS cap. Single room only. Earlier delta-derived native-01 intervals are not real frame-time proof.

This block has NO pistol, Listener AI, doors, two switches, campaign exit or complete run. Current local light checkpoint is an intermediate concrete binding. No heard audio, subjective gun feel, horror score, other-hardware performance, fresh-clone release or final-run claim. Production sound is not yet integrated. Private compositor XIM warning is retained; actual engine errors in earlier failed attempts are not hidden. Session profiles/caches excluded from Git; selected telemetry is copied without modification for evidence. No unrelated process/audio default was changed.
