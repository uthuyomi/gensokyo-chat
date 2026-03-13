from __future__ import annotations

import os
import sys
import json
import hashlib
from pathlib import Path
from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List, Optional, Tuple
import random
import asyncio

import httpx
from fastapi import FastAPI, Header, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

# Allow running via uvicorn from the monorepo root (so `from planner ...` works).
_THIS_DIR = Path(__file__).resolve().parent
if str(_THIS_DIR) not in sys.path:
    sys.path.insert(0, str(_THIS_DIR))

from planner import PlannerConfig, maybe_plan_reactions
from planner.interfaces import NpcSnapshot, PlannerContext, UserSnapshot
from planner.memory import SupabaseConn, SupabaseShortMemoryStore, InMemoryShortMemoryStore, ShortMemoryStore
from planner.speech_persona_chat import PersonaChatClient
from content_loader import (
    load_locations as load_locations_from_content,
    load_events as load_events_from_content,
    load_relationships as load_relationships_from_content,
)

import npc_dialogue_engine
from world_simulator import WorldSimulatorConfig, simulator_loop


def _load_root_dotenv_into_environ() -> None:
    """
    Load the monorepo root `.env` into `os.environ` (best-effort) for local dev.

    - Matches the rest of Project-Sigmaris, where Node tools load the root `.env`.
    - Does NOT overwrite existing env vars (shell/env wins).
    - Intentionally minimal parser (KEY=VALUE, optional quotes, ignores comments).
    """
    try:
        here = Path(__file__).resolve()
        root = here.parent.parent  # gensokyo-world-engine/.. (repo root)
        dotenv = root / ".env"
        if not dotenv.exists() or not dotenv.is_file():
            return

        text = dotenv.read_text(encoding="utf-8", errors="replace")
        for raw_line in text.splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            k, v = line.split("=", 1)
            key = k.strip()
            if not key or key.startswith("#"):
                continue
            if key in os.environ:
                continue
            val = v.strip()
            # Strip inline comments for unquoted values: FOO=bar # comment
            if val and val[0] not in ("'", '"') and " #" in val:
                val = val.split(" #", 1)[0].rstrip()
            if len(val) >= 2 and ((val[0] == val[-1] == '"') or (val[0] == val[-1] == "'")):
                val = val[1:-1]
            os.environ[key] = val
    except Exception:
        return


_load_root_dotenv_into_environ()


def env(name: str, default: str = "") -> str:
    return str(os.environ.get(name, default) or "")


