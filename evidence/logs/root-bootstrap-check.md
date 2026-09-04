# Root bootstrap inspection — 2026-09-04

Main baseline3681293; production branches unmerged. This is not a product-quality pass.

Executed portable binaries:

- Godot: `/home/marius/.local/share/nullspace/toolchains/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 --version` → `4.7.2.stable.official.ed1daf0bf`.
- Blender: `/home/marius/.local/share/nullspace/toolchains/blender-5.2.1/blender --version` → `Blender 5.2.1 LTS`, build2026-08-25.

Opened native diagnostic screenshot at original1920×1080: `/home/marius/Projekte/Dev/NULLSPACE-worktrees/native-qa/evidence/native-qa/fixture-dev-01/moved.png`, SHA256`c28f6456daef4130a1a5be17a251e9169c0a7aeb70852a8697e41d2dc8b6d6d7`. Observed explicitly non-production corridor fixture, playing/captured state, changed position/look and accepted shot. Metadata reports focused owned game window and no held controls at capture. Corresponding game.log reports Forward+ on RADV AMD Radeon660M. Root only inspected image/logs; supplied no input.

Later agent findings require correction/retest: obscured surface VSync throttling, PipeWire sink cleanup lookup and unexplained later dev01 input. Initial screenshot corroborates rendered input capability, not final harness acceptance, native Windows support, audible quality, game feel or performance target.

Frozen contract, gates, game design and art direction SHA256 were rechecked and exactly match `evidence/design-freeze.md`.

Later root checks:

- Executed M2 logical test scene independently with a fresh XDG profile on exactGodot:70checks, no failures, exit0. This is not native interaction or a feature PASS. Static flow inspection identified focus loss during loading defectM2-001, correction assigned.
- Opened native-qa/fixture-dev-04/04-final.png at original1080p: playing/captured,3accepted fixture fires, expected60/-15mouse total. Read input/media verification:10s600frames,48kHzstereo, measured55–58ms pulse synchronization. This clean scripted diagnostic replaces unexplained dev01 inputs for controlled evidence, pending independent review.
- Attempted actual audio input using10s `fixture-stereo.ogg` (107175bytes) through the supported AudioContent helper. Runtime returned `audio content omitted because you do not support audio input`. No auditory review occurred; QA-002 remains open. Capture and numerical analysis cannot establish perceived audio quality.
