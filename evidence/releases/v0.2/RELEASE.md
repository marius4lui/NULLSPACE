# v0.2 Raw Beta preparation

User authorized all current work on GitHub main and the next beta release,2026-09-08.
Source7307821d60cd8bf449a67d81f5a2487bdf6b9428 includes Android work plus remote main4250b49
(difficulty modes and website changes). One STATUS.md conflict resolved by retaining both sections.
No unrelated worktrees or private signing material included. Later evidence-only commits do not change binaries.

- Fresh Godot4.7.2 imports and exports: Linux, Windows, offline Android ARM64 preview.
- Automated merged-source core258 + scene155 =413 assertions pass; three clock schedules pass.
  Website interaction DOM checks pass. These are labelled automated and are not device/feel proof.
- Fresh exported Linux Start Medium, forward movement and Escape pause exercised using
  existing isolated native runner; title/playing/paused screenshots inspected. Owned session
  stopped. No engine/script errors; known XIM initialization warning. No full-run/audio claim.
- Android APK signature v2/v3 verified; ZIP CRC and ARM64-only native libraries checked.
  Debug preview package, versionCode3/0.2.0-beta-preview. Offline template limitations and
  missing physical Android testing explicitly disclosed in RELEASE_NOTES.md.
- Windows ZIP CRC verified; Linux TAR contains complete instructions/notices/build information.
- Release artifacts in build/archive/v0.2; checksums copied here. Publication and remote
  asset-digest verification recorded after upload. Prerelease only, not latest stable.

Final10–15minute game duration, listening, real Android installation/update/touch/thermal and
full final runs remain open. This release does not mark them complete.
