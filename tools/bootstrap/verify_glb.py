#!/usr/bin/env python3
"""Check the tiny M0 export's required glTF structure (not a general Khronos validator)."""

import argparse
import hashlib
import json
from pathlib import Path
import struct


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", type=Path)
    args = parser.parse_args()
    data = args.path.read_bytes()
    magic, version, length = struct.unpack_from("<4sII", data)
    assert magic == b"glTF" and version == 2 and length == len(data), "Invalid GLB header"
    chunk_size, chunk_type = struct.unpack_from("<I4s", data, 12)
    assert chunk_type == b"JSON", "Missing GLB JSON chunk"
    document = json.loads(data[20:20 + chunk_size])
    assert len(document["meshes"]) == 3, "Expected three diagnostic meshes"
    assert len(document["materials"]) == 3, "Expected three exported PBR materials"
    assert document.get("animations"), "Expected object transform animation"
    assert all("uri" not in item for item in document["buffers"]), "GLB depends on external buffer"
    for mesh in document["meshes"]:
        for primitive in mesh["primitives"]:
            assert {"POSITION", "NORMAL", "TEXCOORD_0"} <= primitive["attributes"].keys()
    print(json.dumps({"result": "PASS", "kind": "diagnostic-structure-check",
                      "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data),
                      "mesh_count": len(document["meshes"]),
                      "material_count": len(document["materials"]),
                      "animations": [item.get("name") for item in document["animations"]]}, indent=2))


if __name__ == "__main__":
    main()
