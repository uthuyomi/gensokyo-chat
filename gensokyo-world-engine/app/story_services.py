from __future__ import annotations

from typing import Any, Dict, List, Optional

import httpx
from fastapi import HTTPException

from app.models import Actor, EmitEventRequest
from app.story_models import (
    CharacterMemoryInput,
    StoryAdvanceRequest,
    StoryEventCreateRequest,
    StoryHistoryInput,
    StoryParticipationRequest,
)
from app.story_repository import (
    fetch_character_memories,
    fetch_story_actions,
    fetch_story_beats,
    fetch_story_cast,
    fetch_story_event,
    fetch_story_events,
    fetch_story_history,
    fetch_story_phases,
    fetch_story_projections,
    fetch_user_story_overlays,
    insert_character_memories,
    insert_story_actions,
    insert_story_beats,
    insert_story_cast,
    insert_story_event,
    insert_story_history,
    insert_story_phases,
    insert_user_story_overlay,
    rpc_story_advance_phase,
    rpc_story_refresh_projection,
    update_story_beat_status,
    upsert_story_projection,
)
from app.world_logic import check_secret, is_uuid_like, now_utc


def _story_id(prefix: str, *parts: str) -> str:
    clean = [str(part or "").strip().replace(" ", "_") for part in parts if str(part or "").strip()]
    return ":".join([prefix, *clean, now_utc().strftime("%Y%m%d%H%M%S%f")])


def _find_phase_by_code(phases: List[Dict[str, Any]], phase_code: str) -> Optional[Dict[str, Any]]:
    for phase in phases:
        if str(phase.get("phase_code") or "") == phase_code:
            return phase
    return None


def _phase_id_map(phases: List[Dict[str, Any]]) -> Dict[str, str]:
    return {str(phase.get("phase_code") or ""): str(phase.get("id") or "") for phase in phases}


async def get_story_state(
    *,
    world_id: str,
    location_id: str,
    user_id: Optional[str],
    limit: int,
    x_world_secret: Optional[str],
) -> Dict[str, Any]:
    check_secret(x_world_secret)
    async with httpx.AsyncClient(timeout=20.0) as client:
        active_events = await fetch_story_events(client, world_id=world_id, status="active,scheduled", limit=limit)
        projections = await fetch_story_projections(client, world_id=world_id, location_id=location_id or "", user_scope="global")
        if location_id:
            global_projections = await fetch_story_projections(client, world_id=world_id, location_id="", user_scope="global")
            seen = {f"{row.get('location_id')}::{row.get('projection_type')}" for row in projections}
            for row in global_projections:
                key = f"{row.get('location_id')}::{row.get('projection_type')}"
                if key not in seen:
                    projections.append(row)
        user_overlays: List[Dict[str, Any]] = []
        if user_id and is_uuid_like(user_id):
            user_overlays = await fetch_user_story_overlays(client, world_id=world_id, user_id=user_id, limit=min(limit, 20))
        recent_history = await fetch_story_history(client, world_id=world_id, limit=min(limit, 20))
        return {
            "world_id": world_id,
            "location_id": location_id or "",
            "active_events": active_events,
            "projections": projections,
            "recent_history": recent_history,
            "user_overlays": user_overlays,
        }


async def list_story_events(
    *,
    world_id: str,
    status: str,
    limit: int,
    x_world_secret: Optional[str],
) -> Dict[str, Any]:
    check_secret(x_world_secret)
    async with httpx.AsyncClient(timeout=20.0) as client:
        events = await fetch_story_events(client, world_id=world_id, status=status, limit=limit)
        return {"world_id": world_id, "events": events}


async def get_story_event_detail(*, event_id: str, x_world_secret: Optional[str]) -> Dict[str, Any]:
    check_secret(x_world_secret)
    async with httpx.AsyncClient(timeout=20.0) as client:
        event = await fetch_story_event(client, event_id=event_id)
        if not event:
            raise HTTPException(status_code=404, detail="story_event_not_found")
        phases = await fetch_story_phases(client, event_id=event_id)
        beats = await fetch_story_beats(client, event_id=event_id)
        cast = await fetch_story_cast(client, event_id=event_id)
        actions = await fetch_story_actions(client, event_id=event_id)
        history = await fetch_story_history(client, world_id=str(event.get("world_id") or ""), event_id=event_id, limit=50)
        return {
            "event": event,
            "phases": phases,
            "beats": beats,
            "cast": cast,
            "actions": actions,
            "history": history,
        }


