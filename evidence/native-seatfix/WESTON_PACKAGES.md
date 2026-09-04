# User-local Weston dependency provenance

Downloaded from the official Fedora 44 `fedora`/`updates` repositories using:

```sh
dnf --repo=fedora --repo=updates download --arch=x86_64 --resolve \
  --destdir /home/marius/.local/share/nullspace/toolchains/weston-fedora-x86_64 weston.x86_64
rpm -K /home/marius/.local/share/nullspace/toolchains/weston-fedora-x86_64/*.rpm
```

Every listed RPM returned `digests signatures OK`; rechecked 2026-09-04 UTC. The seven archives were extracted with `rpm2cpio` / `cpio` into the **new** prefix `/home/marius/.local/share/nullspace/toolchains/weston-15.0.1-fedora44`. No RPM scriptlets were executed and no system installation or overwrite was performed. The exact executable reports Weston 15.0.1 and has SHA256 `b9f15748a1612c321896f3f2d24f6ea2417db7bedeb68a303cef28d007615747`.

| RPM filename | SHA256 |
|---|---|
| aml-0.3.0-10.fc44.x86_64.rpm | `c410c305bc9bc8962e74246b97edf3f1e89f11ac6a984e05c4ce31f98a51a2db` |
| neatvnc-0.9.0-6.fc44.x86_64.rpm | `0a687524c6258cee66f6532debbd23b780b6205b6ad706dbda9d58e8b4323d15` |
| turbojpeg-3.1.3-1.fc44.x86_64.rpm | `5b9624e130b4c4f0585cefbbf5510885b261d4f110b4344939c66a58dec6adaf` |
| weston-15.0.1-2.fc44.x86_64.rpm | `8b0eea5b5b2e68acc3919dbddcb05e2444f0832cb82cd765a6b682cbf207234c` |
| weston-libs-15.0.1-2.fc44.x86_64.rpm | `70735861cdd03f1ec50d8324544d11f0aac2a83ba479e0de5fc028fd87ebd420` |
| weston-libs-backend-rdp-15.0.1-2.fc44.x86_64.rpm | `2c5f5aeaf48db6aad79744791ac91dfdc2bc61c346e5ba278aec62767f2dc240` |
| weston-libs-backend-vnc-15.0.1-2.fc44.x86_64.rpm | `8d59fb510d7975fcb16f1a5d207205cdb24530267910f834c4aecf1ec8255693` |

The runner supplies relocated `LD_LIBRARY_PATH` and semicolon-separated `WESTON_MODULE_MAP` only to the owned compositor. The game receives neither override. Exact module hashes, compositor command, socket peer and owned device-descriptor audit are in every run's `state.json`. Only headless GL/kiosk shell is requested; no DRM/libinput seat grab, RDP or VNC service is launched. The compositor has no host DISPLAY/Wayland/D-Bus connection.

An earlier `sudo -n dnf install -y weston` failed because passwordless authorization was unavailable; no password was requested interactively. An initial architecture-unrestricted download was stopped and superseded by the explicit x86_64/official-repository command above. Those unused cached archives are not installed or Git evidence. This report authenticates the tested bytes; a future repository update must not silently substitute a different Weston version.
