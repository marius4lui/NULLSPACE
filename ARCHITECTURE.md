# NULLSPACE concrete architecture

Current solo/short-game design replaces prior campaign layers and agent interfaces. Godot4.7.2, typed GDScript.

- Section scene coordinates actual map, two switches, exit/restart/end, HUD and checkpoints.
- SectionPlayer owns movement/look/collision/flashlight/interact/health using existing InputGate/settings/time.
- Pistol owns ammo/fire/reload and coordinated presentation.
- Listener owns actual LOS/hearing, dated decaying evidence, FSM/nav/combat. Search cannot query hidden player location.
- Concrete Door/Switch scenes use direct typed references and signals; acoustics only for this real map.
- Preserve tested GameFlow, SettingsManager, SaveSystem, CheckpointSystem, EventHub, SimulationClock, Telemetry. Bind snapshot fields directly without new generic adapter/registry/service layer.

Solo feat/short-game selectively reuses foundation52b8ace and secured Player WIPd0c60c1; Listener3b67be9 when needed. Complete existing room/player first, then pistol/Listener/doors/two-switch game in same scene. Import/build/actual operation/targeted tests before promoting coherent changes to main.

Save needed switch/pickup/player/pistol/safe-checkpoint data through existing atomic versioned storage. Pause-aware clock and InputGate clear held inputs across pause/death/load/focus. Listener resets away from spawn without hidden target injection.

Reuse original environment/materials, creature rig/clips and native capture tool. Two affordable laptop profiles; measurement, not expensive effects by default. No blanket core rewrite or new diagnostic platform.