async def get_story_history_view(
    *,
    world_id: str,
    character_id: str,
    user_id: Optional[str],
    limit: int,
    x_world_secret: Optional[str],
) -> Dict[str, Any]:
    check_secret(x_world_secret)
    async with httpx.AsyncClient(timeout=20.0) as client:
        history = await fetch_story_history(client, world_id=world_id, limit=limit)
        memories: List[Dict[str, Any]] = []
        overlays: List[Dict[str, Any]] = []
        if character_id:
            memories = await fetch_character_memories(client, world_id=world_id, character_id=character_id, limit=limit)
        if user_id and is_uuid_like(user_id):
            overlays = await fetch_user_story_overlays(client, world_id=world_id, user_id=user_id, limit=limit)
        return {
            "world_id": world_id,
            "character_id": character_id or None,
            "history": history,
            "character_memories": memories,
            "user_overlays": overlays,
        }


def _build_history_rows(
    *,
    req_rows: List[StoryHistoryInput],
    world_id: str,
    event_id: str,
    phase_id_map: Dict[str, str],
) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    for item in req_rows:
        phase_id = phase_id_map.get(item.phase_code or "", None)
        rows.append(
            {
                "id": _story_id(event_id, "history", item.history_kind),
                "world_id": world_id,
                "event_id": event_id,
                "phase_id": phase_id,
                "history_kind": item.history_kind,
                "fact_summary": item.fact_summary,
                "location_id": item.location_id,
                "actor_ids": item.actor_ids,
                "payload": item.payload,
                "committed_at": item.committed_at or now_utc().isoformat(),
            }
        )
    return rows


def _build_memory_rows(
    *,
    req_rows: List[CharacterMemoryInput],
    world_id: str,
    event_id: str,
) -> List[Dict[str, Any]]:
    rows: List[Dict[str, Any]] = []
    for item in req_rows:
        rows.append(
            {
                "id": _story_id(event_id, "memory", item.character_id),
                "world_id": world_id,
                "character_id": item.character_id,
                "event_id": event_id,
                "history_id": item.history_ref,
                "memory_type": item.memory_type,
                "importance": item.importance,
                "summary": item.summary,
                "stance": item.stance,
                "knows_truth": item.knows_truth,
                "payload": item.payload,
            }
        )
    return rows


