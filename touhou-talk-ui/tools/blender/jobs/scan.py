import os
import sys
import time
from typing import Any, Dict, List

import bpy  # type: ignore

_HERE = os.path.dirname(os.path.abspath(__file__))
if _HERE not in sys.path:
    sys.path.insert(0, _HERE)

from _common import parse_job_args, write_json  # type: ignore


def _reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def _import_gltf(path: str) -> None:
    bpy.ops.import_scene.gltf(filepath=path)


def _collect_armatures() -> List[bpy.types.Object]:  # type: ignore
    return [o for o in bpy.data.objects if o.type == "ARMATURE"]


def _collect_meshes() -> List[bpy.types.Object]:  # type: ignore
    return [o for o in bpy.data.objects if o.type == "MESH"]


def _mesh_shape_keys(mesh_obj: bpy.types.Object) -> List[str]:  # type: ignore
    try:
        key = mesh_obj.data.shape_keys
        if not key or not key.key_blocks:
            return []
        return [kb.name for kb in key.key_blocks]
    except Exception:
        return []


def _armature_bones(arm_obj: bpy.types.Object) -> List[str]:  # type: ignore
    try:
        return [b.name for b in arm_obj.data.bones]
    except Exception:
        return []


def main() -> None:
    args = parse_job_args()
    started = time.time()

    _reset_scene()
    _import_gltf(args.input)

    armatures = _collect_armatures()
    meshes = _collect_meshes()

    data: Dict[str, Any] = {
        "input": args.input,
        "kind": "vrm_scan",
        "generatedAt": int(time.time()),
        "elapsedSec": round(time.time() - started, 3),
        "armatures": [],
        "meshes": [],
        "notes": [
            "Imported via Blender glTF importer (no VRM addon dependency).",
            "This scan lists armature bone names and mesh shape keys (morph targets).",
        ],
    }

    for a in armatures:
        data["armatures"].append(
            {
                "name": a.name,
                "scale": [float(a.scale[0]), float(a.scale[1]), float(a.scale[2])],
                "rotationEuler": [
                    float(a.rotation_euler[0]),
                    float(a.rotation_euler[1]),
                    float(a.rotation_euler[2]),
                ],
                "bones": _armature_bones(a),
            }
        )

    for m in meshes:
        data["meshes"].append(
            {
                "name": m.name,
                "shapeKeys": _mesh_shape_keys(m),
                "vertexCount": int(len(m.data.vertices)) if getattr(m, "data", None) else None,
            }
        )

    write_json(args.output, data)
    print(f"[scan] wrote: {args.output}")


if __name__ == "__main__":
    main()
