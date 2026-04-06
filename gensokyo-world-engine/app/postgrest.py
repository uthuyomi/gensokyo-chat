from __future__ import annotations

from typing import Any, Dict, List, Optional

import httpx
from fastapi import HTTPException

from app.config import auth_headers, postgrest_base_url


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
    response = await client.get(table_url(table) + query, headers=headers)
    if response.status_code >= 400:
        raise HTTPException(status_code=500, detail=f"select_failed:{table}:{response.status_code}:{response.text}")
    return response.json()


async def postgrest_upsert_one(
    client: httpx.AsyncClient,
    table: str,
    row: Dict[str, Any],
    on_conflict: str,
) -> Dict[str, Any]:
    headers = auth_headers()
    headers["Prefer"] = "resolution=merge-duplicates,return=representation"
    response = await client.post(table_url(table) + f"?on_conflict={on_conflict}", headers=headers, json=row)
    if response.status_code >= 400:
        raise HTTPException(status_code=500, detail=f"upsert_failed:{table}:{response.status_code}:{response.text}")
    data = response.json()
    if isinstance(data, list) and data:
        return data[0]
    if isinstance(data, dict):
        return data
    return row


async def postgrest_insert_one(
    client: httpx.AsyncClient,
    table: str,
    row: Dict[str, Any],
) -> Dict[str, Any]:
    headers = auth_headers()
    headers["Prefer"] = "return=representation"
    response = await client.post(table_url(table), headers=headers, json=row)
    if response.status_code >= 400:
        raise HTTPException(status_code=500, detail=f"insert_failed:{table}:{response.status_code}:{response.text}")
    data = response.json()
    if isinstance(data, list) and data:
        return data[0]
    if isinstance(data, dict):
        return data
    return row


async def postgrest_insert_many(
    client: httpx.AsyncClient,
    table: str,
    rows: List[Dict[str, Any]],
) -> List[Dict[str, Any]]:
    if not rows:
        return []
    headers = auth_headers()
    headers["Prefer"] = "return=representation"
    response = await client.post(table_url(table), headers=headers, json=rows)
    if response.status_code >= 400:
        raise HTTPException(status_code=500, detail=f"insert_many_failed:{table}:{response.status_code}:{response.text}")
    data = response.json()
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        return [data]
    return []


async def postgrest_update(
    client: httpx.AsyncClient,
    table: str,
    where: str,
    patch: Dict[str, Any],
) -> List[Dict[str, Any]]:
    headers = auth_headers()
    headers["Prefer"] = "return=representation"
    response = await client.patch(table_url(table) + where, headers=headers, json=patch)
    if response.status_code >= 400:
        raise HTTPException(status_code=500, detail=f"update_failed:{table}:{response.status_code}:{response.text}")
    data = response.json()
    if isinstance(data, list):
        return data
    if isinstance(data, dict):
        return [data]
    return []


async def postgrest_rpc(
    client: httpx.AsyncClient,
    fn: str,
    payload: Dict[str, Any],
) -> Any:
    headers = auth_headers()
    response = await client.post(postgrest_base_url().rstrip("/") + f"/rpc/{fn}", headers=headers, json=payload)
    if response.status_code >= 400:
        raise HTTPException(status_code=500, detail=f"rpc_failed:{fn}:{response.status_code}:{response.text}")
    return response.json()
