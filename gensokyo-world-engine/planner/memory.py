from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Dict, Optional

import httpx


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


class ShortMemoryStore:
    """
    Short-term, per NPC state used for cooldown / throttling.

    Backends are swappable. Initial backend is Supabase JSON, but callers must be tolerant of missing data.
    """

    async def get_state(self, world_id: str, npc_id: str) -> Dict[str, Any]:
        raise NotImplementedError

    async def put_state(self, world_id: str, npc_id: str, state: Dict[str, Any]) -> None:
        raise NotImplementedError


class InMemoryShortMemoryStore(ShortMemoryStore):
    def __init__(self):
        self._data: Dict[str, Dict[str, Any]] = {}

    def _key(self, world_id: str, npc_id: str) -> str:
        return f"{world_id}::{npc_id}"

    async def get_state(self, world_id: str, npc_id: str) -> Dict[str, Any]:
        return dict(self._data.get(self._key(world_id, npc_id), {}) or {})

    async def put_state(self, world_id: str, npc_id: str, state: Dict[str, Any]) -> None:
        self._data[self._key(world_id, npc_id)] = dict(state or {})


@dataclass(frozen=True)
class SupabaseConn:
    base_url: str
    headers: Dict[str, str]


class SupabaseShortMemoryStore(ShortMemoryStore):
    def __init__(self, conn: SupabaseConn):
        self._conn = conn

    async def get_state(self, world_id: str, npc_id: str) -> Dict[str, Any]:
        url = self._conn.base_url.rstrip("/") + "/world_npc_memory_short"
        params = {
            "world_id": f"eq.{world_id}",
            "npc_id": f"eq.{npc_id}",
            "select": "state",
            "limit": "1",
        }
        async with httpx.AsyncClient(timeout=10.0) as client:
            r = await client.get(url, headers=self._conn.headers, params=params)
            if r.status_code >= 400:
                return {}
            rows = r.json()
            if not rows:
                return {}
            row = rows[0] if isinstance(rows[0], dict) else {}
            state = row.get("state") if isinstance(row.get("state"), dict) else {}
            return dict(state)

    async def put_state(self, world_id: str, npc_id: str, state: Dict[str, Any]) -> None:
        url = self._conn.base_url.rstrip("/") + "/world_npc_memory_short"
        payload = {
            "world_id": world_id,
            "npc_id": npc_id,
            "state": state or {},
            "updated_at": _now_iso(),
        }
        async with httpx.AsyncClient(timeout=10.0) as client:
            # PostgREST upsert via resolution=merge-duplicates
            await client.post(
                url,
                headers={
                    **self._conn.headers,
                    "Prefer": "resolution=merge-duplicates,return=minimal",
                },
                json=payload,
            )


def parse_dt(value: Optional[str]) -> Optional[datetime]:
    if not value or not isinstance(value, str):
        return None
    try:
        dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc)
    except Exception:
        return None

