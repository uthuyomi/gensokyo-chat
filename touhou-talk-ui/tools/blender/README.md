# Blender 自動化（ヘッドレス）ツール

Touhou-talk-ui の `vrm-characters/*.vrm` を、Blender を使って **自動スキャン**／**idleアニメ生成**するためのローカルツールです。

目的
- `reimu.vrm` などのVRMを読み込み、骨/メッシュ/シェイプキー情報を `*.scan.json` に保存
- “呼吸・微揺れ”の簡易 idle を生成し、`GLB` として書き出し（three.js 側で `AnimationMixer` で再生できる形）

## 前提
- Windows
- Blender がインストール済み
- `BLENDER_EXE` 環境変数に `blender.exe` のフルパスを設定

例（PowerShell）:
```powershell
$env:BLENDER_EXE="C:\Program Files\Blender Foundation\Blender 5.0\blender.exe"
```

## コマンド

### VRMスキャン
`vrm-characters/reimu.vrm` を読み込み、`vrm-characters/reimu.scan.json` を更新します。

```powershell
npm run blender:scan -- --input "vrm-characters/reimu.vrm" --output "vrm-characters/reimu.scan.json"
```

### idle生成（GLB書き出し）
`idle_breathe` アクションを生成して `vrm-characters/motion-library/converted/glb/reimu_idle_breathe.glb` に書き出します。

```powershell
npm run blender:idle -- --input "vrm-characters/reimu.vrm" --output "vrm-characters/motion-library/converted/glb/reimu_idle_breathe.glb"
```

## 設計メモ（重要）
- VRMアドオンに依存しないよう、Blender標準の glTF インポート/エクスポートを使います。
  - そのため Humanoid マップや VRM拡張（表情プリセット等）は“直接”は扱いません。
  - 代わりに、アーマチュア骨名・メッシュ・シェイプキー（morph target）等をスキャンしてJSON化します。
- アニメ生成は「安全第一」：回転中心になりやすい MMD骨（`センター/上半身/首/頭/肩` 等）が見つかる場合のみ軽く揺らします。
