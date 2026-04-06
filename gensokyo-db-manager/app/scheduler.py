from __future__ import annotations

import asyncio
from datetime import UTC, datetime
import logging

import httpx
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from tenacity import retry, stop_after_attempt, wait_fixed

from app.ai import ai_extract_claim_candidates, ai_judge_claim, ai_plan_harvest
from app.config import (
    DB_MANAGER_AUTO_REVIEW_ENABLED,
    DB_MANAGER_DISCOVERY_ENABLED,
    DB_MANAGER_EMBED_REFRESH_ENABLED,
    DB_MANAGER_HTTP_TIMEOUT,
    DB_MANAGER_SWEEP_ENABLED,
    DB_MANAGER_SWEEP_SECONDS,
)
from app.models import DiscoverySourceRequest, InteractionSignalRequest
from app.repository import (
    create_conflict,
    create_job_run,
    find_claim_by_fingerprint,
    find_discovery_source_by_url,
    find_related_claims,
    find_source_by_canonical_url,
    find_web_candidate_by_url,
    finish_job_run,
    add_job_item,
    coverage_preview,
    fetch_claim_rows,
    fetch_conflict_rows,
    fetch_signal_rows,
    fetch_source_rows,
    insert_approval_action,
    insert_claim,
    insert_discovery_source,
    insert_harvest_plan,
    insert_interaction_signal,
    insert_source,
    insert_web_candidate,
    link_claim_sources,
    list_active_discovery_sources,
    list_claim_conflict_memberships,
    list_claim_sources,
    list_pending_claims,
    get_policy,
    get_discovery_source,
    list_reviewable_web_candidates,
    trigger_embedding_refresh,
    update_claim_status,
    update_discovery_source,
    update_web_candidate,
)
from app.service import (
    build_claim_request_from_candidate,
    build_claim_fingerprint,
    build_audit_report,
    build_coverage_preview,
    canonicalize_url,
    classify_error_category,
    detect_conflicting_claims,
    default_source_registry,
    discover_urls_from_document,
    evaluate_claim_for_auto_review,
    extract_web_preview,
    find_near_duplicate_claim,
)

logger = logging.getLogger("gensokyo-db-manager.scheduler")
_scheduler: AsyncIOScheduler | None = None
_last_cycle_started_at: str | None = None
_last_cycle_finished_at: str | None = None
_last_cycle_error: str | None = None


@retry(stop=stop_after_attempt(3), wait=wait_fixed(2))
async def _fetch_body(client: httpx.AsyncClient, url: str) -> str:
    response = await client.get(url, follow_redirects=True)
    response.raise_for_status()
    return response.text


