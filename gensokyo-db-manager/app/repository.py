from __future__ import annotations

from typing import Any, Dict, List
from urllib.parse import quote

import httpx
from fastapi import HTTPException

from app.models import ClaimIngestRequest, CoverageItem, DiscoverySourceRequest, InteractionSignalRequest, SchemaSuggestRequest
from app.postgrest import postgrest_count, postgrest_insert_many, postgrest_insert_one, postgrest_rpc, postgrest_select, postgrest_update


_COVERAGE_TABLES = (
    "world_characters",
    "world_locations",
    "world_relationships",
    "world_canon_claims",
    "world_wiki_pages",
    "world_chat_context_cache",
    "world_story_events",
    "world_chronicle_entries",
    "world_historian_notes",
    "world_source_index",
    "world_knowledge_claims",
    "world_knowledge_sources",
)


def _missing_table(detail: str, table: str) -> bool:
    return table in detail and ("does not exist" in detail or "relation" in detail)


async def coverage_preview(client: httpx.AsyncClient, world_id: str) -> list[CoverageItem]:
    items: list[CoverageItem] = []
    for table in _COVERAGE_TABLES:
        try:
            count = await postgrest_count(client, table, f"?world_id=eq.{quote(world_id, safe='')}&select=*")
            note = ""
            if count == 0:
                note = "empty"
            elif count < 5:
                note = "thin"
            items.append(CoverageItem(table=table, count=count, exists=True, note=note))
        except HTTPException as exc:
            detail = str(exc.detail)
            if _missing_table(detail, table):
                items.append(CoverageItem(table=table, count=0, exists=False, note="missing_table"))
                continue
            raise
    return items


async def insert_interaction_signal(client: httpx.AsyncClient, req: InteractionSignalRequest) -> bool:
    row = {
        "world_id": req.world_id,
        "signal_type": req.signal_type,
        "entity_kind": req.entity_kind,
        "entity_id": req.entity_id or None,
        "entity_name": req.entity_name or None,
        "source_text": req.source_text or None,
        "source_url": req.source_url or None,
        "observed_in": req.observed_in,
        "reason": req.reason or None,
        "user_message": req.user_message or None,
        "assistant_message": req.assistant_message or None,
        "proposed_fields": req.proposed_fields,
        "metadata": req.metadata,
        "status": "pending",
    }
    try:
        await postgrest_insert_one(client, "world_admin_signals", row)
        return True
    except HTTPException as exc:
        if _missing_table(str(exc.detail), "world_admin_signals"):
            return False
        raise


async def insert_schema_proposal(
    client: httpx.AsyncClient,
    *,
    request: SchemaSuggestRequest,
    decision: str,
    reason: str,
    suggested_table: str,
    suggested_columns: list[str],
) -> bool:
    row = {
        "world_id": request.world_id,
        "need": request.need or None,
        "candidate_name": request.candidate_name or None,
        "observed_fields": request.observed_fields,
        "expected_rows": request.expected_rows,
        "repeats_per_entity": request.repeats_per_entity,
        "requires_history": request.requires_history,
        "context": request.context,
        "decision": decision,
        "reason": reason,
        "suggested_table": suggested_table or None,
        "suggested_columns": suggested_columns,
        "status": "proposed",
    }
    try:
        await postgrest_insert_one(client, "world_schema_proposals", row)
        return True
    except HTTPException as exc:
        if _missing_table(str(exc.detail), "world_schema_proposals"):
            return False
        raise


async def insert_source(client: httpx.AsyncClient, world_id: str, source: Dict[str, Any]) -> str:
    row = {
        "world_id": world_id,
        "source_kind": source.get("source_kind") or "unknown",
        "title": source.get("title") or "",
        "source_url": source.get("source_url") or None,
        "canonical_url": source.get("canonical_url") or source.get("source_url") or None,
        "citation": source.get("citation") or None,
        "origin": source.get("origin") or None,
        "authority_score": source.get("authority_score") or 0.5,
        "published_at": source.get("published_at") or None,
        "quote_excerpt": source.get("excerpt") or None,
        "metadata": source.get("metadata") or {},
    }
    inserted = await postgrest_insert_one(client, "world_knowledge_sources", row)
    return str(inserted.get("id") or "")


