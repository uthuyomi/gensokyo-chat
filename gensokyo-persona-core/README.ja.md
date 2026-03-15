**Languages:** [English](README.md) | 譌･譛ｬ隱・
# sigmaris-core・・igmaris Persona OS Engine・・
`sigmaris-core` 縺ｯ Project Sigmaris 縺ｮ **繝舌ャ繧ｯ繧ｨ繝ｳ繝会ｼ医お繝ｳ繧ｸ繝ｳ・・*縺ｧ縺吶・ 
FastAPI 縺ｮHTTP API繧呈署萓帙＠縲￣ersona OS・・LM螟夜Κ蛻ｶ蠕｡螻､・峨ｒ螳溯｣・＠縺ｾ縺吶・
- 險俶・縺ｮ蜿匁昏驕ｸ謚槭→蜀肴ｳｨ蜈･・・emory orchestration・・- 繧ｻ繝・す繝ｧ繝ｳ繧偵∪縺溘＄蜷御ｸ諤ｧ・・dentity continuity・・- 萓｡蛟､/迚ｹ諤ｧ縺ｮ繝峨Μ繝輔ヨ・・alue/Trait drift・・- 莨夊ｩｱ迥ｶ諷九Ν繝ｼ繝・ぅ繝ｳ繧ｰ・・hase03・・- Safety / Guardrails
- 蜿ｯ隕ｳ貂ｬ諤ｧ・・trace_id` + `meta`・・
縺薙・繧ｨ繝ｳ繧ｸ繝ｳ繧貞茜逕ｨ縺吶ｋUI:

---

## API

- `POST /persona/chat` 竊・`{ reply, meta }`
- `POST /persona/chat/stream` 竊・SSE・・start` / `delta` / `done`・・

- `POST /io/web/search` 窶・Web讀懃ｴ｢・・erper・・- `POST /io/web/fetch` 窶・Web蜿門ｾ暦ｼ具ｼ井ｻｻ諢擾ｼ芽ｦ∫ｴ・ｼ・llowlist/SSRF繧ｬ繝ｼ繝会ｼ・- `POST /io/web/rag` 窶・讀懃ｴ｢竊呈ｷｱ謗倥ｊ・井ｸ企剞縺ゅｊ・俄・謚ｽ蜃ｺ竊偵Λ繝ｳ繧ｭ繝ｳ繧ｰ竊呈枚閼域ｳｨ蜈･・井ｻｻ諢擾ｼ・
Swagger:

- `http://127.0.0.1:8000/docs`

### 譛蟆上Μ繧ｯ繧ｨ繧ｹ繝・
```bash
curl -X POST "http://127.0.0.1:8000/persona/chat" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"u_test_001","session_id":"s_test_001","message":"縺薙ｓ縺ｫ縺｡縺ｯ縲・譁・〒霑斐＠縺ｦ縲・}'
```

### Streaming・・SE・・
```bash
curl -N -X POST "http://127.0.0.1:8000/persona/chat/stream" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"u_test_001","session_id":"s_test_001","message":"縺薙ｓ縺ｫ縺｡縺ｯ縲ゅせ繝医Μ繝ｼ繝縺ｧ霑斐＠縺ｦ縲・}'
```

---

## Web RAG・井ｻｻ諢擾ｼ・
sigmaris-core 縺ｯ縲∝ｿ・ｦ√↓蠢懊§縺ｦ **螟夜ΚWeb諠・ｱ** 繧貞叙蠕励＠縺ｦ蝗樒ｭ斐ｒ陬懷ｼｷ縺ｧ縺阪∪縺呻ｼ郁ｨｭ螳壹〒ON/OFF・峨・
### 蠢・茨ｼ域､懃ｴ｢繝励Ο繝舌う繝・・
- `SERPER_API_KEY`