async def run_harvest_planning_once(*, world_id: str = "gensokyo_main") -> dict:
    async with httpx.AsyncClient(timeout=DB_MANAGER_HTTP_TIMEOUT) as client:
        run = await create_job_run(client, world_id=world_id, job_type="harvest_planning", metadata={})
        run_id = str(run.get("id") or "")
        items = await coverage_preview(client, world_id)
        claims = await fetch_claim_rows(client, world_id)
        sources = await fetch_source_rows(client, world_id)
        signals = await fetch_signal_rows(client, world_id)
        conflicts = await fetch_conflict_rows(client, world_id)
        active_sources = await list_active_discovery_sources(client, world_id, 20)
        report = build_audit_report(
            world_id=world_id,
            coverage=build_coverage_preview(world_id, items),
            claims=claims,
            sources=sources,
            signals=signals,
            conflicts=conflicts,
        )
        source_registry = default_source_registry(world_id)
        plan = await ai_plan_harvest(
            world_id=world_id,
            audit_report=report,
            active_sources=active_sources,
            source_registry=source_registry,
        )
        if not plan or not plan.tasks:
            if run_id:
                await finish_job_run(client, run_id, status="completed", success_count=0, error_count=0, summary={"planned": 0})
            return {"world_id": world_id, "planned": 0, "tasks": []}

        stored_tasks = []
        for task in plan.tasks:
            row = await insert_harvest_plan(
                client,
                {
                    "world_id": world_id,
                    "task_type": task.task_type,
                    "entity_kind": task.entity_kind or None,
                    "entity_id": task.entity_id or None,
                    "topic": task.topic or None,
                    "priority": task.priority,
                    "reason": task.reason,
                    "suggested_source_name": task.suggested_source_name or None,
                    "suggested_start_url": task.suggested_start_url or None,
                    "status": "planned",
                    "metadata": {
                        "source_kind": task.source_kind,
                        "include_patterns": task.include_patterns,
                        "exclude_patterns": task.exclude_patterns,
                    },
                },
            )
            stored_tasks.append(row)
            if run_id:
                await add_job_item(
                    client,
                    run_id=run_id,
                    item_key=str(row.get("id") or task.topic or task.reason),
                    status="success",
                    category="harvest_plan",
                    message=task.reason,
                    metadata={"task_type": task.task_type, "source_name": task.suggested_source_name, "start_url": task.suggested_start_url},
                )
            if task.suggested_start_url:
                existing_source = await find_discovery_source_by_url(client, world_id, task.suggested_start_url)
                if not existing_source:
                    await insert_discovery_source(
                        client,
                        DiscoverySourceRequest(
                            world_id=world_id,
                            source_name=task.suggested_source_name or f"AI Planned {task.topic or task.task_type}",
                            source_kind=task.source_kind,
                            start_url=task.suggested_start_url,
                            entity_kind=task.entity_kind,
                            entity_id=task.entity_id,
                            topic=task.topic,
                            claim_type="fact",
                            layer="official_secondary",
                            include_patterns=task.include_patterns,
                            exclude_patterns=task.exclude_patterns,
                            max_urls_per_run=12,
                            metadata={"planned_by_ai": True, "reason": task.reason},
                        ),
                    )
        if run_id:
            await finish_job_run(client, run_id, status="completed", success_count=len(stored_tasks), error_count=0, summary={"planned": len(stored_tasks)})
        return {"world_id": world_id, "planned": len(stored_tasks), "tasks": stored_tasks}


async def _ingest_candidate_as_claim(client: httpx.AsyncClient, candidate: dict, title: str, summary: str) -> None:
    claim_req = build_claim_request_from_candidate({**candidate, "title": title, "summary": summary})
    claim_req.metadata["claim_fingerprint"] = build_claim_fingerprint(claim_req)
    existing_by_fingerprint = await find_claim_by_fingerprint(client, claim_req.world_id, claim_req.metadata["claim_fingerprint"])
    existing_claims = await find_related_claims(
        client,
        world_id=claim_req.world_id,
        entity_kind=claim_req.entity_kind,
        entity_id=claim_req.entity_id,
        claim_type=claim_req.claim_type,
    )
    reused_claim = existing_by_fingerprint or find_near_duplicate_claim(
        claim_req,
        existing_claims,
        str(claim_req.metadata["claim_fingerprint"]),
    )
    inserted_claim = reused_claim or await insert_claim(client, claim_req, status="pending")
    claim_id = str(inserted_claim.get("id") or "")
    if not claim_id:
        return

    primary_source = claim_req.sources[0]
    canonical_url = canonicalize_url(primary_source.source_url) or primary_source.source_url
    existing_source = await find_source_by_canonical_url(client, claim_req.world_id, canonical_url)
    if existing_source:
        source_id = str(existing_source.get("id") or "")
    else:
        payload = primary_source.model_dump()
        payload["canonical_url"] = canonical_url
        source_id = await insert_source(client, claim_req.world_id, payload)
    await link_claim_sources(
        client,
        claim_id,
        [{"source_id": source_id, "support_type": primary_source.support_type, "excerpt": primary_source.excerpt}],
    )

    conflicts_with = [claim for claim in existing_claims if str(claim.get("id") or "") != claim_id]
    competing_ids = [] if reused_claim else detect_conflicting_claims(claim_req, conflicts_with)
    if competing_ids:
        await create_conflict(
            client,
            world_id=claim_req.world_id,
            entity_kind=claim_req.entity_kind,
            entity_id=claim_req.entity_id,
            topic=claim_req.topic or claim_req.claim_type,
            claim_ids=[claim_id, *competing_ids],
        )


