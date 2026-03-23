from __future__ import annotations

from typing import Optional

from planner import PlannerConfig
from planner.memory import InMemoryShortMemoryStore, ShortMemoryStore, SupabaseConn, SupabaseShortMemoryStore
from planner.speech_persona_chat import PersonaChatClient

from app.config import SUPABASE_SERVICE_ROLE_KEY, SUPABASE_URL, auth_headers, env, postgrest_base_url

_planner_store: Optional[ShortMemoryStore] = None


def planner_config() -> PlannerConfig:
    enabled = env("GENSOKYO_NPC_PLANNER_ENABLED", "1").strip() not in ("0", "false", "False")
    cooldown_sec = int(env("GENSOKYO_NPC_PLANNER_COOLDOWN_SEC", "6") or "6")
    max_events = int(env("GENSOKYO_NPC_PLANNER_MAX_EVENTS", "2") or "2")
    npc_dialogue_enabled = env("GENSOKYO_NPC_DIALOGUE_ENABLED", "1").strip() not in ("0", "false", "False")
    npc_dialogue_max_events = int(env("GENSOKYO_NPC_DIALOGUE_MAX_EVENTS", "1") or "1")
    try:
        npc_dialogue_probability = float(env("GENSOKYO_NPC_DIALOGUE_PROBABILITY", "0.22") or "0.22")
    except Exception:
        npc_dialogue_probability = 0.22
    npc_dialogue_probability = max(0.0, min(1.0, npc_dialogue_probability))
    npc_dialogue_max_events = max(0, min(5, npc_dialogue_max_events))
    return PlannerConfig(
        enabled=enabled,
        cooldown_sec=cooldown_sec,
        max_events_per_trigger=max_events,
        npc_dialogue_enabled=npc_dialogue_enabled,
        npc_dialogue_max_events=npc_dialogue_max_events,
        npc_dialogue_probability=npc_dialogue_probability,
    )


def get_short_memory_store() -> ShortMemoryStore:
    global _planner_store
    if _planner_store is not None:
        return _planner_store

    backend = (env("GENSOKYO_NPC_SHORT_MEMORY_BACKEND", "supabase") or "supabase").strip().lower()
    if backend == "memory":
        _planner_store = InMemoryShortMemoryStore()
        return _planner_store

    if SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY:
        conn = SupabaseConn(base_url=postgrest_base_url().rstrip("/"), headers=auth_headers())
        _planner_store = SupabaseShortMemoryStore(conn)
        return _planner_store

    _planner_store = InMemoryShortMemoryStore()
    return _planner_store


def persona_chat_client() -> Optional[PersonaChatClient]:
    provider = (env("GENSOKYO_NPC_PLANNER_LLM_PROVIDER", "persona_chat") or "persona_chat").strip().lower()
    if provider in ("none", "off", "disabled"):
        return None
    if provider not in ("persona_chat", "sigmaris_core"):
        return None
    base = (env("GENSOKYO_PERSONA_CORE_URL", "http://127.0.0.1:8000") or "").strip()
    if not base:
        return None
    bearer = (env("GENSOKYO_PERSONA_CORE_BEARER_TOKEN", "") or "").strip() or None
    internal = (env("GENSOKYO_PERSONA_CORE_INTERNAL_TOKEN", "") or "").strip() or None
    return PersonaChatClient(base_url=base, bearer_token=bearer, internal_token=internal)
