# M0 toolchain implementer evidence

Status: implementer local M0 checks PASS: exact toolchain, authoring/import, offline idempotence, both desktop cross-exports, native editor rendering and clean-checkout Linux exported runtime. Independent adversarial review and integration are separate requirements. No product, visual-quality, gun-feel, audio-quality, campaign or final-release gate is claimed.

Source revision: `9bdcfc35be84020f4340e5f727893793e409df5e` on `agent/toolchain`. Ownership is restricted to `tools/bootstrap/`, `docs/TOOLCHAIN.md` and this evidence directory. No `game/` files or root-owned state files changed. The earlier editor trial ran the identical implementation before its source commit; `source-files.sha256` records the subsequently frozen files. The clean clone started at the exact source commit and remained clean after generation/import/exports (`fresh-checkout/commit.txt`, empty `fresh-checkout/git-status.txt`).

## Host and installed tools

`host.txt` records Fedora 44 x86-64, kernel 7.1.12, AMD Ryzen 5 7535HS (6 cores/12 threads), approximately 30 GiB usable RAM and 657 GiB free project disk at the probe. Hardware Vulkan selects the integrated Radeon 660M through Mesa RADV 26.1.8. The PCI database labels the shared device ID Radeon 680M; Vulkan's actual selected device is Radeon 660M. llvmpipe is present but was not selected for native validation.

Existing supporting tools: Git 2.55.0, Python 3.14.7, FFmpeg 8.1.2, ImageMagick 7.1.2-27 (host build labels itself Beta), ripgrep 15.2.0, file 5.46, archive/Vulkan inspection tools. FFmpeg synthesis, convolution, echo and audio analysis filters were enumerated; it is the required audio-processing equivalent to SoX. No dependency installation outside the pinned portable tools was necessary. Host numpy 2.4.6/Pillow 12.3.0 and Blender-bundled numpy 2.3.4 were separately probed for the art worker.

| Artifact | Actual version / archive bytes | Verified SHA256 |
|---|---|---|
| Godot Linux editor | `4.7.2.stable.official.ed1daf0bf` / 77,860,424 | `cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4` |
| Blender Linux archive | `Blender 5.2.1 LTS`, build `9e2066aef7ef` / 383,688,088 | `a31f524fa99a527d3d52b7f5aaa68c34e1a19d5a1c9473f79c5cc610fd5b10e9` |
| Standard export templates | exact `4.7.2.stable` marker / 1,281,349,702 | `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011` |

Godot editor binary SHA256: `8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e`. Blender binary SHA256: `c2fd82553c979a7f6ba85202c487aa1173c90db588a67d74d70cc7b0c2bea01c`.

All bytes came from the official exact URLs in `tools/bootstrap/toolchain.lock.json`. Godot archives additionally matched the independently fetched official SHA512 entries. Blender matched its independently fetched official SHA256 entry. Published manifests are retained here. `install.json` records actual versions, paths, sizes and both checksum families. Shared installs are `/home/marius/.local/share/nullspace/toolchains/godot-4.7.2/`, `/home/marius/.local/share/nullspace/toolchains/blender-5.2.1/`, and `/home/marius/.local/share/godot/export_templates/4.7.2.stable/`.

`install-final.log` completed with exit 0. A separate `install-offline.log`/`install-offline.json` run completed with exit 0 and independently rechecked archive hashes plus immutable installed-file inventories. It reused every installation without replacement. `offline-empty-refusal.log` is an intentional negative check: missing cached official manifests make an offline bootstrap fail visibly instead of using an unpinned program. Archives, retained resumable parts and installed tools/templates occupy about 6.2 GiB total.

## Authoring and export checks

The diagnostic is original test geometry: three meshes, 564 triangles, three PBR materials, UVs/normals and an animated parent (`BootstrapRotation`). It is not production art. Blender created an editable `.blend` and GLB successfully. The exact clean-build source and export are retained under `fresh-checkout/source/`, with generator/version/hash/provenance manifest. The GLB structural check is deliberately limited to this diagnostic; no general Khronos-validator result is claimed.

Blender's unrounded bevel UV output varied by tiny floating-point values between runs. Diagnostic-only canonicalization to six decimal places produced matching GLB SHA256 `261f481db175fa81795a0a5e08f31f3079fd3a5f8ecea1863906c95d1591e2e7` in two separate Blender processes and the fresh checkout. Editable `.blend` saves are not asserted byte-identical. This precision policy was not applied to any production asset.

`validation/` contains one complete `bash tools/bootstrap/validate.sh` run. `fresh-checkout/` contains the same command run after `git clone --no-hardlinks --branch agent/toolchain` into a new directory at the source revision, without an existing Godot import cache. Both runs exited 0. Godot imported and instantiated exactly three meshes and the expected clip, then produced embedded-PCK release executables for both platforms. The clean exported Linux executable additionally instantiated its packed scene with `--headless`, exit 0 (`fresh-checkout/exported-linux-headless.log`).

| Build | Linux x86-64 ELF SHA256 | Windows x86-64 PE32+ SHA256 |
|---|---|---|
| Initial worktree | `bf318991b59de508ef301e92ded3a901cb87d41811313ad34096e59443e3e47c` | `2e85f0a0e4e5da77633cbeed83080b8082d7ed48c1b3189733eff70909901d92` |
| Clean checkout | `3ab8519bb7477ab25ecfc3ef75cbfbd4909c92a0a62c07e40a9424c1304b26b9` | `12636048e6c8a787c000e9ef030c2c6ee406542cbc1973cfe73897378df8d033` |

