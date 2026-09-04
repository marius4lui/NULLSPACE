"""Check exact runtime skin, attributes, clip endpoints and source/runtime bytes."""
from __future__ import annotations

import hashlib
import json
import struct
import numpy as np
from recipe import EXPORT, RUNTIME, EVIDENCE


def main():
    raw = (EXPORT / "listener.glb").read_bytes()
    magic, version, length = struct.unpack_from('<III', raw)
    assert magic == 0x46546c67 and version == 2 and length == len(raw)
    size, kind = struct.unpack_from('<II', raw, 12)
    document = json.loads(raw[20:20 + size])
    data_size, data_kind = struct.unpack_from('<II', raw, 20 + size)
    data = raw[28 + size:28 + size + data_size]
    def accessor(index):
        item = document['accessors'][index]
        view = document['bufferViews'][item['bufferView']]
        dtype = {5126: '<f4', 5125: '<u4', 5123: '<u2', 5121: 'u1'}[item['componentType']]
        components = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[item['type']]
        offset = view.get('byteOffset', 0) + item.get('byteOffset', 0)
        step = view.get('byteStride', np.dtype(dtype).itemsize * components)
        result = np.ndarray((item['count'], components), dtype=dtype, buffer=data, offset=offset, strides=(step, np.dtype(dtype).itemsize))
        if item.get('normalized'):
            result = result.astype(float) / np.iinfo(np.dtype(dtype)).max
        assert np.all(np.isfinite(result)), index
        return result
    failures = []
    primitives = [primitive for mesh in document['meshes'] for primitive in mesh['primitives']]
    triangle_count = 0
    weight_max_error = 0.0
    minimum, maximum = np.full(3, np.inf), np.full(3, -np.inf)
    for primitive in primitives:
        fields = primitive['attributes']
        for name in ('POSITION', 'NORMAL', 'TANGENT', 'TEXCOORD_0', 'JOINTS_0', 'WEIGHTS_0'):
            if name not in fields:
                failures.append(f'missing {name}')
        pos = accessor(fields['POSITION'])
        minimum, maximum = np.minimum(minimum, pos.min(axis=0)), np.maximum(maximum, pos.max(axis=0))
        weights = accessor(fields['WEIGHTS_0'])
        weight_max_error = max(weight_max_error, float(np.abs(weights.sum(axis=1) - 1).max()))
        if weight_max_error > 1e-5:
            failures.append('weights not normalized')
        joints = accessor(fields['JOINTS_0'])
        if joints.max() >= len(document['skins'][0]['joints']):
            failures.append('skin joint index out of range')
        if 'WEIGHTS_1' in fields or 'JOINTS_1' in fields:
            failures.append('more than four influences')
        triangle_count += len(accessor(primitive['indices'])) // 3
    clips = {}
    for animation in document.get('animations', []):
        durations = []
        max_endpoint = 0.0
        for sampler in animation['samplers']:
            time = accessor(sampler['input'])[:, 0]
            values = accessor(sampler['output'])
            if not np.all(np.diff(time) > 0):
                failures.append(f"nonincreasing keys in {animation['name']}")
            durations.append(float(time[-1] - time[0]))
            max_endpoint = max(max_endpoint, float(np.max(np.abs(values[0] - values[-1]))))
        clips[animation['name']] = {'seconds': max(durations), 'channels': len(animation['channels']), 'max_loop_endpoint_component_error': max_endpoint}
        if max_endpoint > 1e-5:
            failures.append(f"nonmatching loop endpoint {animation['name']}")
    if set(clips) != {'idle', 'breathing', 'listen'}:
        failures.append('bounded clip set mismatch')
    if not 30000 <= triangle_count <= 50000:
        failures.append('triangle budget')
    bones = len(document['skins'][0]['joints'])
    if not 50 <= bones <= 70:
        failures.append('bone budget')
    if len(document['materials']) > 2:
        failures.append('material budget')
    runtime_bytes = (RUNTIME / 'listener.glb').read_bytes()
    if runtime_bytes != raw:
        failures.append('runtime staging mismatch')
    result = {'schema': 1, 'result': 'FAIL' if failures else 'PASS', 'triangles': triangle_count,
        'surfaces': len(primitives), 'bones': bones, 'materials': len(document['materials']),
        'position_bounds_gltf_y_up': [minimum.tolist(), maximum.tolist()], 'max_weight_sum_error': weight_max_error,
        'clips': clips, 'glb_sha256': hashlib.sha256(raw).hexdigest(), 'failures': failures,
        'limitations': 'Structural checks only; no native deformation, silhouette or independent quality claim.'}
    (EVIDENCE / 'export_structure.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result, indent=2))
    if failures:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
