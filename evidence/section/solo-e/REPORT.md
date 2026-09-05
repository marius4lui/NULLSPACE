# Compact two-switch map — in-progress verification

2026-09-05, solo root, Godot 4.7.2 / Blender 5.2.1, Fedora / Radeon 660M. Same production scene, original M4/module/material kit extended into ten asset groups (existing office group contains subdivisions); six physical doors, two original switch cabinets, safe objective anchors, returned exit/ending. No third objective or kill requirement.

Native-01 source is its recorded launch/source hashes and this working block, BEFORE subsequent fixes. Start/pickup/shot/open office door/first relay/hit/three-shot interruption/office-loop escape/reload/service door chase/three-shot retreat/door closure/blackout flashlight/second relay/Continue at Service/alternate service bypass/return/open exit/ending operated with real keyboard/mouse. Screenshots 01–23 opened at full resolution. Clips include inspection pauses; audio captured, NOT heard. End save contains both relays true, ending true, 10 loaded +3 spare; seven shots. Owned session stopped cleanly.

Office activated at 23.033s, Service at 55.767s, ending at 74.783s simulation time (Continue resets to saved time). This is a known-route, paused diagnostic, NOT a natural first run, 10–15 minute proof or final validation run. Duration/pacing is a serious open risk. No wait padding will be used.

Observed defects: twelve self-list.h:46 engine errors after Continue; detached enormous viewmodel flashlight shadow and glare; visible new-door transom openings; too-small panel lettering; insufficient persistent injury feedback. Corrections are in current work but require another native run. No error-free release claim.

Headless real-scene tests: controller16, pistol20, Listener12, door13 pass on first map. New escape26 passes in test_escape-02: nav reachability, both switch orders, closed-before-both exit, two-action power, safe death restores, unarmed physical exit crossing, ending save. Enemy disabled ONLY in focused objective test; not proof of ammo-free evasion. test_escape-01 retained: incorrect new expectation about completed Continue; existing core deliberately disables completed-game Continue and was not rewritten to satisfy that assumption.

Performance: initial scene windows typically ~16.65ms p50, but up to 374.67ms max and 42–45ms p95 during first-use/recorded encounter windows. Record overhead/first-use cause not isolated. No stable complete-game performance claim; targeted hitch telemetry added to identify actual event/timing in rerun. Laptop profile, 1920×1080 window, 75% internal scale, cap60; no other-hardware claim.

Final full exported successful validation runs: 0/2. Listening, natural first-play timing, reproducible full-map Linux export and final polish remain open.

## Corrected native-02 rerun

Started from native-01's real pre-ending backup (two circuits powered) in a separate fixture profile, not a new full run. Initial Continue plus three menu/Continue cycles restored safely: four section_restored records, zero engine/script errors. The expected isolated X input-method startup warning remains. Original failure was not hidden. Then flashlight off/on, one pistol shot into a closed service door, open/close/reopen, ordinary return movement, opening powered exit and ending/credits were operated. Session stopped cleanly; telemetry copied to run_1788573947.12239_191373.jsonl. Screens 01–10 opened, 07/08 have pause overlays. 05/06/07 verify moving door puncture; 03/04 show corrected viewmodel lighting; 06/09 show service/exit headers; 10 shows ending.

Four frame windows (1920×1080, Laptop 75%, cap60): p50 16.640–16.678ms, p95 16.970–17.654ms. Max386.734ms, four >50ms hitches; GPU last samples7.348–14.560ms. Uncaptured exploration still needed to separate capture/first-use effects. No stable-performance claim.

Targeted updated scene tests: room_player-05 16, pistol-03 20, listener-03 12, door-03 13, escape-final 26 pass. room_player-03/04 retained: test tried to inspect floor contact before the new safe process-frame acknowledgement; wait now allows acknowledgement and actual floor contact, no assertion removed. Core-final 258 plus three clock probes pass (two added FPS compatibility/invalid-value checks). Existing v1 settings lacking fps_limit normalize to60; saved values round-trip. New preference was added after native-02 launch and needs native/export exercise. Injury-label interaction also still pending.
