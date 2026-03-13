#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using UnityEditor;
using UnityEditor.Animations;
using UnityEngine;
using UnityEngine.Animations;
using UnityEngine.Playables;

namespace TouhouTalk.UnityRetarget
{
    public sealed class TouhouTalkMixamoToVrmBakeWindow : EditorWindow
    {
        [SerializeField] private GameObject vrmPrefab;
        [SerializeField] private DefaultAsset mixamoFolder;
        [SerializeField] private DefaultAsset outputFolder;
        [SerializeField] private int sampleFps = 30;
        [SerializeField] private bool exportGlb = false;
        [SerializeField] private DefaultAsset glbOutputFolder;

        [MenuItem("Tools/Touhou Talk/Mixamo → VRM Bake")]
        public static void Open()
        {
            var w = GetWindow<TouhouTalkMixamoToVrmBakeWindow>();
            w.titleContent = new GUIContent("Mixamo → VRM Bake");
            w.minSize = new Vector2(560, 380);
            w.Show();
        }

        private void OnGUI()
        {
            EditorGUILayout.Space(10);
            EditorGUILayout.LabelField("Mixamo → VRM Bake", EditorStyles.boldLabel);
            EditorGUILayout.LabelField("Humanoid Retarget → Transform Bake (.anim) 量産 + 任意でGLB書き出し", EditorStyles.wordWrappedMiniLabel);

            EditorGUILayout.Space(10);
            vrmPrefab = (GameObject)EditorGUILayout.ObjectField("VRM Prefab", vrmPrefab, typeof(GameObject), false);
            mixamoFolder = (DefaultAsset)EditorGUILayout.ObjectField("Mixamo Folder", mixamoFolder, typeof(DefaultAsset), false);
            outputFolder = (DefaultAsset)EditorGUILayout.ObjectField("Output Folder", outputFolder, typeof(DefaultAsset), false);
            sampleFps = Mathf.Clamp(EditorGUILayout.IntField("Sample FPS", sampleFps), 5, 120);

            EditorGUILayout.Space(10);
            exportGlb = EditorGUILayout.ToggleLeft("Export GLB (requires UnityGLTF)", exportGlb);
            using (new EditorGUI.DisabledScope(!exportGlb))
            {
                glbOutputFolder = (DefaultAsset)EditorGUILayout.ObjectField("GLB Output Folder", glbOutputFolder, typeof(DefaultAsset), false);
            }

            EditorGUILayout.Space(14);
            using (new EditorGUI.DisabledScope(!IsReady()))
            {
                if (GUILayout.Button("Bake All", GUILayout.Height(38)))
                {
                    try
                    {
                        BakeAll();
                    }
                    catch (Exception ex)
                    {
                        Debug.LogException(ex);
                        EditorUtility.DisplayDialog("Bake failed", ex.Message, "OK");
                    }
                }
            }

            EditorGUILayout.Space(12);
            EditorGUILayout.HelpBox(
                "GLBを書き出したい場合は UnityGLTF をプロジェクトに導入してください。\n" +
                "書き出しに失敗/スキップした場合は Console に [TouhouTalk] ログが出ます。",
                MessageType.Info);
        }

        private bool IsReady()
        {
            if (vrmPrefab == null) return false;
            if (mixamoFolder == null) return false;
            if (outputFolder == null) return false;
            if (sampleFps < 5) return false;
            if (exportGlb && glbOutputFolder == null) return false;
            return true;
        }

