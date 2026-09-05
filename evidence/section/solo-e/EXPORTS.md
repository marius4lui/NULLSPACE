# Current playable development artifacts

Not a final release. Runtime/gameplay source: f30b31e. Subsequent0c1fe2c changes only test isolation and records; no exported gameplay change. Development branch is published at https://github.com/marius4lui/NULLSPACE/tree/feat/short-game; public main remains the documentation baseline.

Godot4.7.2 stable, checked-in original production assets, matching export templates. `NULLSPACE_GODOT_BIN=/absolute/path/to/Godot bash tools/build.sh all`. Root README also documents a fresh branch clone.

| Artifact | SHA256 | Actual check |
|---|---|---|
| build/linux/nullspace.x86_64 | caa078d82b7445365b727dbf5f22fbc04cd5e46d618e42ea5eefb30f291a78d0 | unarmed-export-02: complete Start/Service/Office/pursuit/hit/exit, no death/restore,54.333 active seconds; known-route diagnostic, not first-play duration. |
| build/windows/NULLSPACE.exe | 77ddf7fb324988dc78bccce9f72c3949fdc2abd4a58d4d233c7fd0794910ecb9 | Successful cross-export, no native Windows validation. |
| build/nullspace-linux-playtest-f30b31e.tar.gz | c1ce0e5b59fe0443dd839a50ceb814b933c5acefbd95105cc0fc3a8a0666ef26 | Archive listing verified: executable, README, credits, licences/engine notices, release notes, build info and executable checksum. |
| Fresh local clone Linux, /tmp/nullspace-current-repro.OneZkg/build/linux/nullspace.x86_64 | 2d8d97bb2ff44fbaa46bcbf990acda118d1c2da1cb656e1a25569b35b0d20780 | Clean clone/build succeeds, source escape26 passes. Abrupt five-frame headless startup warns of two exit leaks; normal native launch/quit of this rebuilt file still due. Not bit-identical packaging. |

Audio listening, meaningful10–15 minute first exploration, further pacing/polish, armed post-change flow and two final candidate runs remain open. User first-play feedback requested; all owned GPU previews stopped. See REPORT.md and the current issue register, including the test-profile overwrite/isolation correction. No earlier player-data recovery claimed.