async def create_story_event(
    *,
    req: StoryEventCreateRequest,
    x_world_secret: Optional[str],
    emit_event_fn,
) -> Dict[str, Any]:
    check_secret(x_world_secret)
    event_id = f"story:{req.world_id}:{req.event_code}"

    async with httpx.AsyncClient(timeout=20.0) as client:
        existing = await fetch_story_event(client, event_id=event_id)
        if existing:
            raise HTTPException(status_code=409, detail="story_event_already_exists")

        sorted_phases = sorted(req.phases, key=lambda phase: phase.phase_order)
        current_phase = next((phase for phase in sorted_phases if phase.status == "active"), None)
        event_row = await insert_story_event(
            client,
            {
                "id": event_id,
                "world_id": req.world_id,
                "event_code": req.event_code,
                "title": req.title,
                "theme": req.theme,
                "canon_level": req.canon_level,
                "status": req.status,
                "start_at": req.start_at,
                "end_at": req.end_at,
                "current_phase_id": f"{event_id}:phase:{current_phase.phase_code}" if current_phase else None,
                "current_phase_order": current_phase.phase_order if current_phase else None,
                "lead_location_id": req.lead_location_id,
                "organizer_character_id": req.organizer_character_id,
                "synopsis": req.synopsis,
                "narrative_hook": req.narrative_hook,
                "payload": req.payload,
                "metadata": req.metadata,
            },
        )

        phase_rows: List[Dict[str, Any]] = []
        beat_rows: List[Dict[str, Any]] = []
        for phase in sorted_phases:
            phase_id = f"{event_id}:phase:{phase.phase_code}"
            phase_rows.append(
                {
                    "id": phase_id,
                    "event_id": event_id,
                    "phase_code": phase.phase_code,
                    "phase_order": phase.phase_order,
                    "title": phase.title,
                    "status": phase.status,
                    "summary": phase.summary,
                    "start_condition": phase.start_condition,
                    "end_condition": phase.end_condition,
                    "required_beats": phase.required_beats,
                    "allowed_locations": phase.allowed_locations,
                    "active_cast": phase.active_cast,
                    "starts_at": phase.starts_at,
                    "ends_at": phase.ends_at,
                    "metadata": phase.metadata,
                }
            )
            for beat in phase.beats:
                beat_rows.append(
                    {
                        "id": f"{event_id}:beat:{beat.beat_code}",
                        "event_id": event_id,
                        "phase_id": phase_id,
                        "beat_code": beat.beat_code,
                        "beat_kind": beat.beat_kind,
                        "title": beat.title,
                        "summary": beat.summary,
                        "location_id": beat.location_id,
                        "actor_ids": beat.actor_ids,
                        "is_required": beat.is_required,
                        "status": beat.status,
                        "happens_at": beat.happens_at,
                        "payload": beat.payload,
                    }
                )

        cast_rows = [
            {
                "id": f"{event_id}:cast:{cast.character_id}",
                "event_id": event_id,
                "character_id": cast.character_id,
                "role_type": cast.role_type,
                "knowledge_level": cast.knowledge_level,
                "must_appear": cast.must_appear,
                "primary_location_id": cast.primary_location_id,
                "availability": cast.availability,
                "notes": cast.notes,
            }
            for cast in req.cast
        ]

        phase_id_map = {phase.phase_code: f"{event_id}:phase:{phase.phase_code}" for phase in sorted_phases}
        action_rows = [
            {
                "id": f"{event_id}:action:{action.action_code}",
                "event_id": event_id,
                "phase_id": phase_id_map.get(action.phase_code or "", None),
                "action_code": action.action_code,
                "title": action.title,
                "description": action.description,
                "action_kind": action.action_kind,
                "location_id": action.location_id,
                "actor_id": action.actor_id,
                "is_repeatable": action.is_repeatable,
                "is_active": action.is_active,
                "result_summary": action.result_summary,
                "payload": action.payload,
            }
            for action in req.actions
        ]

        history_rows = _build_history_rows(req_rows=req.initial_history, world_id=req.world_id, event_id=event_id, phase_id_map=phase_id_map)
        memory_rows = _build_memory_rows(req_rows=req.initial_memories, world_id=req.world_id, event_id=event_id)

        if phase_rows:
            await insert_story_phases(client, phase_rows)
        if beat_rows:
            await insert_story_beats(client, beat_rows)
        if cast_rows:
            await insert_story_cast(client, cast_rows)
        if action_rows:
            await insert_story_actions(client, action_rows)
        if history_rows:
            await insert_story_history(client, history_rows)
        if memory_rows:
            await insert_character_memories(client, memory_rows)

        await rpc_story_refresh_projection(client, event_id=event_id)

        if emit_event_fn:
            await emit_event_fn(
                EmitEventRequest(
                    world_id=req.world_id,
                    layer_id="gensokyo",
                    location_id=req.lead_location_id,
                    type="system",
                    actor=Actor(kind="system", id="world_story_engine"),
                    payload={
                        "event_type": "story_event_created",
                        "event_id": event_id,
                        "title": req.title,
                        "summary": req.synopsis or req.narrative_hook or req.title,
                    },
                ),
                x_world_secret=x_world_secret,
            )

        return {"ok": True, "event": event_row, "phase_count": len(phase_rows), "beat_count": len(beat_rows)}


