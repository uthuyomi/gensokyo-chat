from __future__ import annotations

import httpx
from fastapi import APIRouter, Header, HTTPException

from app.config import require_supabase
from app.legacy import check_secret
from app.models import WebIngestRequest
from app.repository import insert_web_candidate
from app.scheduler import process_web_ingest_queue_once
from app.service import build_web_ingest_response, canonicalize_url, extract_web_preview

router = APIRouter(prefix="/ingest", tags=["ingest"])


@router.post("/web-page")
async def ingest_web_page(req: WebIngestRequest, x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    async with httpx.AsyncClient(timeout=20.0, follow_redirects=True) as client:
        response = await client.get(req.url)
        if response.status_code >= 400:
            raise HTTPException(status_code=500, detail=f"web_fetch_failed:{response.status_code}:{response.text[:200]}")
        html = response.text
        title, summary = extract_web_preview(html)
        stored = await insert_web_candidate(
            client,
            {
                "world_id": req.world_id,
                "url": req.url,
                "canonical_url": canonicalize_url(req.url) or req.url,
                "source_kind": req.source_kind,
                "entity_kind": req.entity_kind or None,
                "entity_id": req.entity_id or None,
                "topic": req.topic or None,
                "claim_type": req.claim_type,
                "layer": req.layer,
                "extract_as_claim": req.extract_as_claim,
                "title": title or None,
                "summary": summary or None,
                "note": req.note or None,
                "status": "queued",
            },
        )
    return build_web_ingest_response(stored=stored, fetched=True, title=title, summary=summary)


@router.post("/process-queue")
async def ingest_process_queue(x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    await process_web_ingest_queue_once()
    return {"ok": True}