        private void BakeAll()
        {
            var mixamoPath = AssetDatabase.GetAssetPath(mixamoFolder);
            var outPath = AssetDatabase.GetAssetPath(outputFolder);
            var glbPath = exportGlb ? AssetDatabase.GetAssetPath(glbOutputFolder) : null;

            var clips = FindAnimationClipsUnder(mixamoPath)
                .Where(c => c != null && !c.name.StartsWith("__preview__", StringComparison.OrdinalIgnoreCase))
                .Distinct()
                .OrderBy(c => c.name, StringComparer.OrdinalIgnoreCase)
                .ToList();

            if (clips.Count == 0)
                throw new InvalidOperationException($"No AnimationClip found under: {mixamoPath}");

            var tempRoot = new GameObject("__TouhouTalk_BakeRoot__");
            try
            {
                var instance = (GameObject)PrefabUtility.InstantiatePrefab(vrmPrefab);
                if (instance == null) throw new InvalidOperationException("Failed to instantiate VRM prefab.");
                instance.transform.SetParent(tempRoot.transform, false);

                var animator = instance.GetComponentInChildren<Animator>();
                if (animator == null) throw new InvalidOperationException("VRM prefab has no Animator.");
                if (animator.avatar == null) throw new InvalidOperationException("VRM Animator has no Avatar (Humanoid).");
                if (!animator.avatar.isHuman) throw new InvalidOperationException("VRM Avatar is not Humanoid. Check import settings.");

                var bones = CollectSkeletonBones(instance);
                var recorder = new TransformCurveRecorder(instance.transform, bones);

                int done = 0;
                foreach (var srcClip in clips)
                {
                    EditorUtility.DisplayProgressBar("Baking", srcClip.name, done / (float)clips.Count);

                    var baked = HumanoidClipBaker.BakeToTransformClip(animator, recorder, srcClip, sampleFps);

                    // Stable name: include source asset filename (Mixamo clips often share the same internal name).
                    var srcPath = AssetDatabase.GetAssetPath(srcClip);
                    var srcFile = Path.GetFileNameWithoutExtension(srcPath);
                    baked.name = SanitizeName($"{srcFile}__{srcClip.name}");

                    EnsureFolder(outPath);
                    var dstAnimPath = AssetDatabase.GenerateUniqueAssetPath(PathCombine(outPath, baked.name + ".anim"));
                    AssetDatabase.CreateAsset(baked, dstAnimPath);

                    if (exportGlb && glbPath != null)
                    {
                        EnsureFolder(glbPath);
                        var dstGlbPath = PathCombine(glbPath, baked.name + ".glb");
                        GlbExporter.TryExportUnityGltf(instance, baked, dstGlbPath);
                    }

                    done++;
                }
            }
            finally
            {
                EditorUtility.ClearProgressBar();
                DestroyImmediate(tempRoot);
                AssetDatabase.SaveAssets();
                AssetDatabase.Refresh();
            }
        }

        private static List<AnimationClip> FindAnimationClipsUnder(string folderPath)
        {
            var guids = AssetDatabase.FindAssets("t:AnimationClip", new[] { folderPath });
            var clips = new List<AnimationClip>(guids.Length);
            foreach (var g in guids)
            {
                var p = AssetDatabase.GUIDToAssetPath(g);
                var c = AssetDatabase.LoadAssetAtPath<AnimationClip>(p);
                if (c != null) clips.Add(c);
            }
            return clips;
        }

        private static List<Transform> CollectSkeletonBones(GameObject root)
        {
            var set = new HashSet<Transform>();
            foreach (var smr in root.GetComponentsInChildren<SkinnedMeshRenderer>(true))
            {
                if (smr.rootBone != null) set.Add(smr.rootBone);
                if (smr.bones != null)
                {
                    foreach (var b in smr.bones)
                        if (b != null) set.Add(b);
                }
            }

            var anim = root.GetComponentInChildren<Animator>();
            if (anim != null && anim.avatar != null && anim.avatar.isHuman)
            {
                foreach (HumanBodyBones hb in Enum.GetValues(typeof(HumanBodyBones)))
                {
                    if (hb == HumanBodyBones.LastBone) continue;
                    var t = anim.GetBoneTransform(hb);
                    if (t != null) set.Add(t);
                }
            }

            return set
                .Where(t => t != null)
                .OrderBy(GetDepth)
                .ThenBy(t => t.name, StringComparer.OrdinalIgnoreCase)
                .ToList();
        }