async def advance_story_event(
    *,
    event_id: str,
    req: StoryAdvanceRequest,
    x_world_secret: Optional[str],
    emit_event_fn,
) -> Dict[str, Any]:
    check_secret(x_world_secret)
    async with httpx.AsyncClient(timeout=20.0) as client:
        event = await fetch_story_event(client, event_id=event_id)
        if not event:
            raise HTTPException(status_code=404, detail="story_event_not_found")

        phases = await fetch_story_phases(client, event_id=event_id)
        phase: Optional[Dict[str, Any]] = None
        if req.phase_id:
            phase = next((row for row in phases if str(row.get("id") or "") == req.phase_id), None)
        elif req.phase_code:
            phase = _find_phase_by_code(phases, req.phase_code)
        else:
            current_order = int(event.get("current_phase_order") or 0)
            phase = next((row for row in phases if int(row.get("phase_order") or 0) == current_order + 1), None)

        if not phase:
            raise HTTPException(status_code=400, detail="story_phase_not_found")

        result = await rpc_story_advance_phase(client, event_id=event_id, phase_id=str(phase.get("id") or ""), summary=req.summary)
        for beat_code in req.committed_beats:
            await update_story_beat_status(
                client,
                event_id=event_id,
                beat_code=beat_code,
                patch={"status": "committed", "happens_at": now_utc().isoformat(), "updated_at": now_utc().isoformat()},
            )

        phase_id_map = _phase_id_map(phases)
        history_rows = _build_history_rows(
            req_rows=req.history,
            world_id=str(event.get("world_id") or ""),
            event_id=event_id,
            phase_id_map=phase_id_map,
        )
        memory_rows = _build_memory_rows(
            req_rows=req.memories,
            world_id=str(event.get("world_id") or ""),
            event_id=event_id,
        )
        if history_rows:
            await insert_story_history(client, history_rows)
        if memory_rows:
            await insert_character_memories(client, memory_rows)

        await rpc_story_refresh_projection(client, event_id=event_id)

        if emit_event_fn:
            await emit_event_fn(
                EmitEventRequest(
                    world_id=str(event.get("world_id") or ""),
                    layer_id="gensokyo",
                    location_id=str(event.get("lead_location_id") or "") or None,
                    type="system",
                    actor=Actor(kind="system", id="world_story_engine"),
                    payload={
                        "event_type": "story_phase_changed",
                        "event_id": event_id,
                        "phase_id": phase.get("id"),
                        "phase_code": phase.get("phase_code"),
                        "phase_title": phase.get("title"),
                        "summary": req.summary or phase.get("summary"),
                    },
                ),
                x_world_secret=x_world_secret,
            )

        return {"ok": True, "advance": result}


async def participate_story_event(
    *,
    event_id: str,
    req: StoryParticipationRequest,
    x_world_secret: Optional[str],
    emit_event_fn,
) -> Dict[str, Any]:
    check_secret(x_world_secret)
    if not is_uuid_like(req.user_id):
        raise HTTPException(status_code=400, detail="invalid_user_id")

    async with httpx.AsyncClient(timeout=20.0) as client:
        event = await fetch_story_event(client, event_id=event_id)
        if not event:
            raise HTTPException(status_code=404, detail="story_event_not_found")
        if str(event.get("world_id") or "") != req.world_id:
            raise HTTPException(status_code=400, detail="story_event_world_mismatch")
        phases = await fetch_story_phases(client, event_id=event_id)
        phase = _find_phase_by_code(phases, req.phase_code) if req.phase_code else None

        overlay = await insert_user_story_overlay(
            client,
            {
                "id": _story_id(event_id, "overlay", req.user_id),
                "world_id": req.world_id,
                "user_id": req.user_id,
                "event_id": event_id,
                "phase_id": str(phase.get("id") or "") if phase else None,
                "overlay_type": req.overlay_type,
                "summary": req.summary,
                "payload": {
                    **req.payload,
                    "action_code": req.action_code,
                    "location_id": req.location_id,
                },
            },
        )

        await upsert_story_projection(
            client,
            {
                "world_id": req.world_id,
                "location_id": req.location_id or "",
                "user_scope": req.user_id,
                "projection_type": "user_participation",
                "event_id": event_id,
                "title": str(event.get("title") or ""),
                "phase_label": str(phase.get("title") or "") if phase else None,
                "summary": req.summary,
                "actor_ids": [str(event.get("organizer_character_id") or "")] if event.get("organizer_character_id") else [],
                "payload": {"overlay_type": req.overlay_type, "action_code": req.action_code, **req.payload},
                "updated_at": now_utc().isoformat(),
            },
        )

        if emit_event_fn:
            await emit_event_fn(
                EmitEventRequest(
                    world_id=req.world_id,
                    layer_id="gensokyo",
                    location_id=req.location_id or str(event.get("lead_location_id") or "") or None,
                    type="system",
                    actor=Actor(kind="user", id=req.user_id),
                    payload={
                        "event_type": "story_participation",
                        "event_id": event_id,
                        "action_code": req.action_code,
                        "summary": req.summary,
                    },
                ),
                x_world_secret=x_world_secret,
            )

        return {"ok": True, "overlay": overlay}
