from __future__ import annotations

import random
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple

import httpx
from fastapi import HTTPException

from app.config import auth_headers, postgrest_base_url, require_supabase
from app.content_store import load_events
from app.models import Actor, CommandRequest, EmitEventRequest, TickRequest, VisitRequest
from app.planner_support import get_short_memory_store, persona_chat_client, planner_config
from app.postgrest import postgrest_select, postgrest_upsert_one
from app.queries import ensure_default_npcs_present, fetch_npcs_here, fetch_recent_summaries
from app.world_logic import (
    apply_effects_world,
    check_secret,
    check_sub_location,
    compute_event_budget,
    day_part,
    effect_location_changes,
    event_constraints_ok,
    event_participants,
    extract_event_type,
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
from planner.interfaces import PlannerContext


async def visit_world(
    *,
    req: VisitRequest,
    x_world_secret: Optional[str],
    emit_event_fn,
) -> Dict[str, Any]:
    check_secret(x_world_secret)
    require_supabase()

    user_dt = parse_user_time(req.user_time) or now_utc()
    visitor_key = req.visitor_key or "anon"
    sub_loc = check_sub_location(req.location_id, req.sub_location_id)

    async with httpx.AsyncClient(timeout=20.0) as client:
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
            last_visit = user_dt
        if user_dt < last_visit:
            user_dt = last_visit

        delta_sec = max(0, int((user_dt - last_visit).total_seconds()))
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

        await emit_event_fn(
            EmitEventRequest(
                world_id=req.world_id,
                layer_id=req.layer_id,
                location_id=req.location_id,
                type="world_tick",
                actor=Actor(kind="system", id="world_engine"),
                ts=user_dt.isoformat(),
                payload={
                    "delta_sec": delta_sec,
                    "location_id": req.location_id,
                    "sub_location_id": sub_loc,
                    "time_of_day": state.get("time_of_day"),
                    "weather": state.get("weather"),
                    "season": state.get("season"),
                    "moon_phase": state.get("moon_phase"),
                },
            ),
            x_world_secret=x_world_secret,
        )

        density = location_density(req.location_id)
        budget = compute_event_budget(delta_sec, density)
        recent_rows_desc = await postgrest_select(
            client,
            "world_event_log",
            f"?channel=eq.world:{req.world_id}:{req.location_id}&order=seq.desc&limit=50&select=seq,ts,payload",
        )
        recent_types_desc: List[str] = []
        last_seen_ts: Dict[str, datetime] = {}
        for row in recent_rows_desc or []:
            if not isinstance(row, dict):
                continue
            event_type = extract_event_type(row)
            if not event_type:
                continue
            recent_types_desc.append(event_type)
            if event_type not in last_seen_ts and isinstance(row.get("ts"), str):
                try:
                    last_seen_ts[event_type] = datetime.fromisoformat(row["ts"].replace("Z", "+00:00")).astimezone(
                        timezone.utc
                    )
                except Exception:
                    pass

        defs = load_events()
        seed = stable_seed(req.layer_id, req.location_id, last_visit.isoformat(), user_dt.isoformat(), visitor_key)
        rng = random.Random(seed)
        selected: List[Dict[str, Any]] = []
        selected_ids: set[str] = set()
        reserved_locations: Dict[str, str] = {}
        candidates_count_total = 0
        excluded_by_constraints = 0
        excluded_by_cooldown = 0
        excluded_by_conflict = 0
        reduced_by_recent = 0
        excluded_by_recent_zero = 0

        for _ in range(budget):
            weighted: List[Tuple[Dict[str, Any], float]] = []
            for definition in defs:
                event_id = str(definition.get("id") or "")
                if not event_id or event_id in selected_ids:
                    continue
                loc = str(definition.get("location_id") or "")
                if loc and loc != req.location_id:
                    continue
                if not event_constraints_ok(definition, state):
                    excluded_by_constraints += 1
                    continue
                probability = float(definition.get("probability") or 0.0)
                if probability <= 0:
                    continue
                candidates_count_total += 1
                cooldown_h = float(definition.get("cooldown_hours") or 0.0)
                if cooldown_h > 0 and event_id in last_seen_ts:
                    if (user_dt - last_seen_ts[event_id]).total_seconds() < cooldown_h * 3600:
                        excluded_by_cooldown += 1
                        continue
                rw = recent_weight(event_id, recent_types_desc)
                if rw < 1.0:
                    reduced_by_recent += 1
                weight = probability * rw
                if weight <= 0:
                    excluded_by_recent_zero += 1
                    continue
                changes = effect_location_changes(definition)
                if any(npc_id in reserved_locations and reserved_locations[npc_id] != new_loc for npc_id, new_loc in changes):
                    excluded_by_conflict += 1
                    continue
                weighted.append((definition, weight))

            total = sum(weight for _, weight in weighted)
            if total <= 0:
                break
            pick = rng.random() * total
            acc = 0.0
            chosen: Optional[Dict[str, Any]] = None
            for definition, weight in weighted:
                acc += weight
                if acc >= pick:
                    chosen = definition
                    break
            if not chosen:
                break
            selected.append(chosen)
            selected_ids.add(str(chosen.get("id")))
            for npc_id, new_loc in effect_location_changes(chosen):
                reserved_locations[npc_id] = new_loc
            state = apply_effects_world(state, chosen)

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

        npc_state_changes: List[Dict[str, Any]] = []
        for definition in selected:
            for npc_id, patch in npc_effect_patches(definition):
                new_loc = str(patch.get("location_id") or "")
                await postgrest_upsert_one(
                    client,
                    "world_npc_state",
                    {
                        "world_id": req.world_id,
                        "npc_id": npc_id,
                        "location_id": new_loc,
                        "action": patch.get("action"),
                        "emotion": patch.get("emotion"),
                        "updated_at": user_dt.isoformat(),
                    },
                    on_conflict="world_id,npc_id",
                )
                if new_loc:
                    npc_state_changes.append({"id": npc_id, "location_id": new_loc})

        recent_events: List[Dict[str, Any]] = []
        if selected:
            step = max(1, int(delta_sec / (len(selected) + 1))) if delta_sec > 0 else 0
            for index, definition in enumerate(selected):
                event_id = str(definition.get("id") or "event")
                payload = definition.get("payload") if isinstance(definition.get("payload"), dict) else {}
                summary = str(payload.get("summary") or "").strip()
                participants = event_participants(definition)
                log_type = str(definition.get("log_type") or "system")
                ev_ts = user_dt if step == 0 else (last_visit + timedelta(seconds=step * (index + 1)))
                ev_ts = min(ev_ts, user_dt)
                actor: Optional[Actor] = None
                if log_type in ("npc_action", "npc_say") and participants:
                    actor = Actor(kind="npc", id=participants[0])
                await emit_event_fn(
                    EmitEventRequest(
                        world_id=req.world_id,
                        layer_id=req.layer_id,
                        location_id=req.location_id,
                        type=log_type,
                        actor=actor,
                        ts=ev_ts.isoformat(),
                        payload={
                            "event_type": event_id,
                            "summary": summary,
                            "participants": participants,
                            "sub_location_id": sub_loc,
                        },
                    ),
                    x_world_secret=x_world_secret,
                )
                if summary:
                    recent_events.append({"event_type": event_id, "summary": summary, "created_at": ev_ts.isoformat()})

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
                "picked_event_types": [str(definition.get("id") or "") for definition in selected],
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


async def submit_command(*, req: CommandRequest, x_world_secret: Optional[str]) -> Dict[str, Any]:
    check_secret(x_world_secret)
    require_supabase()
    url = postgrest_base_url().rstrip("/") + "/world_command_log"
    headers = auth_headers()
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
        response = await client.post(url, headers=headers, json=row)
        if response.status_code == 409:
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
        if response.status_code >= 400:
            raise HTTPException(status_code=500, detail=f"command_insert_failed: {response.status_code} {response.text}")
        inserted = response.json()
        cmd = inserted[0] if isinstance(inserted, list) and inserted else inserted
        return {"ok": True, "command_id": cmd.get("id"), "correlation_id": cmd.get("correlation_id"), "status": cmd.get("status")}


async def tick_world(
    *,
    req: TickRequest,
    x_world_secret: Optional[str],
    emit_event_fn,
) -> Dict[str, Any]:
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

        emitted = await emit_event_fn(
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
        try:
            if loc:
                await ensure_default_npcs_present(
                    client,
                    world_id=req.world_id,
                    location_id=loc,
                    default_npc_ids=[],
                )
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

                    planned, _next_mem = await maybe_plan_reactions(
                        cfg=planner_config(),
                        ctx=ctx,
                        short_memory=store,
                        speech_generator=_speech,
                        npc_dialogue_llm_generate=_npc_dialogue_llm if llm is not None else None,
                    )
                    for planned_event in planned or []:
                        result = await emit_event_fn(
                            EmitEventRequest(
                                world_id=req.world_id,
                                layer_id=req.layer_id,
                                location_id=loc,
                                type=planned_event.type,
                                actor=Actor(kind=planned_event.actor.kind, id=planned_event.actor.id),
                                ts=planned_event.ts.isoformat(),
                                payload=planned_event.payload,
                            ),
                            x_world_secret=x_world_secret,
                        )
                        if isinstance(result, dict) and isinstance(result.get("event"), dict):
                            planned_events.append(result["event"])
        except Exception:
            planned_events = []

        return {"ok": True, "world_state": state, "planned_events": planned_events, **(emitted or {})}


async def get_command(*, command_id: str, x_world_secret: Optional[str]) -> Dict[str, Any]:
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
        return {"ok": True, "command": rows[0] if isinstance(rows[0], dict) else {}}


async def list_commands(*, world_id: str, status: str, limit: int, x_world_secret: Optional[str]) -> Dict[str, Any]:
    check_secret(x_world_secret)
    require_supabase()
    wid = str(world_id or "").strip()
    if not wid:
        raise HTTPException(status_code=400, detail="missing_world_id")
    n = max(1, min(int(limit or 20), 50))
    where = f"?world_id=eq.{wid}"
    st = str(status or "").strip()
    if st:
        parts = [p.strip() for p in st.split(",") if p.strip()]
        where += f"&status={'eq.' + parts[0] if len(parts) == 1 else 'in.(' + ','.join(parts) + ')'}"
    where += f"&order=created_at.desc&limit={n}&select=id,correlation_id,type,status,error_code,error_message,created_at,updated_at"
    async with httpx.AsyncClient(timeout=20.0) as client:
        rows = await postgrest_select(client, "world_command_log", where)
        return {"ok": True, "commands": rows or []}
