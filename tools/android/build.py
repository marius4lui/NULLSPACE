#!/usr/bin/env python3
"""Build/sign Android APK without modifying the user's Godot/Java settings."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import secrets
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[2]

def run(args, **kwargs):
    subprocess.run([str(item) for item in args], check=True, **kwargs)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["debug", "release"])
    parser.add_argument("--offline-preview", action="store_true", help="Use installed APK template, no Gradle or downloads; debug preview only")
    parser.add_argument("--allow-downloads", action="store_true", help="Explicitly permit Gradle dependency downloads")
    parser.add_argument("--sdk", type=Path, default=Path.home() / "Android")
    parser.add_argument("--java", type=Path, default=Path.home() / ".sdkman/candidates/java/21.0.8-tem")
    parser.add_argument("--godot", type=Path, default=Path.home() / ".local/share/nullspace/toolchains/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64")
    parser.add_argument("--templates", type=Path, default=Path.home() / ".local/share/godot/export_templates/4.7.2.stable")
    parser.add_argument("--keys", type=Path, default=Path.home() / ".local/share/nullspace/android-signing")
    args = parser.parse_args()
    if args.offline_preview and args.mode != "debug":
        raise SystemExit("Offline preview is not the final API31 release configuration.")
    if not args.offline_preview and not args.allow_downloads:
        raise SystemExit("Gradle may download dependencies. Use --offline-preview for the debug APK, or explicitly authorize --allow-downloads.")
    args.sdk = args.sdk.resolve()
    args.java = args.java.resolve()
    out = ROOT / "build/android"
    out.mkdir(parents=True, exist_ok=True)
    source = args.templates / "android_source.zip"
    android = ROOT / "game/android"
    build = android / "build"
    stamp = android / ".template-sha256"
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    if not args.offline_preview and not stamp.exists():
        if build.exists():
            raise SystemExit("Existing untracked Android template: inspect it before replacing.")
        build.mkdir(parents=True)
        with zipfile.ZipFile(source) as archive:
            archive.extractall(build)
        (build / "gradlew").chmod(0o755)
        (build / ".gdignore").touch()
        (android / ".build_version").write_text("4.7.2.stable\n")
        stamp.write_text(digest)
    elif not args.offline_preview and stamp.read_text() != digest:
        raise SystemExit("Android template changed; inspect before rebuilding.")
    args.keys.mkdir(parents=True, exist_ok=True, mode=0o700)
    key = args.keys / (args.mode + ".keystore")
    password_file = args.keys / (args.mode + ".password")
    if not key.exists():
        if password_file.exists():
            raise SystemExit("Password exists without key; recover signing material before proceeding.")
        fd = os.open(password_file, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, "w") as stream:
            stream.write(secrets.token_hex(24))
        run([args.java / "bin/keytool", "-genkeypair", "-noprompt", "-keystore", key,
             "-alias", "nullspace", "-keyalg", "RSA", "-keysize", "3072", "-validity", "10000",
             "-dname", "CN=NULLSPACE, OU=Game, O=marius4lui",
             "-storepass:file", password_file, "-keypass:file", password_file])
        key.chmod(0o600)
    password = password_file.read_text().strip()
    env = os.environ.copy()
    env["JAVA_HOME"] = str(args.java)
    env["ANDROID_HOME"] = str(args.sdk)
    prefix = "GODOT_ANDROID_KEYSTORE_" + args.mode.upper()
    env.update({prefix + "_PATH": str(key), prefix + "_USER": "nullspace", prefix + "_PASSWORD": password})
    label = "offline-preview" if args.offline_preview else args.mode
    apk = out / ("NULLSPACE-android-" + label + ".apk")
    with tempfile.TemporaryDirectory(prefix="nullspace-android-editor-") as profile:
        env["XDG_CONFIG_HOME"] = profile
        config = Path(profile) / "godot"
        config.mkdir()
        (config / "editor_settings-4.7.tres").write_text(
            '[gd_resource type="EditorSettings" format=3]\n[resource]\n'
            + 'export/android/java_sdk_path = ' + json.dumps(str(args.java)) + '\n'
            + 'export/android/android_sdk_path = ' + json.dumps(str(args.sdk)) + '\n')
        with (out / (label + "-build.log")).open("w") as log:
            run([args.godot, "--headless", "--path", ROOT / "game", "--export-" + args.mode,
                 "Android Offline Preview" if args.offline_preview else "Android ARM64", apk], env=env, stdout=log, stderr=subprocess.STDOUT)
    log_text = (out / (label + "-build.log")).read_text()
    if "ERROR:" in log_text or "SCRIPT ERROR" in log_text or not apk.exists():
        raise SystemExit("Export error: inspect build/android/" + args.mode + "-build.log")
    build_tools = args.sdk / "build-tools/36.0.0"
    with (out / (label + "-signature.txt")).open("w") as report:
        run([build_tools / "apksigner", "verify", "--verbose", "--print-certs", apk], stdout=report, env=env)
    with (out / (label + "-manifest.txt")).open("w") as report:
        run([build_tools / "aapt2", "dump", "xmltree", apk, "--file", "AndroidManifest.xml"], stdout=report)
    (out / (apk.name + ".sha256")).write_text(hashlib.sha256(apk.read_bytes()).hexdigest() + "  " + apk.name + "\n")
    print(apk)

if __name__ == "__main__":
    main()
