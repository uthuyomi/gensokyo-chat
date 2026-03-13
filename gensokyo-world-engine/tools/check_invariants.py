from __future__ import annotations

import os
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Set, Tuple

import httpx

from content_loader import load_locations


def env(name: str, default: str = "") -> str:
    return str(os.environ.get(name, default) or "")


SUPABASE_URL = env("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = env("SUPABASE_SERVICE_ROLE_KEY")
SUPABASE_SCHEMA = env("SUPABASE_SCHEMA", "public")


def auth_headers() -> Dict[str, str]:
    return {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Accept-Profile": SUPABASE_SCHEMA,
        "Content-Profile": SUPABASE_SCHEMA,
    }


def postgrest_base_url() -> str:
    return SUPABASE_URL.rstrip("/") + "/rest/v1"


def table_url(table: str) -> str:
    return postgrest_base_url().rstrip("/") + f"/{table}"


def parse_dt(s: Optional[str]) -> Optional[datetime]:
    if not s:
        return None
    try:
        dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc)
    except Exception:
        return None


async def select(client: httpx.AsyncClient, table: str, query: str) -> Any:
    r = await client.get(table_url(table) + query, headers=auth_headers())
    r.raise_for_status()
    return r.json()


def build_location_sets() -> Tuple[Set[str], Dict[str, str]]:
    data = load_locations()
    loc_ids: Set[str] = set()
    sub_parent: Dict[str, str] = {}
    for loc in data.get("locations", []) or []:
        if isinstance(loc, dict) and isinstance(loc.get("id"), str) and loc["id"]:
            loc_ids.add(loc["id"])
    for sub in data.get("sub_locations", []) or []:
        if not isinstance(sub, dict):
            continue
        sid = sub.get("id")
        parent = sub.get("parent")
        if isinstance(sid, str) and sid and isinstance(parent, str) and parent:
            sub_parent[sid] = parent
    return loc_ids, sub_parent


async def main():
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        print("[check] SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY missing; skip")
        return

    loc_ids, sub_parent = build_location_sets()
    errors: List[str] = []

    async with httpx.AsyncClient(timeout=20.0) as client:
        npcs = await select(client, "world_npc_state", "?select=world_id,npc_id,location_id,updated_at&limit=5000")
        for r in npcs or []:
            if not isinstance(r, dict):
                continue
            loc = str(r.get("location_id") or "")
            if loc and loc not in loc_ids:
                errors.append(f"npc {r.get('npc_id')} has unknown location_id={loc}")

        visits = await select(client, "world_visits", "?select=world_id,visitor_key,location_id,last_visit&limit=5000")
        now = datetime.now(timezone.utc)
        for r in visits or []:
            if not isinstance(r, dict):
                continue
            lv = parse_dt(r.get("last_visit"))
            if lv and lv > now:
                errors.append(
                    f"visit future last_visit world={r.get('world_id')} key={r.get('visitor_key')} loc={r.get('location_id')}"
                )

        states = await select(client, "world_state", "?select=world_id,location_id,time_of_day,updated_at&limit=5000")
        allowed = {"morning", "day", "evening", "night"}
        for r in states or []:
            if not isinstance(r, dict):
                continue
            tod = str(r.get("time_of_day") or "")
            if tod and tod not in allowed:
                errors.append(f"world_state invalid time_of_day={tod} world={r.get('world_id')} loc={r.get('location_id')}")

    if errors:
        print("[check] FAIL")
        for e in errors[:100]:
            print(" -", e)
        raise SystemExit(1)

    print("[check] OK")


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())

