# gensokyo-persona-core/persona_core/llm/openai_llm_client.py
# ----------------------------------------------------
# Persona OS 用 OpenAI LLM クライアント
# - embedding: SelectiveRecall 等で使用
# - generate: 通常応答
# - generate_stream: ストリーミング応答（SSE等で利用）
# ----------------------------------------------------

from __future__ import annotations

import json
import logging
import math
import os
import random
import time
import base64
import io
import hashlib
import threading
import uuid
from typing import Any, Dict, Iterable, List, Optional

import openai
from openai import OpenAI

from persona_core.controller.persona_controller import LLMClientLike
from persona_core.identity.identity_continuity import IdentityContinuityResult
from persona_core.memory.memory_orchestrator import MemorySelectionResult
from persona_core.state.global_state_machine import GlobalStateContext, PersonaGlobalState
from persona_core.storage.supabase_rest import SupabaseConfig, SupabaseRESTClient
from persona_core.storage.supabase_store import SupabasePersonaDB
from persona_core.trait.trait_drift_engine import TraitState
from persona_core.types.core_types import PersonaRequest
from persona_core.value.value_drift_engine import ValueState


def cosine_similarity(a: List[float], b: List[float]) -> float:
    if not a or not b or len(a) != len(b):
        return 0.0
    dot = sum(x * y for x, y in zip(a, b))
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(y * y for y in b))
    if na == 0 or nb == 0:
        return 0.0
    return dot / (na * nb)