async def insert_claim(client: httpx.AsyncClient, req: ClaimIngestRequest, status: str = "pending") -> Dict[str, Any]:
    row = {
        "world_id": req.world_id,
        "entity_kind": req.entity_kind,
        "entity_id": req.entity_id or None,
        "topic": req.topic or None,
        "claim_type": req.claim_type,
        "claim_fingerprint": req.metadata.get("claim_fingerprint") if isinstance(req.metadata, dict) else None,
        "layer": req.layer,
        "claim_text": req.claim_text,
        "confidence": req.confidence,
        "temporal_scope": req.temporal_scope or None,
        "status": status,
        "metadata": req.metadata,
    }
    return await postgrest_insert_one(client, "world_knowledge_claims", row)


async def link_claim_sources(client: httpx.AsyncClient, claim_id: str, links: List[Dict[str, Any]]) -> int:
    inserted_count = 0
    for link in links:
        source_id = str(link["source_id"])
        existing = await postgrest_select(
            client,
            "world_knowledge_claim_sources",
            f"?claim_id=eq.{quote(claim_id, safe='')}&source_id=eq.{quote(source_id, safe='')}&select=claim_id&limit=1",
        )
        if isinstance(existing, list) and existing:
            continue
        inserted = await postgrest_insert_one(
            client,
            "world_knowledge_claim_sources",
            {
                "claim_id": claim_id,
                "source_id": source_id,
                "support_type": link.get("support_type") or "supports",
                "quote_excerpt": link.get("excerpt") or None,
            },
        )
        if inserted:
            inserted_count += 1
    return inserted_count


async def find_related_claims(
    client: httpx.AsyncClient,
    *,
    world_id: str,
    entity_kind: str,
    entity_id: str,
    claim_type: str,
) -> List[Dict[str, Any]]:
    params = [
        "select=id,claim_text,status,topic,layer,claim_fingerprint",
        f"world_id=eq.{quote(world_id, safe='')}",
        f"entity_kind=eq.{quote(entity_kind, safe='')}",
        f"claim_type=eq.{quote(claim_type, safe='')}",
    ]
    if entity_id:
        params.append(f"entity_id=eq.{quote(entity_id, safe='')}")
    params.append("status=in.(pending,accepted,disputed)")
    return await postgrest_select(client, "world_knowledge_claims", "?" + "&".join(params))


async def create_conflict(
    client: httpx.AsyncClient,
    *,
    world_id: str,
    entity_kind: str,
    entity_id: str,
    topic: str,
    claim_ids: List[str],
) -> str:
    conflict = await postgrest_insert_one(
        client,
        "world_knowledge_conflicts",
        {
            "world_id": world_id,
            "entity_kind": entity_kind,
            "entity_id": entity_id or None,
            "topic": topic or None,
            "resolution_status": "open",
            "metadata": {},
        },
    )
    conflict_id = str(conflict.get("id") or "")
    await postgrest_insert_many(
        client,
        "world_knowledge_conflict_members",
        [{"conflict_id": conflict_id, "claim_id": claim_id, "stance": "competing"} for claim_id in claim_ids],
    )
    return conflict_id


async def list_pending_claims(client: httpx.AsyncClient, world_id: str) -> List[Dict[str, Any]]:
    return await postgrest_select(
        client,
        "world_knowledge_claims",
        f"?world_id=eq.{quote(world_id, safe='')}&status=eq.pending&order=created_at.desc&select=*",
    )


async def update_claim_status(client: httpx.AsyncClient, claim_id: str, patch: Dict[str, Any]) -> Dict[str, Any]:
    rows = await postgrest_update(client, "world_knowledge_claims", f"?id=eq.{quote(claim_id, safe='')}", patch)
    return rows[0] if rows else {}


async def insert_approval_action(client: httpx.AsyncClient, row: Dict[str, Any]) -> bool:
    try:
        await postgrest_insert_one(client, "world_approval_actions", row)
        return True
    except HTTPException as exc:
        if _missing_table(str(exc.detail), "world_approval_actions"):
            return False
        raise


