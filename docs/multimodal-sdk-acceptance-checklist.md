# Multimodal SDK Acceptance Checklist

## Implemented In Code

- `Responses API` is the preferred chat generation path
- `web_search` tool can be enabled through the same chat request contract
- Uploaded images are passed as native multimodal inputs
- Uploaded pdf/text-like files are passed as native multimodal inputs
- Unsupported attachments still fall back to bounded extracted context
- Cached OpenAI `file_id` handles are stored in `common_attachments.meta.openai_files`
- Cached file handles expire after `SIGMARIS_OPENAI_FILE_CACHE_TTL_SEC`
- Expired or replaced OpenAI files are best-effort deleted when cleanup is enabled
- Audit records for cache upload / reuse / delete are written as `common_io_events.event_type=openai_file_cache`
- Stale cache metadata can be inspected or cleaned via `gensokyo-persona-core/tools/openai_file_cache_maintenance.py`

## Verification That Can Run Locally

1. `python -m py_compile gensokyo-persona-core\\persona_core\\storage\\supabase_rest.py gensokyo-persona-core\\persona_core\\storage\\supabase_store.py gensokyo-persona-core\\persona_core\\server_persona_os.py gensokyo-persona-core\\persona_core\\llm\\openai_llm_client.py`
2. `python -m unittest discover -s gensokyo-persona-core\\tests -p "test_*.py"`
3. `npm exec --prefix touhou-talk-ui -- tsc -p touhou-talk-ui\\tsconfig.json --noEmit --pretty false`

## External Validation Still Needed

- Live OpenAI check:
  - upload an image and confirm the reply reflects the image naturally
  - upload the same file twice and confirm cache reuse reduces resend behavior
  - wait past TTL or lower TTL temporarily and confirm cached handle rotation works
- Live Supabase check:
  - confirm `common_attachments.meta.openai_files` is written as expected
  - confirm `common_io_events` receives `openai_file_cache` audit events
- Operational check:
  - confirm cleanup does not remove files that are still needed too aggressively
  - measure latency and token/cost impact on repeated attachment turns

## Maintenance Commands

Inspect stale cache entries:

```powershell
python gensokyo-persona-core\tools\openai_file_cache_maintenance.py --dry-run
```

Clean stale metadata only:

```powershell
python gensokyo-persona-core\tools\openai_file_cache_maintenance.py --cleanup-stale
```

Clean stale metadata and delete stale remote OpenAI files:

```powershell
python gensokyo-persona-core\tools\openai_file_cache_maintenance.py --cleanup-stale --delete-remote
```
