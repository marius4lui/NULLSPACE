# NULLSPACE pinned Linux toolchain

M0 uses the official standard Godot 4.7.2 stable editor, matching 4.7.2 stable export templates, and Blender 5.2.1 LTS. The exact URLs, archive lengths, SHA256 values, and independently published checksum pins live in `tools/bootstrap/toolchain.lock.json`. No installer selects a newer release or a fallback version. These development tools and the standalone bootstrap diagnostic do not establish any game quality or release gate.

## Install and verify

On Linux x86-64 with Python 3.12 or newer, run from the repository root:

```bash
python3 tools/bootstrap/install.py --report evidence/logs/bootstrap/install.json
source tools/bootstrap/env.sh
"${NULLSPACE_GODOT}" --version
"${NULLSPACE_BLENDER}" --version
```

The host's existing Git, Python, curl, FFmpeg, ImageMagick, ripgrep, file, archive tools and Vulkan tools are sufficient. FFmpeg provides the required audio processing equivalent to SoX. If bootstrapping a fresh Fedora host, the corresponding repository packages are `git python3 curl ffmpeg ImageMagick ripgrep file unzip tar xz vulkan-tools pciutils`; the script reports missing utilities instead of prompting for privileges. No Snap, content packs, package-index Python dependencies or global desktop settings are used.

Default binary paths are:

```text
${XDG_DATA_HOME:-$HOME/.local/share}/nullspace/toolchains/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64
${XDG_DATA_HOME:-$HOME/.local/share}/nullspace/toolchains/blender-5.2.1/blender
```

Matching templates install to `${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/4.7.2.stable/`. The installer checks the `version.txt` marker. `--root` and `--template-root` can override these destinations; when using a custom tool root, set `NULLSPACE_TOOLCHAIN_ROOT` before sourcing `env.sh`. Godot must see the chosen template directory through its standard data location during export. An isolated QA runtime does not require templates, so its separate XDG profile is safe for launches.

Downloads remain in the tool root's `downloads/` directory. Large archives use six concurrent 32 MiB HTTP ranges; the entire assembled archive is authenticated afterward. Completed ranges can be reused after interruption. The downloader only follows HTTPS redirects. Godot archives must match both pinned SHA256 and the downloaded official SHA512 manifest; Blender must match the pinned SHA256 and its separately downloaded official manifest. Archive sizes are checked too. A mismatch fails visibly and keeps the bytes for diagnosis.

Installation records hashes of immutable extracted files and checks them on repeat runs; generated Python bytecode caches are excluded. Existing unmanaged or changed installations cause an error instead of silent replacement. All installers share a process lock. Version checks execute each actual binary and require `4.7.2.stable.official.*` and `Blender 5.2.1 LTS` respectively. After a successful online install, this command verifies the cache and installations without network:

```bash
python3 tools/bootstrap/install.py --offline --report evidence/logs/bootstrap/install-offline.json
```

Approximately 7 GiB of free space accommodates archives, resumable parts and extracted tools. Diagnostic exports and evidence need additional space. The installer operates only under its explicitly selected tool/template destinations and does not modify shell startup files.

## Reproduce the asset/import/export diagnostic

```bash
bash tools/bootstrap/validate.sh
```

The generator creates three beveled, UV-mapped meshes with distinct PBR materials and an animated parent transform. It preserves the editable `.blend`, GLB and source/hash manifest under `tools/bootstrap/output/source/`. Its exported GLB FLOAT values are canonicalized to six decimal places to remove tiny Blender bevel/UV roundoff differences between runs; this is a diagnostic-only precision policy. Editable `.blend` files are retained but not asserted byte-identical between saves. Only GLB is staged into `tools/bootstrap/diagnostic/generated/`; Godot does not implicitly invoke Blender. This is original diagnostic geometry, intentionally separate from `game/` and unsuitable as production art.

The validation command checks the GLB header, self-contained buffers, materials, UVs, normals and animation; this targeted structural check is not a general Khronos validator. It then imports the GLB in Godot, loads it to verify three meshes and an animation clip, and cross-exports embedded-PCK release diagnostics for Linux and Windows x86-64. Logs are checked for engine error messages as well as process exit status because Godot import can return success despite an asset error. Output paths are:

```text
tools/bootstrap/output/linux/nullspace-bootstrap.x86_64
tools/bootstrap/output/windows/nullspace-bootstrap.exe
evidence/logs/bootstrap/validation/
```

The GLB, source and exported executables are generated outputs ignored by Git. A clean checkout recreates them from the committed generator, scenes and lock. Validation logs include their hashes. Windows PE cross-export is not native Windows runtime certification. Headless import/export is not a rendering check or shader-baked release build.

## Real Forward+ smoke

Use the separate `tools/qa/native.py` supervisor from the accepted native-QA branch once integrated. It isolates display, input, save data and game audio. Supply the absolute project or Linux executable path and these Godot options:

```text
--display-driver x11 --rendering-method forward_plus --rendering-driver vulkan --audio-driver PulseAudio
```

For the editor-runtime diagnostic, add `--path /absolute/repository/tools/bootstrap/diagnostic -- --output-dir /absolute/evidence/directory`. For the Linux export, use the executable followed by the renderer options and `-- --output-dir /absolute/evidence/directory`. Inspect the actual startup log for Forward+, Vulkan and hardware RADV, then open the 1920×1080 screenshot at original resolution. The diagnostic automatically captures its initial viewport after two rendered seconds; F12 adds a capture. A/D orbit the camera, Space pauses/resumes the imported animation, F toggles the dynamic shadowed light, and Escape quits. Logs record these native key events and the resulting state changes. The test does not generate audio or certify gameplay input, audio quality, gun feel, animation quality or final campaign acceptance.

On this host, Vulkan identifies an integrated AMD Radeon 660M, Mesa RADV; this cannot establish performance on the contract's discrete-GPU target. Actual native Windows, audio listening and game-quality evidence remain separate project requirements. See `evidence/logs/bootstrap/REPORT.md` for executed scenarios, corrections, observed outcomes and exact evidence paths.