async def list_conflicts(client: httpx.AsyncClient, world_id: str) -> List[Dict[str, Any]]:
    conflicts = await postgrest_select(
        client,
        "world_knowledge_conflicts",
        f"?world_id=eq.{quote(world_id, safe='')}&select=id,topic,resolution_status,world_knowledge_conflict_members(claim_id)&order=created_at.desc",
    )
    return conflicts if isinstance(conflicts, list) else []


async def insert_web_candidate(client: httpx.AsyncClient, row: Dict[str, Any]) -> bool:
    try:
        await postgrest_insert_one(client, "world_web_ingest_queue", row)
        return True
    except HTTPException as exc:
        if _missing_table(str(exc.detail), "world_web_ingest_queue"):
            return False
        raise


async def list_web_candidates(client: httpx.AsyncClient, limit: int = 10) -> List[Dict[str, Any]]:
    rows = await postgrest_select(
        client,
        "world_web_ingest_queue",
        f"?status=eq.queued&order=created_at.asc&limit={max(1, limit)}&select=*",
    )
    return rows if isinstance(rows, list) else []


async def update_web_candidate(client: httpx.AsyncClient, candidate_id: str, patch: Dict[str, Any]) -> Dict[str, Any]:
    rows = await postgrest_update(client, "world_web_ingest_queue", f"?id=eq.{quote(candidate_id, safe='')}", patch)
    return rows[0] if rows else {}


async def list_claim_sources(client: httpx.AsyncClient, claim_id: str) -> List[Dict[str, Any]]:
    rows = await postgrest_select(
        client,
        "world_knowledge_claim_sources",
        f"?claim_id=eq.{quote(claim_id, safe='')}&select=support_type,quote_excerpt,world_knowledge_sources(*)",
    )
    return rows if isinstance(rows, list) else []


async def list_claim_conflict_memberships(client: httpx.AsyncClient, claim_id: str) -> List[Dict[str, Any]]:
    rows = await postgrest_select(
        client,
        "world_knowledge_conflict_members",
        f"?claim_id=eq.{quote(claim_id, safe='')}&select=conflict_id,stance,world_knowledge_conflicts(id,resolution_status,topic)",
    )
    return rows if isinstance(rows, list) else []


async def get_claim(client: httpx.AsyncClient, claim_id: str) -> Dict[str, Any]:
    rows = await postgrest_select(
        client,
        "world_knowledge_claims",
        f"?id=eq.{quote(claim_id, safe='')}&select=*&limit=1",
    )
    return rows[0] if isinstance(rows, list) and rows else {}


async def list_reviewable_web_candidates(client: httpx.AsyncClient, limit: int = 10) -> List[Dict[str, Any]]:
    rows = await postgrest_select(
        client,
        "world_web_ingest_queue",
        f"?status=in.(queued,fetched)&order=created_at.asc&limit={max(1, limit)}&select=*",
    )
    return rows if isinstance(rows, list) else []


async def find_claim_by_fingerprint(client: httpx.AsyncClient, world_id: str, fingerprint: str) -> Dict[str, Any]:
    rows = await postgrest_select(
        client,
        "world_knowledge_claims",
        f"?world_id=eq.{quote(world_id, safe='')}&claim_fingerprint=eq.{quote(fingerprint, safe='')}&select=*&limit=1",
    )
    return rows[0] if isinstance(rows, list) and rows else {}


async def find_source_by_canonical_url(client: httpx.AsyncClient, world_id: str, canonical_url: str) -> Dict[str, Any]:
    rows = await postgrest_select(
        client,
        "world_knowledge_sources",
        f"?world_id=eq.{quote(world_id, safe='')}&canonical_url=eq.{quote(canonical_url, safe='')}&select=*&limit=1",
    )
    return rows[0] if isinstance(rows, list) and rows else {}


async def insert_discovery_source(client: httpx.AsyncClient, req: DiscoverySourceRequest) -> Dict[str, Any]:
    row = {
        "world_id": req.world_id,
        "source_name": req.source_name,
        "source_kind": req.source_kind,
        "start_url": req.start_url,
        "entity_kind": req.entity_kind or None,
        "entity_id": req.entity_id or None,
        "topic": req.topic or None,
        "claim_type": req.claim_type,
        "layer": req.layer,
        "include_patterns": req.include_patterns,
        "exclude_patterns": req.exclude_patterns,
        "max_urls_per_run": req.max_urls_per_run,
        "metadata": req.metadata,
        "status": "active",
    }
    return await postgrest_insert_one(client, "world_discovery_sources", row)