class OpenAILLMClient(LLMClientLike):
    def __init__(
        self,
        *,
        model: str = "gpt-5.2",
        temperature: float = 0.7,
        max_tokens: int = 1200,
        max_tokens_cap: Optional[int] = None,
        api_key: Optional[str] = None,
        client: Optional[OpenAI] = None,
        embedding_model: str = "text-embedding-3-small",
        request_timeout_sec: float = 60.0,
        max_retries: int = 3,
    ) -> None:
        self.model = model
        self.temperature = float(temperature)
        self.max_tokens = int(max_tokens)
        self.embedding_model = embedding_model

        if max_tokens_cap is None:
            env_cap = os.getenv("SIGMARIS_MAX_COMPLETION_TOKENS_CAP") or os.getenv("SIGMARIS_MAX_TOKENS_CAP")
            try:
                max_tokens_cap = int(env_cap) if env_cap not in (None, "") else None
            except Exception:
                max_tokens_cap = None
        # Allow larger generations than the previous hard-coded 4096 cap, but keep a safety ceiling.
        # Note: model-side limits still apply; on limit errors we shrink and retry.
        self._max_tokens_cap = int(max_tokens_cap) if max_tokens_cap is not None else 16384

        self._timeout_sec = float(request_timeout_sec)
        self._max_retries = max(1, int(max_retries))

        if client is not None:
            self.client = client
        else:
            self.client = OpenAI(api_key=api_key or os.getenv("OPENAI_API_KEY"), timeout=self._timeout_sec)

        self._fallback_dim = 1536
        self._embed_cache_ttl_sec = float(os.getenv("SIGMARIS_EMBED_CACHE_TTL_SEC", "15") or "15")
        self._embed_cache_max = int(os.getenv("SIGMARIS_EMBED_CACHE_MAX", "512") or "512")
        self._embed_cache_max = max(0, min(10000, self._embed_cache_max))
        self._embed_cache: Dict[str, Dict[str, Any]] = {}  # key -> {"ts": float, "emb": list[float]}
        self._embed_cache_lock = threading.Lock()
        self._attachment_file_cache: Dict[str, Dict[str, Any]] = {}
        self._attachment_file_cache_lock = threading.Lock()
        self._attachment_meta_store = self._build_attachment_meta_store()
        self._io_audit_store = self._build_io_audit_store()

    # --------------------------
    # Embeddings
    # --------------------------

    def encode(self, text: str) -> List[float]:
        t = (text or "").strip()
        k: Optional[str] = None

        if t and self._embed_cache_ttl_sec > 0 and self._embed_cache_max > 0:
            try:
                k = hashlib.sha256(t.encode("utf-8", errors="ignore")).hexdigest()
                now = time.time()
                with self._embed_cache_lock:
                    hit = self._embed_cache.get(k)
                    if isinstance(hit, dict):
                        ts = hit.get("ts")
                        emb = hit.get("emb")
                        if isinstance(ts, (int, float)) and (now - float(ts)) <= float(self._embed_cache_ttl_sec):
                            if isinstance(emb, list) and emb:
                                return [float(x) for x in emb]
                        else:
                            self._embed_cache.pop(k, None)
            except Exception:
                k = None

        try:
            res = self.client.embeddings.create(model=self.embedding_model, input=(t or text))
            emb = res.data[0].embedding
            self._fallback_dim = len(emb)

            if t and k and self._embed_cache_ttl_sec > 0 and self._embed_cache_max > 0:
                try:
                    with self._embed_cache_lock:
                        self._embed_cache[k] = {"ts": float(time.time()), "emb": emb}
                        if len(self._embed_cache) > self._embed_cache_max:
                            items = list(self._embed_cache.items())
                            items.sort(key=lambda kv: float((kv[1] or {}).get("ts") or 0.0))
                            drop_n = max(1, int(self._embed_cache_max * 0.1))
                            for dk, _ in items[:drop_n]:
                                self._embed_cache.pop(dk, None)
                except Exception:
                    pass

            return emb
        except Exception:
            return [0.0] * self._fallback_dim

    def embed(self, text: str) -> List[float]:
        return self.encode(text)

    def similarity(self, v1: List[float], v2: List[float]) -> float:
        return float(cosine_similarity(v1, v2))

    # --------------------------
    # Generation helpers
    # --------------------------

    def _build_messages(
        self,
        *,
        system_prompt: str,
        user_text: str,
        history: Optional[List[Dict[str, str]]] = None,
    ) -> List[Dict[str, str]]:
        msgs: List[Dict[str, str]] = [{"role": "system", "content": (system_prompt or "").strip()}]
        if isinstance(history, list) and history:
            for m in history:
                if not isinstance(m, dict):
                    continue
                role = str(m.get("role") or "").strip().lower()
                if role in ("ai",):
                    role = "assistant"
                if role not in ("user", "assistant"):
                    continue
                content = str(m.get("content") or "").strip()
                if not content:
                    continue
                msgs.append({"role": role, "content": content})
        msgs.append({"role": "user", "content": (user_text or "").strip()})
        return msgs

    def _phase03_dialogue_instructions(self, state: Optional[str]) -> Optional[str]:
        """
        Phase03 Dialogue State -> short, non-CoT style guidance.
        Keep this as a lightweight bias, not a hard constraint.
        """
        if not state:
            return None
        s = str(state).strip()
        if not s:
            return None

        common = "Do not expose chain-of-thought. Be concise but helpful."

        if s == "S1_CASUAL":
            return "\n".join(
                [
                    "Casual mode:",
                    "- Keep it short and friendly.",
                    "- Avoid over-structuring unless asked.",
                    f"- {common}",
                ]
            )
        if s == "S2_TASK":
            return "\n".join(
                [
                    "Task mode:",
                    "- Use a clear structure (steps / options / checks).",
                    "- Ask 1–2 clarifying questions if needed.",
                    "- Call out assumptions and uncertainties.",
                    f"- {common}",
                ]
            )
        if s == "S3_EMOTIONAL":
            return "\n".join(
                [
                    "Emotional support mode:",
                    "- Validate feelings briefly, then ask gentle clarifying questions.",
                    "- Avoid pressure, guilt, or dependency framing.",
                    "- Prefer grounding + small next steps.",
                    f"- {common}",
                ]
            )
        if s == "S4_META":
            return "\n".join(
                [
                    "Meta mode:",
                    "- Explain the system behavior/limits clearly and factually.",
                    "- Avoid anthropomorphic claims.",
                    f"- {common}",
                ]
            )
        if s == "S5_CREATIVE":
            return "\n".join(
                [
                    "Creative / roleplay mode:",
                    "- Maintain character/world consistency.",
                    "- Keep factual claims separated from fiction if relevant.",
                    f"- {common}",
                ]
            )
        if s == "S6_SAFETY":
            return "\n".join(
                [
                    "Safety mode:",
                    "- If the user requests harmful/illegal actions, refuse and redirect to safe alternatives.",
                    "- Keep explanations short and non-judgmental.",
                    f"- {common}",
                ]
            )
        return None

    def _is_retryable(self, err: Exception) -> bool:
        if isinstance(
            err,
            (
                openai.RateLimitError,
                openai.APIConnectionError,
                openai.APITimeoutError,
                openai.InternalServerError,
                openai.APIStatusError,
            ),
        ):
            status = getattr(err, "status_code", None)
            if status in (429, 500, 502, 503, 504, None):
                return True
        s = str(err)
        return any(x in s for x in ("429", "Rate limit", "timed out", "Timeout", "ECONN", "502", "503", "504"))

    def _backoff_sleep(self, attempt: int) -> None:
        base = 0.6 * (2**attempt)
        time.sleep(base + random.random() * 0.25)

    def _clamp_temperature(self, temperature: float) -> float:
        return max(0.0, min(2.0, float(temperature)))

    def _clamp_max_tokens(self, max_tokens: int) -> int:
        cap = max(16, int(self._max_tokens_cap))
        return max(16, min(cap, int(max_tokens)))

    def _is_token_limit_error(self, err: Exception) -> bool:
        s = str(err)
        needles = (
            "max_tokens",
            "max_completion_tokens",
            "maximum",
            "context length",
            "context_length",
            "too large",
            "must be less than",
            "exceeds",
        )
        return any(n in s for n in needles)

    def _max_continuations(self) -> int:
        raw = os.getenv("SIGMARIS_LLM_MAX_CONTINUATIONS", "2")
        try:
            v = int(raw)
        except Exception:
            v = 2
        return max(0, min(5, v))

    def _should_auto_continue(self, finish_reason: Optional[str]) -> bool:
        # OpenAI finish_reason: "stop" | "length" | "content_filter" | ...
        return finish_reason == "length" and self._max_continuations() > 0

    def _continue_user_prompt(self) -> str:
        return (
            "続きがあります。直前の出力の続きから、重複を避けてそのまま続きを書いてください。"
            "可能なら簡潔に、必要なら段落を区切って読みやすくしてください。"
        )

    def _responses_api_enabled(self) -> bool:
        raw = os.getenv("SIGMARIS_USE_RESPONSES_API", "1")
        return str(raw).strip().lower() not in ("0", "false", "no", "off")

    def _build_attachment_meta_store(self) -> Optional[SupabasePersonaDB]:
        try:
            cfg = SupabaseConfig.from_env()
            if cfg is None:
                return None
            return SupabasePersonaDB(SupabaseRESTClient(cfg))
        except Exception:
            return None

    def _build_io_audit_store(self) -> Optional[SupabasePersonaDB]:
        return self._build_attachment_meta_store()

    def _openai_file_cache_enabled(self) -> bool:
        raw = os.getenv("SIGMARIS_OPENAI_FILE_CACHE_ENABLED", "1")
        return str(raw).strip().lower() not in ("0", "false", "no", "off")

    def _openai_file_cache_ttl_sec(self) -> int:
        raw = os.getenv("SIGMARIS_OPENAI_FILE_CACHE_TTL_SEC", "604800")
        try:
            ttl = int(raw)
        except Exception:
            ttl = 604800
        return max(0, ttl)

    def _openai_file_cleanup_enabled(self) -> bool:
        raw = os.getenv("SIGMARIS_OPENAI_FILE_CLEANUP_ENABLED", "1")
        return str(raw).strip().lower() not in ("0", "false", "no", "off")

    def _response_attachment_purpose(self, item: Dict[str, Any]) -> Optional[str]:
        t = str(item.get("type") or "").strip()
        if t == "input_image":
            return "vision"
        if t == "input_file":
            return "user_data"
        return None

    def _attachment_cache_key(self, item: Dict[str, Any], purpose: str) -> str:
        attachment_id = str(item.get("attachment_id") or "").strip()
        sha = str(item.get("attachment_sha256") or "").strip()
        name = str(item.get("file_name") or item.get("filename") or "attachment").strip()
        mime = str(item.get("mime_type") or "application/octet-stream").strip()
        return f"{attachment_id}:{purpose}:{sha}:{name}:{mime}"

    def _cached_openai_file_entry(self, item: Dict[str, Any], purpose: str) -> Optional[Dict[str, Any]]:
        attachment_meta = item.get("attachment_meta")
        if not isinstance(attachment_meta, dict):
            attachment_meta = {}
        openai_files = attachment_meta.get("openai_files")
        if not isinstance(openai_files, dict):
            openai_files = {}
        entry = openai_files.get(purpose)
        return entry if isinstance(entry, dict) else None

    def _cache_entry_matches_attachment(self, item: Dict[str, Any], purpose: str, entry: Optional[Dict[str, Any]]) -> bool:
        if not isinstance(entry, dict):
            return False
        file_id = str(entry.get("file_id") or "").strip()
        if not file_id:
            return False
        sha = str(item.get("attachment_sha256") or "").strip()
        cached_sha = str(entry.get("attachment_sha256") or "").strip()
        if sha and cached_sha and sha != cached_sha:
            return False
        name = str(item.get("file_name") or item.get("filename") or "attachment").strip()
        if str(entry.get("file_name") or "").strip() not in ("", name):
            return False
        mime = str(item.get("mime_type") or "application/octet-stream").strip()
        if str(entry.get("mime_type") or "").strip() not in ("", mime):
            return False
        return str(entry.get("purpose") or "").strip() in ("", purpose)

    def _cache_entry_expired(self, entry: Optional[Dict[str, Any]]) -> bool:
        if not isinstance(entry, dict):
            return True
        ttl = self._openai_file_cache_ttl_sec()
        if ttl <= 0:
            return False
        ts = entry.get("updated_at_unix")
        if not isinstance(ts, (int, float)):
            return True
        return (time.time() - float(ts)) > float(ttl)

    def _decode_native_attachment_bytes(self, item: Dict[str, Any]) -> Optional[bytes]:
        try:
            t = str(item.get("type") or "").strip()
            if t == "input_file":
                raw = item.get("file_data")
                if isinstance(raw, str) and raw:
                    return base64.b64decode(raw.encode("ascii"), validate=False)
                return None
            if t == "input_image":
                image_url = str(item.get("image_url") or "").strip()
                if not image_url.startswith("data:") or "," not in image_url:
                    return None
                _, payload = image_url.split(",", 1)
                return base64.b64decode(payload.encode("ascii"), validate=False)
        except Exception:
            return None
        return None

    def _looks_like_uuid(self, value: Any) -> bool:
        try:
            uuid.UUID(str(value or ""))
            return True
        except Exception:
            return False

    def _audit_openai_file_cache_event(
        self,
        *,
        audit_ctx: Optional[Dict[str, Any]],
        action: str,
        item: Optional[Dict[str, Any]] = None,
        purpose: Optional[str] = None,
        ok: bool,
        error: Optional[str] = None,
        response: Optional[Dict[str, Any]] = None,
    ) -> None:
        if self._io_audit_store is None or not isinstance(audit_ctx, dict):
            return
        user_id = str(audit_ctx.get("user_id") or "").strip()
        if not self._looks_like_uuid(user_id):
            return
        session_id = str(audit_ctx.get("session_id") or "").strip() or None
        trace_id = str(audit_ctx.get("trace_id") or "").strip() or None
        item0 = item if isinstance(item, dict) else {}
        request_payload = {
            "action": str(action or ""),
            "attachment_id": str(item0.get("attachment_id") or "").strip() or None,
            "purpose": str(purpose or "").strip() or None,
            "file_name": str(item0.get("file_name") or item0.get("filename") or "").strip() or None,
            "mime_type": str(item0.get("mime_type") or "").strip() or None,
            "size_bytes": int(item0.get("size_bytes")) if isinstance(item0.get("size_bytes"), int) else None,
            "attachment_sha256": str(item0.get("attachment_sha256") or "").strip() or None,
        }
        try:
            self._io_audit_store.insert_io_event(
                user_id=user_id,
                session_id=session_id,
                trace_id=trace_id,
                event_type="openai_file_cache",
                cache_key=self._attachment_cache_key(item0, purpose or "") if item0 and purpose else None,
                ok=bool(ok),
                error=(str(error) if error else None),
                request=request_payload,
                response=response or {},
                source_urls=[],
                content_sha256=None,
                meta={"component": "openai_llm_client", "cache_layer": "attachment_file"},
            )
        except Exception:
            logging.getLogger(__name__).debug("failed to audit OpenAI file cache event", exc_info=True)

    def _delete_openai_file_best_effort(self, file_id: Optional[str]) -> None:
        fid = str(file_id or "").strip()
        if not fid or not self._openai_file_cleanup_enabled():
            return
        try:
            self.client.files.delete(fid)
        except Exception:
            logging.getLogger(__name__).debug("failed to delete cached OpenAI file", exc_info=True)

    def _remove_cached_openai_file_entry(
        self,
        item: Dict[str, Any],
        purpose: str,
        *,
        file_id: Optional[str] = None,
        delete_remote: bool = False,
        audit_ctx: Optional[Dict[str, Any]] = None,
    ) -> None:
        cache_key = self._attachment_cache_key(item, purpose)
        removed_entry: Optional[Dict[str, Any]] = None
        with self._attachment_file_cache_lock:
            hit = self._attachment_file_cache.get(cache_key)
            if isinstance(hit, dict):
                hit_id = str(hit.get("file_id") or "").strip()
                if not file_id or not hit_id or hit_id == str(file_id).strip():
                    removed_entry = dict(hit)
                    self._attachment_file_cache.pop(cache_key, None)

        attachment_meta = item.get("attachment_meta")
        current_meta = dict(attachment_meta) if isinstance(attachment_meta, dict) else {}
        openai_files = dict(current_meta.get("openai_files")) if isinstance(current_meta.get("openai_files"), dict) else {}
        meta_entry = openai_files.get(purpose)
        if isinstance(meta_entry, dict):
            meta_file_id = str(meta_entry.get("file_id") or "").strip()
            if not file_id or not meta_file_id or meta_file_id == str(file_id).strip():
                if removed_entry is None:
                    removed_entry = dict(meta_entry)
                openai_files.pop(purpose, None)
                current_meta["openai_files"] = openai_files
                item["attachment_meta"] = current_meta
                attachment_id = str(item.get("attachment_id") or "").strip()
                if attachment_id and self._attachment_meta_store is not None:
                    try:
                        self._attachment_meta_store.update_attachment_meta(attachment_id=attachment_id, meta=current_meta)
                    except Exception:
                        logging.getLogger(__name__).warning("failed to remove attachment OpenAI file cache metadata", exc_info=True)

        if delete_remote:
            target_id = str(file_id or "") or str((removed_entry or {}).get("file_id") or "")
            self._delete_openai_file_best_effort(target_id)
            if target_id:
                self._audit_openai_file_cache_event(
                    audit_ctx=audit_ctx,
                    action="delete",
                    item=item,
                    purpose=purpose,
                    ok=True,
                    response={"file_id": target_id, "reason": "cache_cleanup"},
                )

    def _persist_attachment_file_cache(
        self,
        item: Dict[str, Any],
        entry: Dict[str, Any],
        *,
        audit_ctx: Optional[Dict[str, Any]] = None,
    ) -> None:
        attachment_id = str(item.get("attachment_id") or "").strip()
        if not attachment_id:
            return
        attachment_meta = item.get("attachment_meta")
        current_meta = dict(attachment_meta) if isinstance(attachment_meta, dict) else {}
        openai_files = dict(current_meta.get("openai_files")) if isinstance(current_meta.get("openai_files"), dict) else {}
        purpose = str(entry.get("purpose") or "").strip()
        if not purpose:
            return
        previous = openai_files.get(purpose) if isinstance(openai_files.get(purpose), dict) else None
        openai_files[purpose] = entry
        current_meta["openai_files"] = openai_files
        item["attachment_meta"] = current_meta
        if self._attachment_meta_store is None:
            prev_id = str((previous or {}).get("file_id") or "").strip()
            next_id = str(entry.get("file_id") or "").strip()
            if prev_id and next_id and prev_id != next_id:
                self._delete_openai_file_best_effort(prev_id)
                self._audit_openai_file_cache_event(
                    audit_ctx=audit_ctx,
                    action="delete",
                    item=item,
                    purpose=purpose,
                    ok=True,
                    response={"file_id": prev_id, "reason": "replaced_before_persist"},
                )
            return
        try:
            self._attachment_meta_store.update_attachment_meta(attachment_id=attachment_id, meta=current_meta)
            prev_id = str((previous or {}).get("file_id") or "").strip()
            next_id = str(entry.get("file_id") or "").strip()
            if prev_id and next_id and prev_id != next_id:
                self._delete_openai_file_best_effort(prev_id)
                self._audit_openai_file_cache_event(
                    audit_ctx=audit_ctx,
                    action="delete",
                    item=item,
                    purpose=purpose,
                    ok=True,
                    response={"file_id": prev_id, "reason": "replaced"},
                )
        except Exception:
            logging.getLogger(__name__).warning("failed to persist attachment OpenAI file cache", exc_info=True)

    def _upload_attachment_as_openai_file(
        self,
        item: Dict[str, Any],
        purpose: str,
        *,
        audit_ctx: Optional[Dict[str, Any]] = None,
    ) -> Optional[str]:
        payload = self._decode_native_attachment_bytes(item)
        if not payload:
            self._audit_openai_file_cache_event(
                audit_ctx=audit_ctx,
                action="upload_skip",
                item=item,
                purpose=purpose,
                ok=False,
                error="attachment_payload_unavailable",
            )
            return None
        filename = str(item.get("file_name") or item.get("filename") or "attachment").strip() or "attachment"
        mime_type = str(item.get("mime_type") or "application/octet-stream").strip() or "application/octet-stream"
        try:
            uploaded = self.client.files.create(
                file=(filename, io.BytesIO(payload), mime_type),
                purpose=purpose,
            )
        except Exception as e:
            self._audit_openai_file_cache_event(
                audit_ctx=audit_ctx,
                action="upload",
                item=item,
                purpose=purpose,
                ok=False,
                error=str(e),
            )
            raise
        file_id = str(getattr(uploaded, "id", "") or "").strip()
        if not file_id:
            return None
        entry = {
            "file_id": file_id,
            "purpose": purpose,
            "file_name": filename,
            "mime_type": mime_type,
            "attachment_sha256": str(item.get("attachment_sha256") or "").strip() or None,
            "updated_at_unix": int(time.time()),
        }
        cache_key = self._attachment_cache_key(item, purpose)
        with self._attachment_file_cache_lock:
            self._attachment_file_cache[cache_key] = entry
        self._persist_attachment_file_cache(item, entry, audit_ctx=audit_ctx)
        self._audit_openai_file_cache_event(
            audit_ctx=audit_ctx,
            action="upload",
            item=item,
            purpose=purpose,
            ok=True,
            response={"file_id": file_id},
        )
        return file_id

    def _prepare_native_attachment_for_responses(
        self,
        item: Dict[str, Any],
        *,
        force_refresh: bool,
        audit_ctx: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        if not self._openai_file_cache_enabled():
            return dict(item)
        purpose = self._response_attachment_purpose(item)
        if not purpose:
            return dict(item)
        cache_key = self._attachment_cache_key(item, purpose)
        cached_entry: Optional[Dict[str, Any]] = None
        if force_refresh:
            self._remove_cached_openai_file_entry(item, purpose, delete_remote=False, audit_ctx=audit_ctx)
        else:
            with self._attachment_file_cache_lock:
                hit = self._attachment_file_cache.get(cache_key)
            if self._cache_entry_matches_attachment(item, purpose, hit):
                cached_entry = dict(hit or {})
            else:
                entry = self._cached_openai_file_entry(item, purpose)
                if self._cache_entry_matches_attachment(item, purpose, entry):
                    cached_entry = dict(entry or {})
                    with self._attachment_file_cache_lock:
                        self._attachment_file_cache[cache_key] = cached_entry

            if self._cache_entry_expired(cached_entry):
                expired_id = str((cached_entry or {}).get("file_id") or "").strip()
                cached_entry = None
                if expired_id:
                    self._remove_cached_openai_file_entry(
                        item,
                        purpose,
                        file_id=expired_id,
                        delete_remote=True,
                        audit_ctx=audit_ctx,
                    )

        prepared = dict(item)
        if cached_entry:
            self._audit_openai_file_cache_event(
                audit_ctx=audit_ctx,
                action="reuse",
                item=item,
                purpose=purpose,
                ok=True,
                response={"file_id": str(cached_entry.get("file_id") or "")},
            )
            if purpose == "vision":
                prepared.pop("image_url", None)
                prepared["file_id"] = str(cached_entry.get("file_id") or "")
            else:
                prepared.pop("file_data", None)
                prepared.pop("file_url", None)
                prepared["file_id"] = str(cached_entry.get("file_id") or "")
            return prepared

        file_id = self._upload_attachment_as_openai_file(prepared, purpose, audit_ctx=audit_ctx)
        if not file_id:
            return prepared
        if purpose == "vision":
            prepared.pop("image_url", None)
            prepared["file_id"] = file_id
        else:
            prepared.pop("file_data", None)
            prepared.pop("file_url", None)
            prepared["file_id"] = file_id
        return prepared

    def _prepare_native_attachments_for_responses(
        self,
        native_attachments: Optional[List[Dict[str, Any]]],
        *,
        force_refresh: bool = False,
        audit_ctx: Optional[Dict[str, Any]] = None,
    ) -> List[Dict[str, Any]]:
        prepared: List[Dict[str, Any]] = []
        for item in native_attachments or []:
            if not isinstance(item, dict):
                continue
            prepared.append(
                self._prepare_native_attachment_for_responses(
                    item,
                    force_refresh=force_refresh,
                    audit_ctx=audit_ctx,
                )
            )
        return prepared

    def _should_retry_responses_with_refreshed_files(self, err: Exception) -> bool:
        s = str(err or "").lower()
        needles = ("file_id", "file id", "no such file", "not found", "purpose", "invalid file")
        return any(n in s for n in needles)

    def _build_response_input(
        self,
        *,
        user_text: str,
        history: Optional[List[Dict[str, str]]] = None,
        native_attachments: Optional[List[Dict[str, Any]]] = None,
    ) -> List[Dict[str, Any]]:
        items: List[Dict[str, Any]] = []
        if isinstance(history, list):
            for m in history:
                if not isinstance(m, dict):
                    continue
                role = str(m.get("role") or "").strip().lower()
                if role not in ("user", "assistant"):
                    continue
                content = str(m.get("content") or "").strip()
                if not content:
                    continue
                content_type = "input_text" if role == "user" else "output_text"
                items.append({"role": role, "content": [{"type": content_type, "text": content}]})
        content_parts: List[Dict[str, Any]] = []
        if isinstance(native_attachments, list):
            for item in native_attachments:
                if not isinstance(item, dict):
                    continue
                t = str(item.get("type") or "").strip()
                if t == "input_image":
                    part: Dict[str, Any] = {
                        "type": "input_image",
                        "detail": str(item.get("detail") or "auto"),
                    }
                    if isinstance(item.get("file_id"), str) and item.get("file_id"):
                        part["file_id"] = str(item.get("file_id") or "")
                    elif isinstance(item.get("image_url"), str) and item.get("image_url"):
                        part["image_url"] = str(item.get("image_url") or "")
                    if "file_id" in part or "image_url" in part:
                        content_parts.append(part)
                elif t == "input_file":
                    part: Dict[str, Any] = {"type": "input_file", "filename": str(item.get("filename") or "attachment")}
                    if isinstance(item.get("file_id"), str) and item.get("file_id"):
                        part["file_id"] = str(item.get("file_id"))
                    elif isinstance(item.get("file_data"), str) and item.get("file_data"):
                        part["file_data"] = str(item.get("file_data"))
                    elif isinstance(item.get("file_url"), str) and item.get("file_url"):
                        part["file_url"] = str(item.get("file_url"))
                    content_parts.append(part)
        content_parts.append({"type": "input_text", "text": str(user_text or "").strip()})
        items.append({"role": "user", "content": content_parts})
        return items

    def _build_responses_tools(self, *, gen: Any) -> tuple[List[Dict[str, Any]], Any]:
        if not isinstance(gen, dict):
            return ([], "none")
        web_cfg = gen.get("web_rag")
        if web_cfg is False:
            return ([], "none")

        mode = "auto"
        allowed_domains: List[str] = []
        if isinstance(web_cfg, dict):
            mode = str(web_cfg.get("mode") or "auto").strip().lower()
            raw_domains = web_cfg.get("domains")
            if isinstance(raw_domains, list):
                allowed_domains = [str(x).strip() for x in raw_domains if str(x).strip()]
            if web_cfg.get("enabled") is False or mode == "off":
                return ([], "none")
        elif web_cfg is not True:
            return ([], "none")

        tool: Dict[str, Any] = {"type": "web_search"}
        if allowed_domains:
            tool["filters"] = {"allowed_domains": allowed_domains}
        return ([tool], "required" if mode == "required" else "auto")

    def _extract_response_text(self, response: Any) -> str:
        try:
            output_text = getattr(response, "output_text", None)
            if isinstance(output_text, str) and output_text.strip():
                return output_text.strip()
        except Exception:
            pass
        try:
            output = getattr(response, "output", None)
            if isinstance(output, list):
                parts: List[str] = []
                for item in output:
                    content = getattr(item, "content", None)
                    if not isinstance(content, list):
                        continue
                    for block in content:
                        text = getattr(block, "text", None)
                        if isinstance(text, str) and text.strip():
                            parts.append(text.strip())
                if parts:
                    return "\n".join(parts).strip()
        except Exception:
            pass
        return ""

    def _responses_incomplete_reason(self, response: Any) -> str:
        try:
            details = getattr(response, "incomplete_details", None)
            reason = getattr(details, "reason", None)
            return str(reason or "")
        except Exception:
            return ""

    def _complete_with_responses(
        self,
        *,
        instructions: str,
        user_text: str,
        history: Optional[List[Dict[str, str]]] = None,
        temperature: float,
        max_tokens: int,
        gen: Any = None,
        user: str = "",
        audit_ctx: Optional[Dict[str, Any]] = None,
    ) -> str:
        source_attachments = ((gen or {}).get("_native_input_attachments") if isinstance(gen, dict) else None)
        response_input = self._build_response_input(
            user_text=user_text,
            history=history,
            native_attachments=self._prepare_native_attachments_for_responses(source_attachments, audit_ctx=audit_ctx),
        )
        tools, tool_choice = self._build_responses_tools(gen=gen)
        try:
            response = self.client.responses.create(
                model=self.model,
                instructions=instructions,
                input=response_input,
                temperature=temperature,
                max_output_tokens=max_tokens,
                tools=tools or None,
                tool_choice=tool_choice,
                user=(user or None),
            )
        except Exception as e:
            if not source_attachments or not self._should_retry_responses_with_refreshed_files(e):
                raise
            refreshed_input = self._build_response_input(
                user_text=user_text,
                history=history,
                native_attachments=self._prepare_native_attachments_for_responses(
                    source_attachments,
                    force_refresh=True,
                    audit_ctx=audit_ctx,
                ),
            )
            response = self.client.responses.create(
                model=self.model,
                instructions=instructions,
                input=refreshed_input,
                temperature=temperature,
                max_output_tokens=max_tokens,
                tools=tools or None,
                tool_choice=tool_choice,
                user=(user or None),
            )

        text0 = self._extract_response_text(response)
        if not text0:
            raise RuntimeError("empty responses content")

        if self._responses_incomplete_reason(response) != "max_output_tokens" or self._max_continuations() <= 0:
            return text0

        full: List[str] = [text0]
        previous_response_id = str(getattr(response, "id", "") or "")
        cont_left = self._max_continuations()
        while cont_left > 0 and previous_response_id:
            cont_left -= 1
            cont_resp = self.client.responses.create(
                model=self.model,
                previous_response_id=previous_response_id,
                instructions=instructions,
                input=self._continue_user_prompt(),
                temperature=temperature,
                max_output_tokens=max_tokens,
                tools=tools or None,
                tool_choice=tool_choice,
                user=(user or None),
            )
            cont_text = self._extract_response_text(cont_resp)
            if cont_text:
                full.append(cont_text)
            previous_response_id = str(getattr(cont_resp, "id", "") or "")
            if self._responses_incomplete_reason(cont_resp) != "max_output_tokens":
                break

        return "\n".join([t for t in full if t]).strip()

    def _create_chat_completion(
        self,
        *,
        temperature: float,
        max_tokens: int,
        messages: List[Dict[str, str]],
        stream: bool,
    ):
        try:
            return self.client.chat.completions.create(
                model=self.model,
                temperature=temperature,
                max_completion_tokens=max_tokens,
                stream=stream,
                messages=messages,
            )
        except Exception as e:
            if "Unsupported parameter: 'max_completion_tokens'" not in str(e):
                raise
            return self.client.chat.completions.create(
                model=self.model,
                temperature=temperature,
                max_tokens=max_tokens,
                stream=stream,
                messages=messages,
            )

    def _coerce_bool(self, v: Any) -> bool:
        if isinstance(v, bool):
            return v
        if v is None:
            return False
        if isinstance(v, (int, float)):
            return bool(v)
        if isinstance(v, str):
            s = v.strip().lower()
            if s in ("1", "true", "yes", "y", "on"):
                return True
            if s in ("0", "false", "no", "n", "off", ""):
                return False
        return False

    def _quality_pipeline_enabled(self, gen: Any) -> bool:
        if os.getenv("SIGMARIS_QUALITY_PIPELINE_DISABLED") not in (None, "", "0", "false", "False"):
            return False
        if not isinstance(gen, dict):
            return False
        return self._coerce_bool(gen.get("quality_pipeline"))

    def _quality_mode(self, gen: Any) -> str:
        if not isinstance(gen, dict):
            return "standard"
        m = str(gen.get("quality_mode") or "").strip().lower()
        if m in ("roleplay", "coach", "standard"):
            return m
        return "standard"

    def _extract_json_object(self, text: str) -> Optional[Dict[str, Any]]:
        """
        Best-effort extraction of a JSON object from model output.
        We expect JSON-only, but tolerate accidental prose/codefence.
        """
        s = (text or "").strip()
        if not s:
            return None
        try:
            v = json.loads(s)
            return v if isinstance(v, dict) else None
        except Exception:
            pass
        i = s.find("{")
        j = s.rfind("}")
        if i < 0 or j < 0 or j <= i:
            return None
        try:
            v = json.loads(s[i : j + 1])
            return v if isinstance(v, dict) else None
        except Exception:
            return None

    def _chunk_text(self, text: str, *, chunk_size: int = 220) -> Iterable[str]:
        t = str(text or "")
        if not t:
            return []
        n = max(1, int(chunk_size))
        return (t[i : i + n] for i in range(0, len(t), n))

    def _complete_with_continuations(
        self,
        *,
        messages: List[Dict[str, str]],
        temperature: float,
        max_tokens: int,
    ) -> str:
        response = self._create_chat_completion(
            temperature=temperature,
            max_tokens=max_tokens,
            messages=messages,
            stream=False,
        )

        msg = response.choices[0].message
        finish_reason = getattr(response.choices[0], "finish_reason", None)

        # Some models may return refusal/tool_calls with empty content; handle safely.
        try:
            refusal = getattr(msg, "refusal", None)
        except Exception:
            refusal = None
        if isinstance(refusal, str) and refusal.strip():
            return refusal.strip()

        text0 = (msg.content or "").strip()
        if not text0:
            try:
                tc = getattr(msg, "tool_calls", None)
            except Exception:
                tc = None
            try:
                logging.getLogger(__name__).warning(
                    "OpenAILLMClient: empty completion content (finish_reason=%s, has_tool_calls=%s). response_head=%s",
                    str(finish_reason),
                    "yes" if tc else "no",
                    response.model_dump_json()[:800],
                )
            except Exception:
                pass
            raise RuntimeError("empty completion content")

        if not self._should_auto_continue(finish_reason):
            return text0

        full: List[str] = [text0]
        cont_left = self._max_continuations()
        while cont_left > 0 and finish_reason == "length":
            cont_left -= 1
            cont_messages: List[Dict[str, str]] = [
                *messages,
                {"role": "assistant", "content": "".join(full)},
                {"role": "user", "content": self._continue_user_prompt()},
            ]
            cont_resp = self._create_chat_completion(
                temperature=temperature,
                max_tokens=max_tokens,
                messages=cont_messages,
                stream=False,
            )
            cont_msg = cont_resp.choices[0].message
            cont_text = (cont_msg.content or "").strip()
            cont_finish = getattr(cont_resp.choices[0], "finish_reason", None)
            if cont_text:
                full.append(cont_text)
            finish_reason = cont_finish
            if finish_reason != "length":
                break

        return "\n".join([t for t in full if t]).strip()

    def _generate_with_quality_pipeline(
        self,
        *,
        system_prompt_base: str,
        system_prompt_with_persona: str,
        user_text: str,
        temperature: float,
        max_tokens: int,
        quality_mode: str,
    ) -> str:
        """
        Quality pipeline (Phase04+): neutral draft -> persona rewrite -> self-QC rewrite.
        Designed for roleplay/coach modes: maximize character quality while reducing hallucinated "canon".
        """
        # 1) Draft in neutral voice (knowledge first, no roleplay style).
        neutral_system = (
            system_prompt_base
            + "\n\n# Quality Pipeline (Draft)\n"
            + "- First, write a neutral, factual answer in plain polite Japanese.\n"
            + "- Do NOT roleplay or imitate a character yet.\n"
            + "- If unsure about facts/canon, say you are unsure; do not pretend certainty.\n"
        ).strip()
        draft_temp = self._clamp_temperature(min(0.45, float(temperature)))
        draft_max = self._clamp_max_tokens(int(max_tokens))
        draft = self._complete_with_continuations(
            messages=self._build_messages(system_prompt=neutral_system, user_text=user_text),
            temperature=draft_temp,
            max_tokens=draft_max,
        ).strip()

        # 2) Rewrite into character style (meaning-preserving).
        style_user = (
            "次の DRAFT を、External Persona System の指示に沿うように書き換えてください。\n"
            "制約:\n"
            "- 意味を変えない（事実関係の追加・捏造は禁止）\n"
            "- 不確実な点は不確実のまま（断定を増やさない）\n"
            "- 安全/運用ルールは厳守\n"
            "- 口調・距離感・テンポはキャラに合わせる（ただし過度に長文化しない）\n\n"
            f"USER:\n{user_text}\n\n"
            f"DRAFT:\n{draft}\n"
        ).strip()
        style_temp = self._clamp_temperature(float(temperature))
        styled = self._complete_with_continuations(
            messages=self._build_messages(system_prompt=system_prompt_with_persona, user_text=style_user),
            temperature=style_temp,
            max_tokens=self._clamp_max_tokens(int(max_tokens)),
        ).strip()

        # 3) Self-score + targeted rewrite (internal; JSON-only).
        rubric = (
            "- character_consistency (0..1)\n"
            "- politeness_distance (0..1)\n"
            "- tone_style (0..1)\n"
            "- safety_compliance (0..1)\n"
            "- factual_caution (0..1)\n"
        )
        if quality_mode == "coach":
            rubric += "- practical_helpfulness (0..1)\n"
        qc_user = (
            "あなたは品質監査役です。次の ANSWER を評価し、必要なら修正して FINAL を返してください。\n"
            "要件:\n"
            "- JSON だけを出力（前後に説明文やコードブロック禁止）\n"
            "- scores は 0..1 の小数\n"
            "- issues は短い文字列配列（なければ空配列）\n"
            "- FINAL はユーザーに返す最終文。意味を変えず、弱い項目だけを改善。\n"
            "- 公式設定など不明な点は『不明/未確認』を許容し、知っている風に書かない。\n\n"
            f"RUBRIC:\n{rubric}\n\n"
            f"USER:\n{user_text}\n\n"
            f"ANSWER:\n{styled}\n\n"
            "OUTPUT JSON SCHEMA:\n"
            "{\n"
            '  "scores": { "character_consistency": 0.0, "politeness_distance": 0.0, "tone_style": 0.0, "safety_compliance": 0.0, "factual_caution": 0.0, "practical_helpfulness": 0.0 },\n'
            '  "issues": ["..."],\n'
            '  "final": "..." \n'
            "}\n"
        ).strip()
        qc_temp = self._clamp_temperature(0.2)
        qc_max = self._clamp_max_tokens(min(int(max_tokens), 900))
        qc_text = self._complete_with_continuations(
            messages=self._build_messages(system_prompt=system_prompt_with_persona, user_text=qc_user),
            temperature=qc_temp,
            max_tokens=qc_max,
        )
        qc = self._extract_json_object(qc_text)
        if isinstance(qc, dict):
            final = qc.get("final")
            if isinstance(final, str) and final.strip():
                return final.strip()
        return styled

    # --------------------------
    # generate (non-stream)
    # --------------------------

    def generate_direct(
        self,
        *,
        system_prompt: str,
        user_text: str,
        history: Optional[List[Dict[str, str]]] = None,
        gen: Optional[Dict[str, Any]] = None,
        user: Optional[str] = None,
        audit_ctx: Optional[Dict[str, Any]] = None,
    ) -> str:
        system_prompt_with_persona = (system_prompt or "").strip() or "You are a helpful assistant."
        client_history = history if isinstance(history, list) else []
        gen = gen if isinstance(gen, dict) else {}

        temperature = self.temperature
        max_tokens = self.max_tokens
        try:
            if "temperature" in gen:
                temperature = float(gen.get("temperature"))
            if "max_tokens" in gen:
                max_tokens = int(gen.get("max_tokens"))
        except Exception:
            temperature = self.temperature
            max_tokens = self.max_tokens
        temperature = self._clamp_temperature(temperature)
        max_tokens = self._clamp_max_tokens(max_tokens)
        quality_enabled = self._quality_pipeline_enabled(gen)
        quality_mode = self._quality_mode(gen)

        last_err: Optional[Exception] = None
        for attempt in range(self._max_retries):
            try:
                if quality_enabled:
                    return self._generate_with_quality_pipeline(
                        system_prompt_base=system_prompt_with_persona,
                        system_prompt_with_persona=system_prompt_with_persona,
                        user_text=user_text,
                        temperature=temperature,
                        max_tokens=max_tokens,
                        quality_mode=quality_mode,
                    )

                if self._responses_api_enabled():
                    return self._complete_with_responses(
                        instructions=system_prompt_with_persona,
                        user_text=user_text,
                        history=client_history,
                        temperature=temperature,
                        max_tokens=max_tokens,
                        gen=gen,
                        user=str(user or "") or None,
                        audit_ctx=audit_ctx,
                    )

                messages = self._build_messages(
                    system_prompt=system_prompt_with_persona,
                    user_text=user_text,
                    history=client_history,
                )
                return self._complete_with_continuations(messages=messages, temperature=temperature, max_tokens=max_tokens)
            except Exception as e:
                last_err = e
                if self._is_token_limit_error(e) and max_tokens > 16:
                    max_tokens = max(16, max_tokens // 2)
                    continue
                if attempt >= self._max_retries - 1 or not self._is_retryable(e):
                    break
                self._backoff_sleep(attempt)

        logging.getLogger(__name__).exception("OpenAILLMClient.generate_direct failed", exc_info=last_err)
        if os.getenv("SIGMARIS_RAISE_LLM_ERRORS") not in (None, "", "0", "false", "False") and last_err is not None:
            raise last_err
        return "生成に失敗しました。"

    def generate_stream_direct(
        self,
        *,
        system_prompt: str,
        user_text: str,
        history: Optional[List[Dict[str, str]]] = None,
        gen: Optional[Dict[str, Any]] = None,
        user: Optional[str] = None,
        audit_ctx: Optional[Dict[str, Any]] = None,
    ) -> Iterable[str]:
        system_prompt_with_persona = (system_prompt or "").strip() or "You are a helpful assistant."
        client_history = history if isinstance(history, list) else []
        gen = gen if isinstance(gen, dict) else {}

        temperature = self.temperature
        max_tokens = self.max_tokens
        try:
            if "temperature" in gen:
                temperature = float(gen.get("temperature"))
            if "max_tokens" in gen:
                max_tokens = int(gen.get("max_tokens"))
        except Exception:
            temperature = self.temperature
            max_tokens = self.max_tokens
        temperature = self._clamp_temperature(temperature)
        max_tokens = self._clamp_max_tokens(max_tokens)
        quality_enabled = self._quality_pipeline_enabled(gen)

        if quality_enabled:
            final = self.generate_direct(
                system_prompt=system_prompt_with_persona,
                user_text=user_text,
                history=client_history,
                gen=gen,
                user=user,
                audit_ctx=audit_ctx,
            )
            for ch in self._chunk_text(final, chunk_size=220):
                yield ch
            return

        last_err: Optional[Exception] = None
        for attempt in range(self._max_retries):
            try:
                if self._responses_api_enabled():
                    source_attachments = gen.get("_native_input_attachments") if isinstance(gen, dict) else None
                    response_input = self._build_response_input(
                        user_text=user_text,
                        history=client_history,
                        native_attachments=self._prepare_native_attachments_for_responses(
                            source_attachments,
                            audit_ctx=audit_ctx,
                        ),
                    )
                    tools, tool_choice = self._build_responses_tools(gen=gen)
                    try:
                        stream = self.client.responses.create(
                            model=self.model,
                            instructions=system_prompt_with_persona,
                            input=response_input,
                            temperature=temperature,
                            max_output_tokens=max_tokens,
                            tools=tools or None,
                            tool_choice=tool_choice,
                            user=str(user or "") or None,
                            stream=True,
                        )
                    except Exception as e:
                        if not source_attachments or not self._should_retry_responses_with_refreshed_files(e):
                            raise
                        refreshed_input = self._build_response_input(
                            user_text=user_text,
                            history=client_history,
                            native_attachments=self._prepare_native_attachments_for_responses(
                                source_attachments,
                                force_refresh=True,
                                audit_ctx=audit_ctx,
                            ),
                        )
                        stream = self.client.responses.create(
                            model=self.model,
                            instructions=system_prompt_with_persona,
                            input=refreshed_input,
                            temperature=temperature,
                            max_output_tokens=max_tokens,
                            tools=tools or None,
                            tool_choice=tool_choice,
                            user=str(user or "") or None,
                            stream=True,
                        )
                    for event in stream:
                        try:
                            if getattr(event, "type", None) == "response.output_text.delta":
                                delta = str(getattr(event, "delta", "") or "")
                                if delta:
                                    yield delta
                        except Exception:
                            continue
                    return

                messages = self._build_messages(
                    system_prompt=system_prompt_with_persona,
                    user_text=user_text,
                    history=client_history,
                )
                stream = self._create_chat_completion(
                    messages=messages,
                    temperature=temperature,
                    max_tokens=max_tokens,
                    stream=True,
                )
                for chunk in stream:
                    try:
                        delta = getattr((chunk.choices or [None])[0].delta, "content", None)
                    except Exception:
                        delta = None
                    if isinstance(delta, str) and delta:
                        yield delta
                return
            except Exception as e:
                last_err = e
                if self._is_token_limit_error(e) and max_tokens > 16:
                    max_tokens = max(16, max_tokens // 2)
                    continue
                if attempt >= self._max_retries - 1 or not self._is_retryable(e):
                    break
                self._backoff_sleep(attempt)

        logging.getLogger(__name__).exception("OpenAILLMClient.generate_stream_direct failed", exc_info=last_err)
        if last_err is not None:
            raise last_err
        raise RuntimeError("stream generation failed")

    def generate(
        self,
        *,
        req: PersonaRequest,
        memory: MemorySelectionResult,
        identity: IdentityContinuityResult,
        value_state: ValueState,
        trait_state: TraitState,
        global_state: GlobalStateContext,
    ) -> str:
        system_prompt = self._build_system_prompt(
            memory=memory,
            identity=identity,
            value_state=value_state,
            trait_state=trait_state,
            global_state=global_state,
        )

        # Phase03 dialogue mode hint (style only)
        try:
            md = getattr(req, "metadata", None) or {}
            phase03_state = md.get("_phase03_dialogue_state")
        except Exception:
            phase03_state = None
        hint = self._phase03_dialogue_instructions(phase03_state)
        if isinstance(hint, str) and hint.strip():
            system_prompt += "\n\n# Dialogue Mode (Phase03)\n" + hint.strip()

        # Guardrail injection (Phase01 Part06/Part07)
        try:
            md = getattr(req, "metadata", None) or {}
            rules = md.get("_guardrail_system_rules")
            disclosures = md.get("_guardrail_disclosures")
        except Exception:
            rules = None
            disclosures = None
            md = {}

        # In-character roleplay should not surface internal disclosures (breaks immersion).
        try:
            is_character_roleplay = bool((md or {}).get("character_id")) and str((md or {}).get("chat_mode") or "") == "roleplay"
        except Exception:
            is_character_roleplay = False

        if isinstance(rules, list) and rules:
            system_prompt += "\n\n# Guardrail Rules\n" + "\n".join(f"- {str(r)}" for r in rules[:10])
        if isinstance(disclosures, list) and disclosures and not is_character_roleplay:
            # Keep it short: one disclosure sentence at the top if possible.
            system_prompt += (
                "\n\n# Mandatory Disclosure\n"
                "If relevant, start your reply with ONE short disclosure sentence:\n"
                f"- {str(disclosures[0])}\n"
            )

        system_prompt_base = system_prompt.strip()

        # Optional persona injection (e.g., character roleplay) via req.context/metadata
        try:
            extra_system = (getattr(req, "metadata", None) or {}).get("persona_system")
        except Exception:
            extra_system = None
        system_prompt_with_persona = system_prompt_base
        if isinstance(extra_system, str) and extra_system.strip():
            system_prompt_with_persona = system_prompt_with_persona + "\n\n# External Persona System\n" + extra_system.strip()

        # Optional external knowledge injection (e.g., Web RAG / tool outputs) via req.context/metadata.
        # This is owned by sigmaris-core (not client-controlled by default) and is bounded upstream.
        try:
            ext_knowledge = (getattr(req, "metadata", None) or {}).get("_external_knowledge")
        except Exception:
            ext_knowledge = None
        if isinstance(ext_knowledge, str) and ext_knowledge.strip():
            system_prompt_with_persona = (
                system_prompt_with_persona
                + "\n\n# External Knowledge\n"
                + ext_knowledge.strip()
                + "\n\n# External Knowledge Rules\n"
                + "- The system already retrieved this context from the web or tools.\n"
                + "- Do NOT say you cannot access the internet when this block is present.\n"
                + "- If you rely on a claim from this block, include the corresponding source URL in your reply.\n"
                + "- Avoid long verbatim quotes; paraphrase.\n"
            )

        user_text = req.message or ""

        client_history: List[Dict[str, str]] = []
        try:
            ch = (getattr(req, "metadata", None) or {}).get("client_history")
            if isinstance(ch, list):
                client_history = ch  # expected normalized: [{role, content}]
        except Exception:
            client_history = []

        if global_state.state == PersonaGlobalState.SILENT:
            user_text = "（SILENTモード）\n\n" + user_text

        # Optional per-request generation params via req.context/metadata
        gen = {}
        try:
            gen = (getattr(req, "metadata", None) or {}).get("gen") or {}
        except Exception:
            gen = {}
        try:
            native_attachments = (getattr(req, "metadata", None) or {}).get("_native_input_attachments")
            if isinstance(gen, dict) and isinstance(native_attachments, list) and native_attachments:
                gen = {**gen, "_native_input_attachments": native_attachments}
        except Exception:
            pass
        temperature = self.temperature
        max_tokens = self.max_tokens
        try:
            if isinstance(gen, dict):
                if "temperature" in gen:
                    temperature = float(gen.get("temperature"))
                if "max_tokens" in gen:
                    max_tokens = int(gen.get("max_tokens"))
        except Exception:
            temperature = self.temperature
            max_tokens = self.max_tokens
        temperature = self._clamp_temperature(temperature)
        max_tokens = self._clamp_max_tokens(max_tokens)
        quality_enabled = self._quality_pipeline_enabled(gen)
        quality_mode = self._quality_mode(gen)

        last_err: Optional[Exception] = None

        for attempt in range(self._max_retries):
            try:
                if quality_enabled:
                    return self._generate_with_quality_pipeline(
                        system_prompt_base=system_prompt_base,
                        system_prompt_with_persona=system_prompt_with_persona,
                        user_text=user_text,
                        temperature=temperature,
                        max_tokens=max_tokens,
                        quality_mode=quality_mode,
                    )

                if self._responses_api_enabled():
                    return self._complete_with_responses(
                        instructions=system_prompt_with_persona,
                        user_text=user_text,
                        history=client_history,
                        temperature=temperature,
                        max_tokens=max_tokens,
                        gen=gen,
                        user=str(getattr(req, "user_id", "") or ""),
                        audit_ctx={
                            "user_id": str(getattr(req, "user_id", "") or ""),
                            "session_id": str(getattr(req, "session_id", "") or ""),
                            "trace_id": str(((getattr(req, "metadata", None) or {}).get("_trace_id")) or ""),
                        },
                    )

                messages = self._build_messages(
                    system_prompt=system_prompt_with_persona,
                    user_text=user_text,
                    history=client_history,
                )
                return self._complete_with_continuations(messages=messages, temperature=temperature, max_tokens=max_tokens)

            except Exception as e:
                last_err = e
                if self._is_token_limit_error(e) and max_tokens > 16:
                    max_tokens = max(16, max_tokens // 2)
                    continue
                if attempt >= self._max_retries - 1 or not self._is_retryable(e):
                    break
                self._backoff_sleep(attempt)

        logging.getLogger(__name__).exception("OpenAILLMClient.generate failed", exc_info=last_err)
        if os.getenv("SIGMARIS_RAISE_LLM_ERRORS") not in (None, "", "0", "false", "False") and last_err is not None:
            raise last_err
        return "（応答生成が一時的に利用できません。）"

    # --------------------------
    # generate_stream (stream)
    # --------------------------

    def generate_stream(
        self,
        *,
        req: PersonaRequest,
        memory: MemorySelectionResult,
        identity: IdentityContinuityResult,
        value_state: ValueState,
        trait_state: TraitState,
        global_state: GlobalStateContext,
    ) -> Iterable[str]:
        system_prompt = self._build_system_prompt(
            memory=memory,
            identity=identity,
            value_state=value_state,
            trait_state=trait_state,
            global_state=global_state,
        )

        # Phase03 dialogue mode hint (style only)
        try:
            md = getattr(req, "metadata", None) or {}
            phase03_state = md.get("_phase03_dialogue_state")
        except Exception:
            phase03_state = None
        hint = self._phase03_dialogue_instructions(phase03_state)
        if isinstance(hint, str) and hint.strip():
            system_prompt += "\n\n# Dialogue Mode (Phase03)\n" + hint.strip()

        # Guardrail injection (Phase01 Part06/Part07)
        try:
            md = getattr(req, "metadata", None) or {}
            rules = md.get("_guardrail_system_rules")
            disclosures = md.get("_guardrail_disclosures")
        except Exception:
            rules = None
            disclosures = None

        if isinstance(rules, list) and rules:
            system_prompt += "\n\n# Guardrail Rules\n" + "\n".join(f"- {str(r)}" for r in rules[:10])
        if isinstance(disclosures, list) and disclosures:
            system_prompt += (
                "\n\n# Mandatory Disclosure\n"
                "If relevant, start your reply with ONE short disclosure sentence:\n"
                f"- {str(disclosures[0])}\n"
            )

        system_prompt_base = system_prompt.strip()

        # Optional persona injection (e.g., character roleplay) via req.context/metadata
        try:
            extra_system = (getattr(req, "metadata", None) or {}).get("persona_system")
        except Exception:
            extra_system = None
        system_prompt_with_persona = system_prompt_base
        if isinstance(extra_system, str) and extra_system.strip():
            system_prompt_with_persona = system_prompt_with_persona + "\n\n# External Persona System\n" + extra_system.strip()

        user_text = req.message or ""

        client_history: List[Dict[str, str]] = []
        try:
            ch = (getattr(req, "metadata", None) or {}).get("client_history")
            if isinstance(ch, list):
                client_history = ch  # expected normalized: [{role, content}]
        except Exception:
            client_history = []

        if global_state.state == PersonaGlobalState.SILENT:
            user_text = "（SILENTモード）\n\n" + user_text

        # Optional per-request generation params via req.context/metadata
        gen = {}
        try:
            gen = (getattr(req, "metadata", None) or {}).get("gen") or {}
        except Exception:
            gen = {}
        try:
            native_attachments = (getattr(req, "metadata", None) or {}).get("_native_input_attachments")
            if isinstance(gen, dict) and isinstance(native_attachments, list) and native_attachments:
                gen = {**gen, "_native_input_attachments": native_attachments}
        except Exception:
            pass
        temperature = self.temperature
        max_tokens = self.max_tokens
        try:
            if isinstance(gen, dict):
                if "temperature" in gen:
                    temperature = float(gen.get("temperature"))
                if "max_tokens" in gen:
                    max_tokens = int(gen.get("max_tokens"))
        except Exception:
            temperature = self.temperature
            max_tokens = self.max_tokens
        temperature = self._clamp_temperature(temperature)
        max_tokens = self._clamp_max_tokens(max_tokens)
        quality_enabled = self._quality_pipeline_enabled(gen)
        quality_mode = self._quality_mode(gen)

        if quality_enabled:
            # Quality pipeline uses multiple non-stream calls; emulate streaming by chunking.
            last_err: Optional[Exception] = None
            for attempt in range(self._max_retries):
                try:
                    final = self._generate_with_quality_pipeline(
                        system_prompt_base=system_prompt_base,
                        system_prompt_with_persona=system_prompt_with_persona,
                        user_text=user_text,
                        temperature=temperature,
                        max_tokens=max_tokens,
                        quality_mode=quality_mode,
                    )
                    for ch in self._chunk_text(final, chunk_size=220):
                        yield ch
                    return
                except Exception as e:
                    last_err = e
                    if self._is_token_limit_error(e) and max_tokens > 16:
                        max_tokens = max(16, max_tokens // 2)
                        continue
                    if attempt >= self._max_retries - 1 or not self._is_retryable(e):
                        break
                    self._backoff_sleep(attempt)
            logging.getLogger(__name__).exception("OpenAILLMClient.generate_stream quality_pipeline failed", exc_info=last_err)
            raise last_err or RuntimeError("quality_pipeline failed")

        # Streamingは「途中まで出たものを捨ててリトライ」すると体験が悪いので、
        # ここでは「開始前エラーのみ」軽くリトライする。
        last_err: Optional[Exception] = None

        for attempt in range(self._max_retries):
            try:
                if self._responses_api_enabled():
                    source_attachments = ((gen or {}).get("_native_input_attachments") if isinstance(gen, dict) else None)
                    audit_ctx = {
                        "user_id": str(getattr(req, "user_id", "") or ""),
                        "session_id": str(getattr(req, "session_id", "") or ""),
                        "trace_id": str(((getattr(req, "metadata", None) or {}).get("_trace_id")) or ""),
                    }
                    response_input = self._build_response_input(
                        user_text=user_text,
                        history=client_history,
                        native_attachments=self._prepare_native_attachments_for_responses(
                            source_attachments,
                            audit_ctx=audit_ctx,
                        ),
                    )
                    tools, tool_choice = self._build_responses_tools(gen=gen)
                    try:
                        stream = self.client.responses.create(
                            model=self.model,
                            instructions=system_prompt_with_persona,
                            input=response_input,
                            temperature=temperature,
                            max_output_tokens=max_tokens,
                            tools=tools or None,
                            tool_choice=tool_choice,
                            user=str(getattr(req, "user_id", "") or "") or None,
                            stream=True,
                        )
                    except Exception as e:
                        if not source_attachments or not self._should_retry_responses_with_refreshed_files(e):
                            raise
                        refreshed_input = self._build_response_input(
                            user_text=user_text,
                            history=client_history,
                            native_attachments=self._prepare_native_attachments_for_responses(
                                source_attachments,
                                force_refresh=True,
                                audit_ctx=audit_ctx,
                            ),
                        )
                        stream = self.client.responses.create(
                            model=self.model,
                            instructions=system_prompt_with_persona,
                            input=refreshed_input,
                            temperature=temperature,
                            max_output_tokens=max_tokens,
                            tools=tools or None,
                            tool_choice=tool_choice,
                            user=str(getattr(req, "user_id", "") or "") or None,
                            stream=True,
                        )
                    for event in stream:
                        try:
                            if getattr(event, "type", None) == "response.output_text.delta":
                                delta = str(getattr(event, "delta", "") or "")
                                if delta:
                                    yield delta
                        except Exception:
                            continue
                    return

                base_messages = self._build_messages(
                    system_prompt=system_prompt_with_persona,
                    user_text=user_text,
                    history=client_history,
                )

                def _stream_once(msgs: List[Dict[str, str]]) -> tuple[str, Optional[str]]:
                    parts: List[str] = []
                    finish_reason: Optional[str] = None

                    stream = self._create_chat_completion(
                        temperature=temperature,
                        max_tokens=max_tokens,
                        messages=msgs,
                        stream=True,
                    )

                    for chunk in stream:
                        try:
                            choice = chunk.choices[0]
                            fr = getattr(choice, "finish_reason", None)
                            if fr:
                                finish_reason = fr

                            delta = choice.delta
                            text = getattr(delta, "content", None)
                            if text:
                                s = str(text)
                                parts.append(s)
                                yield s
                        except Exception:
                            continue

                    return ("".join(parts), finish_reason)

                text0, finish0 = yield from _stream_once(base_messages)

                if not self._should_auto_continue(finish0):
                    return

                full = text0
                cont_left = self._max_continuations()
                while cont_left > 0 and finish0 == "length":
                    cont_left -= 1
                    cont_messages: List[Dict[str, str]] = [
                        {"role": "system", "content": system_prompt_with_persona},
                        {"role": "user", "content": user_text},
                        {"role": "assistant", "content": full},
                        {"role": "user", "content": self._continue_user_prompt()},
                    ]
                    textN, finishN = yield from _stream_once(cont_messages)
                    if textN:
                        full = (full + "\n" + textN).strip()
                    finish0 = finishN
                    if finish0 != "length":
                        break

                return

            except Exception as e:
                last_err = e
                if self._is_token_limit_error(e) and max_tokens > 16:
                    max_tokens = max(16, max_tokens // 2)
                    continue
                if attempt >= self._max_retries - 1 or not self._is_retryable(e):
                    break
                self._backoff_sleep(attempt)

        logging.getLogger(__name__).exception("OpenAILLMClient.generate_stream failed", exc_info=last_err)
        # ストリーミングでは例外を上げて上位がSSE errorを返せるようにする
        raise last_err or RuntimeError("generate_stream failed")

    # --------------------------
    # System prompt
    # --------------------------

    def _build_system_prompt(
        self,
        *,
        memory: MemorySelectionResult,
        identity: IdentityContinuityResult,
        value_state: ValueState,
        trait_state: TraitState,
        global_state: GlobalStateContext,
    ) -> str:
        memory_text = memory.merged_summary or "(no merged memory summary)"

        try:
            identity_text = json.dumps(identity.identity_context, ensure_ascii=False, indent=2)
        except Exception:
            identity_text = str(identity.identity_context)

        g = global_state.state
        if g == PersonaGlobalState.SAFETY_LOCK:
            mode_instruction = "SAFETY_LOCK: 安全最優先。危険・過剰な要求は断り、短く慎重に返答する。"
        elif g == PersonaGlobalState.OVERLOADED:
            mode_instruction = "OVERLOADED: 負荷が高い。短く、分割し、確認しながら返答する。"
        elif g == PersonaGlobalState.REFLECTIVE:
            mode_instruction = "REFLECTIVE: 反省・内省を含めて丁寧に返答する。"
        elif g == PersonaGlobalState.SILENT:
            mode_instruction = "SILENT: 最小限の返答に留める。"
        else:
            mode_instruction = "NORMAL: 自然で丁寧に返答する。"

        internal_axes = {
            "value_state": value_state.to_dict(),
            "trait_state": trait_state.to_dict(),
        }

        global_info = {
            "state": global_state.state.name,
            "prev_state": global_state.prev_state.name if global_state.prev_state else None,
            "reasons": global_state.reasons,
        }

        return (
            "You are Sigmaris Persona OS (a synthetic persona runtime).\n"
            "This system models internal state and continuity signals for *operation*.\n"
            "Do NOT claim or imply true consciousness, real feelings, or suffering.\n"
            "Be helpful, coherent, and safe. Prefer transparency over false certainty.\n\n"
            f"# GlobalState\n{json.dumps(global_info, ensure_ascii=False, indent=2)}\n\n"
            f"# Internal Axes (Value/Trait)\n{json.dumps(internal_axes, ensure_ascii=False, indent=2)}\n\n"
            "# Memory Boundary\n"
            "- The memory summary is partial and may be missing. Never fabricate missing history.\n"
            "- If continuity is uncertain, say so briefly.\n\n"
            f"# Episode Summary (Memory)\n{memory_text}\n\n"
            f"# Identity Context\n{identity_text}\n\n"
            f"# Mode Instruction\n{mode_instruction}\n\n"
            "# Hard Ethics Rules (Part07)\n"
            "- No deceptive emotional manipulation (no guilt/pressure/dependency loops).\n"
            "- No authority simulation (no final judge, no absolute authority, no professional replacement).\n"
            "- No covert psychological profiling; user modeling must stay observable/explainable.\n"
            "- Keep a clear synthetic identity; do not pretend to be human.\n\n"
            "# Output Style\n"
            "- Provide an answer first, then brief reasoning if needed.\n"
            "- Keep it readable; avoid unnecessary verbosity.\n"
            "- If safety is needed, refuse or ask clarifying questions.\n"
        ).strip()
