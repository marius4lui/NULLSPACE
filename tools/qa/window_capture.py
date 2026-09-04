"""Composite backing-store capture of exactly the verified game window.

Never redirects the root or its children wholesale. A new pixmap reference is
named for each snapshot because remap/resize replaces the backing store.
"""
from __future__ import annotations

import time
from typing import Any

from PIL import Image
from Xlib import X, error
from Xlib.ext import composite

from qa_common import utc
from x11_input import GameWindow


class WindowCapture:
    def __init__(self, owner: GameWindow) -> None:
        self.owner = owner
        self.redirected = False
        with owner.lock:
            owner.ensure_owned()
            connection = owner.connection
            if not connection.has_extension("Composite"):
                raise RuntimeError("Private X server lacks Composite window capture")
            version = connection.composite_query_version()
            if (version.major_version, version.minor_version) < (0, 2):
                raise RuntimeError("Composite 0.2 or newer is required")
            failures: list[Any] = []
            owner.window.composite_redirect_window(composite.RedirectAutomatic,
                onerror=lambda failure, _request: failures.append(failure))
            connection.sync()
            if failures:
                raise RuntimeError(f"Owned-window Composite redirect failed: {failures}")
            self.redirected = True
            self.window_id = owner.window.id
            self.metadata = {"window_id": self.window_id,
                "method": "composite_redirect_automatic_owned_window",
                "version": [version.major_version, version.minor_version],
                "scope": "verified game window only; no root/subwindow-list redirection"}

    def snapshot(self) -> tuple[Image.Image, dict[str, Any]]:
        owner = self.owner
        with owner.lock:
            owner.ensure_owned()
            if not self.redirected or owner.window.id != self.window_id:
                raise RuntimeError("Composite target changed or was released")
            before = owner.status()
            geometry = owner.window.get_geometry()
            attributes = owner.window.get_attributes()
            connection = owner.connection
            info = connection.display.info
            formats = [entry for entry in info.pixmap_formats if entry.depth == geometry.depth]
            visuals = [visual for depth in connection.screen().allowed_depths
                       for visual in depth.visuals if visual.visual_id == attributes.visual]
            if (geometry.border_width != 0 or len(formats) != 1 or len(visuals) != 1
                or geometry.depth not in (24, 32) or formats[0].bits_per_pixel != 32
                or formats[0].scanline_pad != 32 or info.image_byte_order != X.LSBFirst
                or visuals[0].visual_class != X.TrueColor
                or (visuals[0].red_mask, visuals[0].green_mask, visuals[0].blue_mask)
                   != (0xff0000, 0xff00, 0xff)):
                raise RuntimeError("Unsupported Composite pixel layout; refusing guessed decoding")
            failures: list[Any] = []
            pixmap = owner.window.composite_name_window_pixmap(
                onerror=lambda failure, _request: failures.append(failure))
            connection.sync()
            if failures:
                raise RuntimeError(f"Owned-window pixmap naming failed: {failures}")
            started = time.monotonic()
            acquired_utc = utc()
            try:
                pixmap_geometry = pixmap.get_geometry()
                if (pixmap_geometry.width, pixmap_geometry.height) != (geometry.width, geometry.height):
                    raise RuntimeError("Composite backing store changed geometry")
                reply = pixmap.get_image(0, 0, geometry.width, geometry.height, X.ZPixmap, 0xffffffff)
                if reply.depth != geometry.depth or len(reply.data) != geometry.width * geometry.height * 4:
                    raise RuntimeError("Incomplete or unexpected Composite image reply")
                data = bytes(reply.data)
                after = owner.status()
                if any(before[key] != after[key] for key in ("window_id", "width", "height")):
                    raise RuntimeError("Owned window changed during snapshot")
            finally:
                pixmap.free()
                connection.sync()
            metadata = {"window": after, "method": "composite_named_pixmap_getimage",
                        "composite": self.metadata, "acquired_utc": acquired_utc,
                        "acquired_monotonic": started,
                        "x_readback_ms": (time.monotonic() - started) * 1000,
                        "pixel_layout": "32-bit little-endian BGRX, RGB output"}
        # CPU conversion and PNG encoding do not hold the input-safety X lock.
        return Image.frombytes("RGB", (geometry.width, geometry.height), data, "raw", "BGRX"), metadata

    def close(self) -> None:
        with self.owner.lock:
            if self.redirected:
                failures: list[Any] = []
                self.owner.window.composite_unredirect_window(composite.RedirectAutomatic,
                    onerror=lambda failure, _request: failures.append(failure))
                self.owner.connection.sync()
                self.redirected = False
                # Normal game exit may have already destroyed its window.
                unexpected = [failure for failure in failures if not isinstance(failure, error.BadWindow)]
                if unexpected:
                    raise RuntimeError(f"Owned-window unredirect failed: {unexpected}")
