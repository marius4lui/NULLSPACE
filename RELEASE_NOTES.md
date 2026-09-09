# v0.3 — Beta Unstable

Listener death feature integrated with current main, including difficulty modes and Android touch support.
Download: https://github.com/marius4lui/NULLSPACE/releases/tag/v0.3

- A valid lethal Listener hit plays a guarded2.6-second grab, pull, finishing strike and collapse. Tight spaces use a short local death. Skip with Enter/Escape or a touch after the minimum duration; checkpoint restart clears the sequence.
- Independent saved Blood effects and Intense death animation settings; Reduce motion overrides camera pulling. Existing death menu provides checkpoint restart or a new run with the selected difficulty, plus Main menu.
- Linux and Windows x86-64 archives; signed offline Android ARM64 debug preview, versionCode4, package `dev.marius4lui.nullspace.preview`, using the existing preview signing key. No Gradle downloads.

**Unstable prerelease, not a finished game.** Windows and physical Android validation remain unavailable; no heard-audio quality claim. Android retains the offline-template limitations described below. Known-route Linux completion is functional evidence, not a10–15minute first-play duration claim. See evidence/releases/v0.3/RELEASE.md for exact source, checks and artifacts.

Extract desktop archives before launching. Android preview can update the same preview package; do not uninstall to resolve a signing mismatch because it deletes app data. Start replaces current progress. SHA256SUMS accompanies all downloads. Original credits/licences retained.

---

## v0.2 — Raw Beta (previous release)

Second public prerelease: Android touch support plus the current main changes.
Download: https://github.com/marius4lui/NULLSPACE/releases/tag/v0.2

- Android ARM64: signed **debug preview APK**, versionCode3, package `dev.marius4lui.nullspace.preview`. Analog movement, swipe look, tap/drag fire, reload, interaction, flashlight, sprint/crouch toggles, pause, mobile graphics and touch settings.
- Fresh Linux and Windows x86-64 exports of the same source.
- Retains Easy, Medium (default), Hard and Nightmare already merged on main, with the respective switch/latch/fuse objectives, plus the redesigned website.

Extract desktop archives before launching. Android: copy the APK over USB and open it on the phone, permitting installation from the file manager. SHA256SUMS accompanies the assets. Preview updates use the same development signing key; do not uninstall to resolve a signing mismatch, since that deletes app data. Future final Android release uses a separate package; preview progress is not automatically migrated. Start replaces current progress; Continue restores a valid checkpoint.

**Known limits:** Android installation, real multitouch/audio/lifecycle, thermal performance and full runs are unverified; no phone was visible to ADB. This APK uses the installed offline Godot template to avoid uncached Gradle downloads. Template minimumAPI24 is not a support promise; Android12+/ARM64 is the intended target and final API31 Gradle release remains pending. Legacy exporter optional Vulkan attribute typing causes `aapt dump badging` to fail; aapt2 XML inspection and v2/v3 signature verification succeed. An unused themed-icon reference warning remains. Installation is not guaranteed. Windows is cross-exported, not natively validated. Initial touch regression reports a24-object shutdown warning. Meaningful10–15minute first-play duration, pacing, listening/balance and final full runs remain open. No finished-game or phone-performance claim.

Build instructions: tools/android/README.md and tools/build.sh. Original assets, credits and licences retained. Report device/OS, settings and reproduction steps in Issues.

---

## v0.1 — Raw Beta (previous release)

First public prerelease of the current short-game development build. Unpolished, not a finished or fully optimized release. This release changes version metadata and packaging only; no new rooms, tasks or gameplay changes are included.

Download the Linux or Windows archive from https://github.com/marius4lui/NULLSPACE/releases/tag/v0.1 . Extract the entire archive before launching. Linux is the exercised platform; Windows is a cross-export without native validation. Checksums are provided alongside the downloads.

Not a finished release. The complete two-circuit escape now runs in one connected original map: quiet arrival, offices, service/blackout, return and ending/credits. One pistol, one Listener, tactical doors, battery-free flashlight and milestone checkpoints.

Native checks exercised firing/reload, creature encounters, both switches, Continue, injury/death/restart and ending. FPS preference persists; two graphics profiles are available. First-shot render preparation and correctly scaled impact particles address observed defects. Linux export is operated; Windows is cross-exported but not natively tested.

Open: meaningful 10–15 minute first exploration, pacing/presentation/listening, full-map performance and final complete runs. A known-route diagnostic completed in approximately 54 active seconds; the advertised design duration has not been achieved or verified. See current ISSUES.md and evidence/section/solo-e/REPORT.md. No final completion claim.

Use the Laptop graphics profile first on integrated GPUs. Save files may change between future beta builds; keep a copy of existing saves before testing if you want to preserve them. Start begins a new game and replaces current short-game progress. Report bugs with your platform, graphics settings and reproduction steps through the repository Issues page.