SUPABASE_URL = env("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = env("SUPABASE_SERVICE_ROLE_KEY")
SUPABASE_SCHEMA = env("SUPABASE_SCHEMA", "public")

# Optional shared secret for server-to-server calls (recommended when exposing publicly).
WORLD_ENGINE_SECRET = env("GENSOKYO_WORLD_ENGINE_SECRET", "")


def require_supabase():
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        raise RuntimeError("SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY missing")


def postgrest_base_url() -> str:
    # Supabase PostgREST endpoint
    return SUPABASE_URL.rstrip("/") + "/rest/v1"


def rpc_url(fn: str) -> str:
    return postgrest_base_url().rstrip("/") + f"/rpc/{fn}"


def auth_headers() -> Dict[str, str]:
    return {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
        "Accept": "application/json",
        # schema routing (PostgREST)
        "Accept-Profile": SUPABASE_SCHEMA,
        "Content-Profile": SUPABASE_SCHEMA,
    }

async def fetch_recent_summaries(
    client: httpx.AsyncClient,
    *,
    world_id: str,
    location_id: str,
    limit: int = 6,
) -> str:
    """
    Fetch recent world_event_log summaries to ground NPC-to-NPC dialogue.
    Returns a short single-string context (Japanese).
    Best-effort; returns "" on any failure.
    """
    try:
        n = max(0, min(int(limit or 6), 12))
        if n <= 0:
            return ""
        channel = f"world:{world_id}:{location_id}"
        rows = await postgrest_select(
            client,
            "world_event_log",
            f"?channel=eq.{channel}&order=seq.desc&limit={n}&select=seq,ts,type,actor,payload",
        )
        rows = list(rows or [])
        rows.reverse()
        parts: List[str] = []
        for r in rows:
            if not isinstance(r, dict):
                continue
            payload = r.get("payload") if isinstance(r.get("payload"), dict) else {}
            s = str(payload.get("summary") or "").strip()
            if not s:
                continue
            # avoid flooding with repeats
            if parts and parts[-1] == s:
                continue
            parts.append(s)
        if not parts:
            return ""
        # Keep it short; last few lines only.
        parts = parts[-4:]
        return " / ".join(parts)
    except Exception:
        return ""


def is_uuid_like(value: Optional[str]) -> bool:
    if not value or not isinstance(value, str):
        return False
    s = value.strip()
    if len(s) != 36:
        return False
    parts = s.split("-")
    if len(parts) != 5:
        return False
    lens = [8, 4, 4, 4, 12]
    for p, ln in zip(parts, lens):
        if len(p) != ln:
            return False
        try:
            int(p, 16)
        except Exception:
            return False
    return True


class Actor(BaseModel):
    kind: str = Field(..., description="npc|user|system")
    id: Optional[str] = None


class EmitEventRequest(BaseModel):
    world_id: str
    layer_id: str
    location_id: Optional[str] = None
    type: str
    actor: Optional[Actor] = None
    ts: Optional[str] = None  # ISO8601; if omitted, DB uses now()
    payload: Dict[str, Any] = Field(default_factory=dict)


class CommandRequest(BaseModel):
    world_id: str
    layer_id: str = Field(default="gensokyo")
    user_id: Optional[str] = None
    type: str
    payload: Dict[str, Any] = Field(default_factory=dict)
    dedupe_key: Optional[str] = None
    causation_id: Optional[str] = None


class VisitRequest(BaseModel):
    world_id: str
    layer_id: str = Field(default="gensokyo")
    location_id: str
    sub_location_id: Optional[str] = None
    user_time: Optional[str] = None  # ISO8601 with tz preferred
    visitor_key: Optional[str] = None  # user_id / session_id / arbitrary


class TickRequest(BaseModel):
    world_id: str
    layer_id: str = Field(default="gensokyo")
    location_id: Optional[str] = None
    delta_sec: int = Field(default=0, ge=0)
    reason: Optional[str] = None


class Utf8JSONResponse(JSONResponse):
    # Help Windows PowerShell / some clients decode JSON as UTF-8 consistently.
    media_type = "application/json; charset=utf-8"


app = FastAPI(title="gensokyo-world-engine", version="0.1.0", default_response_class=Utf8JSONResponse)

_worker_task: Optional[asyncio.Task] = None
_sim_task: Optional[asyncio.Task] = None
_planner_store: Optional[ShortMemoryStore] = None


@app.get("/health")
def health():
    return {"ok": True}


@app.on_event("startup")
async def _startup():
    global _worker_task, _sim_task
    # Warm content caches (incl. relationships.json).
    try:
        _ = load_locations()
        _ = load_events()
        _ = load_relationships()
        # Warm npc_dialogue_engine relationship graph cache too.
        try:
            _ = npc_dialogue_engine.relationship_graph()
        except Exception:
            pass
    except Exception:
        pass

    enabled = env("GENSOKYO_COMMAND_WORKER_ENABLED", "1").strip() not in ("0", "false", "False")
    if enabled and not (_worker_task and not _worker_task.done()):
        _worker_task = asyncio.create_task(command_worker_loop(x_world_secret=WORLD_ENGINE_SECRET or None))

    sim_enabled = env("GENSOKYO_WORLD_SIM_ENABLED", "0").strip() not in ("0", "false", "False")
    if sim_enabled and not (_sim_task and not _sim_task.done()):
        cfg = world_simulator_config()
        _sim_task = asyncio.create_task(simulator_loop(cfg=cfg, tick_once=_world_sim_tick_once, on_error=_on_sim_error))


@app.on_event("shutdown")
async def _shutdown():
    global _worker_task, _sim_task
    if _worker_task:
        _worker_task.cancel()
        _worker_task = None
    if _sim_task:
        _sim_task.cancel()
        _sim_task = None


def _on_sim_error(e: Exception) -> None:
    try:
        print("[world.sim] error:", repr(e))
    except Exception:
        pass


def _csv_env(name: str) -> List[str]:
    raw = (env(name, "") or "").strip()
    if not raw:
        return []
    parts = []
    for p in raw.split(","):
        s = p.strip()
        if s:
            parts.append(s)
    return list(dict.fromkeys(parts))


def world_simulator_config() -> WorldSimulatorConfig:
    enabled = env("GENSOKYO_WORLD_SIM_ENABLED", "0").strip() not in ("0", "false", "False")
    interval_sec = int(env("GENSOKYO_WORLD_SIM_INTERVAL_SEC", "30") or "30")
    return WorldSimulatorConfig(enabled=enabled, interval_sec=interval_sec)


async def _fetch_world_ids(client: httpx.AsyncClient) -> List[str]:
    # Prefer explicit env, then DB worlds, then fallback.
    ids = _csv_env("GENSOKYO_WORLD_SIM_WORLDS")
    if ids:
        return ids
    try:
        rows = await postgrest_select(client, "worlds", "?select=id&order=created_at.asc&limit=50")
        out = []
        for r in rows or []:
            if isinstance(r, dict) and isinstance(r.get("id"), str) and r["id"].strip():
                out.append(r["id"].strip())
        if out:
            return out
    except Exception:
        pass
    return ["gensokyo_main"]


def _content_location_ids() -> List[str]:
    data = load_locations()
    out: List[str] = []
    for loc in data.get("locations", []) or []:
        if isinstance(loc, dict) and isinstance(loc.get("id"), str) and loc["id"].strip():
            out.append(loc["id"].strip())
    return out


def _location_neighbors(location_id: str) -> List[str]:
    data = load_locations()
    for loc in data.get("locations", []) or []:
        if not isinstance(loc, dict) or str(loc.get("id") or "") != location_id:
            continue
        neigh = loc.get("neighbors") if isinstance(loc.get("neighbors"), list) else []
        out = [str(x).strip() for x in neigh if isinstance(x, str) and x.strip()]
        return list(dict.fromkeys(out))
    return []


async def _fetch_active_locations(
    client: httpx.AsyncClient,
    *,
    world_id: str,
    now: datetime,
    max_locations: int,
) -> List[str]:
    # Strategy:
    # - env override: GENSOKYO_WORLD_SIM_LOCATIONS
    # - else: locations visited recently by any visitor_key
    # - else: default to the first content location(s)
    override = _csv_env("GENSOKYO_WORLD_SIM_LOCATIONS")
    if override:
        return override[: max(1, int(max_locations or 1))]

    window_sec = int(env("GENSOKYO_WORLD_SIM_ACTIVE_WINDOW_SEC", "600") or "600")
    cutoff = (now - timedelta(seconds=max(1, window_sec))).isoformat()
    try:
        rows = await postgrest_select(
            client,
            "world_visits",
            f"?world_id=eq.{world_id}&last_visit=gt.{cutoff}&select=location_id,last_visit&order=last_visit.desc&limit={int(max_locations)}",
        )
        out: List[str] = []
        for r in rows or []:
            if isinstance(r, dict) and isinstance(r.get("location_id"), str) and r["location_id"].strip():
                out.append(r["location_id"].strip())
        out = list(dict.fromkeys(out))
        if out:
            return out
    except Exception:
        pass

    locs = _content_location_ids()
    if locs:
        return locs[: max(1, int(max_locations or 1))]
    return ["hakurei_shrine"]


async def _world_sim_tick_once(dt: datetime) -> None:
    """
    Autonomous world loop tick.

    Uses /world/visit logic for time-skip event generation, then adds:
    - NPC movement (very lightweight, rule-based)
    - NPC-to-NPC dialogue (BT planner trigger on a synthetic world_tick source event)
    """

    if not (SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY):
        return

    max_locations = int(env("GENSOKYO_WORLD_SIM_MAX_LOCATIONS", "2") or "2")
    max_locations = max(1, min(20, max_locations))
    move_prob = float(env("GENSOKYO_WORLD_SIM_NPC_MOVE_PROB", "0.18") or "0.18")
    move_prob = max(0.0, min(1.0, move_prob))

    async with httpx.AsyncClient(timeout=20.0) as client:
        world_ids = await _fetch_world_ids(client)
        for world_id in world_ids:
            layer_id = "gensokyo" if world_id.startswith("gensokyo") else "gensokyo"
            locs = await _fetch_active_locations(
                client,
                world_id=world_id,
                now=dt,
                max_locations=max_locations,
            )
            for location_id in locs:
                # 1) Time-skip event generation via visit (visitor_key isolates simulator cadence).
                try:
                    await visit(
                        VisitRequest(
                            world_id=world_id,
                            layer_id=layer_id,
                            location_id=location_id,
                            sub_location_id=None,
                            user_time=dt.isoformat(),
                            visitor_key="world_simulator",
                        ),
                        x_world_secret=WORLD_ENGINE_SECRET or None,
                    )
                except Exception:
                    # best-effort: keep the loop alive
                    pass

                # 2) Ensure NPC presence and optionally move one NPC.
                await ensure_default_npcs_present(client, world_id=world_id, location_id=location_id)
                npcs_here = await fetch_npcs_here(client, world_id=world_id, location_id=location_id)
                if npcs_here and move_prob > 0 and random.random() < move_prob:
                    neigh = _location_neighbors(location_id)
                    if neigh:
                        mover = random.choice(npcs_here)
                        dst = random.choice(neigh)
                        try:
                            await postgrest_upsert_one(
                                client,
                                "world_npc_state",
                                {
                                    "world_id": world_id,
                                    "npc_id": mover.npc_id,
                                    "location_id": dst,
                                    "action": "move",
                                    "emotion": mover.emotion or "neutral",
                                    "updated_at": dt.isoformat(),
                                },
                                on_conflict="world_id,npc_id",
                            )
                            await emit_event(
                                EmitEventRequest(
                                    world_id=world_id,
                                    layer_id=layer_id,
                                    location_id=location_id,
                                    type="npc_action",
                                    actor=Actor(kind="npc", id=mover.npc_id),
                                    ts=dt.isoformat(),
                                    payload={
                                        "event_type": "npc_move",
                                        "from": location_id,
                                        "to": dst,
                                        "summary": f"{mover.npc_id} moved to {dst}",
                                    },
                                ),
                                x_world_secret=WORLD_ENGINE_SECRET or None,
                            )
                        except Exception:
                            pass

                # 3) Trigger planner on a synthetic world_tick source event (dialogue + tiny actions).
                try:
                    await ensure_default_npcs_present(client, world_id=world_id, location_id=location_id)
                    npcs_here = await fetch_npcs_here(client, world_id=world_id, location_id=location_id)
                    ctx = PlannerContext(
                        world_id=world_id,
                        layer_id=layer_id,
                        location_id=location_id,
                        source_event={
                            "id": "",
                            "world_id": world_id,
                            "layer_id": layer_id,
                            "location_id": location_id,
                            "type": "world_tick",
                            "actor": {"kind": "system", "id": "world_simulator"},
                            "payload": {"event_type": "world_tick"},
                        },
                        npcs_here=npcs_here,
                        user=None,
                        now=dt,
                    )
                    # No user relations in autonomous ticks.
                    store = get_short_memory_store()
                    llm = persona_chat_client()

                    async def _speech(speaker_id: str, _ctx: PlannerContext) -> str:
                        if llm is None:
                            return ""
                        return await llm.generate_reply(speaker_character_id=speaker_id, ctx=_ctx)

                    world_ctx = await fetch_recent_summaries(
                        client,
                        world_id=world_id,
                        location_id=location_id,
                        limit=8,
                    )

                    async def _npc_dialogue_llm(
                        speaker_id: str,
                        listener_id: str,
                        loc_id: str,
                        previous_text: Optional[str],
                        _ctx: PlannerContext,
                    ) -> str:
                        if llm is None:
                            return ""
                        return await llm.generate_npc_dialogue_line(
                            speaker_character_id=speaker_id,
                            listener_character_id=listener_id,
                            location_id=loc_id,
                            ctx=_ctx,
                            previous_text=previous_text,
                            world_context=world_ctx,
                        )

                    cfg = planner_config()
                    planned, _next_mem = await maybe_plan_reactions(
                        cfg=cfg,
                        ctx=ctx,
                        short_memory=store,
                        speech_generator=_speech,
                        npc_dialogue_llm_generate=_npc_dialogue_llm if llm is not None else None,
                    )
                    for pe in planned or []:
                        await emit_event(
                            EmitEventRequest(
                                world_id=world_id,
                                layer_id=layer_id,
                                location_id=location_id,
                                type=pe.type,
                                actor=Actor(kind=pe.actor.kind, id=pe.actor.id),
                                ts=pe.ts.isoformat(),
                                payload=pe.payload,
                            ),
                            x_world_secret=WORLD_ENGINE_SECRET or None,
                        )
                except Exception:
                    pass


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
    """
    Prefer Supabase-backed short memory when possible, but fall back to in-memory.

    Supabase table may not exist yet (migration not applied). In that case the store behaves as best-effort.
    """
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


def check_secret(x_world_secret: Optional[str]):
    if not WORLD_ENGINE_SECRET:
        return
    if not x_world_secret or x_world_secret != WORLD_ENGINE_SECRET:
        raise HTTPException(status_code=403, detail="Forbidden")


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def parse_user_time(value: Optional[str]) -> Optional[datetime]:
    if not value:
        return None
    try:
        # Accept ISO8601 "2026-03-12T18:00:00+09:00" (preferred)
        dt = datetime.fromisoformat(value)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc)
    except Exception:
        return None


