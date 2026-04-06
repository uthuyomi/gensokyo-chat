from __future__ import annotations

import httpx
from fastapi import APIRouter, Header

from app.ai import ai_schema_suggest
from app.config import require_supabase
from app.legacy import check_secret
from app.models import MigrationDraftRequest, SchemaSuggestRequest
from app.repository import insert_schema_proposal
from app.service import build_migration_draft, suggest_schema

router = APIRouter(prefix="/schema", tags=["schema"])


@router.post("/suggest")
async def schema_suggest(req: SchemaSuggestRequest, x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    require_supabase()
    result = await ai_schema_suggest(req) or suggest_schema(req)
    async with httpx.AsyncClient(timeout=20.0) as client:
        stored = await insert_schema_proposal(
            client,
            request=req,
            decision=result.decision,
            reason=result.reason,
            suggested_table=result.suggested_table,
            suggested_columns=result.suggested_columns,
        )
    payload = result.model_dump()
    payload["stored"] = stored
    return payload


@router.post("/migration-draft")
async def schema_migration_draft(req: MigrationDraftRequest, x_db_manager_secret: str | None = Header(default=None)):
    check_secret(x_db_manager_secret)
    return build_migration_draft(req)
