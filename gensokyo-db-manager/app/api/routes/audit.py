from __future__ import annotations

import httpx
from fastapi import APIRouter, Header

from app.config import require_supabase
from app.legacy import check_secret
from app.repository import coverage_preview, fetch_claim_rows, fetch_conflict_rows, fetch_signal_rows, fetch_source_rows
from app.service import build_audit_report, build_coverage_preview

router = APIRouter(prefix="/audit", tags=["audit"])


@router.get("/coverage-preview")
async def get_coverage_preview(world_id: str = "gensokyo_main", x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    async with httpx.AsyncClient(timeout=20.0) as client:
        items = await coverage_preview(client, world_id)
    return build_coverage_preview(world_id, items)


@router.get("/report")
async def get_audit_report(world_id: str = "gensokyo_main", x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    async with httpx.AsyncClient(timeout=20.0) as client:
        items = await coverage_preview(client, world_id)
        claims = await fetch_claim_rows(client, world_id)
        sources = await fetch_source_rows(client, world_id)
        signals = await fetch_signal_rows(client, world_id)
        conflicts = await fetch_conflict_rows(client, world_id)
    coverage = build_coverage_preview(world_id, items)
    return build_audit_report(world_id=world_id, coverage=coverage, claims=claims, sources=sources, signals=signals, conflicts=conflicts)