def day_part(dt_utc: datetime) -> str:
    h = dt_utc.hour
    if 5 <= h < 10:
        return "morning"
    if 10 <= h < 17:
        return "day"
    if 17 <= h < 21:
        return "evening"
    return "night"


def season_of(dt_utc: datetime) -> str:
    m = dt_utc.month
    if m in (3, 4, 5):
        return "spring"
    if m in (6, 7, 8):
        return "summer"
    if m in (9, 10, 11):
        return "autumn"
    return "winter"


def base_event_budget(delta_sec: int) -> int:
    # Docs-driven ranges (tune later, but keep caps explicit).
    if delta_sec < 10 * 60:
        return 1 if delta_sec >= 60 else 0
    if delta_sec < 2 * 60 * 60:
        return 2
    if delta_sec < 8 * 60 * 60:
        return 5
    return 8


def density_multiplier(density: str) -> float:
    d = (density or "").strip().lower()
    if d == "low":
        return 0.5
    if d == "high":
        return 1.5
    return 1.0


def compute_event_budget(delta_sec: int, density: str) -> int:
    b = base_event_budget(delta_sec)
    m = density_multiplier(density)
    n = int(round(b * m))
    return max(0, min(n, 8))


def stable_seed(*parts: str) -> int:
    s = "|".join([p for p in parts if p is not None])
    h = hashlib.sha256(s.encode("utf-8")).hexdigest()
    # 32-bit seed
    return int(h[:8], 16)


def log_world_visit_debug(data: Dict[str, Any]):
    if env("GENSOKYO_WORLD_LOG_VISIT_DEBUG", "1").strip() in ("0", "false", "False"):
        return
    try:
        print("[world.visit]", json.dumps(data, ensure_ascii=False, separators=(",", ":")))
    except Exception:
        pass


_LOC_CACHE: Optional[Dict[str, Any]] = None
_EVENT_CACHE: Optional[List[Dict[str, Any]]] = None
_REL_CACHE: Optional[List[Dict[str, Any]]] = None


def load_locations() -> Dict[str, Any]:
    global _LOC_CACHE
    if _LOC_CACHE is not None:
        return _LOC_CACHE
    data = load_locations_from_content()
    _LOC_CACHE = data if isinstance(data, dict) else {"locations": [], "sub_locations": []}
    return _LOC_CACHE


def load_events() -> List[Dict[str, Any]]:
    global _EVENT_CACHE
    if _EVENT_CACHE is not None:
        return _EVENT_CACHE
    _EVENT_CACHE = load_events_from_content()
    return _EVENT_CACHE


def load_relationships() -> List[Dict[str, Any]]:
    global _REL_CACHE
    if _REL_CACHE is not None:
        return _REL_CACHE
    rr = load_relationships_from_content()
    _REL_CACHE = rr if isinstance(rr, list) else []
    return _REL_CACHE


def table_url(table: str) -> str:
    return postgrest_base_url().rstrip("/") + f"/{table}"


async def postgrest_select(
    client: httpx.AsyncClient,
    table: str,
    query: str,
    extra_headers: Optional[Dict[str, str]] = None,
) -> Any:
    headers = auth_headers()
    if extra_headers:
        headers.update(extra_headers)
    r = await client.get(table_url(table) + query, headers=headers)
    if r.status_code >= 400:
        raise HTTPException(status_code=500, detail=f"select_failed:{table}:{r.status_code}:{r.text}")
    return r.json()


async def postgrest_upsert_one(
    client: httpx.AsyncClient,
    table: str,
    row: Dict[str, Any],
    on_conflict: str,
) -> Dict[str, Any]:
    headers = auth_headers()
    headers["Prefer"] = "resolution=merge-duplicates,return=representation"
    r = await client.post(table_url(table) + f"?on_conflict={on_conflict}", headers=headers, json=row)
    if r.status_code >= 400:
        raise HTTPException(status_code=500, detail=f"upsert_failed:{table}:{r.status_code}:{r.text}")
    data = r.json()
    if isinstance(data, list) and data:
        return data[0]
    if isinstance(data, dict):
        return data
    return row


async def postgrest_update(
    client: httpx.AsyncClient,
    table: str,
    where: str,
    patch: Dict[str, Any],
) -> List[Dict[str, Any]]:
    headers = auth_headers()
    headers["Prefer"] = "return=representation"
    r = await client.patch(table_url(table) + where, headers=headers, json=patch)
    if r.status_code >= 400:
        raise HTTPException(status_code=500, detail=f"update_failed:{table}:{r.status_code}:{r.text}")
    data = r.json()
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        return [data]
    return []


def location_density(location_id: str) -> str:
    data = load_locations()
    for loc in data.get("locations", []) or []:
        if isinstance(loc, dict) and loc.get("id") == location_id:
            return str(loc.get("density") or "med")
    return "med"


def default_npcs_for_location(location_id: str) -> List[str]:
    out: List[str] = []

    data = load_locations()
    for loc in data.get("locations", []) or []:
        if not isinstance(loc, dict) or str(loc.get("id") or "") != location_id:
            continue
        default_npcs = loc.get("default_npcs") if isinstance(loc.get("default_npcs"), list) else []
        for n in default_npcs:
            if isinstance(n, str) and n.strip() and n.strip() not in out:
                out.append(n.strip())

    if out:
        return out

    # Fallback: infer from event definitions (required participants for this location).
    try:
        events = load_events()
    except Exception:
        return out
    for e in events:
        if not isinstance(e, dict) or str(e.get("location_id") or "") != location_id:
            continue
        parts = e.get("participants") if isinstance(e.get("participants"), dict) else {}
        required = parts.get("required") if isinstance(parts.get("required"), list) else []
        for n in required:
            if isinstance(n, str) and n.strip() and n.strip() not in out:
                out.append(n.strip())
    return out


def check_sub_location(parent_location_id: str, sub_location_id: Optional[str]) -> Optional[str]:
    if not sub_location_id:
        return None
    data = load_locations()
    for sub in data.get("sub_locations", []) or []:
        if isinstance(sub, dict) and sub.get("id") == sub_location_id:
            if sub.get("parent") == parent_location_id:
                return str(sub_location_id)
            return None
    return None


def event_constraints_ok(defn: Dict[str, Any], world_state: Dict[str, Any]) -> bool:
    c = defn.get("constraints") if isinstance(defn.get("constraints"), dict) else {}
    tod = str(world_state.get("time_of_day") or "")
    weather = str(world_state.get("weather") or "")
    if isinstance(c.get("time_of_day"), list) and c["time_of_day"]:
        if tod not in [str(x) for x in c["time_of_day"]]:
            return False
    if isinstance(c.get("weather_not"), list) and c["weather_not"]:
        if weather in [str(x) for x in c["weather_not"]]:
            return False
    return True


def event_participants(defn: Dict[str, Any]) -> List[str]:
    parts = defn.get("participants")
    if not isinstance(parts, dict):
        return []
    req = parts.get("required")
    if not isinstance(req, list):
        return []
    return [str(x) for x in req if isinstance(x, str) and x.strip()]


def extract_event_type(row: Dict[str, Any]) -> Optional[str]:
    payload = row.get("payload")
    if isinstance(payload, dict) and isinstance(payload.get("event_type"), str):
        return str(payload["event_type"])
    return None


def extract_summary(row: Dict[str, Any]) -> str:
    payload = row.get("payload")
    if isinstance(payload, dict) and isinstance(payload.get("summary"), str):
        return str(payload["summary"]).strip()
    return ""


