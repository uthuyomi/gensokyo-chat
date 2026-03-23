from __future__ import annotations

from typing import Any, Dict, List, Optional

import httpx

from app.postgrest import (
    postgrest_insert_many,
    postgrest_insert_one,
    postgrest_rpc,
    postgrest_select,
    postgrest_update,
    postgrest_upsert_one,
)


async def fetch_story_events(
    client: httpx.AsyncClient,
    *,
    world_id: str,
    status: str = "",
    limit: int = 20,
) -> List[Dict[str, Any]]:
    n = max(1, min(int(limit or 20), 100))
    query = f"?world_id=eq.{world_id}&order=created_at.desc&limit={n}&select=*"
    if status:
        parts = [part.strip() for part in status.split(",") if part.strip()]
        if len(parts) == 1:
            query = f"?world_id=eq.{world_id}&status=eq.{parts[0]}&order=created_at.desc&limit={n}&select=*"
        elif parts:
            query = f"?world_id=eq.{world_id}&status=in.({','.join(parts)})&order=created_at.desc&limit={n}&select=*"
    return list(await postgrest_select(client, "world_story_events", query) or [])


async def fetch_story_event(client: httpx.AsyncClient, *, event_id: str) -> Optional[Dict[str, Any]]:
    rows = await postgrest_select(client, "world_story_events", f"?id=eq.{event_id}&select=*&limit=1")
    if rows and isinstance(rows[0], dict):
        return rows[0]
    return None


async def fetch_story_phases(client: httpx.AsyncClient, *, event_id: str) -> List[Dict[str, Any]]:
    return list(
        await postgrest_select(
            client,
            "world_story_phases",
            f"?event_id=eq.{event_id}&order=phase_order.asc&select=*",
        )
        or []
    )


async def fetch_story_beats(client: httpx.AsyncClient, *, event_id: str) -> List[Dict[str, Any]]:
    return list(
        await postgrest_select(
            client,
            "world_story_beats",
            f"?event_id=eq.{event_id}&order=created_at.asc&select=*",
        )
        or []
    )


async def fetch_story_cast(client: httpx.AsyncClient, *, event_id: str) -> List[Dict[str, Any]]:
    return list(
        await postgrest_select(
            client,
            "world_story_cast",
            f"?event_id=eq.{event_id}&order=created_at.asc&select=*",
        )
        or []
    )


async def fetch_story_actions(client: httpx.AsyncClient, *, event_id: str) -> List[Dict[str, Any]]:
    return list(
        await postgrest_select(
            client,
            "world_story_actions",
            f"?event_id=eq.{event_id}&order=created_at.asc&select=*",
        )
        or []
    )


async def fetch_story_history(
    client: httpx.AsyncClient,
    *,
    world_id: str,
    event_id: Optional[str] = None,
    limit: int = 20,
) -> List[Dict[str, Any]]:
    n = max(1, min(int(limit or 20), 100))
    base = f"?world_id=eq.{world_id}&order=committed_at.desc&limit={n}&select=*"
    if event_id:
        base = f"?world_id=eq.{world_id}&event_id=eq.{event_id}&order=committed_at.desc&limit={n}&select=*"
    return list(await postgrest_select(client, "world_story_history", base) or [])


async def fetch_character_memories(
    client: httpx.AsyncClient,
    *,
    world_id: str,
    character_id: str,
    limit: int = 20,
) -> List[Dict[str, Any]]:
    n = max(1, min(int(limit or 20), 100))
    return list(
        await postgrest_select(
            client,
            "world_character_memories",
            f"?world_id=eq.{world_id}&character_id=eq.{character_id}&order=created_at.desc&limit={n}&select=*",
        )
        or []
    )


async def fetch_user_story_overlays(
    client: httpx.AsyncClient,
    *,
    world_id: str,
    user_id: str,
    limit: int = 20,
) -> List[Dict[str, Any]]:
    n = max(1, min(int(limit or 20), 100))
    return list(
        await postgrest_select(
            client,
            "world_user_story_overlays",
            f"?world_id=eq.{world_id}&user_id=eq.{user_id}&order=created_at.desc&limit={n}&select=*",
        )
        or []
    )


async def fetch_story_projections(
    client: httpx.AsyncClient,
    *,
    world_id: str,
    location_id: str = "",
    user_scope: str = "global",
) -> List[Dict[str, Any]]:
    return list(
        await postgrest_select(
            client,
            "world_story_projections",
            f"?world_id=eq.{world_id}&location_id=eq.{location_id}&user_scope=eq.{user_scope}&order=updated_at.desc&select=*",
        )
        or []
    )


async def insert_story_event(client: httpx.AsyncClient, row: Dict[str, Any]) -> Dict[str, Any]:
    return await postgrest_insert_one(client, "world_story_events", row)


async def insert_story_phases(client: httpx.AsyncClient, rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    return await postgrest_insert_many(client, "world_story_phases", rows)


async def insert_story_beats(client: httpx.AsyncClient, rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    return await postgrest_insert_many(client, "world_story_beats", rows)


async def insert_story_cast(client: httpx.AsyncClient, rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    return await postgrest_insert_many(client, "world_story_cast", rows)


async def insert_story_actions(client: httpx.AsyncClient, rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    return await postgrest_insert_many(client, "world_story_actions", rows)


async def insert_story_history(client: httpx.AsyncClient, rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    return await postgrest_insert_many(client, "world_story_history", rows)


async def insert_character_memories(client: httpx.AsyncClient, rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    return await postgrest_insert_many(client, "world_character_memories", rows)


async def insert_user_story_overlay(client: httpx.AsyncClient, row: Dict[str, Any]) -> Dict[str, Any]:
    return await postgrest_insert_one(client, "world_user_story_overlays", row)


async def upsert_story_projection(client: httpx.AsyncClient, row: Dict[str, Any]) -> Dict[str, Any]:
    return await postgrest_upsert_one(
        client,
        "world_story_projections",
        row,
        on_conflict="world_id,location_id,user_scope,projection_type",
    )


async def update_story_event(client: httpx.AsyncClient, *, event_id: str, patch: Dict[str, Any]) -> List[Dict[str, Any]]:
    return await postgrest_update(client, "world_story_events", f"?id=eq.{event_id}", patch)


async def update_story_phase(client: httpx.AsyncClient, *, phase_id: str, patch: Dict[str, Any]) -> List[Dict[str, Any]]:
    return await postgrest_update(client, "world_story_phases", f"?id=eq.{phase_id}", patch)


async def update_story_beat_status(
    client: httpx.AsyncClient,
    *,
    event_id: str,
    beat_code: str,
    patch: Dict[str, Any],
) -> List[Dict[str, Any]]:
    return await postgrest_update(
        client,
        "world_story_beats",
        f"?event_id=eq.{event_id}&beat_code=eq.{beat_code}",
        patch,
    )


async def rpc_story_refresh_projection(client: httpx.AsyncClient, *, event_id: str) -> Any:
    return await postgrest_rpc(client, "world_story_refresh_projection", {"p_event_id": event_id})


async def rpc_story_advance_phase(
    client: httpx.AsyncClient,
    *,
    event_id: str,
    phase_id: str,
    summary: Optional[str],
) -> Any:
    return await postgrest_rpc(
        client,
        "world_story_advance_phase",
        {"p_event_id": event_id, "p_phase_id": phase_id, "p_summary": summary},
    )
