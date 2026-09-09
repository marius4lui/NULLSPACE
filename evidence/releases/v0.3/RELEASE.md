# v0.3 — Beta Unstable

User authorized merging the Listener death feature into main and building the next
unstable beta on2026-09-09. [PR #4](https://github.com/marius4lui/NULLSPACE/pull/4)
was merged at07:44:07 UTC. Build/tag source is
**1700f3184db551a74768556c9feccbccbd9269ec**, the actual main merge commit.
Subsequent evidence/status changes do not change runtime or packaged binaries.
Release: [v0.3 Beta Unstable](https://github.com/marius4lui/NULLSPACE/releases/tag/v0.3).

Publication complete: all three packages and SHA256SUMS uploaded, every GitHub
asset digest/size matched the local file before publishing. The release is public,
prerelease=true, draft=false, and was not marked latest stable. Tag v0.3 resolves
to1700f31. [Published asset verification](publication.json). A transient DNS error
and slow upload delayed delivery; the completed files were not replaced or rebuilt.

## Integration and tests

Main had advanced through Android/v0.2. Mergece3e6a9 preserved Android controls,
mobile layouts, all difficulty modes and both additive preference sets. Touch can
now skip the death sequence after the same minimum as keyboard input. The existing
touch restart fixture checks an early rejected tap and a later accepted tap.
No new content, rigs or frameworks. Existing preview signing identity is reused.

- **671 automated assertions pass:** core258, existing scene90, difficulty42,
  Listener death176, wall/door/crouch79 and touch26. Three30/60/120 clock probes
  pass. Logs are retained under [logs](logs/). The touch fixture still reports the
  pre-existing24-object shutdown warning; this is not silently marked fixed.
- Native **Mobile renderer + touch menu**: actual scene176 death checks pass,
  including all four blood/intensity combinations, reduced motion, skip and reset.
  [Full video](native-mobile/death-matrix.mp4) and
  [opened temporal frames](native-mobile/temporal-frames.jpg) show reach, pull,
  finishing strike, collapse, blood-off black fade and readable touch skip/menu.
  This ran on desktop Linux, **not a physical Android device**. Fixture sourcece3e6a9
  has an identical game tree to main1700f31 (checked after merge); direct positioning
  and low health are explicitly automated fixture setup. Original MKV stays local;
  the MP4 is a full-length CRF26/AAC review derivative, not original lossless audio.
- Fresh Linux release binaries were operated using the existing isolated XTEST
  supervisor. Two full successful Medium campaigns follow the last gameplay change:

| Run | Actual result |
|---|---|
| [linux-01](linux-01/route-result.json) | Fresh Start -> both switches -> returned exit,52.8167 simulation seconds, session536f76fcc6e6fb7e1217ddb4903b8c01. |
| [linux-02](linux-02/route-result.json) | Separate process/fresh Start -> both switches -> returned exit,52.9 simulation seconds, session1fe194505b223507c32a7aed93a2101b. |

Both runs end at health45, with no weapon/ammo/shots, no death and no checkpoint
restart within the campaign. No game-state injection or AI disabling in these
routes. Ending screenshots were opened. Run02 reuses only an earlier task-owned
QA profile: blood/intensity=false and reduced motion/flashes=true persist while
new touch defaults are added. Telemetry is copied into each run directory; the
second process log originally lives in listener-death/export-route-03/profile.
Profiles/shader caches remain ignored and personal saves/settings are untouched.

These are **known-route automated functional checks**, not first-player experience
or proof of10–15minute duration. Runtime `unverified_os_input` labels are retained;
supervisor request logs supply the automation provenance.

## Build, packaging and performance

- Godot4.7.2 stable. Linux/Windows exports from main1700f31 via tools/build.sh all.
  Initial isolated export failed because the temporary template link was absent;
  recreated a task-only link to installed templates, then both exports passed.
  Original failed export log is retained. No toolchain download or global change.
- Offline Android ARM64 debug preview built with tools/android/build.py; no Gradle
  downloads. Package `dev.marius4lui.nullspace.preview`, versionCode4,
  versionName0.3.0-beta-unstable-preview. APK ZIP CRC, ARM64-only native libraries,
  manifest and v2/v3 signature verified. Public certificate SHA256 matches the
  prior preview:44edf5f7709f1f2527f1f65d2e71cd0614c84ae5471379ec58a4e73c2d14f857.
  Private signing files are outside Git/artifacts and were not published.
- Linux TAR fully read back; Windows ZIP CRC checked. Both contain executable,
  source BUILD_INFO, controls/readme, release notes, credits/licences, Godot notices
  and executable checksum. Three downloadable packages have [SHA256SUMS](SHA256SUMS);
  [audit.json](audit.json) records exact binary/package hashes and sizes.
- Fedora/Ryzen5 7535HS/Radeon660M RADV,1920x1080 window, Laptop75% internal scale,
  VSync/60 cap. Ten uncaptured5s windows per Linux run: run01 p50 16.662–16.720ms,
  p95 16.913–19.019ms, max47.340ms; run02 p50 16.659–16.847ms,
  p95 16.895–19.318ms, max27.623ms. Captured Mobile fixture windows reach
  p95 maximum28.845ms and overall setup/window maximum939.485ms;
  capture is not a locked60FPS or phone-performance claim.
- All three owned native sessions stopped; cleanup errors empty and before/after
  default audio devices identical. No unrelated process stopped.

## Remaining limits

Unstable prerelease, not complete-game acceptance. Windows cross-export only;
no physical Android install/update/multitouch/lifecycle/audio/thermal validation.
No heard-audio quality claim. Android retains the offline template's optional
Vulkan attribute typing and unused themed-icon issues; installation is not
guaranteed. Final API31 Gradle export and actual device checks remain open.
First exploration duration, pacing and listening/balance are still open.