def recent_weight(event_id: str, recent_event_types: List[str]) -> float:
    # Docs examples: within last 3 -> 0.05, within last 10 -> 0.2
    if event_id in recent_event_types[:3]:
        return 0.05
    if event_id in recent_event_types[:10]:
        return 0.2
    return 1.0


def effect_location_changes(defn: Dict[str, Any]) -> List[Tuple[str, str]]:
    effects = defn.get("effects") if isinstance(defn.get("effects"), dict) else {}
    state = effects.get("state") if isinstance(effects.get("state"), list) else []
    changes: List[Tuple[str, str]] = []
    for e in state:
        if not isinstance(e, dict):
            continue
        target = e.get("target")
        patch = e.get("set") if isinstance(e.get("set"), dict) else {}
        if isinstance(target, str) and isinstance(patch.get("location_id"), str) and patch.get("location_id"):
            changes.append((target, str(patch.get("location_id"))))
    return changes


def apply_effects_world(world_state: Dict[str, Any], defn: Dict[str, Any]) -> Dict[str, Any]:
    effects = defn.get("effects") if isinstance(defn.get("effects"), dict) else {}
    world = effects.get("world") if isinstance(effects.get("world"), list) else []
    out = dict(world_state)
    for e in world:
        if not isinstance(e, dict):
            continue
        patch = e.get("set") if isinstance(e.get("set"), dict) else {}
        for k in ("time_of_day", "weather", "season", "moon_phase", "anomaly"):
            if k in patch:
                out[k] = patch.get(k)
    return out


def npc_effect_patches(defn: Dict[str, Any]) -> List[Tuple[str, Dict[str, Any]]]:
    effects = defn.get("effects") if isinstance(defn.get("effects"), dict) else {}
    state = effects.get("state") if isinstance(effects.get("state"), list) else []
    out: List[Tuple[str, Dict[str, Any]]] = []
    for e in state:
        if not isinstance(e, dict):
            continue
        target = e.get("target")
        patch = e.get("set") if isinstance(e.get("set"), dict) else {}
        if isinstance(target, str) and patch:
            out.append((target, patch))
    return out


@app.post("/world/emit")
async def emit_event(req: EmitEventRequest, x_world_secret: Optional[str] = Header(default=None)):
    check_secret(x_world_secret)
    require_supabase()

    actor_json = req.actor.model_dump() if req.actor else None
    payload = req.payload or {}
    ts = parse_user_time(req.ts) if req.ts else None

    async with httpx.AsyncClient(timeout=20.0) as client:
        r = await client.post(
            rpc_url("world_append_event"),
            headers=auth_headers(),
            json={
                "p_world_id": req.world_id,
                "p_layer_id": req.layer_id,
                "p_location_id": req.location_id or "",
                "p_type": req.type,
                "p_actor": actor_json,
                "p_payload": payload,
                "p_ts": (ts.isoformat() if ts else None),
            },
        )
        if r.status_code >= 400:
            raise HTTPException(status_code=500, detail=f"append_event_failed: {r.status_code} {r.text}")

        return {"ok": True, "event": r.json()}


def command_trace(cmd: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "command_id": cmd.get("id"),
        "correlation_id": cmd.get("correlation_id"),
        "causation_id": cmd.get("causation_id"),
        "command_type": cmd.get("type"),
    }


async def upsert_user_state(
    client: httpx.AsyncClient,
    world_id: str,
    user_id: str,
    location_id: Optional[str],
    sub_location_id: Optional[str],
):
    if not is_uuid_like(user_id):
        return
    loc = (location_id or "").strip()
    sub = sub_location_id.strip() if isinstance(sub_location_id, str) and sub_location_id.strip() else None
    await postgrest_upsert_one(
        client,
        "world_user_state",
        {
            "world_id": world_id,
            "user_id": user_id,
            "location_id": loc,
            "sub_location_id": sub,
            "updated_at": now_utc().isoformat(),
        },
        on_conflict="world_id,user_id",
    )


def _looks_like_missing_column_or_table(err: Exception, token: str) -> bool:
    msg = str(err or "")
    return token in msg and ("column" in msg or "schema" in msg or "relation" in msg or "does not exist" in msg)


async def fetch_player_character_relations(
    client: httpx.AsyncClient,
    *,
    user_id: str,
    character_ids: List[str],
) -> Dict[str, Dict[str, Any]]:
    """
    Returns per-character relation rows keyed by character_id.
    Best-effort: if the table is missing (migration not applied), returns {}.
    """

    if not is_uuid_like(user_id):
        return {}
    ids = [str(x or "").strip() for x in (character_ids or []) if str(x or "").strip()]
    ids = list(dict.fromkeys(ids))
    if not ids:
        return {}
    joined = ",".join(ids)
    try:
        rows = await postgrest_select(
            client,
            "player_character_relations",
            f"?user_id=eq.{user_id}&character_id=in.({joined})&select=user_id,character_id,affinity,trust,friendship,role,last_updated",
        )
    except Exception as e:
        if _looks_like_missing_column_or_table(e, "player_character_relations"):
            return {}
        return {}

    out: Dict[str, Dict[str, Any]] = {}
    for r in rows or []:
        if not isinstance(r, dict):
            continue
        cid = r.get("character_id")
        if isinstance(cid, str) and cid.strip():
            out[cid.strip()] = r
    return out


def _clamp01(x: float) -> float:
    if x != x:
        return 0.0
    return max(0.0, min(1.0, x))


async def bump_player_character_relation(
    client: httpx.AsyncClient,
    *,
    user_id: str,
    character_id: str,
    delta_affinity: float = 0.0,
    delta_trust: float = 0.0,
    delta_friendship: float = 0.0,
    role: Optional[str] = None,
) -> None:
    """
    Best-effort upsert. Safe when the table is missing (no-op).
    """

    uid = str(user_id or "").strip()
    cid = str(character_id or "").strip()
    if not (is_uuid_like(uid) and cid):
        return
    try:
        existing = await postgrest_select(
            client,
            "player_character_relations",
            f"?user_id=eq.{uid}&character_id=eq.{cid}&select=affinity,trust,friendship,role&limit=1",
        )
        row0 = existing[0] if isinstance(existing, list) and existing and isinstance(existing[0], dict) else {}
        a0 = float(row0.get("affinity") or 0.0)
        t0 = float(row0.get("trust") or 0.0)
        f0 = float(row0.get("friendship") or 0.0)
        role0 = str(row0.get("role") or "").strip() or None

        row = {
            "user_id": uid,
            "character_id": cid,
            "affinity": _clamp01(a0 + float(delta_affinity or 0.0)),
            "trust": _clamp01(t0 + float(delta_trust or 0.0)),
            "friendship": _clamp01(f0 + float(delta_friendship or 0.0)),
            "role": role if (isinstance(role, str) and role.strip()) else role0,
            "last_updated": now_utc().isoformat(),
        }
        await postgrest_upsert_one(
            client,
            "player_character_relations",
            row,
            on_conflict="user_id,character_id",
        )
    except Exception as e:
        if _looks_like_missing_column_or_table(e, "player_character_relations"):
            return
        return


