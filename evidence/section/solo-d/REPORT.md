# Tactical door in the actual room

2026-09-05 solo root; Godot 4.7.2/Blender 5.2.1 on the same Fedora/Radeon 660M. Source is the integrated-core commit containing this report. Original editable panels/hardware/astragal; existing room/Player/pistol/Listener/storage/native tools reused.

door-test-01.log FAIL: central leaf gap admitted sight and door-probe rays. Sealed leaf collision/astragal corrected it. door-test-02.log: 11 focused physical checks pass. test_door-final.log: 13 pass, also covering saved state and a puncture moving with its leaf. Attached-mark visual retest remains due: native-03/04-doorway-retreat visibly shows the former floating puncture, before this correction.

Native-02 actual pickup/sprint/E-open/walk-through exposed awkward targeting of open leaves. A concrete interaction-only doorway Area makes closing easy without affecting sight/shots/navigation. Occupancy prevents closing through a body.

Native-03 operated and opened: 02-door-tactical shows E-open/pass/turn/E-close; 03-listener-opens shows it reopen/enter after a shot; 04-doorway-retreat follows three aimed shots interrupting attack; 05-reclosed-after-stagger shows closing after it vacates. Telemetry records player opening at simulation 4.983s, closing 6.783s, Listener opening 8.633s, three stagger hits and retreat at 11.667s. These are scenario times, not campaign duration. Videos retain actual output; hit-motion-02/04 opened, showing shell/weapon/body reaction poses. Pauses between inspection calls are explicit. No uninterrupted-play or heard-audio claim.

Owned sessions stopped cleanly; no unrelated processes touched. Native-03 retained known startup XIM warning, no script exception or loop-resource leak. Final scene checks: 16 controller, 20 pistol, 12 Listener, 13 door; engine errors count as failures. Core 256 and three clock probes retained. No tests removed.

Integrated core, NOT complete game: connected map, two switches/exit, first-run duration, full-map polish/performance, reproducible release and final runs remain open.
