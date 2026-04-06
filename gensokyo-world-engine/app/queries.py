from __future__ import annotations

from typing import Any, Dict, List, Optional

import httpx

from app.models import Actor, EmitEventRequest
from app.postgrest import postgrest_select, postgrest_upsert_one
from app.world_logic import (
    check_secret,
    day_part,
    extract_event_type,
    extract_summary,
    is_uuid_like,
    now_utc,
    season_of,
)

from planner.interfaces import NpcSnapshot, UserSnapshot


async def fetch_recent_summaries(
    client: httpx.AsyncClient,
    *,
    world_id: str,
    location_id: str,
    limit: int = 6,
) -> str:
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
        for row in rows:
            if not isinstance(row, dict):
                continue
            payload = row.get("payload") if isinstance(row.get("payload"), dict) else {}
            summary = str(payload.get("summary") or "").strip()
            if not summary:
                continue
            if parts and parts[-1] == summary:
                continue
            parts.append(summary)
        if not parts:
            return ""
        return " / ".join(parts[-4:])
    except Exception:
        return ""


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
    row = rows[0] if isinstance(rows[0], dict) else {}
    return UserSnapshot(
        user_id=str(row.get("user_id") or ""),
        location_id=str(row.get("location_id") or ""),
        sub_location_id=str(row.get("sub_location_id")) if row.get("sub_location_id") is not None else None,
        inventory=row.get("inventory") if isinstance(row.get("inventory"), dict) else {},
        updated_at=str(row.get("updated_at")) if row.get("updated_at") is not None else None,
    )


async def ensure_default_npcs_present(
    client: httpx.AsyncClient,
    *,
    world_id: str,
    location_id: str,
    default_npc_ids: List[str],
) -> None:
    if not default_npc_ids:
        return
    for npc_id in default_npc_ids:
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
    *,
    world_id: str,
    location_id: str,
) -> List[NpcSnapshot]:
    rows = await postgrest_select(
        client,
        "world_npc_state",
        f"?world_id=eq.{world_id}&location_id=eq.{location_id}&select=npc_id,location_id,action,emotion,updated_at",
    )
    out: List[NpcSnapshot] = []
    for row in rows or []:
        if not isinstance(row, dict) or not isinstance(row.get("npc_id"), str):
            continue
        out.append(
            NpcSnapshot(
                npc_id=str(row.get("npc_id") or ""),
                location_id=str(row.get("location_id") or ""),
                action=str(row.get("action")) if row.get("action") is not None else None,
                emotion=str(row.get("emotion")) if row.get("emotion") is not None else None,
                updated_at=str(row.get("updated_at")) if row.get("updated_at") is not None else None,
            )
        )
    return out


async def get_world_state(
    *,
    world_id: str,
    location_id: str,
    x_world_secret: Optional[str],
) -> Dict[str, Any]:
    check_secret(x_world_secret)
    loc = location_id or ""
    async with httpx.AsyncClient(timeout=20.0) as client:
        rows = await postgrest_select(
            client,
            "world_state",
            f"?world_id=eq.{world_id}&location_id=eq.{loc}&select=*",
        )
        if rows:
            return rows[0]

        now = now_utc()
        return await postgrest_upsert_one(
            client,
            "world_state",
            {
                "world_id": world_id,
                "location_id": loc,
                "time_of_day": day_part(now),
                "weather": "clear",
                "season": season_of(now),
                "moon_phase": "unknown",
                "anomaly": None,
                "updated_at": now.isoformat(),
            },
            on_conflict="world_id,location_id",
        )


async def get_recent_events(
    *,
    world_id: str,
    location_id: str,
    limit: int,
    x_world_secret: Optional[str],
) -> Dict[str, List[Dict[str, Any]]]:
    check_secret(x_world_secret)
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
        out: List[Dict[str, Any]] = []
        for row in rows:
            if not isinstance(row, dict):
                continue
            event_type = extract_event_type(row) or str(row.get("type") or "event")
            summary = extract_summary(row) or ""
            created_at = row.get("ts")
            if not summary:
                continue
            out.append({"event_type": event_type, "summary": summary, "created_at": created_at})
        return {"recent_events": out}


async def get_npcs(
    *,
    world_id: str,
    location_id: str,
    x_world_secret: Optional[str],
) -> Dict[str, List[Dict[str, Any]]]:
    check_secret(x_world_secret)
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
                "id": row.get("npc_id"),
                "location_id": row.get("location_id") or None,
                "action": row.get("action"),
                "emotion": row.get("emotion"),
            }
            for row in rows or []
        ]
        return {"npcs": npcs}
