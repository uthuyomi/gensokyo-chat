# Multimodal SDK Integration Plan

## Goal

Move `gensokyo-chat` closer to a unified multimodal conversation stack where:

- the user message stays as plain conversational text
- attachments are passed as first-class inputs instead of being flattened into the message body
- web search policy is carried as part of the same chat request
- character style remains a separate persona layer on top of retrieval and multimodal understanding

This is intended to make the system behave more like "a character layer on top of a multimodal ChatGPT-style runtime" without collapsing persona, memory, or safety behavior into the model call itself.

## Non-goals

- Do not remove Touhou persona prompting
- Do not remove memory, continuity, or safety control layers
- Do not force every turn to browse the web
- Do not rely only on attachment summaries when native file/image handling is available

## Character Preservation

Character quality should not be reduced by this migration if the layering is preserved:

1. Facts and multimodal inputs are gathered first
2. Persona system instructions are applied after that as the style and behavior layer
3. Safety and continuity constraints remain outside the vendor model

The risk is not "multimodal support removes character". The real risk is letting retrieval or file summaries overwrite the persona layer. The implementation below avoids that by keeping persona injection explicit and late-bound.

## Migration Shape

### Phase 1

- Stop stuffing attachment summaries into the user message on the UI side
- Send raw user text plus structured `attachments`
- Add `tool_policy` to the core chat contract
- Let persona-core rebuild bounded attachment context server-side

### Phase 2

- Normalize attachment handling for:
  - uploaded files
  - analyzed links
  - auto-browsed web results
- Carry multimodal preferences in `gen.multimodal`
- Carry web-search intent in `tool_policy`

### Phase 3

- Replace text-only OpenAI calls with a Responses API based client
- Prefer native file/image inputs where supported
- Keep existing parsers as fallback for unsupported formats

### Phase 4

- Unify tool execution around the same request builder:
  - attachments
  - web search
  - optional file search / knowledge retrieval

## Current Implementation Work In This Change

- Add `tool_policy` to persona-core `/persona/chat` and `/persona/chat/stream`
- Merge tool policy into generation metadata in persona-core
- Respect `tool_policy.web_search_mode` before triggering Web RAG
- Extend attachment context builder to include link analysis results, not only uploaded file excerpts
- Update Touhou UI session message path to send raw text with structured attachments instead of pre-flattened augmented text
- Prefer `Responses API` for text generation and web search tool usage
- Resolve uploaded attachments into native multimodal inputs when possible:
  - images -> `input_image`
  - pdf/text-like files -> `input_file`
- Cache uploaded attachment handles via OpenAI Files API when possible:
  - images -> `purpose=vision`
  - pdf/text-like files -> `purpose=user_data`
  - persist returned `file_id` under `common_attachments.meta.openai_files`
  - refresh cached handles if the model API rejects a stale file reference
  - expire cached handles after `SIGMARIS_OPENAI_FILE_CACHE_TTL_SEC`
  - delete superseded or expired OpenAI files when cleanup is enabled
- Keep attachment excerpt/context fallback in place for unsupported formats

## Expected Outcome

- Better separation between user intent text and retrieved context
- Cleaner future path to native Responses API multimodal input
- Better preservation of character voice because multimodal context is no longer fused into the user utterance prematurely
- Safer path to integrating web search and file handling under one contract
- Lower resend cost for repeated attachments because large files can reuse cached OpenAI `file_id`
- Better operational hygiene because stale file handles can be rotated and cleaned up automatically

## Implemented In-Repo

- Structured attachment and tool policy flow from UI to persona-core
- Responses API based multimodal request builder
- Native attachment input for images and pdf/text-like files
- Responses API web search tool integration
- OpenAI Files API handle caching in `common_attachments.meta.openai_files`
- TTL rotation and best-effort cleanup of stale or replaced cached files
- Audit events for OpenAI file-cache upload / reuse / delete actions
- Maintenance script for stale cache inspection and cleanup

## External Validation Still Required

- End-to-end verification against a live OpenAI project with real file uploads
- End-to-end verification against a live Supabase project with attachment persistence enabled
- Cost / latency measurements for repeated large-attachment conversations
- Operational tuning of TTL and cleanup settings for production traffic