        private static int GetDepth(Transform t)
        {
            int d = 0;
            while (t != null)
            {
                d++;
                t = t.parent;
            }
            return d;
        }

        private static void EnsureFolder(string assetFolderPath)
        {
            if (AssetDatabase.IsValidFolder(assetFolderPath)) return;
            var parts = assetFolderPath.Split(new[] { '/' }, StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length == 0) return;
            var cur = parts[0];
            for (int i = 1; i < parts.Length; i++)
            {
                var next = cur + "/" + parts[i];
                if (!AssetDatabase.IsValidFolder(next))
                    AssetDatabase.CreateFolder(cur, parts[i]);
                cur = next;
            }
        }

        private static string SanitizeName(string s)
        {
            var chars = s.Select(ch => char.IsLetterOrDigit(ch) || ch == '_' || ch == '-' ? ch : '_').ToArray();
            return new string(chars);
        }

        private static string PathCombine(string a, string b)
        {
            if (string.IsNullOrEmpty(a)) return b;
            if (a.EndsWith("/")) return a + b;
            return a + "/" + b;
        }
    }

    internal sealed class TransformCurveRecorder
    {
        public readonly Transform Root;
        public readonly List<Transform> Bones;
        private readonly Dictionary<Transform, string> pathCache = new Dictionary<Transform, string>();
        private readonly Dictionary<Transform, Quaternion> lastQuat = new Dictionary<Transform, Quaternion>();

        public TransformCurveRecorder(Transform root, List<Transform> bones)
        {
            Root = root;
            Bones = bones ?? new List<Transform>();
        }

        public string PathFor(Transform t)
        {
            if (t == null) return "";
            if (pathCache.TryGetValue(t, out var p)) return p;
            p = AnimationUtility.CalculateTransformPath(t, Root);
            pathCache[t] = p;
            return p;
        }

        public void ResetContinuity()
        {
            lastQuat.Clear();
        }

        public Quaternion StabilizeQuat(Transform t, Quaternion q)
        {
            if (lastQuat.TryGetValue(t, out var prev))
            {
                if (Quaternion.Dot(prev, q) < 0f) q = new Quaternion(-q.x, -q.y, -q.z, -q.w);
            }
            lastQuat[t] = q;
            return q;
        }
    }