async def _ingest_body_with_ai(client: httpx.AsyncClient, candidate: dict, title: str, summary: str, body: str) -> int:
    extracted = await ai_extract_claim_candidates(
        world_id=str(candidate.get("world_id") or "gensokyo_main"),
        source_url=str(candidate.get("canonical_url") or candidate.get("url") or ""),
        title=title,
        summary=summary,
        body=body,
        entity_kind=str(candidate.get("entity_kind") or ""),
        entity_id=str(candidate.get("entity_id") or ""),
        topic=str(candidate.get("topic") or ""),
        default_layer=str(candidate.get("layer") or "official_secondary"),
        default_claim_type=str(candidate.get("claim_type") or "fact"),
    )
    created = 0
    for item in extracted:
        claim_req = build_claim_request_from_candidate(
            {
                **candidate,
                "title": title,
                "summary": item.claim_text,
                "entity_kind": item.entity_kind or candidate.get("entity_kind") or "web_entity",
                "entity_id": item.entity_id or candidate.get("entity_id") or "",
                "topic": item.topic or candidate.get("topic") or "",
                "claim_type": item.claim_type or candidate.get("claim_type") or "fact",
                "layer": item.layer or candidate.get("layer") or "official_secondary",
                "note": item.reason or candidate.get("note") or "",
            }
        )
        claim_req.claim_text = item.claim_text
        claim_req.confidence = item.confidence
        claim_req.temporal_scope = item.temporal_scope
        claim_req.metadata["ai_reason"] = item.reason
        existing_claims = await find_related_claims(
            client,
            world_id=claim_req.world_id,
            entity_kind=claim_req.entity_kind,
            entity_id=claim_req.entity_id,
            claim_type=claim_req.claim_type,
        )
        judgement = await ai_judge_claim(claim_req.model_dump(), existing_claims)
        if judgement and not judgement.should_store:
            continue
        if judgement and judgement.layer:
            claim_req.layer = judgement.layer
        if judgement and judgement.confidence is not None:
            claim_req.confidence = judgement.confidence
        await _ingest_candidate_as_claim(
            client,
            {
                **candidate,
                "world_id": claim_req.world_id,
                "entity_kind": claim_req.entity_kind,
                "entity_id": claim_req.entity_id,
                "topic": claim_req.topic,
                "claim_type": claim_req.claim_type,
                "layer": claim_req.layer,
                "title": title,
                "summary": claim_req.claim_text,
                "note": claim_req.metadata.get("ai_reason") or candidate.get("note") or "",
            },
            title,
            claim_req.claim_text,
        )
        created += 1
    return created


async def _auto_review_pending_claims(client: httpx.AsyncClient, world_id: str = "gensokyo_main", limit: int = 20) -> None:
    if not DB_MANAGER_AUTO_REVIEW_ENABLED:
        return
    stored_policy_row = await get_policy(client, "auto_review")
    stored_policy = stored_policy_row.get("policy_value") if isinstance(stored_policy_row, dict) else None
    pending_rows = await list_pending_claims(client, world_id)
    for claim in pending_rows[: max(1, limit)]:
        claim_id = str(claim.get("id") or "")
        previous_status = str(claim.get("status") or "pending")
        if not claim_id:
            continue
        source_links = await list_claim_sources(client, claim_id)
        memberships = await list_claim_conflict_memberships(client, claim_id)
        outcome = evaluate_claim_for_auto_review(claim, source_links, memberships, stored_policy if isinstance(stored_policy, dict) else None)
        if outcome.next_status == previous_status:
            continue
        updated = await update_claim_status(client, claim_id, {"status": outcome.next_status, "review_note": outcome.reason})
        if updated:
            await insert_approval_action(
                client,
                {
                    "target_type": "claim",
                    "target_id": claim_id,
                    "action": outcome.next_status,
                    "reviewer": "scheduler-auto-review",
                    "note": outcome.reason,
                },
            )
            if DB_MANAGER_EMBED_REFRESH_ENABLED and outcome.next_status == "accepted":
                await trigger_embedding_refresh(client, world_id)