async def list_active_discovery_sources(client: httpx.AsyncClient, world_id: str, limit: int = 5) -> List[Dict[str, Any]]:
    rows = await postgrest_select(
        client,
        "world_discovery_sources",
        f"?world_id=eq.{quote(world_id, safe='')}&status=eq.active&order=last_discovered_at.asc.nullsfirst&limit={max(1, limit)}&select=*",
    )
    return rows if isinstance(rows, list) else []


async def update_discovery_source(client: httpx.AsyncClient, source_id: str, patch: Dict[str, Any]) -> Dict[str, Any]:
    rows = await postgrest_update(client, "world_discovery_sources", f"?id=eq.{quote(source_id, safe='')}", patch)
    return rows[0] if rows else {}


async def find_discovery_source_by_url(client: httpx.AsyncClient, world_id: str, start_url: str) -> Dict[str, Any]:
    rows = await postgrest_select(
        client,
        "world_discovery_sources",
        f"?world_id=eq.{quote(world_id, safe='')}&start_url=eq.{quote(start_url, safe='')}&select=*&limit=1",
    )
    return rows[0] if isinstance(rows, list) and rows else {}


async def find_web_candidate_by_url(client: httpx.AsyncClient, url: str) -> Dict[str, Any]:
    rows = await postgrest_select(
        client,
        "world_web_ingest_queue",
        f"?canonical_url=eq.{quote(url, safe='')}&select=id,status,url,canonical_url&limit=1",
    )
    return rows[0] if isinstance(rows, list) and rows else {}


async def upsert_policy(client: httpx.AsyncClient, key: str, value: Dict[str, Any]) -> Dict[str, Any]:
    existing = await postgrest_select(client, "world_manager_policies", f"?policy_key=eq.{quote(key, safe='')}&select=*&limit=1")
    if isinstance(existing, list) and existing:
        rows = await postgrest_update(
            client,
            "world_manager_policies",
            f"?policy_key=eq.{quote(key, safe='')}",
            {"policy_value": value},
        )
        return rows[0] if rows else {}
    return await postgrest_insert_one(client, "world_manager_policies", {"policy_key": key, "policy_value": value})


async def get_policy(client: httpx.AsyncClient, key: str) -> Dict[str, Any]:
    rows = await postgrest_select(client, "world_manager_policies", f"?policy_key=eq.{quote(key, safe='')}&select=*&limit=1")
    return rows[0] if isinstance(rows, list) and rows else {}


async def list_policies(client: httpx.AsyncClient) -> List[Dict[str, Any]]:
    rows = await postgrest_select(client, "world_manager_policies", "?select=*&order=policy_key.asc")
    return rows if isinstance(rows, list) else []


async def create_job_run(client: httpx.AsyncClient, *, world_id: str, job_type: str, metadata: Dict[str, Any] | None = None) -> Dict[str, Any]:
    return await postgrest_insert_one(
        client,
        "world_manager_job_runs",
        {"world_id": world_id, "job_type": job_type, "status": "running", "metadata": metadata or {}},
    )


async def finish_job_run(
    client: httpx.AsyncClient,
    run_id: str,
    *,
    status: str,
    success_count: int = 0,
    error_count: int = 0,
    summary: Dict[str, Any] | None = None,
) -> Dict[str, Any]:
    rows = await postgrest_update(
        client,
        "world_manager_job_runs",
        f"?id=eq.{quote(run_id, safe='')}",
        {"status": status, "success_count": success_count, "error_count": error_count, "summary": summary or {}},
    )
    return rows[0] if rows else {}


async def add_job_item(
    client: httpx.AsyncClient,
    *,
    run_id: str,
    item_key: str,
    status: str,
    category: str = "",
    message: str = "",
    metadata: Dict[str, Any] | None = None,
) -> Dict[str, Any]:
    return await postgrest_insert_one(
        client,
        "world_manager_job_items",
        {
            "run_id": run_id,
            "item_key": item_key,
            "status": status,
            "category": category or None,
            "message": message or None,
            "metadata": metadata or {},
        },
    )


