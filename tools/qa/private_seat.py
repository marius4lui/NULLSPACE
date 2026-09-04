"""XI2 policy on an authenticated, kernel-verified owned Xwayland connection."""
from __future__ import annotations

import os
from pathlib import Path
import re
import socket
import stat
import struct
import threading
from typing import Any, Callable

import Xlib.threaded  # Enable library locks before opening either X connection.
from Xlib import X, display
from Xlib.ext import xinput

from qa_common import same_process


class PrivateSeat:
    """Require an inputless compositor in controlled sessions; fail on drift.

    Device IDs are discovered, never supplied by an operator. The X socket's
    SO_PEERCRED must match the exact child process before querying XI2.
    This guard performs no device-property writes. Controlled Xwayland runs
    under a separate inputless compositor. Its fake-seat protocol proxies are
    enabled for Xwayland compatibility but have no host device producer.
    This is a provenance guard, not a sandbox against another same-UID client
    that deliberately obtains this run's cookie and uses XTEST itself.
    """

    PHYSICAL = re.compile(r"xwayland-(pointer|relative-pointer|pointer-gestures|keyboard):[0-9]+\Z")
    CORE = {"Virtual core pointer": xinput.MasterPointer,
            "Virtual core keyboard": xinput.MasterKeyboard,
            "Virtual core XTEST pointer": xinput.SlavePointer,
            "Virtual core XTEST keyboard": xinput.SlaveKeyboard}
    RAW = {13: "key_press", 14: "key_release", 15: "button_press",
           16: "button_release", 17: "motion"}

    def __init__(self, display_name: str, authority: Path, runtime: Path,
                 server_identity: dict[str, int], host_display: str | None,
                 allow_physical: bool, event: Callable[..., None], *, inputless_verified: bool = False) -> None:
        self.lock = threading.RLock()
        self.event = event
        self.allow_physical = allow_physical
        self.server_identity = server_identity
        self.connection: Any = None
        self.audits = 0
        self.raw_counts: dict[str, int] = {}
        self.baseline: list[dict[str, Any]] = []
        if not allow_physical and not inputless_verified:
            raise RuntimeError("Controlled XI2 guard requires a verified inputless compositor")
        if not re.fullmatch(r":[0-9]+", display_name) or display_name == host_display:
            raise RuntimeError("Private seat refuses host or nonlocal display")
        if authority.parent != runtime or authority.name != "Xauthority":
            raise RuntimeError("Private seat requires its exact runtime authority")
        for path, mode in ((runtime, 0o700), (authority, 0o600)):
            info = path.lstat()
            if info.st_uid != os.getuid() or stat.S_IMODE(info.st_mode) != mode or path.is_symlink():
                raise RuntimeError("Private runtime/authority ownership or mode is unsafe")
        if not same_process(server_identity):
            raise RuntimeError("Owned Xwayland identity changed before seat setup")
        os.environ["XAUTHORITY"] = str(authority)
        self.connection = display.Display(display_name)
        try:
            peer = struct.unpack("3i", self.connection.display.socket.getsockopt(
                socket.SOL_SOCKET, socket.SO_PEERCRED, struct.calcsize("3i")))
            if peer[0] != server_identity["pid"] or peer[1] != os.getuid():
                raise RuntimeError("X socket peer is not the exact owned Xwayland PID/UID")
            if not self.connection.has_extension(xinput.extname):
                raise RuntimeError("Private server lacks XI2")
            self.opcode = self.connection.display.get_extension_major(xinput.extname)
            # Python-Xlib's convenience query negotiates only XI2.0. XI2.1+
            # supplies raw sourceid and raw events even while Godot grabs input.
            version = xinput.XIQueryVersion(display=self.connection.display, opcode=self.opcode,
                                           major_version=2, minor_version=2)
            if (version.major_version, version.minor_version) < (2, 1):
                raise RuntimeError("XI2.1 or later required for grabbed raw-event provenance")
            self.enabled_atom = self.connection.intern_atom("Device Enabled", only_if_exists=True)
            self.xtest_atom = self.connection.intern_atom("XTEST Device", only_if_exists=True)
            self.integer_atom = self.connection.intern_atom("INTEGER", only_if_exists=True)
            if not all((self.enabled_atom, self.xtest_atom, self.integer_atom)):
                raise RuntimeError("Required server-owned XI2 properties absent")
            before = self.inventory()
            self.classify(before)
            self.event("private_seat_before", display=display_name,
                       socket_peer={"pid": peer[0], "uid": peer[1], "gid": peer[2]},
                       xi_version=[version.major_version, version.minor_version], devices=before)
            if not allow_physical and len(before) != 8:
                raise RuntimeError("Unexpected inputless Xwayland/fake-seat device count")
            after = self.inventory()
            self.classify(after)
            for device in after:
                if not device["enabled"]:
                    raise RuntimeError(f"Private XI2 device policy did not take effect: {device}")
            self.baseline = after
            self.xtest_ids = {d["id"] for d in after if d["role"] == "xtest"}
            self.event("private_seat_gated", policy=self.policy, devices=after,
                       scope="kernel-verified owned Xwayland; XI2 read-only; no host devices")
            # Later hierarchy or
            # enable-property notifications invalidate controlled provenance,
            # including enable-then-disable changes between inventory polls.
            mask = xinput.HierarchyChangedMask | xinput.PropertyEventMask
            mask |= sum(1 << number for number in self.RAW)
            self.connection.screen().root.xinput_select_events([(xinput.AllDevices, mask)])
            self.connection.sync()
        except Exception:
            self.connection.close()
            self.connection = None
            raise

    @property
    def policy(self) -> str:
        return "physical_manual_opt_in" if self.allow_physical else "xtest_only_inputless_compositor"

    def _byte_property(self, device: int, atom: int, required: bool) -> int | None:
        prop = self.connection.xinput_get_device_property(device, atom, X.AnyPropertyType, 0, 1)
        if prop.value is None and not required:
            return None
        if (prop.type != self.integer_atom or prop.bytes_after or prop.value is None
                or prop.value[0] != 8 or len(prop.value[1]) != 1 or prop.value[1][0] not in (0, 1)):
            raise RuntimeError(f"Unexpected XI2 boolean property on private device {device}")
        return int(prop.value[1][0])

    def inventory(self) -> list[dict[str, Any]]:
        result = []
        for item in self.connection.xinput_query_device(xinput.AllDevices).devices:
            enabled = self._byte_property(item.deviceid, self.enabled_atom, True)
            if bool(item.enabled) != bool(enabled):
                raise RuntimeError("XIQueryDevice and Device Enabled disagree")
            result.append({"id": int(item.deviceid), "name": item.name, "use": int(item.use),
                           "attachment": int(item.attachment), "enabled": bool(item.enabled),
                           "device_enabled": enabled,
                           "xtest_property": self._byte_property(item.deviceid, self.xtest_atom, False)})
        return sorted(result, key=lambda item: item["id"])

    def classify(self, devices: list[dict[str, Any]]) -> None:
        by_name = {device["name"]: device for device in devices}
        if len(by_name) != len(devices) or not self.CORE.keys() <= by_name.keys():
            raise RuntimeError("Unexpected private XI2 core hierarchy")
        pointer = by_name["Virtual core pointer"]["id"]
        keyboard = by_name["Virtual core keyboard"]["id"]
        kinds = set()
        for device in devices:
            name = device["name"]
            if name in self.CORE:
                xtest = "XTEST" in name
                if device["use"] != self.CORE[name] or (xtest and device["xtest_property"] != 1):
                    raise RuntimeError("Core/XTEST device identity is not server-verified")
                device["role"] = "xtest" if xtest else "master"
            else:
                match = self.PHYSICAL.fullmatch(name)
                if not match or device["xtest_property"] is not None:
                    raise RuntimeError(f"Unrecognized private XI2 device; refusing broad disable: {device}")
                kind = match.group(1)
                kinds.add(kind)
                expected_use = xinput.SlaveKeyboard if kind == "keyboard" else xinput.SlavePointer
                # DisableDevice detaches an Xwayland slave: XIQueryDevice then
                # reports FloatingSlave, whose attachment is protocol-undefined.
                if device["use"] != expected_use and not (not device["enabled"] and device["use"] == xinput.FloatingSlave):
                    raise RuntimeError(f"Xwayland physical device has unexpected role: {device}")
                device["role"] = "physical" if self.allow_physical else "inputless_protocol"
                if device["use"] == xinput.FloatingSlave:
                    continue
            expected_attachment = keyboard if device["use"] in (xinput.MasterPointer, xinput.SlaveKeyboard) else pointer
            if device["attachment"] != expected_attachment:
                raise RuntimeError("Unexpected private XI2 master/slave attachment")
        if self.allow_physical and not {"pointer", "keyboard"} <= kinds:
            raise RuntimeError("Private Xwayland seat lacks the expected pointer/keyboard")
        if not self.allow_physical and kinds != {"pointer", "relative-pointer", "pointer-gestures", "keyboard"}:
            raise RuntimeError("Unexpected inputless fake-seat protocol proxies")

    def _drain(self) -> None:
        while self.connection.pending_events():
            event = self.connection.next_event()
            if event.type != 35 or event.extension != self.opcode:
                continue
            if event.evtype in self.RAW:
                # xXIRawEvent in the installed X11/extensions/XI2proto.h;
                # Python-Xlib leaves raw GenericEvent payloads as bytes.
                device, stamp, detail, source, masks, flags = struct.unpack_from("=HIIHHI", event.data)
                size = masks * 4
                bits = int.from_bytes(event.data[22:22 + size], byteorder=os.sys.byteorder)
                axes = [axis for axis in range(size * 8) if bits & (1 << axis)]
                offset = 22 + size + len(axes) * 8
                values = {}
                for index, axis in enumerate(axes):
                    whole, fraction = struct.unpack_from("=iI", event.data, offset + index * 8)
                    values[str(axis)] = whole + fraction / (1 << 32)
                kind = self.RAW[event.evtype]
                self.raw_counts[kind] = self.raw_counts.get(kind, 0) + 1
                self.event("private_xi2_raw", input_kind=kind, device_id=device, source_id=source,
                           server_ms=stamp, detail=detail, flags=flags, raw_axes=values,
                           source_is_xtest=source in self.xtest_ids)
                if not self.allow_physical and source not in self.xtest_ids:
                    raise RuntimeError("Non-XTEST raw input invalidated controlled run")
            elif event.evtype == xinput.HierarchyChanged:
                self.event("private_seat_hierarchy_changed", details=str(event.data))
                if not self.allow_physical:
                    raise RuntimeError("Private XI2 hierarchy changed; controlled run invalid")
            elif event.evtype == xinput.PropertyEvent and event.data.property in (self.enabled_atom, self.xtest_atom):
                self.event("private_seat_property_changed", device_id=event.data.deviceid,
                           property_id=event.data.property)
                if not self.allow_physical:
                    raise RuntimeError("Private XI2 identity/enable property changed; controlled run invalid")

    def audit(self) -> dict[str, Any]:
        with self.lock:
            if not same_process(self.server_identity):
                raise RuntimeError("Private Xwayland process identity changed")
            self._drain()
            current = self.inventory()
            self.classify(current)
            if not self.allow_physical and current != self.baseline:
                raise RuntimeError("Private XI2 device inventory drift; controlled run invalid")
            self.audits += 1
            return {"policy": self.policy, "audits": self.audits, "devices": current,
                    "raw_counts": dict(self.raw_counts)}

    def close(self) -> None:
        with self.lock:
            if self.connection is not None:
                self.connection.close()
                self.connection = None
