from __future__ import annotations

import httpx
from fastapi import APIRouter, Header

from app.config import DB_MANAGER_HTTP_TIMEOUT, DB_MANAGER_EMBED_REFRESH_ENABLED, require_supabase
from app.legacy import check_secret
from app.repository import (
    get_job_run,
    list_harvest_plans,
    get_policy,
    get_web_candidate,
    list_job_items,
    list_job_runs,
    list_policies,
    trigger_embedding_refresh,
    update_web_candidate,
    upsert_policy,
)
from app.service import build_alerts, build_audit_report, build_coverage_preview, default_manager_policies
from app.repository import coverage_preview, fetch_claim_rows, fetch_conflict_rows, fetch_signal_rows, fetch_source_rows
from app.scheduler import process_web_ingest_queue_once, run_harvest_planning_once, run_scheduled_cycle, scheduler_status

router = APIRouter(prefix="/ops", tags=["ops"])


@router.get("/policies")
async def ops_list_policies(x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    async with httpx.AsyncClient(timeout=DB_MANAGER_HTTP_TIMEOUT) as client:
        rows = await list_policies(client)
    return {"defaults": default_manager_policies(), "stored": rows}


@router.post("/policies/{policy_key}")
async def ops_upsert_policy(policy_key: str, payload: dict, x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    async with httpx.AsyncClient(timeout=DB_MANAGER_HTTP_TIMEOUT) as client:
        row = await upsert_policy(client, policy_key, payload)
    return row


@router.get("/policies/{policy_key}")
async def ops_get_policy(policy_key: str, x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    async with httpx.AsyncClient(timeout=DB_MANAGER_HTTP_TIMEOUT) as client:
        row = await get_policy(client, policy_key)
    return {"default": default_manager_policies().get(policy_key), "stored": row}


@router.get("/jobs")
async def ops_list_jobs(limit: int = 30, x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    async with httpx.AsyncClient(timeout=DB_MANAGER_HTTP_TIMEOUT) as client:
        rows = await list_job_runs(client, min(max(1, limit), 100))
    return rows


@router.get("/jobs/{run_id}")
async def ops_get_job(run_id: str, x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    async with httpx.AsyncClient(timeout=DB_MANAGER_HTTP_TIMEOUT) as client:
        run = await get_job_run(client, run_id)
        items = await list_job_items(client, run_id)
    return {"run": run, "items": items}


@router.post("/embedding-refresh")
async def ops_trigger_embedding_refresh(world_id: str = "gensokyo_main", x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    if not DB_MANAGER_EMBED_REFRESH_ENABLED:
        return {"ok": False, "reason": "disabled"}
    async with httpx.AsyncClient(timeout=DB_MANAGER_HTTP_TIMEOUT) as client:
        result = await trigger_embedding_refresh(client, world_id)
    return {"ok": True, "world_id": world_id, "result": result}


@router.get("/alerts")
async def ops_alerts(world_id: str = "gensokyo_main", x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    async with httpx.AsyncClient(timeout=DB_MANAGER_HTTP_TIMEOUT) as client:
        items = await coverage_preview(client, world_id)
        claims = await fetch_claim_rows(client, world_id)
        sources = await fetch_source_rows(client, world_id)
        signals = await fetch_signal_rows(client, world_id)
        conflicts = await fetch_conflict_rows(client, world_id)
        jobs = await list_job_runs(client, 10)
    report = build_audit_report(
        world_id=world_id,
        coverage=build_coverage_preview(world_id, items),
        claims=claims,
        sources=sources,
        signals=signals,
        conflicts=conflicts,
    )
    return {"world_id": world_id, "alerts": build_alerts(report, jobs)}


@router.post("/candidates/{candidate_id}/requeue")
async def ops_requeue_candidate(candidate_id: str, x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    async with httpx.AsyncClient(timeout=DB_MANAGER_HTTP_TIMEOUT) as client:
        row = await get_web_candidate(client, candidate_id)
        if not row:
            return {"ok": False, "reason": "not_found", "candidate_id": candidate_id}
        updated = await update_web_candidate(client, candidate_id, {"status": "queued"})
    return {"ok": True, "candidate": updated}


@router.post("/ingest/retry-failed")
async def ops_retry_failed_ingest(x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    await process_web_ingest_queue_once()
    return {"ok": True}


@router.get("/scheduler")
async def ops_scheduler_status(x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    return scheduler_status()


@router.post("/scheduler/run-now")
async def ops_scheduler_run_now(x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    await run_scheduled_cycle()
    return {"ok": True, "scheduler": scheduler_status()}


@router.get("/harvest-plans")
async def ops_harvest_plans(world_id: str = "gensokyo_main", limit: int = 30, x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    async with httpx.AsyncClient(timeout=DB_MANAGER_HTTP_TIMEOUT) as client:
        rows = await list_harvest_plans(client, world_id, min(max(1, limit), 100))
    return rows


@router.post("/harvest-planning")
async def ops_run_harvest_planning(world_id: str = "gensokyo_main", x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    result = await run_harvest_planning_once(world_id=world_id)
    return result
