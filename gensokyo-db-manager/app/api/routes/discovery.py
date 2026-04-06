from __future__ import annotations

import httpx
from fastapi import APIRouter, Body, Header

from app.config import DB_MANAGER_HTTP_TIMEOUT, require_supabase
from app.legacy import check_secret
from app.models import DiscoveryPresetInstallRequest, DiscoveryRunRequest, DiscoverySourceRequest
from app.presets import build_discovery_preset
from app.repository import (
    find_discovery_source_by_url,
    insert_discovery_source,
    list_active_discovery_sources,
    update_discovery_source,
)
from app.scheduler import run_discovery_for_source, run_discovery_once

router = APIRouter(prefix="/discovery", tags=["discovery"])


@router.post("/sources")
async def discovery_source_create(req: DiscoverySourceRequest, x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    async with httpx.AsyncClient(timeout=DB_MANAGER_HTTP_TIMEOUT) as client:
        inserted = await insert_discovery_source(client, req)
    return inserted


@router.get("/sources")
async def discovery_sources_list(world_id: str = "gensokyo_main", limit: int = 20, x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    async with httpx.AsyncClient(timeout=DB_MANAGER_HTTP_TIMEOUT) as client:
        rows = await list_active_discovery_sources(client, world_id, min(max(1, limit), 100))
    return rows


@router.post("/run")
async def discovery_run(req: DiscoveryRunRequest | None = Body(default=None), x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    req = req or DiscoveryRunRequest()
    result = await run_discovery_once(world_id=req.world_id, limit=req.limit, dry_run=req.dry_run)
    return result


@router.post("/sources/{source_id}/run")
async def discovery_run_one_source(source_id: str, dry_run: bool = False, x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    result = await run_discovery_for_source(source_id=source_id, dry_run=dry_run)
    return result


@router.post("/presets/install")
async def discovery_install_preset(req: DiscoveryPresetInstallRequest, x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    preset_items = build_discovery_preset(req.preset_name, world_id=req.world_id)
    installed = []
    updated = []
    skipped = []
    async with httpx.AsyncClient(timeout=DB_MANAGER_HTTP_TIMEOUT) as client:
        for item in preset_items:
            existing = await find_discovery_source_by_url(client, req.world_id, item.start_url)
            if existing and not req.overwrite_existing:
                skipped.append({"source_name": item.source_name, "start_url": item.start_url, "reason": "exists"})
                continue
            if existing and req.overwrite_existing:
                row = await update_discovery_source(client, str(existing.get("id") or ""), item.model_dump())
                updated.append({"id": row.get("id"), "source_name": row.get("source_name"), "start_url": row.get("start_url")})
                continue
            row = await insert_discovery_source(client, item)
            installed.append({"id": row.get("id"), "source_name": row.get("source_name"), "start_url": row.get("start_url")})
    return {
        "preset_name": req.preset_name,
        "world_id": req.world_id,
        "installed": installed,
        "updated": updated,
        "skipped": skipped,
    }
