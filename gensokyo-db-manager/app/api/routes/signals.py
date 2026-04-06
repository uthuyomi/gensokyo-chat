from __future__ import annotations

import httpx
from fastapi import APIRouter, Header

from app.ai import ai_judge_signal, ai_schema_suggest
from app.config import require_supabase
from app.legacy import check_secret
from app.models import InteractionSignalRequest, SchemaSuggestRequest
from app.repository import insert_interaction_signal
from app.service import score_interaction_signal, suggest_schema

router = APIRouter(prefix="/signals", tags=["signals"])


@router.post("/interaction")
async def interaction_signal(req: InteractionSignalRequest, x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    scored_ai = await ai_judge_signal(req)
    scored = score_interaction_signal(req)
    if scored_ai:
        scored.accepted = scored_ai.accepted
        scored.importance_score = scored_ai.importance_score
        scored.schema_decision = scored_ai.schema_decision
        scored.note = scored_ai.note
    async with httpx.AsyncClient(timeout=20.0) as client:
        stored = False
        if scored.accepted:
            stored = await insert_interaction_signal(client, req)

    schema_req = SchemaSuggestRequest(
        world_id=req.world_id,
        need=req.reason or req.signal_type,
        candidate_name=f"world_{req.entity_kind}_extensions" if req.entity_kind else "",
        observed_fields=req.proposed_fields,
        expected_rows=max(1, len(req.proposed_fields) * 3),
        repeats_per_entity=2 if req.proposed_fields else 0,
        requires_history="history" in req.reason.lower() or "timeline" in req.reason.lower(),
        context=req.metadata,
    )
    schema_result = await ai_schema_suggest(schema_req) or suggest_schema(schema_req)
    payload = scored.model_dump()
    payload["stored"] = stored
    payload["schema_decision"] = schema_result.decision
    payload["note"] = (
        f"{scored.note} Suggested next step: {schema_result.decision}."
        if scored.accepted
        else "Signal was too weak to store automatically."
    )
    return payload
