# Listener in the playable section — intermediate

2026-09-05, solo root. Godot 4.7.2 ed1daf0bf, Blender 5.2.1, Fedora/Radeon 660M. Base 41cca46 plus working changes committed with this report; system hashes recorded. Original mesh/skin/63-bone rig and idle/breathing/listen preserved; only walk/run/attack/stagger added in a separate editable source.

Native-02/03 actual keyboard/mouse: Start, approach/take pistol, shoot, observe investigation/chase, die, restart pickup checkpoint, aim/fire three hits, force retreat, sprint away, press against wall, title/Continue. Native-03 screenshots 03–08 and copied telemetry show this sequence: three physical hits interrupted the Listener; Continue restored 8/12 and safe Arrival. Pauses between inspection commands are recorded, NOT an uninterrupted playthrough.

Opened native-03 motion-09/11 from corrected-encounter.mkv: articulated feet/arms replace the clearly broken native-02 bake. Child poses had used stale evaluated parents; explicit rest-relative bone bases corrected them. Failed export screenshots/video remain. Native-03 07-wall-tuck and 08-restore-pose confirm pistol clipping/restore-pose correction, not final gun-feel certification.

listener-test-04.log: 12 actual-scene physics checks pass; 45 nav polygons and 8.67m route around a partition separating points by 2m. Covers wall sight/attack rejection, acquisition, old shot clue without hidden tracking, movement, distant crouch rejection, finite search, repeated stagger/retreat. Earlier failures caught wrong navigation property names and repeated hits not resetting stagger. All retained. Core 256 plus three clock probes, controller 16 and pistol 20 remain passing.

Original seeded carpet/body/air/ballast audio uses bounded spatial sources. Initial loop-resource shutdown warnings corrected by stopping voices and allowing a mixer interval before exit; final headless and subsequent native shutdown retested. Recordings contain actual routed audio, NOT evidence of heard quality. Blender warnings concerned armature selection/shared texture sampler; actual model was opened, not accepted from export alone.

Remaining: full two-switch map/exit, pacing, listening, full-map/active-combat performance and release. No first-play duration or full successful run established. Final runs 0/2.
