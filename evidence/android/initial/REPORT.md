# Android initial implementation — 2026-09-08

Source: feat/short-game based on71a53e8; associated implementation commit contains this report.
Solo automated checks, no independent agents. Full Android release is NOT accepted.

Implemented concrete touch scene, analog move/look, single-tap fire with drag aiming,
action toggles, input invalidation, additive touch settings, Android Back/suspension,
mobile render profiles/light budgets, safe-area-aware menu/HUD and Android exports.
Existing map/game content retained; first-play duration is still open.

## Actions and results

- Headless actual-scene touch input:24 checks pass. First failed fixture injected
  window-space OS events on a headless display; corrected fixture injects local viewport
  touch events through the real viewport dispatch. Production action dispatch unchanged.
- Existing core258 checks +30/60/120 clock schedules pass. Player16, pistol20,
  Listener12, door15, escape26 pass. Test profiles isolated from user saves.
- Final touch reruns pass24 assertions but report24 ObjectDB instances at shutdown,
  including after explicit section cleanup. This remains an open test-teardown warning;
  no clean-shutdown or leak-free claim. Logs retained, no assertions disabled.
- Native Linux Mobile Vulkan/RADV660M,1600x900, actual title click Start and screenshot:
  inspected title and playing HUD. Found remaining keyboard introduction; corrected to
  touch instructions afterward. Native screenshot predates that text-only correction.
  This is not a physical touch/audio/performance or Android run. Owned sessions stopped.
- Initial Android export failed without ETC2 imports; enabled and successfully exported
  original assets. Gradle8.11.1 wrapper download timed out. Further download attempts
  stopped following user's slow-connection request; partial archive preserved in /tmp.
- Offline prebuilt-template debug APK built without further downloads; package
  dev.marius4lui.nullspace.preview, ARM64, version2/0.2.0-offline-preview, targetAPI36.
  v2/v3 signatures verify. XML inspected using aapt2; no uses-permission entries.
  SHA256 recorded separately. This is a development key, NOT a published release.
- Legacy template minimumAPI24 differs from final planned minimumAPI31. aapt badging
  rejects string-valued optional Vulkan required attributes produced by the legacy
  exporter; aapt2 XML tree succeeds and warns about an unused themed-icon reference.
  Physical install remains unverified; do not infer compatibility from signature alone.
- adb devices and lsusb show no phone, including after user replied that it was connected.
  No device data read, no APK installed, no app data deleted. Real Android final runs0/2.

## Open work

Final API31 Gradle release/signing and template correction; device installation/update,
physical multitouch/audio/lock/process-recovery and thermal testing; actual first-player
10–15minute duration and meaningful content/pacing corrections; two final release runs.
No finished-game,60FPS-on-phone or publication claim. Main and other worktrees preserved.
Full raw native session evidence remains at /tmp/nullspace-android-native-01 and -02.