### 蠢・茨ｼ亥ｮ牙・縺ｮ縺溘ａ縺ｮ蜿門ｾ苓ｨｱ蜿ｯ・・
Web蜿門ｾ励・ allowlist 譛ｪ險ｭ螳壹□縺ｨ繝悶Ο繝・け縺輔ｌ縺ｾ縺吶・
- `SIGMARIS_WEB_FETCH_ALLOW_DOMAINS`・医き繝ｳ繝槫玄蛻・ｊ縲ゆｾ・ `wikipedia.org, dic.nicovideo.jp, w.atwiki.jp, touhouwiki.net`・・
### 譛牙柑蛹・
- `SIGMARIS_WEB_RAG_ENABLED=1`・・/io/web/rag` 縺ｨ繝√Ε繝・ヨ豕ｨ蜈･繧呈怏蜉ｹ蛹厄ｼ・- `SIGMARIS_WEB_RAG_AUTO=1`・井ｻｻ諢擾ｼ壽凾莠九▲縺ｽ縺・匱隧ｱ縺ｧ閾ｪ蜍戊ｵｷ蜍包ｼ・
### 繝昴Μ繧ｷ繝ｼ/隱ｿ謨ｴ

- `SIGMARIS_WEB_RAG_ALLOW_DOMAINS` / `SIGMARIS_WEB_RAG_DENY_DOMAINS`・郁ｿｽ蜉縺ｮ險ｱ蜿ｯ/諡貞凄・・- `SIGMARIS_WEB_RAG_MAX_PAGES`・域里螳・`20`・・- `SIGMARIS_WEB_RAG_MAX_DEPTH`・域里螳・`1`・・- `SIGMARIS_WEB_RAG_TOP_K`・域里螳・`6`・・- `SIGMARIS_WEB_RAG_CRAWL_CROSS_DOMAIN=1`・域里螳唹FF・壼酔荳繝帙せ繝医・縺ｿ豺ｱ謗倥ｊ・・- `SIGMARIS_WEB_RAG_LINKS_PER_PAGE`・域里螳・`120`・・- `SIGMARIS_WEB_RAG_RECENCY_DAYS`・域凾莠九ち繝ｼ繝ｳ縺ｮ譌｢螳・`14`・・
### 隕∫ｴ・ｼ井ｻｻ諢上・闡嶺ｽ懈ｨｩ驟肴・・・
- `SIGMARIS_WEB_FETCH_SUMMARIZE=1`
- `SIGMARIS_WEB_FETCH_SUMMARY_MODEL`・域里螳・`gpt-5-mini`・・- `SIGMARIS_WEB_FETCH_SUMMARY_TIMEOUT_SEC`・域里螳・`60`・・
### 闡嶺ｽ懈ｨｩ/隕冗ｴ・
- 髟ｷ譁・ｻ｢霈峨・驕ｿ縺代・*隕∫ｴ・ｼ医ヱ繝ｩ繝輔Ξ繝ｼ繧ｺ・・* 繧貞渕譛ｬ縺ｫ縺励∪縺・- Web逕ｱ譚･縺ｮ荳ｻ蠑ｵ縺ｯ **URL繧呈ｷｻ縺医※** 霑斐☆繧医≧縺ｫ縺励∪縺・
---

## Quickstart・・ocal・・
### 蠢・ｦ∬ｦ∽ｻｶ

- Python 3.11+ 謗ｨ螂ｨ

### 1) Install

```bash
cd gensokyo-persona-core
pip install -r requirements.txt
```

### 2) env 險ｭ螳・
譛蟆・

- `OPENAI_API_KEY`

莉ｻ諢擾ｼ域ｰｸ邯壼喧/繧｢繝・・繝ｭ繝ｼ繝・繧ｹ繝医Ξ繝ｼ繧ｸ騾｣謳ｺ・・

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

### 3) 襍ｷ蜍・
```bash
python -m uvicorn server:app --reload --port 8000
```

---

## 莨夊ｩｱ閾ｪ辟ｶ蛹厄ｼ・1・・
縲碁擇隲・▲縺ｽ縺・謨ｴ逅・＠縺吶℃縲阪↓縺ｪ繧翫ｄ縺吶＞蠢懃ｭ斐ｒ謚代∴繧九◆繧√ゞI縺ｫ萓晏ｭ倥＠縺ｪ縺・**繧ｳ繧｢蛛ｴ縺ｮ蛻ｶ蠕｡**縺ｨ縺励※霆ｽ驥上Ξ繧､繝､繧貞・繧後※縺・∪縺吶・
- `session_id` 蜊倅ｽ阪〒繝代Λ繝｡繝ｼ繧ｿ・井ｼ夊ｩｱ縺ｮ驕玖ｻ｢/繧ｹ繧ｿ繧､繝ｫ・峨ｒ菫晄戟
- 1繧ｿ繝ｼ繝ｳ縺ｧ螟ｧ繧ｸ繝｣繝ｳ繝励○縺壹↓貊代ｉ縺九↓譖ｴ譁ｰ
- 蠑ｷ蛻ｶ繝ｫ繝ｼ繝ｫ・郁ｨｱ蜿ｯ蜿悶ｊ繝・Φ繝励Ξ謚大宛縲∬ｳｪ蝠上・蜴溷援1縺､縲∫ｭ会ｼ峨ｒ驕ｩ逕ｨ

螳溯｣・

- `persona_core/phase03/naturalness_controller.py`

---

## 譛ｬ逡ｪ蜷代￠豕ｨ諢・
- `SUPABASE_SERVICE_ROLE_KEY` 縺ｯ繧ｯ繝ｩ繧､繧｢繝ｳ繝医↓蜃ｺ縺輔↑縺・ｼ医し繝ｼ繝仙・縺ｮ縺ｿ・峨・- 繧ｹ繝医Μ繝ｼ繝溘Φ繧ｰ・・SE・峨ｒ菴ｿ縺・ｴ蜷医√・繝ｭ繧ｭ繧ｷ縺ｧ繝舌ャ繝輔ぃ繝ｪ繝ｳ繧ｰ縺輔ｌ縺ｪ縺・ｧ区・縺ｫ縺吶ｋ・亥・騾溘′驕・￥縺ｪ繧具ｼ峨・- 繝ｦ繝ｼ繧ｶ繝ｼ縺ｫ霑代＞繝ｪ繝ｼ繧ｸ繝ｧ繝ｳ縺ｧ蜍輔°縺吶→蛻晏屓繝医・繧ｯ繝ｳ縺碁溘￥縺ｪ繧九・
