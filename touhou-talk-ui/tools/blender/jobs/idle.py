import os
import sys
import time
from math import radians
from typing import Optional

import bpy  # type: ignore

_HERE = os.path.dirname(os.path.abspath(__file__))
if _HERE not in sys.path:
    sys.path.insert(0, _HERE)

from _common import parse_job_args, die  # type: ignore


def _reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)


def _import_gltf(path: str) -> None:
    bpy.ops.import_scene.gltf(filepath=path)


def _find_reimu_armature() -> Optional[bpy.types.Object]:  # type: ignore
    # Prefer an armature that looks like MMD/VRM (センター/上半身).
    for o in bpy.data.objects:
        if o.type != "ARMATURE":
            continue
        try:
            pb = o.pose.bones
            if ("センター" in pb) and ("上半身" in pb):
                return o
        except Exception:
            continue
    # Fallback: any armature.
    for o in bpy.data.objects:
        if o.type == "ARMATURE":
            return o
    return None


def _ensure_action(arm: bpy.types.Object, name: str) -> bpy.types.Action:  # type: ignore
    act = bpy.data.actions.new(name)
    if not arm.animation_data:
        arm.animation_data_create()
    arm.animation_data.action = act
    return act


def _set_rot_xyz(pb: bpy.types.PoseBone, rx: float, ry: float, rz: float) -> None:  # type: ignore
    pb.rotation_mode = "XYZ"
    pb.rotation_euler[0] = radians(rx)
    pb.rotation_euler[1] = radians(ry)
    pb.rotation_euler[2] = radians(rz)


def _insert(pb: bpy.types.PoseBone, frame: int) -> None:  # type: ignore
    pb.keyframe_insert(data_path="rotation_euler", frame=frame)


def _export_glb(path: str) -> None:
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        export_animations=True,
        export_apply=True,
        export_yup=True,
        export_skins=True,
        export_morph=True,
        export_lights=False,
        export_cameras=False,
    )


def main() -> None:
    args = parse_job_args()
    started = time.time()

    _reset_scene()
    _import_gltf(args.input)

    arm = _find_reimu_armature()
    if not arm:
        die("No armature found after import.")

    scene = bpy.context.scene
    scene.frame_start = 1
    scene.frame_end = 120  # ~4s at 30fps

    act = _ensure_action(arm, "idle_breathe")

    bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="DESELECT")
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="POSE")

    pb = arm.pose.bones
    def has(n: str) -> bool:
        return n in pb

    # Keep it conservative; this is a base idle.
    keys = [1, 30, 60, 90, 120]
    phase = {1: 0.0, 30: 1.0, 60: 0.0, 90: -1.0, 120: 0.0}

    amp_center_x = 0.8
    amp_chest_x = 2.0
    amp_chest_z = 1.2
    amp_head_z = 1.0

    for f in keys:
        p = phase[f]

        if has("センター"):
            _set_rot_xyz(pb["センター"], amp_center_x * p, 0.0, 0.0)
            _insert(pb["センター"], f)

        if has("上半身"):
            _set_rot_xyz(pb["上半身"], amp_chest_x * p, 0.0, amp_chest_z * p)
            _insert(pb["上半身"], f)

        if has("上半身2"):
            _set_rot_xyz(pb["上半身2"], (amp_chest_x * 0.6) * p, 0.0, (amp_chest_z * 0.6) * p)
            _insert(pb["上半身2"], f)

        if has("首"):
            _set_rot_xyz(pb["首"], (-amp_chest_x * 0.3) * p, 0.0, (amp_head_z * 0.5) * p)
            _insert(pb["首"], f)

        if has("頭"):
            _set_rot_xyz(pb["頭"], (-amp_chest_x * 0.2) * p, 0.0, (amp_head_z) * p)
            _insert(pb["頭"], f)

        if has("肩.L") and has("肩.R"):
            _set_rot_xyz(pb["肩.L"], 0.8 * p, 0.0, 0.6 * p)
            _set_rot_xyz(pb["肩.R"], 0.8 * p, 0.0, -0.6 * p)
            _insert(pb["肩.L"], f)
            _insert(pb["肩.R"], f)

    bpy.ops.object.mode_set(mode="OBJECT")

    # Add Cycles modifier to all fcurves for looping.
    for fcu in act.fcurves:
        try:
            mod = fcu.modifiers.new(type="CYCLES")
            mod.mode_before = "REPEAT"
            mod.mode_after = "REPEAT"
        except Exception:
            pass

    _export_glb(args.output)
    print(f"[idle] wrote: {args.output} in {round(time.time()-started,3)}s (armature={arm.name})")


if __name__ == "__main__":
    main()