async def emit_for_command(cmd: Dict[str, Any], x_world_secret: Optional[str]) -> Optional[Dict[str, Any]]:
    world_id = str(cmd.get("world_id") or "")
    cmd_type = str(cmd.get("type") or "")
    payload = cmd.get("payload") if isinstance(cmd.get("payload"), dict) else {}
    user_id = cmd.get("user_id")

    layer_id = "gensokyo" if world_id.startswith("gensokyo") else "gensokyo"
    if isinstance(payload.get("layer_id"), str) and str(payload["layer_id"]).strip():
        layer_id = str(payload["layer_id"]).strip()

    loc = payload.get("loc") or payload.get("location_id")
    if cmd_type == "user_move":
        loc = payload.get("to") or loc

    actor = Actor(kind="user", id=str(user_id) if user_id else None)

    if cmd_type == "user_say":
        text = str(payload.get("text") or "")
        to = payload.get("to")
        r = await emit_event(
            EmitEventRequest(
                world_id=world_id,
                layer_id=layer_id,
                location_id=str(loc) if loc else None,
                type="npc_say",
                actor=actor,
                ts=now_utc().isoformat(),
                payload={
                    "event_type": "user_say",
                    "text": text,
                    "to": to,
                    "summary": text[:80] if text else "",
                    "trace": command_trace(cmd),
                },
            ),
            x_world_secret=x_world_secret,
        )
        return r.get("event") if isinstance(r, dict) else None

    if cmd_type == "user_move":
        r = await emit_event(
            EmitEventRequest(
                world_id=world_id,
                layer_id=layer_id,
                location_id=str(loc) if loc else None,
                type="npc_action",
                actor=actor,
                ts=now_utc().isoformat(),
                payload={
                    "event_type": "user_move",
                    **payload,
                    "trace": command_trace(cmd),
                },
            ),
            x_world_secret=x_world_secret,
        )
        return r.get("event") if isinstance(r, dict) else None

    if cmd_type in ("user_choose", "user_request", "user_item_use", "user_item_give", "user_item_take"):
        r = await emit_event(
            EmitEventRequest(
                world_id=world_id,
                layer_id=layer_id,
                location_id=str(loc) if loc else None,
                type="npc_action",
                actor=actor,
                ts=now_utc().isoformat(),
                payload={
                    "event_type": cmd_type,
                    **payload,
                    "trace": command_trace(cmd),
                },
            ),
            x_world_secret=x_world_secret,
        )
        return r.get("event") if isinstance(r, dict) else None

    if cmd_type == "npc_move":
        npc_id = str(payload.get("npc_id") or "").strip()
        to_loc = str(payload.get("to") or payload.get("location_id") or "").strip()
        if not (npc_id and to_loc):
            raise HTTPException(status_code=400, detail="npc_move_missing:npc_id/to")

        async with httpx.AsyncClient(timeout=20.0) as client:
            prev_loc = ""
            try:
                rows = await postgrest_select(
                    client,
                    "world_npc_state",
                    f"?world_id=eq.{world_id}&npc_id=eq.{npc_id}&select=location_id&limit=1",
                )
                if isinstance(rows, list) and rows and isinstance(rows[0], dict):
                    prev_loc = str(rows[0].get("location_id") or "")
            except Exception:
                prev_loc = ""

            await postgrest_upsert_one(
                client,
                "world_npc_state",
                {
                    "world_id": world_id,
                    "npc_id": npc_id,
                    "location_id": to_loc,
                    "action": "move",
                    "emotion": str(payload.get("emotion") or "neutral"),
                    "updated_at": now_utc().isoformat(),
                },
                on_conflict="world_id,npc_id",
            )

        r = await emit_event(
            EmitEventRequest(
                world_id=world_id,
                layer_id=layer_id,
                location_id=to_loc,
                type="npc_action",
                actor=Actor(kind="npc", id=npc_id),
                ts=now_utc().isoformat(),
                payload={
                    "event_type": "npc_move",
                    "from": prev_loc or None,
                    "to": to_loc,
                    "summary": f"{npc_id} moved to {to_loc}",
                    "trace": command_trace(cmd),
                },
            ),
            x_world_secret=x_world_secret,
        )
        return r.get("event") if isinstance(r, dict) else None

    r = await emit_event(
        EmitEventRequest(
            world_id=world_id,
            layer_id=layer_id,
            location_id=str(loc) if loc else None,
            type="system",
            actor=Actor(kind="system", id="world_engine"),
            ts=now_utc().isoformat(),
            payload={
                "event_type": "command_unknown",
                "summary": "コマンドを受理した。",
                "trace": command_trace(cmd),
            },
        ),
        x_world_secret=x_world_secret,
    )
    return r.get("event") if isinstance(r, dict) else None


async def fetch_user_state(
    client: httpx.AsyncClient,
    world_id: str,
    user_id: Optional[str],
) -> Optional[UserSnapshot]:
    if not is_uuid_like(str(user_id) if user_id else ""):
        return None
    rows = await postgrest_select(
        client,
        "world_user_state",
        f"?world_id=eq.{world_id}&user_id=eq.{user_id}&select=user_id,location_id,sub_location_id,inventory,updated_at&limit=1",
    )
    if not rows:
        return None
    r = rows[0] if isinstance(rows[0], dict) else {}
    return UserSnapshot(
        user_id=str(r.get("user_id") or ""),
        location_id=str(r.get("location_id") or ""),
        sub_location_id=str(r.get("sub_location_id")) if r.get("sub_location_id") is not None else None,
        inventory=r.get("inventory") if isinstance(r.get("inventory"), dict) else {},
        updated_at=str(r.get("updated_at")) if r.get("updated_at") is not None else None,
    )


async def ensure_default_npcs_present(
    client: httpx.AsyncClient,
    world_id: str,
    location_id: str,
):
    defaults = default_npcs_for_location(location_id)
    if not defaults:
        return
    for npc_id in defaults:
        await postgrest_upsert_one(
            client,
            "world_npc_state",
            {
                "world_id": world_id,
                "npc_id": npc_id,
                "location_id": location_id,
                "action": "idle",
                "emotion": "neutral",
                "updated_at": now_utc().isoformat(),
            },
            on_conflict="world_id,npc_id",
        )


async def fetch_npcs_here(
    client: httpx.AsyncClient,
    world_id: str,
    location_id: str,
) -> List[NpcSnapshot]:
    rows = await postgrest_select(
        client,
        "world_npc_state",
        f"?world_id=eq.{world_id}&location_id=eq.{location_id}&select=npc_id,location_id,action,emotion,updated_at",
    )
    out: List[NpcSnapshot] = []
    for r in rows or []:
        if not isinstance(r, dict) or not isinstance(r.get("npc_id"), str):
            continue
        out.append(
            NpcSnapshot(
                npc_id=str(r.get("npc_id") or ""),
                location_id=str(r.get("location_id") or ""),
                action=str(r.get("action")) if r.get("action") is not None else None,
                emotion=str(r.get("emotion")) if r.get("emotion") is not None else None,
                updated_at=str(r.get("updated_at")) if r.get("updated_at") is not None else None,
            )
        )
    return out


async def run_planner_after_command(
    client: httpx.AsyncClient,
    cmd: Dict[str, Any],
    source_event: Optional[Dict[str, Any]],
    x_world_secret: Optional[str],
):
    cfg = planner_config()
    if not cfg.enabled:
        return
    if not source_event or not isinstance(source_event, dict):
        return

    world_id = str(cmd.get("world_id") or "")
    layer_id = str(source_event.get("layer_id") or cmd.get("layer_id") or "gensokyo")
    location_id = str(source_event.get("location_id") or "")
    if not world_id or not location_id:
        return

    await ensure_default_npcs_present(client, world_id=world_id, location_id=location_id)
    npcs_here = await fetch_npcs_here(client, world_id=world_id, location_id=location_id)
    user = await fetch_user_state(client, world_id=world_id, user_id=str(cmd.get("user_id") or ""))

    # Update player<->character relation from the triggering user-facing event (best-effort).
    try:
        payload0 = source_event.get("payload") if isinstance(source_event.get("payload"), dict) else {}
        ev0 = str(payload0.get("event_type") or "")
        to0 = payload0.get("to")
        to_id: Optional[str] = None
        if isinstance(to0, str) and to0.strip():
            to_id = to0.strip()
        elif isinstance(to0, dict):
            tid = to0.get("id")
            if isinstance(tid, str) and tid.strip():
                to_id = tid.strip()
        if ev0 == "user_say" and user is not None and to_id:
            await bump_player_character_relation(
                client,
                user_id=user.user_id,
                character_id=to_id,
                delta_affinity=float(env("GENSOKYO_REL_DELTA_AFFINITY_SAY", "0.010") or "0.010"),
                delta_trust=float(env("GENSOKYO_REL_DELTA_TRUST_SAY", "0.004") or "0.004"),
                delta_friendship=float(env("GENSOKYO_REL_DELTA_FRIENDSHIP_SAY", "0.006") or "0.006"),
                role=None,
            )
    except Exception:
        pass

    # Read per-character relation snapshots into planner context (best-effort).
    player_relations: Dict[str, Dict[str, Any]] = {}
    try:
        if user is not None and npcs_here:
            player_relations = await fetch_player_character_relations(
                client,
                user_id=user.user_id,
                character_ids=[n.npc_id for n in npcs_here],
            )
    except Exception:
        player_relations = {}

    ctx = PlannerContext(
        world_id=world_id,
        layer_id=layer_id,
        location_id=location_id,
        source_event=source_event,
        npcs_here=npcs_here,
        user=user,
        player_relations=player_relations,
        now=now_utc(),
    )

    store = get_short_memory_store()

    llm = persona_chat_client()

    async def _speech(speaker_id: str, _ctx: PlannerContext) -> str:
        if llm is None:
            return ""
        return await llm.generate_reply(speaker_character_id=speaker_id, ctx=_ctx)

    planned, next_mem = await maybe_plan_reactions(cfg=cfg, ctx=ctx, short_memory=store, speech_generator=_speech)
    if not planned:
        return

    # Attach trace to every planned event.
    trace0: Dict[str, Any] = {}
    payload0 = source_event.get("payload")
    if isinstance(payload0, dict) and isinstance(payload0.get("trace"), dict):
        trace0 = dict(payload0.get("trace") or {})
    else:
        trace0 = command_trace(cmd)
    trace0["planner"] = "bt_v1"
    trace0["causation_event_id"] = str(source_event.get("id") or "")

    speaker_npc_id: Optional[str] = None
    for pe in planned:
        if not isinstance(pe.payload, dict):
            pe.payload = {}
        pe.payload.setdefault("trace", trace0)
        pe.payload.setdefault("event_type", pe.type)

        r = await emit_event(
            EmitEventRequest(
                world_id=world_id,
                layer_id=layer_id,
                location_id=location_id,
                type=pe.type,
                actor=Actor(kind=pe.actor.kind, id=pe.actor.id),
                ts=pe.ts.isoformat(),
                payload=pe.payload,
            ),
            x_world_secret=x_world_secret,
        )
        _ = r  # reserved for future causation chaining
        if pe.actor.kind == "npc" and pe.actor.id:
            speaker_npc_id = pe.actor.id

    if speaker_npc_id:
        try:
            await store.put_state(world_id, speaker_npc_id, next_mem)
        except Exception:
            pass
        # Update NPC snapshot for UI hints (best-effort).
        try:
            await postgrest_upsert_one(
                client,
                "world_npc_state",
                {
                    "world_id": world_id,
                    "npc_id": speaker_npc_id,
                    "location_id": location_id,
                    "action": "talking",
                    "emotion": "neutral",
                    "updated_at": now_utc().isoformat(),
                },
                on_conflict="world_id,npc_id",
            )
        except Exception:
            pass