Executable hashes are not byte-identical across the two imports: the intentionally regenerated diagnostic `.glb.import` contains a different assigned resource UID. Geometry bytes and source are identical, and both builds load successfully on Linux. This is functional clean-checkout reproduction, not a bit-identical executable claim. Export outputs remain under each checkout's ignored `tools/bootstrap/output/{linux,windows}/`; `exports.sha256` and `export-formats.txt` record exact paths/formats.

## Native editor runtime and inspection

Run `native-editor` used the other worker's isolated Xwayland supervisor, private game display, game-only Pulse sink and isolated profile. Input method: implementer adaptive native diagnostic. It is not independent experiential gameplay. Run UTC: 2026-09-04 20:50:25.268 through 20:52:42.944. Startup records `Vulkan 1.4.354 - Forward+` on `AMD Radeon 660M (RADV REMBRANDT)`, window 1920×1080. Exact invocation and owned process identities are in `native-editor/launch.json` and `state.json`.

The implementer opened these four PNGs at original 1920×1080 resolution:

| Opened artifact | Controls and observed result |
|---|---|
| `native-editor/viewport-000-initial.png` | Three colored imported meshes, visible bevels, direct lighting and cast shadows. Diagnostic instructions readable. |
| `native-editor/viewport-001-requested.png` | Space paused the imported animation; F disabled the lamp; A was held 0.8 s and released. Camera orbit changed from 0.38 to -0.419951. Image became darker and direct lamp shadows disappeared. |
| `native-editor/viewport-002-requested.png` | F re-enabled the lamp while animation remained paused. Same object/camera pose; direct lighting and shadow returned. |
| `native-editor/viewport-003-requested.png` | D held 0.7 s and Space resumed animation. Orbit became 0.281270; visible pose/view changed and animation label returned to speed 1. |

F12 requested each subsequent capture. All ten logged native key presses match this implementer's declared controls. No input was injected through Godot action APIs. Escape exited the actual diagnostic, process exit 0. Cleanup completed with `cleanup_errors=[]`, no held controls, and `host_defaults_unchanged=true`; see `native-editor/state.json` and `supervisor-events.jsonl`.

`native-editor/interaction.mkv` is a 24 s x11grab recording with H.264 1920×1080 60 fps and 48 kHz stereo FLAC, SHA256 `174ff916679cce81193fcaeee3eebe032effc8161650ac24e202f5d6d53a81f3`. It covers the first pause/light-off/orbit interaction interval; later light-on/resume observations are the separate PNGs and event log. The diagnostic is silent. Probe/FFmpeg metadata prove capture structure only; no audio-listening or continuous-video experiential review is claimed.

## Clean Linux export native validation

Run `native-linux` launched the clean-checkout exported ELF directly, without the Godot editor or a source-project argument. Source revision was `9bdcfc35be84020f4340e5f727893793e409df5e`, clean at launch and afterward. The separately implemented native supervisor was clean at `76a9b644d4781ca92fa2fde82314a52576ed531f`. The executable SHA256 exactly matched the fresh build: `3ab8519bb7477ab25ecfc3ef75cbfbd4909c92a0a62c07e40a9424c1304b26b9`. Run UTC: 2026-09-04 21:01:07.291 through 21:01:48.170.

The completed `native-linux/game.log` confirms Godot `4.7.2.stable.official.ed1daf0bf`, Vulkan 1.4.354, Forward+, hardware Radeon 660M RADV, all three packed meshes and `BootstrapRotation`. It records `native_ready` with `renderer=forward_plus` and viewport 1920×1080. Release stdout was buffered during execution and present after normal exit; warning stderr appeared immediately.

The implementer opened `native-linux/viewport-000-initial.png` and `viewport-001-requested.png` at original 1920×1080 resolution. The first shows the imported three-material asset and shadows from the packed release. D held 0.5 s, F and Space changed camera orbit from 0.38 to 0.88, disabled the lamp and paused animation; the second image visibly confirms the changed view and lighting plus state text. F12 captured that state. All five native key presses are accounted for. Escape then quit normally, exit 0. `native-linux/state.json` confirms `cleanup_errors=[]`, no held controls and unchanged host audio defaults. No game code or source changed between source freeze, clean build and this run.

These six opened PNGs and the editor capture are listed with file checksums in `SHA256SUMS`. This proves the bounded diagnostic rendering/import/input/export workflow only. It does not constitute a final game playthrough or an independent review of this implementation.

## Corrections and remaining limits

- The first single-stream template transfer was deliberately terminated to enable bounded six-way range transfer; valid completed editor/Blender archives were preserved. `install.log` preserves that targeted SIGTERM. The ranged transfer completed and authenticated successfully.
- Initial Blender version validation omitted the official `LTS` suffix. The check was corrected to require the actual exact suffix; no version substitution occurred. `install-ranged.log` retains the old validator failure. Final and repeat runs pass.
- An initial diagnostic `.blend` inside the Godot import tree triggered an implicit Blender-path error. Authoring outputs moved outside that tree; only GLB is staged now. Initial `preflight/import.log` and failed load remain visible, followed by clean corrected import/load logs. The validation wrapper also checks engine error text, since that initial import returned exit 0 despite its asset error.
- The deprecated unnecessary `Material.use_nodes` assignment was removed after verifying Blender 5.2.1 creates a node tree by default. Corrected authoring runs are warning-free.
- Isolated X11 emits a nonfatal XIM/input-method warning; the exercised physical keyboard controls work. Text IME behavior is outside this diagnostic. A status request during automatic native cleanup briefly returned a socket reset; the next status confirmed clean stop. This harness race was reported to its owner.
- Windows was cross-exported only; there is no native Windows runtime result. Integrated-Radeon rendering is not target discrete-GPU performance evidence. Headless exports do not bake shader pipelines. No game exists in this branch and no game quality score or final playthrough is claimed.
