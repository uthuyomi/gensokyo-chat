from __future__ import annotations

import asyncio
from typing import Any, Dict, List, Optional

import httpx

from app.config import env, require_supabase
from app.models import Actor, EmitEventRequest
from app.postgrest import postgrest_select, postgrest_update, postgrest_upsert_one
from app.queries import (
    ensure_default_npcs_present,
    fetch_npcs_here,
    fetch_recent_summaries,
    fetch_user_state,
)
from app.world_logic import default_npcs_for_location, is_uuid_like, now_utc

from planner import maybe_plan_reactions
from planner.interfaces import PlannerContext


def command_trace(cmd: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "command_id": cmd.get("id"),
        "correlation_id": cmd.get("correlation_id"),
        "causation_id": cmd.get("causation_id"),
        "command_type": cmd.get("type"),
    }


async def upsert_user_state(
    client: httpx.AsyncClient,
    *,
    world_id: str,
    user_id: str,
    location_id: Optional[str],
    sub_location_id: Optional[str],
) -> None:
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


def _clamp01(x: float) -> float:
    if x != x:
        return 0.0
    return max(0.0, min(1.0, x))


async def fetch_player_character_relations(
    client: httpx.AsyncClient,
    *,
    user_id: str,
    character_ids: List[str],
) -> Dict[str, Dict[str, Any]]:
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
    except Exception as err:
        if _looks_like_missing_column_or_table(err, "player_character_relations"):
            return {}
        return {}

    out: Dict[str, Dict[str, Any]] = {}
    for row in rows or []:
        if not isinstance(row, dict):
            continue
        cid = row.get("character_id")
        if isinstance(cid, str) and cid.strip():
            out[cid.strip()] = row
    return out


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
        row = {
            "user_id": uid,
            "character_id": cid,
            "affinity": _clamp01(float(row0.get("affinity") or 0.0) + float(delta_affinity or 0.0)),
            "trust": _clamp01(float(row0.get("trust") or 0.0) + float(delta_trust or 0.0)),
            "friendship": _clamp01(float(row0.get("friendship") or 0.0) + float(delta_friendship or 0.0)),
            "role": role if (isinstance(role, str) and role.strip()) else (str(row0.get("role") or "").strip() or None),
            "last_updated": now_utc().isoformat(),
        }
        await postgrest_upsert_one(
            client,
            "player_character_relations",
            row,
            on_conflict="user_id,character_id",
        )
    except Exception as err:
        if _looks_like_missing_column_or_table(err, "player_character_relations"):
            return
        return