    internal static class HumanoidClipBaker
    {
        public static AnimationClip BakeToTransformClip(
            Animator animator,
            TransformCurveRecorder recorder,
            AnimationClip srcClip,
            int sampleFps)
        {
            if (animator == null) throw new ArgumentNullException(nameof(animator));
            if (recorder == null) throw new ArgumentNullException(nameof(recorder));
            if (srcClip == null) throw new ArgumentNullException(nameof(srcClip));
            if (sampleFps < 5) throw new ArgumentOutOfRangeException(nameof(sampleFps));

            var baked = new AnimationClip { frameRate = sampleFps };
            var settings = AnimationUtility.GetAnimationClipSettings(baked);
            settings.loopTime = true;
            AnimationUtility.SetAnimationClipSettings(baked, settings);

            var bones = recorder.Bones;
            var curves = new Dictionary<string, BoneCurves>(bones.Count);
            foreach (var t in bones)
            {
                var path = recorder.PathFor(t);
                if (string.IsNullOrEmpty(path)) continue;
                curves[path] = new BoneCurves();
            }

            var graph = PlayableGraph.Create("TouhouTalkBake");
            try
            {
                var output = AnimationPlayableOutput.Create(graph, "anim", animator);
                var playable = AnimationClipPlayable.Create(graph, srcClip);
                playable.SetApplyFootIK(true);
                output.SetSourcePlayable(playable);
                graph.Play();

                var duration = Mathf.Max(0.001f, (float)srcClip.length);
                var frames = Mathf.Max(2, Mathf.CeilToInt(duration * sampleFps));
                var dt = 1f / sampleFps;

                recorder.ResetContinuity();
                graph.Evaluate(0f);
                for (int i = 0; i <= frames; i++)
                {
                    var tSec = Mathf.Min(duration, i * dt);
                    foreach (var bone in bones)
                    {
                        if (bone == null) continue;
                        var path = recorder.PathFor(bone);
                        if (!curves.TryGetValue(path, out var bc)) continue;

                        var lp = bone.localPosition;
                        var lq = recorder.StabilizeQuat(bone, bone.localRotation);
                        var ls = bone.localScale;

                        bc.px.AddKey(tSec, lp.x);
                        bc.py.AddKey(tSec, lp.y);
                        bc.pz.AddKey(tSec, lp.z);
                        bc.qx.AddKey(tSec, lq.x);
                        bc.qy.AddKey(tSec, lq.y);
                        bc.qz.AddKey(tSec, lq.z);
                        bc.qw.AddKey(tSec, lq.w);
                        bc.sx.AddKey(tSec, ls.x);
                        bc.sy.AddKey(tSec, ls.y);
                        bc.sz.AddKey(tSec, ls.z);
                    }
                    graph.Evaluate(dt);
                }
            }
            finally
            {
                graph.Destroy();
            }

            foreach (var kv in curves)
            {
                var path = kv.Key;
                var bc = kv.Value;
                ApplyIfVaries(baked, path, "localPosition.x", bc.px);
                ApplyIfVaries(baked, path, "localPosition.y", bc.py);
                ApplyIfVaries(baked, path, "localPosition.z", bc.pz);
                ApplyIfVaries(baked, path, "localRotation.x", bc.qx);
                ApplyIfVaries(baked, path, "localRotation.y", bc.qy);
                ApplyIfVaries(baked, path, "localRotation.z", bc.qz);
                ApplyIfVaries(baked, path, "localRotation.w", bc.qw);
                ApplyIfVaries(baked, path, "localScale.x", bc.sx);
                ApplyIfVaries(baked, path, "localScale.y", bc.sy);
                ApplyIfVaries(baked, path, "localScale.z", bc.sz);
            }

            baked.EnsureQuaternionContinuity();
            return baked;
        }

        private static void ApplyIfVaries(AnimationClip clip, string path, string property, AnimationCurve curve)
        {
            if (curve == null || curve.length < 2) return;
            if (!Varies(curve)) return;
            clip.SetCurve(path, typeof(Transform), property, curve);
        }

        private static bool Varies(AnimationCurve curve)
        {
            if (curve.length < 2) return false;
            float min = curve.keys[0].value;
            float max = min;
            for (int i = 1; i < curve.length; i++)
            {
                var v = curve.keys[i].value;
                if (v < min) min = v;
                if (v > max) max = v;
            }
            return Mathf.Abs(max - min) > 1e-5f;
        }

        private sealed class BoneCurves
        {
            public readonly AnimationCurve px = new AnimationCurve();
            public readonly AnimationCurve py = new AnimationCurve();
            public readonly AnimationCurve pz = new AnimationCurve();
            public readonly AnimationCurve qx = new AnimationCurve();
            public readonly AnimationCurve qy = new AnimationCurve();
            public readonly AnimationCurve qz = new AnimationCurve();
            public readonly AnimationCurve qw = new AnimationCurve();
            public readonly AnimationCurve sx = new AnimationCurve();
            public readonly AnimationCurve sy = new AnimationCurve();
            public readonly AnimationCurve sz = new AnimationCurve();
        }
    }

