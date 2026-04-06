from __future__ import annotations

from typing import Any, Dict, List, Optional

import httpx
from fastapi import HTTPException

from app.config import auth_headers, postgrest_base_url


def table_url(table: str) -> str:
    return postgrest_base_url().rstrip("/") + f"/{table}"


def rpc_url(function_name: str) -> str:
    return postgrest_base_url().rstrip("/") + f"/rpc/{function_name}"


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


async def postgrest_count(
    client: httpx.AsyncClient,
    table: str,
    query: str = "",
) -> int:
    headers = auth_headers()
    headers["Prefer"] = "count=exact"
    target = table_url(table) + (query or "?select=*")
    if "limit=" not in target:
        target += "&limit=1" if "?" in target else "?limit=1"
    response = await client.get(target, headers=headers)
    if response.status_code >= 400:
        raise HTTPException(status_code=500, detail=f"count_failed:{table}:{response.status_code}:{response.text}")
    content_range = response.headers.get("content-range", "")
    if "/" in content_range:
        total = content_range.rsplit("/", 1)[-1]
        try:
            return int(total)
        except ValueError:
            return 0
    data = response.json()
    return len(data) if isinstance(data, list) else 0


async def postgrest_rpc(
    client: httpx.AsyncClient,
    function_name: str,
    payload: Optional[Dict[str, Any]] = None,
) -> Any:
    headers = auth_headers()
    response = await client.post(rpc_url(function_name), headers=headers, json=payload or {})
    if response.status_code >= 400:
        raise HTTPException(status_code=500, detail=f"rpc_failed:{function_name}:{response.status_code}:{response.text}")
    if not response.text:
        return None
    return response.json()
