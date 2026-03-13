# モーション素材の集め方（Touhou-talk / Reimu VRM）

このフォルダは **「素材を探す→入手→変換→アプリで再生」** までの手順と、最初に揃えるべきモーション一覧をまとめたもの。

## 目的

- デスクトップ常駐・チャットUI両方で使える「会話っぽい身振り」を少ない手間で揃える
- モーション数を闇雲に増やさず、まずは **10〜20個** を“使える状態”にする

## まず揃えるモーション（Mixamoおすすめ）

Mixamo の検索欄で下のキーワードを当てるのが最短。

### 必須（最低限で自然になるセット）

- Idle: `Idle`, `Standing Idle`（2〜3種類）
- Talk: `Talking`, `Talking (Gesture)`（1〜2種類）
- Nod/No: `Head Nod Yes`, `Head Shake No`
- Think: `Thinking`
- Shrug: `Shrug`
- Wave: `Wave` / `Waving`

### あると強い（常駐でも邪魔になりにくい）

- Look: `Look Around`
- Point: `Pointing`
- Small reaction: `Surprised`（やりすぎ注意）

### 移動系（必要になったら）

- Walk: `Walking`
- Turn: `Turn 90`, `Turn 180`

## 保存先（このリポジトリ内）

著作権や再配布条件が素材ごとに違うので、このリポジトリ内では「原本」と「変換後」を分けて管理する。

```
touhou-talk-ui/vrm-characters/motion-library/
  README.md
  sources/
    mixamo/
      (ここにDLした原本FBXを置く。ファイル名は自由だが後述の命名を推奨)
    mmd/
      (VMD等を置く場合)
  converted/
    glb/
      (Blender等でglTF/GLBに変換したアニメーションを置く想定)
  motions.json
```

`motions.json` は後でアプリ側のローダに食わせるためのメタ（任意）。

## 命名ルール（おすすめ）

原本（FBX）:

- `idle_01_mixamo.fbx`
- `talk_01_mixamo.fbx`
- `nod_01_mixamo.fbx`
- `arms_cross_01_mixamo.fbx`

変換後（GLB）:

- `idle_01.glb`
- `talk_01.glb`
- `nod_01.glb`
- `arms_cross_01.glb`

## 変換の基本方針（Mixamo → VRM → Three.js）

Mixamo のボーンと VRM のヒューマノイドは一致しないので、基本は **Blenderでリターゲット** してから glTF/GLB のアニメにする。

### ざっくり手順

1. Mixamo でモーションをDL（FBX）
2. Blender に
   - VRM（霊夢）を読み込み
   - Mixamo FBX を読み込み
3. Blender 内でリターゲット（Mixamo→VRM）
4. VRM側（霊夢）のアクションとして焼き込み（Bake）
5. VRMモデル本体は含めず、アニメーションだけを glTF/GLB として書き出し
6. three.js / three-vrm 側で AnimationMixer で再生

### “使える最小構成”の考え方（重要）

常駐用途では、大振りモーションより以下が効く：

- 目線（lookAt）
- まばたき（blink）
- 呼吸・微揺れ（procedural）
- 短いジェスチャ（nod / shrug / wave 等）

大モーションは少数で十分。管理コストが爆発するので最初は絞る。

## 利用規約メモ（必ず確認）

モーション配布元ごとに「再配布可否」「改変可否」「商用可否」「クレジット必須」などが違う。

- **このリポジトリに原本データを入れる前に** 条件を確認すること
- 公開予定があるなら、原本はリポジトリに入れずローカル管理に寄せるのが安全

## `motions.json`（テンプレ）

必要になったらここを埋める。

```json
{
  "version": 1,
  "notes": "Local-only. Do not redistribute motion sources unless license permits.",
  "motions": [
    { "name": "idle_01", "kind": "idle", "path": "converted/glb/idle_01.glb", "source": "mixamo" },
    { "name": "talk_01", "kind": "talk", "path": "converted/glb/talk_01.glb", "source": "mixamo" },
    { "name": "nod_01", "kind": "gesture", "path": "converted/glb/nod_01.glb", "source": "mixamo" }
  ]
}
```

