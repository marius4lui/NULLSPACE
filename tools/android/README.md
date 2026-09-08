# Android build

Current delivery is an **unaccepted development preview**, not the finished Android release.

## Offline preview (no downloads)

From the repository root, run `python3 tools/android/build.py debug --offline-preview`.
Requires the existing Godot 4.7.2 Android templates, Java 21.0.8 and Android build-tools 36.0.0.
Paths can be supplied with `--godot`, `--templates`, `--java`, `--sdk` and `--keys`.
The script does not modify user Godot/Java defaults. Output is under `build/android/`.

This uses Godot's prebuilt APK template and package `dev.marius4lui.nullspace.preview`.
Its template manifest allows API24+; the supported target remains Android12+/ARM64 and
no physical device has been accepted. It is isolated from the future release package/save.
The 4.7.2 legacy exporter emits string-valued optional Vulkan feature attributes that
`aapt dump badging` rejects; `aapt2 dump xmltree` and APK v2/v3 signature verification
complete. Physical installation remains an explicit check, not an inferred success.
The template resource table also references an unused missing themed icon; launcher
icons are separately supplied. These template issues need device validation/correction
before a final release.

Use USB file transfer to copy the APK to the phone, then open it and permit installation
from that file manager. No Internet download is needed. With an authorized ADB connection:

```sh
adb devices -l
adb install -r build/android/NULLSPACE-android-offline-preview.apk
adb shell monkey -p dev.marius4lui.nullspace.preview 1
```

Never uninstall an existing build merely to resolve a signing mismatch: that deletes
its app data. Preserve the same signing key for updates. Preview and final package data
are separate; preview progress is not automatically migrated to the final package.

## Final release configuration (not yet built)

`python3 tools/android/build.py release --allow-downloads` uses the pinned Godot Gradle template, API31
minimum, API36 target, ARM64, `dev.marius4lui.nullspace`. It may download Gradle/Android
dependencies. **Do not run this on the user's limited connection until downloads are
authorized again.** The attempted Gradle8.11.1 download timed out; downloads are stopped.
Template dependencies: AGP8.6.1, Kotlin2.1.21, Gradle8.11.1, compileSDK36,
build-tools36.1.0, Java17+ (local21.0.8). Installed other Gradle versions do not supply
all the required cached dependencies. No substitutions have been made to fake a build.

Keys live in `~/.local/share/nullspace/android-signing/` with private permissions,
outside Git. Only a development key has been created so far. Back up the final keystore
and password securely before publication; losing them prevents compatible updates.
Do not attach this directory or passwords to logs, issues, commits or releases.

## Controls and remaining acceptance

Left analog stick moves; right-side dragging looks. FIRE fires once per tap and can
be dragged to aim. LOAD reloads; USE operates doors/switches/pickup; LIGHT toggles the
flashlight; RUN/CROUCH toggle; II/Android Back pause. Touch sensitivity/size/opacity
are in Settings. Android suspension clears input and pauses; resume stays paused.

Physical install/update/multitouch/lock/process-death/audio/30-minute thermal checks,
meaningful first-play10–15minute duration and two final successful release runs remain
open. Desktop Mobile-renderer screenshots and headless tests are supporting evidence only.
