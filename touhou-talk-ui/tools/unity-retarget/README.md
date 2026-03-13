# Unity（Humanoid）でMixamo→VRMを量産変換する

狙い：Blenderでのリターゲット沼（スケール/軸/骨ローカル差）を避けて、**Unityを“変換所”**として使い、MixamoのFBXアニメをVRM（霊夢）へ安定して流し込み、three.jsで使える形（GLB）まで持っていきます。

このフォルダは **Unityプロジェクトそのもの**ではありません。`UnityDropIn/` をあなたのUnityプロジェクトへコピーして使います。

## 何ができる
- Mixamoの`AnimationClip`（Humanoid）を、VRMの骨（Transform）へ **サンプリングしてベイク**（Quaternion/Position）した`.anim`を量産出力
- （任意）Unity側にglTF/GLBエクスポータを入れている場合は、GLB書き出しまで一括

## 前提（おすすめ）
- Unity 2022.3 LTS（または 2023 LTS）
- VRMインポート：UniVRM（VRM 0.x/1.0どちらでもOK。あなたのモデルに合わせて）
- GLB書き出し：UnityGLTF など（任意。入れてない場合は`.anim`出力まで）

## セットアップ（最短）
1. Unityで空プロジェクトを作成
2. UniVRMを導入（VRMをUnityでPrefab化できる状態にする）
3. `UnityDropIn/Assets` を、あなたのUnityプロジェクトの `Assets/` にコピー
4. MixamoのFBXを `Assets/Mixamo/` などへ入れる
   - Import Settings:
     - `Rig` → `Animation Type: Humanoid`
     - `Avatar Definition: Create From This Model`
     - `Animations` タブで必要なクリップが出ていること
5. 霊夢VRMをインポートしてPrefab化（UniVRMの手順通り）

## 実行（Editor）
Unityのメニューから開きます：
- `Tools > Touhou Talk > Mixamo → VRM Bake`

指定するもの
- `VRM Prefab`：霊夢のPrefab（Humanoid Avatar付き）
- `Mixamo Folder`：Mixamo FBXが入っているフォルダ（UnityのProject内パス）
- `Output Folder`：出力先（UnityのProject内パス）
- `Sample FPS`：30推奨（重いなら15）

出力
- `Output Folder` に `.anim` が大量に生成されます（Transformカーブに変換済み）

### 重要：`.anim` のプレビュー時に出る警告について
`mixamo_com.anim` のような出力は **Transformカーブ（Generic相当）** です。
霊夢側の `Animator` に **Humanoid Avatar** が付いたままだと、UnityがTransformカーブを無視することがあり、
Consoleに以下のような警告が出ます：
- `Binding warning: Some generic clip(s) animate transforms that are already bound by a humanoid avatar...`

プレビュー（Unity上で動作確認）するときは、テスト用に以下どちらかで回避してください：
- 霊夢の `Animator` の `Avatar` を一時的に `None` にして再生する
- 霊夢を複製して、プレビュー用インスタンスだけ `Avatar=None` にする

## 袖などが追従しない（SkinnedMeshRendererのRootBoneがNone）
モデルによっては `Skinned Mesh Renderer` の `Root Bone` が `None` になっており、袖などが骨に追従しないことがあります。
この場合、以下のメニューで **RootBoneを自動補正**できます：
- `Tools > Touhou Talk > Fix SkinnedMeshRenderer Bindings (RootBone/Bones)`

それでも直らない（`Bones` が `Missing` だらけ）場合は、Unity上での参照破損が濃厚なので、
`reimu.vrm` をSceneに再ドラッグして新しい個体を作り、それをPrefab化して使うのが最短です。

## GLB出力まで一括したい（任意）
このツールは “エクスポータが存在する場合だけ” GLB書き出しを試みます。

対応（実装済みの検出）
- `UnityGLTF` の `GLTFSceneExporter` がプロジェクトに存在する場合

導入後、ウィンドウ内の `Export GLB` をONにして実行します。

## なぜこの方式が安定する？
- MixamoはHumanoid化が得意
- VRM（UniVRM）はHumanoid Avatarを持てる
- Humanoid→HumanoidのリターゲットはUnityが最も安定
- three.js用にする段で、Humanoid（筋肉）曲線ではなく **Transform曲線**としてベイクしてしまうのがミソ

## 注意
- 物理（揺れ物）や表情はこの変換では増えません（別系統）
- 腕組み等の“接触ポーズ”は、モーションだけだと崩れやすいので後段でIK補正が必要になりがちです
