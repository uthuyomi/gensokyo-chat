# gensokyo-persona-core

`gensokyo-persona-core` は、`gensokyo-chat` のキャラクター応答を担う共有 FastAPI backend です。
runtime の進行管理、character assets の読み込み、prompt 構成、safety overlay、locale-aware な表現制御、streaming API、さらに runtime 側 IO 機能を集約しています。

## Quick Read

- Project summary: ワークスペース全体の中核となる character runtime service
- Scope: backend の応答 pipeline、API surface、character asset model、runtime control layer を担う
- Technical highlights: situation-aware routing、safety overlay、response strategy、structured prompt assembly、streaming、retrieval / attachment 統合
- Why it matters: 散在する prompt logic を、保守可能な character behavior system に変えている

## Executive summary

このモジュールは、リポジトリ全体の技術的中心です。
役割は単に文章を生成することではなく、キャラクターがどう返答すべきか、どの制約下で、どの locale で、どの metadata とともに返すか、必要ならどの retrieval や attachment 文脈を使うかまで決めることにあります。

## システム内での役割

このモジュールはキャラクター runtime の正本です。
Frontend は persona prompt を独自に組み立てず、会話状態を送信し、backend がどのように応答すべきかを決定します。

## ポートフォリオ上の価値

このリポジトリをポートフォリオとして読む場合、このモジュールが中核です。
UI 主導の prompting から、character data、situation 分析、safety、strategy、rendering、retrieval 補助を持つ backend runtime へ設計を移している点が一番の見せ場です。

## なぜこの構成が重要か

Character AI は、prompt logic が client 側に分散すると surface が増えるほど壊れやすくなります。
このモジュールは逆に、one runtime, one behavior pipeline, multiple surfaces の方向へ寄せています。
その結果、システムの理解、拡張、一貫性維持がしやすくなります。

## このサービスが責任を持つこと

- chat / streaming endpoint の提供
- backend 側 character assets の管理
- situation 分析と intent 判定
- response strategy と policy の選択
- safety overlay と保護的な挙動の適用
- locale ごとの wording と表現制御
- attachment upload / parse
- runtime 側の web / GitHub retrieval 補助
- relationship score と operator override

## このモジュールが解いている課題

この backend は、Character AI にありがちな次の問題を抑えるためにあります。

- client ごとに character がぶれること
- prompt logic が UI 側で肥大化して保守不能になること
- safety 判断が surface ごとに散ってしまうこと
- locale 切り替えが単なる文言差分で終わってしまうこと
- text 以外の metadata を必要とする richer client を支えられないこと

## 中核 runtime pipeline

システムとして見ると、この runtime は次の段階に分けて整理されています。

1. character asset 解決
2. locale 解決
3. history 正規化と要約
4. situation assessment
5. behavior 解決
6. safety overlay 構築
7. response strategy 構築
8. prompt assembly
9. model invocation
10. reply rendering
11. structured metadata 返却

この段階分離が、このリポジトリでもっとも重要な engineering idea のひとつです。

## Situation / control logic の実態

現状の実装は、「AI がなんとなく判断する」一段ではありません。
コード上で明示的に次の制御が入っています。

- SOS / distress signal
- dependency 系 cue
- medical / legal topic
- technical / informational request
- playful / meta / roleplay / normal interaction
- child / teen / adult を意識した年齢別 handling

これらの signal が、生成前に safety と response strategy の両方へ反映されます。

## 公開 API

| Endpoint | 役割 |
| --- | --- |
| `POST /persona/chat` | 通常の chat 応答 |
| `POST /persona/chat/stream` | streaming 応答 |
| `POST /persona/intent` | 軽量な intent / situation 判定 |
| `POST /persona/relationship/score` | relationship score 補助 |
| `POST /persona/operator/override` | operator からの挙動上書き |
| `GET /persona/characters` | キャラクター一覧 |
| `GET /persona/characters/{character_id}` | キャラクター詳細 |
| `GET /persona/session/{session_id}` | session の状態取得 |
| `POST /io/upload` | attachment upload |
| `POST /io/parse` | attachment parse |
| `GET /io/attachment/{attachment_id}` | attachment 取得 |
| `POST /io/web/search` | web search 補助 |
| `POST /io/web/fetch` | web fetch / 要約補助 |
| `POST /io/web/rag` | web RAG 補助 |
| `POST /io/github/repos` | GitHub repository 検索補助 |
| `POST /io/github/code` | GitHub code 検索補助 |

## リクエストから応答までの実挙動

現状の `CharacterChatRuntime` は、おおむね次の流れで動きます。

1. backend registry から character asset を解決する
2. client context から locale profile を解決する
3. history を正規化し、最近の会話と短い session summary を作る
4. message、chat mode、user profile から situation を判定する
5. behavior、safety overlay、response strategy を解決する
6. layered な runtime 入力から system prompt を組み立てる
7. generation parameter をマージして LLM を呼ぶ
8. 生の reply を character renderer で整形する
9. reply と構造化 meta を返す