    internal static class GlbExporter
    {
        public static void TryExportUnityGltf(GameObject vrmInstance, AnimationClip bakedClip, string glbAssetPath)
        {
            var exporterType = ResolveType("UnityGLTF.GLTFSceneExporter", "GLTFSceneExporter");
            if (exporterType == null)
            {
                Debug.LogWarning("[TouhouTalk] UnityGLTF not found (GLTFSceneExporter type missing); skipped GLB export.");
                return;
            }

            var animator = vrmInstance.GetComponentInChildren<Animator>();
            if (animator == null)
            {
                Debug.LogWarning("[TouhouTalk] No Animator found; skipped GLB export.");
                return;
            }

            var prevAvatar = animator.avatar;
            var prevController = animator.runtimeAnimatorController;

            var tempControllerPath = "Assets/__TouhouTalk_Temp.controller";
            var controller = AnimatorController.CreateAnimatorControllerAtPathWithClip(tempControllerPath, bakedClip);
            animator.avatar = null;
            animator.runtimeAnimatorController = controller;

            try
            {
                var sceneRoots = new[] { vrmInstance.transform };
                object exporter = null;

                // Try common constructors.
                foreach (var ctor in exporterType.GetConstructors())
                {
                    var ps = ctor.GetParameters();
                    if (ps.Length == 1 && ps[0].ParameterType == typeof(Transform[]))
                    {
                        exporter = ctor.Invoke(new object[] { sceneRoots });
                        break;
                    }
                    if (ps.Length == 2 && ps[0].ParameterType == typeof(Transform[]))
                    {
                        object ctx = null;
                        try
                        {
                            var ctxType = ResolveType("UnityGLTF.ExportContext", "ExportContext");
                            if (ctxType != null && ps[1].ParameterType.IsAssignableFrom(ctxType))
                                ctx = Activator.CreateInstance(ctxType);
                        }
                        catch { ctx = null; }

                        exporter = ctor.Invoke(new object[] { sceneRoots, ctx });
                        break;
                    }
                }

                if (exporter == null)
                {
                    Debug.LogWarning("[TouhouTalk] UnityGLTF exporter constructor not found; skipped GLB export.");
                    return;
                }

                var abs = Path.GetFullPath(glbAssetPath);
                var dir = Path.GetDirectoryName(abs);
                if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);

                // Prefer SaveGLB(path, fileName)
                var m2 = exporterType.GetMethod("SaveGLB", new[] { typeof(string), typeof(string) });
                if (m2 != null && dir != null)
                {
                    var fileNoExt = Path.GetFileNameWithoutExtension(abs);
                    m2.Invoke(exporter, new object[] { dir, fileNoExt });
                    Debug.Log($"[TouhouTalk] exported GLB: {Path.Combine(dir, fileNoExt + ".glb")}");
                    return;
                }

                var m1 = exporterType.GetMethod("SaveGLB", new[] { typeof(string) });
                if (m1 != null)
                {
                    m1.Invoke(exporter, new object[] { abs });
                    Debug.Log($"[TouhouTalk] exported GLB: {abs}");
                    return;
                }

                Debug.LogWarning("[TouhouTalk] UnityGLTF exporter has no compatible SaveGLB method; skipped.");
            }
            catch (Exception ex)
            {
                Debug.LogWarning("[TouhouTalk] GLB export failed: " + ex.Message);
            }
            finally
            {
                animator.runtimeAnimatorController = prevController;
                animator.avatar = prevAvatar;
                AssetDatabase.DeleteAsset(tempControllerPath);
            }
        }

        private static Type ResolveType(string fullName, string shortName)
        {
            foreach (var asm in AppDomain.CurrentDomain.GetAssemblies())
            {
                try
                {
                    var t = asm.GetType(fullName, false);
                    if (t != null) return t;
                }
                catch { }
            }

            foreach (var asm in AppDomain.CurrentDomain.GetAssemblies())
            {
                Type[] types = null;
                try { types = asm.GetTypes(); }
                catch (ReflectionTypeLoadException rtle) { types = rtle.Types; }
                catch { types = null; }
                if (types == null) continue;

                foreach (var t in types)
                {
                    if (t == null) continue;
                    if (t.FullName == fullName) return t;
                    if (t.Name == shortName) return t;
                }
            }
            return null;
        }
    }
}
#endif

