from __future__ import annotations

import os
import sys
from pathlib import Path
from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List, Optional, Tuple
import random
import asyncio

import httpx
from fastapi import Header, HTTPException

# Allow running via uvicorn from the monorepo root (so `from planner ...` works).
_THIS_DIR = Path(__file__).resolve().parent
_APP_ROOT = _THIS_DIR.parent
if str(_APP_ROOT) not in sys.path:
    sys.path.insert(0, str(_APP_ROOT))

from app.config import (
    SUPABASE_SERVICE_ROLE_KEY,
    SUPABASE_URL,
    WORLD_ENGINE_SECRET,
    auth_headers,
    env,
    postgrest_base_url,
    require_supabase,
    rpc_url,
)
from app.content_store import load_events, load_locations, load_relationships
from app.application_services import (
    get_command as app_get_command,
    list_commands as app_list_commands,
    submit_command as app_submit_command,
    tick_world,
    visit_world,
)
from app.models import (
    Actor,
    CommandRequest,
    EmitEventRequest,
    TickRequest,
    Utf8JSONResponse,
    VisitRequest,
)
from app.planner_support import get_short_memory_store, persona_chat_client, planner_config
from app.postgrest import postgrest_select, postgrest_update, postgrest_upsert_one
from app.queries import (
    ensure_default_npcs_present,
    fetch_npcs_here,
    fetch_recent_summaries,
    fetch_user_state,
    get_npcs as query_get_npcs,
    get_recent_events as query_get_recent_events,
    get_world_state as query_get_world_state,
)
from app.simulation import world_sim_tick_once, world_simulator_config
from app.workers import command_worker_loop as run_command_worker_loop
from app.world_logic import (
    apply_effects_world,
    check_secret,
    check_sub_location,
    compute_event_budget,
    day_part,
    default_npcs_for_location,
    effect_location_changes,
    event_constraints_ok,
    event_participants,
    extract_event_type,
    extract_summary,
    is_uuid_like,
    location_density,
    log_world_visit_debug,
    now_utc,
    npc_effect_patches,
    parse_user_time,
    recent_weight,
    season_of,
    stable_seed,
)

from planner import maybe_plan_reactions
from planner.interfaces import NpcSnapshot, PlannerContext, UserSnapshot

import npc_dialogue_engine
from world_simulator import WorldSimulatorConfig

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

def health():
    return {"ok": True}


def _on_sim_error(e: Exception) -> None:
    try:
        print("[world.sim] error:", repr(e))
    except Exception:
        pass


async def _world_sim_tick_once(dt: datetime) -> None:
    await world_sim_tick_once(
        dt=dt,
        visit_fn=visit,
        emit_event_fn=emit_event,
        planner_config_fn=planner_config,
        get_short_memory_store_fn=get_short_memory_store,
        persona_chat_client_fn=persona_chat_client,
    )

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
    await run_command_worker_loop(
        x_world_secret=x_world_secret,
        emit_event_fn=emit_event,
        planner_config_fn=planner_config,
        get_short_memory_store_fn=get_short_memory_store,
        persona_chat_client_fn=persona_chat_client,
    )


async def get_world_state(world_id: str, location_id: str = "", x_world_secret: Optional[str] = Header(default=None)):
    require_supabase()
    return await query_get_world_state(
        world_id=world_id,
        location_id=location_id,
        x_world_secret=x_world_secret,
    )


async def get_recent_events(
    world_id: str,
    location_id: str = "",
    limit: int = 10,
    x_world_secret: Optional[str] = Header(default=None),
):
    require_supabase()
    return await query_get_recent_events(
        world_id=world_id,
        location_id=location_id,
        limit=limit,
        x_world_secret=x_world_secret,
    )


async def get_npcs(world_id: str, location_id: str = "", x_world_secret: Optional[str] = Header(default=None)):
    require_supabase()
    return await query_get_npcs(
        world_id=world_id,
        location_id=location_id,
        x_world_secret=x_world_secret,
    )


async def visit(req: VisitRequest, x_world_secret: Optional[str] = Header(default=None)):
    return await visit_world(req=req, x_world_secret=x_world_secret, emit_event_fn=emit_event)


async def tick(req: TickRequest, x_world_secret: Optional[str] = Header(default=None)):
    return await tick_world(req=req, x_world_secret=x_world_secret, emit_event_fn=emit_event)


async def submit_command(req: CommandRequest, x_world_secret: Optional[str] = Header(default=None)):
    return await app_submit_command(req=req, x_world_secret=x_world_secret)


async def get_command(
    command_id: str,
    x_world_secret: Optional[str] = Header(default=None),
):
    return await app_get_command(command_id=command_id, x_world_secret=x_world_secret)


async def list_commands(
    world_id: str,
    status: str = "",
    limit: int = 20,
    x_world_secret: Optional[str] = Header(default=None),
):
    return await app_list_commands(
        world_id=world_id,
        status=status,
        limit=limit,
        x_world_secret=x_world_secret,
    )