async def command_worker_loop(x_world_secret: Optional[str]):
    require_supabase()
    poll_ms = int(env("GENSOKYO_COMMAND_WORKER_POLL_MS", "500") or "500")
    batch = int(env("GENSOKYO_COMMAND_WORKER_BATCH", "20") or "20")
    batch = max(1, min(batch, 50))

    async with httpx.AsyncClient(timeout=20.0) as client:
        while True:
            try:
                rows = await postgrest_select(
                    client,
                    "world_command_log",
                    f"?status=in.(queued,accepted)&order=created_at.asc&limit={batch}&select=*",
                )
                for cmd in rows or []:
                    if not isinstance(cmd, dict) or not cmd.get("id"):
                        continue
                    cmd_id = str(cmd["id"])
                    claimed = await postgrest_update(
                        client,
                        "world_command_log",
                        f"?id=eq.{cmd_id}&status=in.(queued,accepted)",
                        {"status": "processing", "updated_at": now_utc().isoformat()},
                    )
                    if not claimed:
                        continue
                    cmd = claimed[0]
                    try:
                        if isinstance(cmd.get("payload"), dict) and cmd.get("user_id"):
                            p = cmd["payload"]
                            loc = p.get("loc") or p.get("location_id")
                            sub = p.get("sub_location_id")
                            if cmd.get("type") == "user_move":
                                loc = p.get("to") or loc
                            await upsert_user_state(
                                client,
                                str(cmd.get("world_id") or ""),
                                str(cmd.get("user_id") or ""),
                                str(loc) if loc is not None else None,
                                str(sub) if sub is not None else None,
                            )
                        source_event = await emit_for_command(cmd, x_world_secret=x_world_secret)
                        await run_planner_after_command(
                            client,
                            cmd=cmd,
                            source_event=source_event,
                            x_world_secret=x_world_secret,
                        )
                        await postgrest_update(
                            client,
                            "world_command_log",
                            f"?id=eq.{cmd_id}",
                            {"status": "done", "updated_at": now_utc().isoformat()},
                        )
                    except Exception as e:
                        await postgrest_update(
                            client,
                            "world_command_log",
                            f"?id=eq.{cmd_id}",
                            {
                                "status": "failed",
                                "error_code": "worker_error",
                                "error_message": str(e)[:500],
                                "updated_at": now_utc().isoformat(),
                            },
                        )
            except asyncio.CancelledError:
                raise
            except Exception:
                pass

            await asyncio.sleep(max(0.05, poll_ms / 1000.0))


@app.get("/world/state")
async def get_world_state(world_id: str, location_id: str = "", x_world_secret: Optional[str] = Header(default=None)):
    check_secret(x_world_secret)
    require_supabase()

    loc = location_id or ""
    async with httpx.AsyncClient(timeout=20.0) as client:
        rows = await postgrest_select(
            client,
            "world_state",
            f"?world_id=eq.{world_id}&location_id=eq.{loc}&select=*",
        )
        if rows:
            return rows[0]

        # Create default state
        dt = now_utc()
        row = await postgrest_upsert_one(
            client,
            "world_state",
            {
                "world_id": world_id,
                "location_id": loc,
                "time_of_day": day_part(dt),
                "weather": "clear",
                "season": season_of(dt),
                "moon_phase": "unknown",
                "anomaly": None,
                "updated_at": dt.isoformat(),
            },
            on_conflict="world_id,location_id",
        )
        return row


@app.get("/world/recent")
async def get_recent_events(
    world_id: str,
    location_id: str = "",
    limit: int = 10,
    x_world_secret: Optional[str] = Header(default=None),
):
    check_secret(x_world_secret)
    require_supabase()

    loc = location_id or ""
    channel = f"world:{world_id}" if not loc else f"world:{world_id}:{loc}"
    n = max(1, min(int(limit or 10), 50))

    async with httpx.AsyncClient(timeout=20.0) as client:
        rows = await postgrest_select(
            client,
            "world_event_log",
            f"?channel=eq.{channel}&order=seq.desc&limit={n}&select=seq,ts,type,actor,payload",
        )
        rows.reverse()
        out = []
        for r in rows:
            if not isinstance(r, dict):
                continue
            event_type = extract_event_type(r) or str(r.get("type") or "event")
            summary = extract_summary(r) or ""
            created_at = r.get("ts")
            if not summary:
                continue
            out.append({"event_type": event_type, "summary": summary, "created_at": created_at})
        return {"recent_events": out}


@app.get("/world/npcs")
async def get_npcs(world_id: str, location_id: str = "", x_world_secret: Optional[str] = Header(default=None)):
    check_secret(x_world_secret)
    require_supabase()

    loc = location_id or ""
    async with httpx.AsyncClient(timeout=20.0) as client:
        if loc:
            rows = await postgrest_select(
                client,
                "world_npc_state",
                f"?world_id=eq.{world_id}&location_id=eq.{loc}&select=npc_id,location_id,action,emotion,updated_at",
            )
        else:
            rows = await postgrest_select(
                client,
                "world_npc_state",
                f"?world_id=eq.{world_id}&select=npc_id,location_id,action,emotion,updated_at",
            )
        npcs = [
            {
                "id": r.get("npc_id"),
                "location_id": r.get("location_id") or None,
                "action": r.get("action"),
                "emotion": r.get("emotion"),
            }
            for r in rows or []
        ]
        return {"npcs": npcs}