async def run_discovery_once(*, world_id: str = "gensokyo_main", limit: int = 5, dry_run: bool = False) -> dict:
    if not DB_MANAGER_DISCOVERY_ENABLED and not dry_run:
        return {"world_id": world_id, "processed_sources": 0, "discovered_urls": 0, "queued_urls": 0, "dry_run": dry_run}

    processed_sources = 0
    discovered_urls = 0
    queued_urls = 0
    errors = 0
    results = []
    async with httpx.AsyncClient(timeout=DB_MANAGER_HTTP_TIMEOUT) as client:
        run = await create_job_run(client, world_id=world_id, job_type="discovery", metadata={"limit": limit, "dry_run": dry_run})
        run_id = str(run.get("id") or "")
        sources = await list_active_discovery_sources(client, world_id, limit)
        for source in sources:
            source_id = str(source.get("id") or "")
            start_url = str(source.get("start_url") or "")
            if not source_id or not start_url:
                continue
            processed_sources += 1
            try:
                body = await _fetch_body(client, start_url)
                urls = discover_urls_from_document(
                    source_kind=str(source.get("source_kind") or ""),
                    start_url=start_url,
                    body=body,
                    include_patterns=list(source.get("include_patterns") or []),
                    exclude_patterns=list(source.get("exclude_patterns") or []),
                    max_urls=int(source.get("max_urls_per_run") or 20),
                )
                discovered_urls += len(urls)
                queued_here = 0
                for url in urls:
                    canonical_url = canonicalize_url(url)
                    existing = await find_web_candidate_by_url(client, canonical_url)
                    if existing:
                        continue
                    queued_here += 1
                    if not dry_run:
                        await insert_web_candidate(
                            client,
                            {
                                "world_id": source.get("world_id") or world_id,
                                "url": url,
                                "canonical_url": canonical_url,
                                "source_kind": source.get("source_kind") or "web_article",
                                "entity_kind": source.get("entity_kind") or None,
                                "entity_id": source.get("entity_id") or None,
                                "topic": source.get("topic") or None,
                                "claim_type": source.get("claim_type") or "fact",
                                "layer": source.get("layer") or "official_secondary",
                                "extract_as_claim": True,
                                "note": f"discovered_from:{source.get('source_name') or source_id}",
                                "status": "queued",
                            },
                        )
                queued_urls += queued_here
                if not dry_run:
                    await update_discovery_source(
                        client,
                        source_id,
                        {"last_discovered_at": datetime.now(UTC).isoformat(), "last_discovery_note": f"queued:{queued_here}"},
                    )
                if run_id:
                    await add_job_item(
                        client,
                        run_id=run_id,
                        item_key=source_id,
                        status="success",
                        category="discovery_source",
                        message=f"discovered={len(urls)} queued={queued_here}",
                        metadata={"source_name": source.get("source_name"), "start_url": start_url},
                    )
                results.append({"source_id": source_id, "source_name": source.get("source_name"), "discovered": len(urls), "queued": queued_here})
            except Exception as exc:
                errors += 1
                logger.warning("discovery_failed id=%s start_url=%s err=%r", source_id, start_url, exc)
                if not dry_run:
                    await update_discovery_source(client, source_id, {"last_discovery_note": str(exc)[:400]})
                if run_id:
                    await add_job_item(
                        client,
                        run_id=run_id,
                        item_key=source_id or start_url,
                        status="failed",
                        category=classify_error_category(str(exc)),
                        message=str(exc)[:400],
                        metadata={"source_name": source.get("source_name"), "start_url": start_url},
                    )
                results.append({"source_id": source_id, "source_name": source.get("source_name"), "error": str(exc)[:200]})
        if run_id:
            await finish_job_run(
                client,
                run_id,
                status="completed" if errors == 0 else "completed_with_errors",
                success_count=processed_sources - errors,
                error_count=errors,
                summary={"discovered_urls": discovered_urls, "queued_urls": queued_urls, "dry_run": dry_run},
            )

    return {
        "world_id": world_id,
        "processed_sources": processed_sources,
        "discovered_urls": discovered_urls,
        "queued_urls": queued_urls,
        "dry_run": dry_run,
        "sources": results,
    }


