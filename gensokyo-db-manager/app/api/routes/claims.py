from __future__ import annotations

import httpx
from fastapi import APIRouter, Header

from app.ai import ai_judge_claim
from app.config import DB_MANAGER_EMBED_REFRESH_ENABLED, require_supabase
from app.legacy import check_secret
from app.models import ClaimAutoReviewRequest, ClaimIngestRequest, ClaimReviewRequest
from app.repository import (
    create_conflict,
    find_claim_by_fingerprint,
    find_related_claims,
    find_source_by_canonical_url,
    get_claim,
    get_policy,
    insert_approval_action,
    insert_claim,
    insert_source,
    link_claim_sources,
    list_claim_conflict_memberships,
    list_claim_sources,
    list_conflicts,
    list_pending_claims,
    trigger_embedding_refresh,
    update_claim_status,
)
from app.service import (
    build_claim_fingerprint,
    build_auto_review_decision,
    build_claim_ingest_response,
    detect_conflicting_claims,
    evaluate_claim_for_auto_review,
    find_near_duplicate_claim,
    normalize_conflicts,
    canonicalize_url,
)

router = APIRouter(prefix="/claims", tags=["claims"])


@router.post("/ingest")
async def claim_ingest(req: ClaimIngestRequest, x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    req.metadata["claim_fingerprint"] = build_claim_fingerprint(req)
    async with httpx.AsyncClient(timeout=20.0) as client:
        existing_by_fingerprint = await find_claim_by_fingerprint(client, req.world_id, req.metadata["claim_fingerprint"])
        existing_claims = await find_related_claims(
            client,
            world_id=req.world_id,
            entity_kind=req.entity_kind,
            entity_id=req.entity_id,
            claim_type=req.claim_type,
        )
        ai_judgement = await ai_judge_claim(req.model_dump(), existing_claims)
        if ai_judgement and not ai_judgement.should_store:
            return build_claim_ingest_response(claim_id="", linked_sources=0, conflict_ids=[], status=ai_judgement.status_hint)
        if ai_judgement and ai_judgement.layer:
            req.layer = ai_judgement.layer
        if ai_judgement and ai_judgement.confidence is not None:
            req.confidence = ai_judgement.confidence
        reused_claim = existing_by_fingerprint or find_near_duplicate_claim(req, existing_claims, req.metadata["claim_fingerprint"])
        if reused_claim:
            inserted_claim = reused_claim
        else:
            inserted_claim = await insert_claim(client, req, status=(ai_judgement.status_hint if ai_judgement else "pending"))
        claim_id = str(inserted_claim.get("id") or "")

        link_rows = []
        for source in req.sources:
            canonical_url = canonicalize_url(source.source_url) or source.source_url
            existing_source = await find_source_by_canonical_url(client, req.world_id, canonical_url)
            if existing_source:
                source_id = str(existing_source.get("id") or "")
            else:
                payload = source.model_dump()
                payload["canonical_url"] = canonical_url
                source_id = await insert_source(client, req.world_id, payload)
            link_rows.append({"source_id": source_id, "support_type": source.support_type, "excerpt": source.excerpt})
        linked_sources = await link_claim_sources(client, claim_id, link_rows)

        conflicts_with = [claim for claim in existing_claims if str(claim.get("id") or "") != claim_id]
        conflict_ids = []
        competing_ids = [] if reused_claim else detect_conflicting_claims(req, conflicts_with)
        if competing_ids:
            conflict_ids.append(
                await create_conflict(
                    client,
                    world_id=req.world_id,
                    entity_kind=req.entity_kind,
                    entity_id=req.entity_id,
                    topic=req.topic or req.claim_type,
                    claim_ids=[claim_id, *competing_ids],
                )
            )

    return build_claim_ingest_response(
        claim_id=claim_id,
        linked_sources=linked_sources,
        conflict_ids=conflict_ids,
        status=str(inserted_claim.get("status") or "pending"),
    )


@router.get("/pending")
async def claims_pending(world_id: str = "gensokyo_main", x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    async with httpx.AsyncClient(timeout=20.0) as client:
        return await list_pending_claims(client, world_id)


@router.post("/{claim_id}/review")
async def claim_review(claim_id: str, req: ClaimReviewRequest, x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    async with httpx.AsyncClient(timeout=20.0) as client:
        updated = await update_claim_status(client, claim_id, {"status": req.status, "review_note": req.note or None})
        logged = await insert_approval_action(
            client,
            {
                "target_type": "claim",
                "target_id": claim_id,
                "action": req.status,
                "reviewer": req.reviewer,
                "note": req.note or None,
            },
        )
        embedding_refresh = None
        if DB_MANAGER_EMBED_REFRESH_ENABLED and req.status == "accepted":
            embedding_refresh = await trigger_embedding_refresh(client, str(updated.get("world_id") or "gensokyo_main"))
    return {"claim": updated, "approval_logged": logged, "embedding_refresh": embedding_refresh}


@router.get("/conflicts")
async def claims_conflicts(world_id: str = "gensokyo_main", x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    async with httpx.AsyncClient(timeout=20.0) as client:
        rows = await list_conflicts(client, world_id)
    return normalize_conflicts(rows)


@router.post("/auto-review")
async def claims_auto_review(req: ClaimAutoReviewRequest, x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    decisions = []
    async with httpx.AsyncClient(timeout=20.0) as client:
        stored_policy_row = await get_policy(client, "auto_review")
        stored_policy = stored_policy_row.get("policy_value") if isinstance(stored_policy_row, dict) else None
        pending_rows = await list_pending_claims(client, req.world_id)
        for claim in pending_rows[: max(1, req.limit)]:
            claim_id = str(claim.get("id") or "")
            if not claim_id:
                continue
            previous_status = str(claim.get("status") or "pending")
            source_links = await list_claim_sources(client, claim_id)
            memberships = await list_claim_conflict_memberships(client, claim_id)
            outcome = evaluate_claim_for_auto_review(claim, source_links, memberships, stored_policy if isinstance(stored_policy, dict) else None)
            applied = False
            if not req.dry_run and outcome.next_status != previous_status:
                updated = await update_claim_status(
                    client,
                    claim_id,
                    {"status": outcome.next_status, "review_note": outcome.reason},
                )
                applied = bool(updated)
                if applied:
                    await insert_approval_action(
                        client,
                        {
                            "target_type": "claim",
                            "target_id": claim_id,
                            "action": outcome.next_status,
                            "reviewer": req.reviewer,
                            "note": outcome.reason,
                        },
                    )
                    if DB_MANAGER_EMBED_REFRESH_ENABLED and outcome.next_status == "accepted":
                        await trigger_embedding_refresh(client, req.world_id)
                    claim = await get_claim(client, claim_id)
            decisions.append(
                build_auto_review_decision(
                    claim_id=claim_id,
                    previous_status=previous_status,
                    next_status=outcome.next_status,
                    reason=outcome.reason,
                    applied=applied,
                ).model_dump()
            )
    return {"world_id": req.world_id, "decisions": decisions, "dry_run": req.dry_run}