@app.post("/world/visit")
async def visit(req: VisitRequest, x_world_secret: Optional[str] = Header(default=None)):
    check_secret(x_world_secret)
    require_supabase()

    user_dt = parse_user_time(req.user_time) or now_utc()
    visitor_key = req.visitor_key or "anon"
    sub_loc = check_sub_location(req.location_id, req.sub_location_id)

    async with httpx.AsyncClient(timeout=20.0) as client:
        # Get last visit
        visit_rows = await postgrest_select(
            client,
            "world_visits",
            f"?world_id=eq.{req.world_id}&visitor_key=eq.{visitor_key}&location_id=eq.{req.location_id}&select=last_visit",
        )
        last_visit: Optional[datetime] = None
        if visit_rows and isinstance(visit_rows[0], dict) and visit_rows[0].get("last_visit"):
            try:
                last_visit = datetime.fromisoformat(visit_rows[0]["last_visit"].replace("Z", "+00:00")).astimezone(
                    timezone.utc
                )
            except Exception:
                last_visit = None

        if not last_visit:
            # First visit: treat as "no time skip"
            last_visit = user_dt

        # Invariant I2: time must be monotonic
        if user_dt < last_visit:
            user_dt = last_visit

        delta_sec = max(0, int((user_dt - last_visit).total_seconds()))

        # Update visit
        await postgrest_upsert_one(
            client,
            "world_visits",
            {
                "world_id": req.world_id,
                "visitor_key": visitor_key,
                "location_id": req.location_id,
                "last_visit": user_dt.isoformat(),
                "updated_at": now_utc().isoformat(),
            },
            on_conflict="world_id,visitor_key,location_id",
        )

        # Load current world_state, then update time fields deterministically.
        existing = await postgrest_select(
            client,
            "world_state",
            f"?world_id=eq.{req.world_id}&location_id=eq.{req.location_id}&select=*",
        )
        cur = existing[0] if isinstance(existing, list) and existing else {}
        state: Dict[str, Any] = {
            "world_id": req.world_id,
            "location_id": req.location_id,
            "time_of_day": day_part(user_dt),
            "weather": str(cur.get("weather") or "clear"),
            "season": season_of(user_dt),
            "moon_phase": str(cur.get("moon_phase") or "unknown"),
            "anomaly": cur.get("anomaly", None),
            "updated_at": user_dt.isoformat(),
        }

        # Emit a world_tick event for this location (always, but cheap)
        tick_payload = {
            "delta_sec": delta_sec,
            "location_id": req.location_id,
            "sub_location_id": sub_loc,
            "time_of_day": state.get("time_of_day"),
            "weather": state.get("weather"),
            "season": state.get("season"),
            "moon_phase": state.get("moon_phase"),
        }
        await emit_event(
            EmitEventRequest(
                world_id=req.world_id,
                layer_id=req.layer_id,
                location_id=req.location_id,
                type="world_tick",
                actor=Actor(kind="system", id="world_engine"),
                ts=user_dt.isoformat(),
                payload=tick_payload,
            ),
            x_world_secret=x_world_secret,
        )

        # --- Time Skip event generation (docs-driven) ---
        density = location_density(req.location_id)
        budget = compute_event_budget(delta_sec, density)

        recent_rows_desc = await postgrest_select(
            client,
            "world_event_log",
            f"?channel=eq.world:{req.world_id}:{req.location_id}&order=seq.desc&limit=50&select=seq,ts,payload",
        )
        recent_types_desc: List[str] = []
        last_seen_ts: Dict[str, datetime] = {}
        for r in recent_rows_desc or []:
            if not isinstance(r, dict):
                continue
            et = extract_event_type(r)
            if not et:
                continue
            recent_types_desc.append(et)
            if et not in last_seen_ts and isinstance(r.get("ts"), str):
                try:
                    last_seen_ts[et] = datetime.fromisoformat(r["ts"].replace("Z", "+00:00")).astimezone(timezone.utc)
                except Exception:
                    pass

        defs = load_events()
        seed = stable_seed(req.layer_id, req.location_id, last_visit.isoformat(), user_dt.isoformat(), visitor_key)
        rng = random.Random(seed)

        selected: List[Dict[str, Any]] = []
        selected_ids: set[str] = set()
        reserved_locations: Dict[str, str] = {}  # npc_id -> location_id

        candidates_count_total = 0
        excluded_by_constraints = 0
        excluded_by_cooldown = 0
        excluded_by_conflict = 0
        reduced_by_recent = 0
        excluded_by_recent_zero = 0

        for _ in range(budget):
            weighted: List[Tuple[Dict[str, Any], float]] = []
            for d in defs:
                eid = str(d.get("id") or "")
                if not eid or eid in selected_ids:
                    continue

                loc = str(d.get("location_id") or "")
                if loc and loc != req.location_id:
                    continue

                if not event_constraints_ok(d, state):
                    excluded_by_constraints += 1
                    continue

                p = float(d.get("probability") or 0.0)
                if p <= 0:
                    continue

                candidates_count_total += 1

                # cooldown
                cooldown_h = float(d.get("cooldown_hours") or 0.0)
                if cooldown_h > 0 and eid in last_seen_ts:
                    if (user_dt - last_seen_ts[eid]).total_seconds() < cooldown_h * 3600:
                        excluded_by_cooldown += 1
                        continue

                # recent filter weight
                rw = recent_weight(eid, recent_types_desc)
                if rw < 1.0:
                    reduced_by_recent += 1
                w = p * rw
                if w <= 0:
                    excluded_by_recent_zero += 1
                    continue

                # invariant I1 guard: avoid conflicting location changes in same tick
                changes = effect_location_changes(d)
                conflict = False
                for npc_id, new_loc in changes:
                    if npc_id in reserved_locations and reserved_locations[npc_id] != new_loc:
                        conflict = True
                        break
                if conflict:
                    excluded_by_conflict += 1
                    continue

                weighted.append((d, w))

            total = sum(w for _, w in weighted)
            if total <= 0:
                break

            pick = rng.random() * total
            acc = 0.0
            chosen: Optional[Dict[str, Any]] = None
            for d, w in weighted:
                acc += w
                if acc >= pick:
                    chosen = d
                    break

            if not chosen:
                break

            selected.append(chosen)
            selected_ids.add(str(chosen.get("id")))
            for npc_id, new_loc in effect_location_changes(chosen):
                reserved_locations[npc_id] = new_loc

            state = apply_effects_world(state, chosen)

        # Persist world_state
        state_row = await postgrest_upsert_one(
            client,
            "world_state",
            {
                "world_id": req.world_id,
                "location_id": req.location_id,
                "time_of_day": state.get("time_of_day"),
                "weather": state.get("weather"),
                "season": state.get("season"),
                "moon_phase": state.get("moon_phase"),
                "anomaly": state.get("anomaly"),
                "updated_at": user_dt.isoformat(),
            },
            on_conflict="world_id,location_id",
        )

        # Apply NPC state effects
        npc_state_changes: List[Dict[str, Any]] = []
        for d in selected:
            for npc_id, patch in npc_effect_patches(d):
                new_loc = str(patch.get("location_id") or "")
                row = {
                    "world_id": req.world_id,
                    "npc_id": npc_id,
                    "location_id": new_loc,
                    "action": patch.get("action"),
                    "emotion": patch.get("emotion"),
                    "updated_at": user_dt.isoformat(),
                }
                await postgrest_upsert_one(client, "world_npc_state", row, on_conflict="world_id,npc_id")
                if new_loc:
                    npc_state_changes.append({"id": npc_id, "location_id": new_loc})

        # Append generated events (ordered, deterministic timestamps within the window)
        recent_events: List[Dict[str, Any]] = []
        if selected:
            step = max(1, int(delta_sec / (len(selected) + 1))) if delta_sec > 0 else 0
            for i, d in enumerate(selected):
                eid = str(d.get("id") or "event")
                payload = d.get("payload") if isinstance(d.get("payload"), dict) else {}
                summary = str(payload.get("summary") or "").strip()
                participants = event_participants(d)
                log_type = str(d.get("log_type") or "system")

                ev_ts = user_dt if step == 0 else (last_visit + timedelta(seconds=step * (i + 1)))
                ev_ts = min(ev_ts, user_dt)

                actor: Optional[Actor] = None
                if log_type in ("npc_action", "npc_say") and participants:
                    actor = Actor(kind="npc", id=participants[0])

                await emit_event(
                    EmitEventRequest(
                        world_id=req.world_id,
                        layer_id=req.layer_id,
                        location_id=req.location_id,
                        type=log_type,
                        actor=actor,
                        ts=ev_ts.isoformat(),
                        payload={
                            "event_type": eid,
                            "summary": summary,
                            "participants": participants,
                            "sub_location_id": sub_loc,
                        },
                    ),
                    x_world_secret=x_world_secret,
                )

                if summary:
                    recent_events.append({"event_type": eid, "summary": summary, "created_at": ev_ts.isoformat()})

        log_world_visit_debug(
            {
                "world_id": req.world_id,
                "layer_id": req.layer_id,
                "location_id": req.location_id,
                "sub_location_id": sub_loc,
                "visitor_key": visitor_key,
                "last_visit": last_visit.isoformat(),
                "now": user_dt.isoformat(),
                "delta_sec": delta_sec,
                "density": density,
                "event_budget": budget,
                "candidates_count": candidates_count_total,
                "excluded_by_constraints": excluded_by_constraints,
                "excluded_by_cooldown": excluded_by_cooldown,
                "excluded_by_recent_zero": excluded_by_recent_zero,
                "reduced_by_recent": reduced_by_recent,
                "excluded_by_conflict": excluded_by_conflict,
                "picked_event_types": [str(d.get("id") or "") for d in selected],
            }
        )

        return {
            "ok": True,
            "delta_sec": delta_sec,
            "world_state": {
                "world_id": req.world_id,
                "time_of_day": state_row.get("time_of_day"),
                "weather": state_row.get("weather"),
                "season": state_row.get("season"),
                "moon_phase": state_row.get("moon_phase"),
            },
            "recent_events": recent_events[-10:],
            "npc_state_changes": npc_state_changes,
        }


