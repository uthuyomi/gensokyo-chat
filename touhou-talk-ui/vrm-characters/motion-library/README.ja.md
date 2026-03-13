# モーションライブラリ（ローカル専用）

このフォルダは **Touhou-talk のローカル開発用** に、モーション素材を管理する場所です。
著作権・ライセンスの都合があるので、`sources/` 配下の元データや、許諾が不明な変換後データは **配布・公開しない** 前提で使ってください。

## 目標（いま欲しいやつ）

- Unityで作った/変換した **GLB（アニメ入り）** を置く
- Web（three.js / `VrmStage`）が `/api/motions` から一覧取得して読み込み
- `AnimationMixer` で idle / gesture を再生
- talkは素材なし想定で、喋ってる間だけ **微小な“会話微動”** をWeb側で重ねる

## 置き場所

- 元素材（FBX/VMDなど）: `sources/`
- 変換後（GLB）: `converted/glb/`
- メタ情報: `motions.json`

例:

```
vrm-characters/motion-library/
  sources/mixamo/...
  converted/glb/idle_01.glb
  converted/glb/nod_yes.glb
  motions.json
```

## `motions.json` の書き方

`motions.json` は Web 側が「このGLBは idle / gesture のどれ？」を判断するための一覧です。

```json
{
  "version": 1,
  "notes": "Local-only. Do not redistribute motion sources unless license permits.",
  "motions": [
    { "name": "idle_01", "kind": "idle", "path": "converted/glb/idle_01.glb", "source": "mixamo" },
    { "name": "idle_02", "kind": "idle", "path": "converted/glb/idle_02.glb", "source": "mixamo" },
    { "name": "nod_yes", "kind": "gesture", "path": "converted/glb/nod_yes.glb", "source": "mixamo" },
    { "name": "shake_no", "kind": "gesture", "path": "converted/glb/shake_no.glb", "source": "mixamo" },
    { "name": "think", "kind": "gesture", "path": "converted/glb/think.glb", "source": "mixamo" },
    { "name": "bow", "kind": "gesture", "path": "converted/glb/bow.glb", "source": "mixamo" }
  ]
}
```

### 命名のコツ

- Web側のジェスチャは `nod / shake_head / think / bow / wave / shrug` などを使います
- `name` は英数字・`._-` だけ（APIの安全対策）
- 迷ったら:
  - `idle_01`, `idle_02`
  - `nod_yes`, `shake_no`
  - `think`, `bow`, `wave`, `shrug`

## もし `motions.json` を書かない場合

`motions.json` が空/無い場合でも、`converted/glb/*.glb` を自動発見して一覧に出します。
ただし `kind` はファイル名先頭で推測（`idle*`→idle、`talk*`→talk、それ以外→gesture）なので、ちゃんと運用するなら `motions.json` を書くのがおすすめです。

## Web側の確認

- 一覧: `GET /api/motions`
- ファイル: `GET /api/motions/{name}`

Web側（`components/vrm/VrmStage.tsx`）は、見つかったGLBを読み込んで `AnimationMixer` で再生します。