async def run_discovery_for_source(*, source_id: str, dry_run: bool = False) -> dict:
    async with httpx.AsyncClient(timeout=DB_MANAGER_HTTP_TIMEOUT) as client:
        source = await get_discovery_source(client, source_id)
        if not source:
            return {"ok": False, "reason": "not_found", "source_id": source_id}
        start_url = str(source.get("start_url") or "")
        if not start_url:
            return {"ok": False, "reason": "missing_start_url", "source_id": source_id}
        body = await _fetch_body(client, start_url)
        urls = discover_urls_from_document(
            source_kind=str(source.get("source_kind") or ""),
            start_url=start_url,
            body=body,
            include_patterns=list(source.get("include_patterns") or []),
            exclude_patterns=list(source.get("exclude_patterns") or []),
            max_urls=int(source.get("max_urls_per_run") or 20),
        )
        queued_here = 0
        for url in urls:
            canonical_url = canonicalize_url(url)
            existing = await find_web_candidate_by_url(client, canonical_url)
            if existing:
                continue
            queued_here += 1
            if not dry_run:
                await insert_web_candidate(
                    client,
                    {
                        "world_id": source.get("world_id") or "gensokyo_main",
                        "url": url,
                        "canonical_url": canonical_url,
                        "source_kind": source.get("source_kind") or "web_article",
                        "entity_kind": source.get("entity_kind") or None,
                        "entity_id": source.get("entity_id") or None,
                        "topic": source.get("topic") or None,
                        "claim_type": source.get("claim_type") or "fact",
                        "layer": source.get("layer") or "official_secondary",
                        "extract_as_claim": True,
                        "note": f"discovered_from:{source.get('source_name') or source_id}",
                        "status": "queued",
                    },
                )
        if not dry_run:
            await update_discovery_source(
                client,
                source_id,
                {"last_discovered_at": datetime.now(UTC).isoformat(), "last_discovery_note": f"queued:{queued_here}"},
            )
        return {"ok": True, "source_id": source_id, "source_name": source.get("source_name"), "discovered": len(urls), "queued": queued_here, "dry_run": dry_run}