@app.post("/world/tick")
async def tick(req: TickRequest, x_world_secret: Optional[str] = Header(default=None)):
    check_secret(x_world_secret)
    require_supabase()

    dt = now_utc()
    loc = req.location_id or ""

    async with httpx.AsyncClient(timeout=20.0) as client:
        state = await postgrest_upsert_one(
            client,
            "world_state",
            {
                "world_id": req.world_id,
                "location_id": loc,
                "time_of_day": day_part(dt),
                "weather": "clear",
                "season": season_of(dt),
                "moon_phase": "unknown",
                "anomaly": None,
                "updated_at": dt.isoformat(),
            },
            on_conflict="world_id,location_id",
        )

        emitted = await emit_event(
            EmitEventRequest(
                world_id=req.world_id,
                layer_id=req.layer_id,
                location_id=loc or None,
                type="world_tick",
                actor=Actor(kind="system", id="world_engine"),
                ts=dt.isoformat(),
                payload={
                    "event_type": "world_tick",
                    "delta_sec": int(req.delta_sec or 0),
                    "reason": req.reason or "manual_tick",
                    "time_of_day": state.get("time_of_day"),
                    "weather": state.get("weather"),
                    "season": state.get("season"),
                    "moon_phase": state.get("moon_phase"),
                },
            ),
            x_world_secret=x_world_secret,
        )

        planned_events: List[Dict[str, Any]] = []
        # Optionally trigger NPC planner on manual ticks (useful for debugging npc_dialogue).
        try:
            if loc:
                await ensure_default_npcs_present(client, world_id=req.world_id, location_id=loc)
                npcs_here = await fetch_npcs_here(client, world_id=req.world_id, location_id=loc)
                if len(npcs_here) >= 1:
                    ctx = PlannerContext(
                        world_id=req.world_id,
                        layer_id=req.layer_id,
                        location_id=loc,
                        source_event={
                            "id": "",
                            "world_id": req.world_id,
                            "layer_id": req.layer_id,
                            "location_id": loc,
                            "type": "world_tick",
                            "actor": {"kind": "system", "id": "world_engine"},
                            "payload": {"event_type": "world_tick", "reason": req.reason or "manual_tick"},
                        },
                        npcs_here=npcs_here,
                        user=None,
                        now=dt,
                    )

                    store = get_short_memory_store()
                    llm = persona_chat_client()

                    async def _speech(speaker_id: str, _ctx: PlannerContext) -> str:
                        if llm is None:
                            return ""
                        return await llm.generate_reply(speaker_character_id=speaker_id, ctx=_ctx)

                    world_ctx = await fetch_recent_summaries(
                        client,
                        world_id=req.world_id,
                        location_id=loc,
                        limit=8,
                    )

                    async def _npc_dialogue_llm(
                        speaker_id: str,
                        listener_id: str,
                        loc_id: str,
                        previous_text: Optional[str],
                        _ctx: PlannerContext,
                    ) -> str:
                        if llm is None:
                            return ""
                        return await llm.generate_npc_dialogue_line(
                            speaker_character_id=speaker_id,
                            listener_character_id=listener_id,
                            location_id=loc_id,
                            ctx=_ctx,
                            previous_text=previous_text,
                            world_context=world_ctx,
                        )

                    cfg = planner_config()
                    planned, _next_mem = await maybe_plan_reactions(
                        cfg=cfg,
                        ctx=ctx,
                        short_memory=store,
                        speech_generator=_speech,
                        npc_dialogue_llm_generate=_npc_dialogue_llm if llm is not None else None,
                    )
                    for pe in planned or []:
                        r2 = await emit_event(
                            EmitEventRequest(
                                world_id=req.world_id,
                                layer_id=req.layer_id,
                                location_id=loc,
                                type=pe.type,
                                actor=Actor(kind=pe.actor.kind, id=pe.actor.id),
                                ts=pe.ts.isoformat(),
                                payload=pe.payload,
                            ),
                            x_world_secret=x_world_secret,
                        )
                        if isinstance(r2, dict) and isinstance(r2.get("event"), dict):
                            planned_events.append(r2["event"])
        except Exception:
            planned_events = []

        return {"ok": True, "world_state": state, "planned_events": planned_events, **(emitted or {})}


@app.post("/world/command")
async def submit_command(req: CommandRequest, x_world_secret: Optional[str] = Header(default=None)):
    check_secret(x_world_secret)
    require_supabase()

    # Insert command log row via PostgREST table endpoint.
    url = postgrest_base_url().rstrip("/") + "/world_command_log"
    headers = auth_headers()
    # Ask PostgREST to return inserted row.
    headers["Prefer"] = "return=representation"

    row: Dict[str, Any] = {
        "world_id": req.world_id,
        "user_id": req.user_id,
        "type": req.type,
        "payload": req.payload or {},
        "dedupe_key": req.dedupe_key,
        "causation_id": req.causation_id,
        "status": "queued",
    }

    async with httpx.AsyncClient(timeout=20.0) as client:
        r = await client.post(url, headers=headers, json=row)
        if r.status_code == 409:
            # dedupe conflict -> return existing row (idempotent)
            if req.dedupe_key:
                existing = await postgrest_select(
                    client,
                    "world_command_log",
                    f"?world_id=eq.{req.world_id}&dedupe_key=eq.{req.dedupe_key}&select=id,correlation_id,status&limit=1",
                )
                if existing and isinstance(existing, list) and isinstance(existing[0], dict):
                    cmd0 = existing[0]
                    return {
                        "ok": True,
                        "command_id": cmd0.get("id"),
                        "correlation_id": cmd0.get("correlation_id"),
                        "status": cmd0.get("status") or "queued",
                    }
            return {"ok": True, "status": "queued"}
        if r.status_code >= 400:
            raise HTTPException(status_code=500, detail=f"command_insert_failed: {r.status_code} {r.text}")

        inserted = r.json()
        # PostgREST returns a list for return=representation
        cmd = inserted[0] if isinstance(inserted, list) and inserted else inserted
        return {"ok": True, "command_id": cmd.get("id"), "correlation_id": cmd.get("correlation_id"), "status": cmd.get("status")}


@app.get("/world/command/{command_id}")
async def get_command(
    command_id: str,
    x_world_secret: Optional[str] = Header(default=None),
):
    check_secret(x_world_secret)
    require_supabase()

    cid = str(command_id or "").strip()
    if not cid:
        raise HTTPException(status_code=400, detail="missing_command_id")

    async with httpx.AsyncClient(timeout=20.0) as client:
        rows = await postgrest_select(
            client,
            "world_command_log",
            f"?id=eq.{cid}&select=id,correlation_id,world_id,user_id,type,payload,status,error_code,error_message,created_at,updated_at&limit=1",
        )
        if not rows:
            raise HTTPException(status_code=404, detail="command_not_found")
        r = rows[0] if isinstance(rows[0], dict) else {}
        return {"ok": True, "command": r}


@app.get("/world/commands")
async def list_commands(
    world_id: str,
    status: str = "",
    limit: int = 20,
    x_world_secret: Optional[str] = Header(default=None),
):
    check_secret(x_world_secret)
    require_supabase()

    wid = str(world_id or "").strip()
    if not wid:
        raise HTTPException(status_code=400, detail="missing_world_id")
    n = max(1, min(int(limit or 20), 50))

    where = f"?world_id=eq.{wid}"
    st = str(status or "").strip()
    if st:
        # allow comma-separated list, e.g. queued,processing,failed
        parts = [p.strip() for p in st.split(",") if p.strip()]
        if len(parts) == 1:
            where += f"&status=eq.{parts[0]}"
        else:
            joined = ",".join(parts)
            where += f"&status=in.({joined})"

    where += f"&order=created_at.desc&limit={n}&select=id,correlation_id,type,status,error_code,error_message,created_at,updated_at"

    async with httpx.AsyncClient(timeout=20.0) as client:
        rows = await postgrest_select(client, "world_command_log", where)
        return {"ok": True, "commands": rows or []}