async def emit_for_command(
    *,
    cmd: Dict[str, Any],
    x_world_secret: Optional[str],
    emit_event_fn,
) -> Optional[Dict[str, Any]]:
    world_id = str(cmd.get("world_id") or "")
    cmd_type = str(cmd.get("type") or "")
    payload = cmd.get("payload") if isinstance(cmd.get("payload"), dict) else {}
    user_id = cmd.get("user_id")

    layer_id = "gensokyo"
    if isinstance(payload.get("layer_id"), str) and str(payload["layer_id"]).strip():
        layer_id = str(payload["layer_id"]).strip()

    loc = payload.get("loc") or payload.get("location_id")
    if cmd_type == "user_move":
        loc = payload.get("to") or loc

    actor = Actor(kind="user", id=str(user_id) if user_id else None)

    if cmd_type == "user_say":
        text = str(payload.get("text") or "")
        to = payload.get("to")
        result = await emit_event_fn(
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
        return result.get("event") if isinstance(result, dict) else None

    if cmd_type == "user_move":
        result = await emit_event_fn(
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
        return result.get("event") if isinstance(result, dict) else None

    if cmd_type in ("user_choose", "user_request", "user_item_use", "user_item_give", "user_item_take"):
        result = await emit_event_fn(
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
        return result.get("event") if isinstance(result, dict) else None

    if cmd_type == "npc_move":
        npc_id = str(payload.get("npc_id") or "").strip()
        to_loc = str(payload.get("to") or payload.get("location_id") or "").strip()
        if not (npc_id and to_loc):
            raise ValueError("npc_move_missing:npc_id/to")

        prev_loc = ""
        async with httpx.AsyncClient(timeout=20.0) as client:
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

        result = await emit_event_fn(
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
        return result.get("event") if isinstance(result, dict) else None

    result = await emit_event_fn(
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
    return result.get("event") if isinstance(result, dict) else None


async def run_planner_after_command(
    *,
    client: httpx.AsyncClient,
    cmd: Dict[str, Any],
    source_event: Optional[Dict[str, Any]],
    x_world_secret: Optional[str],
    planner_config_fn,
    get_short_memory_store_fn,
    persona_chat_client_fn,
    emit_event_fn,
) -> None:
    cfg = planner_config_fn()
    if not cfg.enabled or not source_event or not isinstance(source_event, dict):
        return

    world_id = str(cmd.get("world_id") or "")
    layer_id = str(source_event.get("layer_id") or cmd.get("layer_id") or "gensokyo")
    location_id = str(source_event.get("location_id") or "")
    if not world_id or not location_id:
        return

    await ensure_default_npcs_present(
        client,
        world_id=world_id,
        location_id=location_id,
        default_npc_ids=default_npcs_for_location(location_id),
    )
    npcs_here = await fetch_npcs_here(client, world_id=world_id, location_id=location_id)
    user = await fetch_user_state(client, world_id=world_id, user_id=str(cmd.get("user_id") or ""))

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

    player_relations: Dict[str, Dict[str, Any]] = {}
    try:
        if user is not None and npcs_here:
            player_relations = await fetch_player_character_relations(
                client,
                user_id=user.user_id,
                character_ids=[npc.npc_id for npc in npcs_here],
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

    store = get_short_memory_store_fn()
    llm = persona_chat_client_fn()

    async def _speech(speaker_id: str, _ctx: PlannerContext) -> str:
        if llm is None:
            return ""
        return await llm.generate_reply(speaker_character_id=speaker_id, ctx=_ctx)

    planned, next_mem = await maybe_plan_reactions(
        cfg=cfg,
        ctx=ctx,
        short_memory=store,
        speech_generator=_speech,
    )
    if not planned:
        return

    payload0 = source_event.get("payload")
    if isinstance(payload0, dict) and isinstance(payload0.get("trace"), dict):
        trace0 = dict(payload0.get("trace") or {})
    else:
        trace0 = command_trace(cmd)
    trace0["planner"] = "bt_v1"
    trace0["causation_event_id"] = str(source_event.get("id") or "")

    speaker_npc_id: Optional[str] = None
    for planned_event in planned:
        if not isinstance(planned_event.payload, dict):
            planned_event.payload = {}
        planned_event.payload.setdefault("trace", trace0)
        planned_event.payload.setdefault("event_type", planned_event.type)
        await emit_event_fn(
            EmitEventRequest(
                world_id=world_id,
                layer_id=layer_id,
                location_id=location_id,
                type=planned_event.type,
                actor=Actor(kind=planned_event.actor.kind, id=planned_event.actor.id),
                ts=planned_event.ts.isoformat(),
                payload=planned_event.payload,
            ),
            x_world_secret=x_world_secret,
        )
        if planned_event.actor.kind == "npc" and planned_event.actor.id:
            speaker_npc_id = planned_event.actor.id

    if speaker_npc_id:
        try:
            await store.put_state(world_id, speaker_npc_id, next_mem)
        except Exception:
            pass
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


async def command_worker_loop(
    *,
    x_world_secret: Optional[str],
    emit_event_fn,
    planner_config_fn,
    get_short_memory_store_fn,
    persona_chat_client_fn,
) -> None:
    require_supabase()
    poll_ms = int(env("GENSOKYO_COMMAND_WORKER_POLL_MS", "500") or "500")
    batch = max(1, min(int(env("GENSOKYO_COMMAND_WORKER_BATCH", "20") or "20"), 50))

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
                            payload = cmd["payload"]
                            loc = payload.get("loc") or payload.get("location_id")
                            sub = payload.get("sub_location_id")
                            if cmd.get("type") == "user_move":
                                loc = payload.get("to") or loc
                            await upsert_user_state(
                                client,
                                world_id=str(cmd.get("world_id") or ""),
                                user_id=str(cmd.get("user_id") or ""),
                                location_id=str(loc) if loc is not None else None,
                                sub_location_id=str(sub) if sub is not None else None,
                            )
                        source_event = await emit_for_command(
                            cmd=cmd,
                            x_world_secret=x_world_secret,
                            emit_event_fn=emit_event_fn,
                        )
                        await run_planner_after_command(
                            client=client,
                            cmd=cmd,
                            source_event=source_event,
                            x_world_secret=x_world_secret,
                            planner_config_fn=planner_config_fn,
                            get_short_memory_store_fn=get_short_memory_store_fn,
                            persona_chat_client_fn=persona_chat_client_fn,
                            emit_event_fn=emit_event_fn,
                        )
                        await postgrest_update(
                            client,
                            "world_command_log",
                            f"?id=eq.{cmd_id}",
                            {"status": "done", "updated_at": now_utc().isoformat()},
                        )
                    except Exception as err:
                        await postgrest_update(
                            client,
                            "world_command_log",
                            f"?id=eq.{cmd_id}",
                            {
                                "status": "failed",
                                "error_code": "worker_error",
                                "error_message": str(err)[:500],
                                "updated_at": now_utc().isoformat(),
                            },
                        )
            except asyncio.CancelledError:
                raise
            except Exception:
                pass

            await asyncio.sleep(max(0.05, poll_ms / 1000.0))