streaming 時も、turn ごとの分析は先に実行され、そのうえで stream 本文と runtime metadata が返されます。

## Post-generation shaping

generation は最終段階ではありません。
現状の renderer では、モデル出力の後に次の整形が入ります。

- safety rewrite
- child 向け日本語調整
- character profile に対する consistency check

つまりこの runtime は、生成を response system 全体の一段として扱っています。

## Retrieval / IO 補助

この runtime は、純粋な text generation から少しずつ広がっています。
現状の API 面からも、次の支援を持っていることが読み取れます。

- attachment の upload / parse
- web search / web fetch
- web RAG 系 endpoint
- GitHub repository / code retrieval

つまり、この backend は単なる prompt wrapper ではなく、character runtime と controlled external-information layer を兼ね始めています。

## Metadata / state 出力

この runtime は、downstream product behavior を支えられるだけの構造化情報を返します。
経路によって差はありますが、たとえば次のような情報が含まれます。

- situation / strategy snapshot
- safety / behavior snapshot
- locale resolution 結果
- rendering hint
- UI 層で後続保存される state 系 field

そのため client は文字列だけでなく、「なぜその応答になったか」の制御面も利用できます。

## meta に何が入るか

この runtime meta は単なる debug 情報ではありません。
たとえば次のような構造化情報を返します。

- interaction type
- safety risk
- strategy snapshot
- situation snapshot
- behavior snapshot
- safety snapshot
- resolved locale
- locale style snapshot
- TTS style や animation hint のような rendering hint

そのため、この backend は文字列生成だけでなく、UI 側の表情制御や観測にも使える設計になっています。

## エンジニアリングサンプルとして強い理由

このモジュールには、本来別チームに分かれがちな仕事がまとまっています。

- API surface 設計
- runtime pipeline 設計
- prompt assembly architecture
- structured asset loading
- safety-aware な応答制御
- streaming 応答処理
- downstream client 向け metadata 設計

そのため、systems-oriented な application engineering のサンプルとして見せやすい構成です。

## エンジニアが直接追うべきコード

高シグナルなのは次のコードパスです。

- `persona_core/server_persona_os.py`
- `persona_core/runtime/character_chat_runtime.py`
- `persona_core/character_runtime/registry.py`
- `persona_core/prompting/`
- `persona_core/rendering/`
- `persona_core/safety/`、`persona_core/situation/`、`persona_core/strategy/`

## ディレクトリガイド

| Path | 役割 |
| --- | --- |
| `persona_core/server_persona_os.py` | FastAPI エントリポイント |
| `persona_core/runtime/` | 中核 runtime 処理 |
| `persona_core/character_runtime/` | asset 読み込みと schema |
| `persona_core/characters/` | キャラクター定義の backend 正本 |
| `persona_core/behavior/` | 振る舞い解決 |
| `persona_core/situation/` | 状況分析 |
| `persona_core/strategy/` と `persona_core/policy/` | 応答戦略と policy |
| `persona_core/safety/` | safety overlay |
| `persona_core/prompting/` | prompt block 構成 |
| `persona_core/rendering/` | 出力の整形 |
| `persona_core/memory/` | memory / recall 補助 |
| `persona_core/storage/` | Supabase ベースの保存と auth 補助 |
| `persona_core/evaluation/` | 評価と回帰確認 |
| `docs/` | 設計・移行ドキュメント |

## キャラクターアセットモデル

各キャラクターは以下に定義されています。

```text
persona_core/characters/<character_id>/
```

代表的なファイルは次のとおりです。

```text
profile.json
world.json
prompts.json
gen_params.json
control_plane_en.json
soul.json
style.json
safety.json
situational_behavior.json
locales/
localized_prompts/
```

runtime で合成しやすい構造を保ちつつ、人が日常的に編集できる粒度を重視しています。

コード上では、`profile.json` を持つディレクトリだけを有効な character として registry が扱い、lazy load と cache を使って runtime に渡します。

## ローカル開発

`requirements.txt` をもとに依存関係を入れたうえで、以下を実行します。

```powershell
cd gensokyo-persona-core
.\.venv\Scripts\python -m uvicorn persona_core.server_persona_os:app --host 127.0.0.1 --port 8000 --reload
```

## このモジュールの重要性

この backend は、リポジトリ全体の中核となる設計判断です。
キャラクター制御をここに集約することで、複数クライアント間で persona logic を重複させず、キャラクター性のぶれも抑えやすくしています。

ポートフォリオとして見ると、API 設計、runtime orchestration、prompt architecture、safety layering、ファイルベースのキャラクター設計、streaming、retrieval 統合までをまたいだ実装になっています。

## 評価するならどこを見るべきか

このモジュールは、「モデルを呼べるか」で評価するより、「キャラクター挙動を保守可能なシステムに変えているか」で評価するほうが本質に近いです。
この README も、その観点が伝わるように書いています。

## 関連資料

設計資料の入口は `docs/README.md` を参照してください。