async def list_job_runs(client: httpx.AsyncClient, limit: int = 30) -> List[Dict[str, Any]]:
    rows = await postgrest_select(client, "world_manager_job_runs", f"?select=*&order=created_at.desc&limit={max(1, limit)}")
    return rows if isinstance(rows, list) else []


async def list_job_items(client: httpx.AsyncClient, run_id: str) -> List[Dict[str, Any]]:
    rows = await postgrest_select(client, "world_manager_job_items", f"?run_id=eq.{quote(run_id, safe='')}&select=*&order=created_at.asc")
    return rows if isinstance(rows, list) else []


async def get_job_run(client: httpx.AsyncClient, run_id: str) -> Dict[str, Any]:
    rows = await postgrest_select(client, "world_manager_job_runs", f"?id=eq.{quote(run_id, safe='')}&select=*&limit=1")
    return rows[0] if isinstance(rows, list) and rows else {}


async def fetch_claim_rows(client: httpx.AsyncClient, world_id: str) -> List[Dict[str, Any]]:
    rows = await postgrest_select(
        client,
        "world_knowledge_claims",
        f"?world_id=eq.{quote(world_id, safe='')}&select=id,status,layer,claim_type,entity_kind,claim_fingerprint,created_at",
    )
    return rows if isinstance(rows, list) else []


async def fetch_source_rows(client: httpx.AsyncClient, world_id: str) -> List[Dict[str, Any]]:
    rows = await postgrest_select(
        client,
        "world_knowledge_sources",
        f"?world_id=eq.{quote(world_id, safe='')}&select=id,source_kind,authority_score,canonical_url,created_at",
    )
    return rows if isinstance(rows, list) else []


async def fetch_signal_rows(client: httpx.AsyncClient, world_id: str) -> List[Dict[str, Any]]:
    rows = await postgrest_select(
        client,
        "world_admin_signals",
        f"?world_id=eq.{quote(world_id, safe='')}&select=id,status,signal_type,created_at",
    )
    return rows if isinstance(rows, list) else []


async def fetch_conflict_rows(client: httpx.AsyncClient, world_id: str) -> List[Dict[str, Any]]:
    rows = await postgrest_select(
        client,
        "world_knowledge_conflicts",
        f"?world_id=eq.{quote(world_id, safe='')}&select=id,resolution_status,topic,created_at",
    )
    return rows if isinstance(rows, list) else []


async def insert_harvest_plan(client: httpx.AsyncClient, row: Dict[str, Any]) -> Dict[str, Any]:
    return await postgrest_insert_one(client, "world_harvest_plans", row)


async def list_harvest_plans(client: httpx.AsyncClient, world_id: str, limit: int = 30) -> List[Dict[str, Any]]:
    rows = await postgrest_select(
        client,
        "world_harvest_plans",
        f"?world_id=eq.{quote(world_id, safe='')}&select=*&order=created_at.desc&limit={max(1, limit)}",
    )
    return rows if isinstance(rows, list) else []


async def update_harvest_plan(client: httpx.AsyncClient, plan_id: str, patch: Dict[str, Any]) -> Dict[str, Any]:
    rows = await postgrest_update(client, "world_harvest_plans", f"?id=eq.{quote(plan_id, safe='')}", patch)
    return rows[0] if rows else {}


async def trigger_embedding_refresh(client: httpx.AsyncClient, world_id: str) -> Dict[str, Any]:
    docs = await postgrest_rpc(client, "world_refresh_embedding_documents", {"p_world_id": world_id})
    jobs = await postgrest_rpc(client, "world_queue_embedding_refresh", {"p_world_id": world_id})
    return {"documents": docs, "jobs": jobs}


async def get_discovery_source(client: httpx.AsyncClient, source_id: str) -> Dict[str, Any]:
    rows = await postgrest_select(client, "world_discovery_sources", f"?id=eq.{quote(source_id, safe='')}&select=*&limit=1")
    return rows[0] if isinstance(rows, list) and rows else {}


async def get_web_candidate(client: httpx.AsyncClient, candidate_id: str) -> Dict[str, Any]:
    rows = await postgrest_select(client, "world_web_ingest_queue", f"?id=eq.{quote(candidate_id, safe='')}&select=*&limit=1")
    return rows[0] if isinstance(rows, list) and rows else {}
