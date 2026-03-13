#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

namespace TouhouTalk.UnityRetarget
{
    public static class TouhouTalkSkinnedMeshFixer
    {
        [MenuItem("Tools/Touhou Talk/Fix SkinnedMeshRenderer Bindings (RootBone/Bones)")]
        public static void FixSelected()
        {
            var go = Selection.activeGameObject;
            if (go == null)
            {
                EditorUtility.DisplayDialog("Fix bindings", "Hierarchy上で霊夢のルート（または任意の親）を選択してから実行してください。", "OK");
                return;
            }

            var root = go.transform;
            var all = root.GetComponentsInChildren<Transform>(true);
            var byName = new Dictionary<string, Transform>(StringComparer.Ordinal);
            foreach (var t in all)
            {
                if (t == null) continue;
                if (!byName.ContainsKey(t.name)) byName[t.name] = t;
            }

            // Prefer common MMD/VRM root bones.
            Transform preferredRootBone =
                FindAny(byName, "センター", "グルーブ", "全ての親", "hips", "Hips") ?? root;

            int changed = 0;
            int missingBoneRefs = 0;
            var renderers = root.GetComponentsInChildren<SkinnedMeshRenderer>(true);
            foreach (var smr in renderers)
            {
                if (smr == null) continue;

                Undo.RecordObject(smr, "Fix SkinnedMeshRenderer Bindings");

                if (smr.rootBone == null)
                {
                    smr.rootBone = preferredRootBone;
                    changed++;
                }

                var bones = smr.bones;
                if (bones == null || bones.Length == 0)
                {
                    // Nothing we can do if there are no bone refs at all.
                    continue;
                }

                bool anyFix = false;
                for (int i = 0; i < bones.Length; i++)
                {
                    var b = bones[i];
                    if (b != null) continue;
                    missingBoneRefs++;
                    anyFix = true;
                    // Try to recover by name from the mesh bindposes (best-effort):
                    // Unity doesn't expose original bone names from bindposes, so we can only attempt common names.
                    // We'll leave missing bones as-is; user may need to re-import the VRM if many are missing.
                }

                // If there are missing refs, try a conservative rebuild by matching names from current hierarchy.
                // This only works when the SkinnedMeshRenderer already has valid names (non-null).
                if (anyFix)
                {
                    var rebuilt = new Transform[bones.Length];
                    for (int i = 0; i < bones.Length; i++)
                    {
                        if (bones[i] != null)
                        {
                            var name = bones[i].name;
                            rebuilt[i] = byName.TryGetValue(name, out var t) ? t : bones[i];
                        }
                        else
                        {
                            rebuilt[i] = null;
                        }
                    }
                    smr.bones = rebuilt;
                    changed++;
                }

                EditorUtility.SetDirty(smr);
            }

            EditorUtility.DisplayDialog(
                "Fix bindings",
                $"対象: {renderers.Length} renderer\n変更: {changed}\nMissing bone refs: {missingBoneRefs}\n\n" +
                "RootBoneがNoneだったものは修正しました。BonesがMissingだらけの場合は、VRMをSceneへ再ドラッグ→新しい個体でPrefab化が最短です。",
                "OK");
        }

        private static Transform FindAny(Dictionary<string, Transform> byName, params string[] names)
        {
            foreach (var n in names)
            {
                if (byName.TryGetValue(n, out var t) && t != null) return t;
            }
            return null;
        }
    }
}
#endif