async def process_web_ingest_queue_once() -> None:
    async with httpx.AsyncClient(timeout=DB_MANAGER_HTTP_TIMEOUT) as client:
        run = await create_job_run(client, world_id="gensokyo_main", job_type="ingest_queue", metadata={})
        run_id = str(run.get("id") or "")
        success_count = 0
        error_count = 0
        candidates = await list_reviewable_web_candidates(client, limit=8)
        for candidate in candidates:
            candidate_id = str(candidate.get("id") or "")
            url = str(candidate.get("canonical_url") or candidate.get("url") or "")
            if not candidate_id or not url:
                continue
            current_status = str(candidate.get("status") or "queued")
            title = str(candidate.get("title") or "")
            summary = str(candidate.get("summary") or "")
            body = ""
            try:
                if current_status == "queued" or not summary:
                    body = await _fetch_body(client, url)
                    title, summary = extract_web_preview(body)
                    await update_web_candidate(
                        client,
                        candidate_id,
                        {
                            "status": "fetched",
                            "title": title or None,
                            "summary": summary or None,
                            "canonical_url": canonicalize_url(url),
                            "note": candidate.get("note") or None,
                        },
                    )

                await insert_interaction_signal(
                    client,
                    InteractionSignalRequest(
                        world_id=str(candidate.get("world_id") or "gensokyo_main"),
                        signal_type="web_ingest_candidate",
                        entity_kind=str(candidate.get("entity_kind") or ""),
                        entity_id=str(candidate.get("entity_id") or ""),
                        entity_name=title,
                        source_text=summary,
                        source_url=url,
                        observed_in="web_ingest_queue",
                        reason="Queued web ingest candidate fetched and should be reviewed for claim extraction.",
                        proposed_fields=["title", "summary", "source_url"],
                        metadata={"queue_id": candidate_id, "source_kind": candidate.get("source_kind")},
                    ),
                )

                if bool(candidate.get("extract_as_claim")) and summary:
                    created = 0
                    if not body:
                        body = await _fetch_body(client, url)
                    created = await _ingest_body_with_ai(client, candidate, title, summary, body)
                    if created == 0:
                        await _ingest_candidate_as_claim(client, candidate, title, summary)
                    await update_web_candidate(client, candidate_id, {"status": "claimed"})
                else:
                    await update_web_candidate(client, candidate_id, {"status": "fetched"})
                success_count += 1
                if run_id:
                    await add_job_item(
                        client,
                        run_id=run_id,
                        item_key=candidate_id,
                        status="success",
                        category="ingest_candidate",
                        message=f"status={current_status}",
                        metadata={"url": url},
                    )
            except Exception as exc:
                error_count += 1
                logger.warning("web_ingest_queue_failed id=%s url=%s err=%r", candidate_id, url, exc)
                await update_web_candidate(client, candidate_id, {"status": "failed", "note": str(exc)[:400]})
                if run_id:
                    await add_job_item(
                        client,
                        run_id=run_id,
                        item_key=candidate_id or url,
                        status="failed",
                        category=classify_error_category(str(exc)),
                        message=str(exc)[:400],
                        metadata={"url": url},
                    )

        await _auto_review_pending_claims(client)
        if run_id:
            await finish_job_run(
                client,
                run_id,
                status="completed" if error_count == 0 else "completed_with_errors",
                success_count=success_count,
                error_count=error_count,
                summary={"candidate_count": len(candidates)},
            )


async def run_scheduled_cycle() -> None:
    global _last_cycle_started_at, _last_cycle_finished_at, _last_cycle_error
    _last_cycle_started_at = datetime.now(UTC).isoformat()
    _last_cycle_error = None
    logger.info("scheduled_cycle_started")
    try:
        await run_harvest_planning_once()
        if DB_MANAGER_DISCOVERY_ENABLED:
            await run_discovery_once()
        await process_web_ingest_queue_once()
        _last_cycle_finished_at = datetime.now(UTC).isoformat()
        logger.info("scheduled_cycle_finished")
    except Exception as exc:
        _last_cycle_error = str(exc)[:500]
        _last_cycle_finished_at = datetime.now(UTC).isoformat()
        logger.exception("scheduled_cycle_failed err=%r", exc)
        raise


async def _run_scheduled_cycle_background() -> None:
    try:
        await run_scheduled_cycle()
    except Exception:
        return


def scheduler_status() -> dict:
    next_run_at = None
    if _scheduler is not None:
        jobs = _scheduler.get_jobs()
        if jobs:
            next_run = jobs[0].next_run_time
            if next_run is not None:
                next_run_at = next_run.isoformat()
    return {
        "enabled": DB_MANAGER_SWEEP_ENABLED,
        "running": _scheduler is not None,
        "interval_seconds": max(30, DB_MANAGER_SWEEP_SECONDS),
        "next_run_at": next_run_at,
        "last_cycle_started_at": _last_cycle_started_at,
        "last_cycle_finished_at": _last_cycle_finished_at,
        "last_cycle_error": _last_cycle_error,
    }


def start_scheduler() -> None:
    global _scheduler
    if not DB_MANAGER_SWEEP_ENABLED or _scheduler is not None:
        return
    scheduler = AsyncIOScheduler()
    scheduler.add_job(run_scheduled_cycle, "interval", seconds=max(30, DB_MANAGER_SWEEP_SECONDS))
    scheduler.start()
    _scheduler = scheduler
    asyncio.create_task(_run_scheduled_cycle_background())


def stop_scheduler() -> None:
    global _scheduler
    if _scheduler is None:
        return
    _scheduler.shutdown(wait=False)
    _scheduler = None
