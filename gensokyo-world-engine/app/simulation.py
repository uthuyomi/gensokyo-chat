from __future__ import annotations

import random
from datetime import datetime, timedelta
from typing import List, Optional

import httpx

from app.config import SUPABASE_SERVICE_ROLE_KEY, SUPABASE_URL, WORLD_ENGINE_SECRET, env
from app.content_store import load_locations
from app.models import Actor, EmitEventRequest, VisitRequest
from app.postgrest import postgrest_select, postgrest_upsert_one
from app.queries import ensure_default_npcs_present, fetch_npcs_here, fetch_recent_summaries
from app.world_logic import now_utc

from planner import maybe_plan_reactions
from planner.interfaces import PlannerContext
from world_simulator import WorldSimulatorConfig


def csv_env(name: str) -> List[str]:
    raw = (env(name, "") or "").strip()
    if not raw:
        return []
    out: List[str] = []
    for part in raw.split(","):
        item = part.strip()
        if item:
            out.append(item)
    return list(dict.fromkeys(out))


def world_simulator_config() -> WorldSimulatorConfig:
    enabled = env("GENSOKYO_WORLD_SIM_ENABLED", "0").strip() not in ("0", "false", "False")
    interval_sec = int(env("GENSOKYO_WORLD_SIM_INTERVAL_SEC", "30") or "30")
    return WorldSimulatorConfig(enabled=enabled, interval_sec=interval_sec)


async def fetch_world_ids(client: httpx.AsyncClient) -> List[str]:
    ids = csv_env("GENSOKYO_WORLD_SIM_WORLDS")
    if ids:
        return ids
    try:
        rows = await postgrest_select(client, "worlds", "?select=id&order=created_at.asc&limit=50")
        out: List[str] = []
        for row in rows or []:
            if isinstance(row, dict) and isinstance(row.get("id"), str) and row["id"].strip():
                out.append(row["id"].strip())
        if out:
            return out
    except Exception:
        pass
    return ["gensokyo_main"]


def content_location_ids() -> List[str]:
    data = load_locations()
    out: List[str] = []
    for loc in data.get("locations", []) or []:
        if isinstance(loc, dict) and isinstance(loc.get("id"), str) and loc["id"].strip():
            out.append(loc["id"].strip())
    return out


def location_neighbors(location_id: str) -> List[str]:
    data = load_locations()
    for loc in data.get("locations", []) or []:
        if not isinstance(loc, dict) or str(loc.get("id") or "") != location_id:
            continue
        neigh = loc.get("neighbors") if isinstance(loc.get("neighbors"), list) else []
        out = [str(x).strip() for x in neigh if isinstance(x, str) and x.strip()]
        return list(dict.fromkeys(out))
    return []


async def fetch_active_locations(
    client: httpx.AsyncClient,
    *,
    world_id: str,
    now: datetime,
    max_locations: int,
) -> List[str]:
    override = csv_env("GENSOKYO_WORLD_SIM_LOCATIONS")
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
        for row in rows or []:
            if isinstance(row, dict) and isinstance(row.get("location_id"), str) and row["location_id"].strip():
                out.append(row["location_id"].strip())
        out = list(dict.fromkeys(out))
        if out:
            return out
    except Exception:
        pass

    locs = content_location_ids()
    if locs:
        return locs[: max(1, int(max_locations or 1))]
    return ["hakurei_shrine"]


async def world_sim_tick_once(
    *,
    dt: datetime,
    visit_fn,
    emit_event_fn,
    planner_config_fn,
    get_short_memory_store_fn,
    persona_chat_client_fn,
) -> None:
    if not (SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY):
        return

    max_locations = max(1, min(20, int(env("GENSOKYO_WORLD_SIM_MAX_LOCATIONS", "2") or "2")))
    move_prob = max(0.0, min(1.0, float(env("GENSOKYO_WORLD_SIM_NPC_MOVE_PROB", "0.18") or "0.18")))

    async with httpx.AsyncClient(timeout=20.0) as client:
        world_ids = await fetch_world_ids(client)
        for world_id in world_ids:
            layer_id = "gensokyo"
            locs = await fetch_active_locations(client, world_id=world_id, now=dt, max_locations=max_locations)
            for location_id in locs:
                try:
                    await visit_fn(
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
                    pass

                await ensure_default_npcs_present(
                    client,
                    world_id=world_id,
                    location_id=location_id,
                    default_npc_ids=[],
                )
                npcs_here = await fetch_npcs_here(client, world_id=world_id, location_id=location_id)
                if npcs_here and move_prob > 0 and random.random() < move_prob:
                    neigh = location_neighbors(location_id)
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
                            await emit_event_fn(
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

                try:
                    await ensure_default_npcs_present(
                        client,
                        world_id=world_id,
                        location_id=location_id,
                        default_npc_ids=[],
                    )
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
                    store = get_short_memory_store_fn()
                    llm = persona_chat_client_fn()

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

                    planned, _next_mem = await maybe_plan_reactions(
                        cfg=planner_config_fn(),
                        ctx=ctx,
                        short_memory=store,
                        speech_generator=_speech,
                        npc_dialogue_llm_generate=_npc_dialogue_llm if llm is not None else None,
                    )
                    for planned_event in planned or []:
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
                            x_world_secret=WORLD_ENGINE_SECRET or None,
                        )
                except Exception:
                    pass
