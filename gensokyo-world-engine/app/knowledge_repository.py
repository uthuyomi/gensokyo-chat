from __future__ import annotations

import json
from typing import Any, List
from urllib.parse import quote

import httpx
from fastapi import HTTPException

from app.knowledge_models import KnowledgeEmbeddingRecord
from app.postgrest import table_url
from app.config import auth_headers


def _parse_embedding(raw: Any) -> List[float]:
    if isinstance(raw, list):
        return [float(x) for x in raw]
    if isinstance(raw, str):
        text = raw.strip()
        if text.startswith("[") and text.endswith("]"):
            parsed = json.loads(text)
            if isinstance(parsed, list):
                return [float(x) for x in parsed]
    raise ValueError(f"unsupported_embedding_payload:{type(raw).__name__}")


async def fetch_knowledge_embeddings(
    client: httpx.AsyncClient,
    *,
    world_id: str,
    limit: int,
    embedding_model: str | None = None,
) -> List[KnowledgeEmbeddingRecord]:
    headers = auth_headers()
    params = [
        "select=document_id,embedding_model,embedding_dimensions,embedding,"
        "world_embedding_documents!inner(id,world_id,source_kind,source_ref_id,source_title,content,metadata)"
    ]
    params.append(f"world_embedding_documents.world_id=eq.{quote(world_id, safe='')}")
    if embedding_model:
        params.append(f"embedding_model=eq.{quote(embedding_model, safe='')}")
    params.append("embedding=not.is.null")
    params.append(f"limit={max(limit, 1)}")
    query = "?" + "&".join(params)
    response = await client.get(table_url("world_embeddings") + query, headers=headers)
    if response.status_code >= 400:
        raise HTTPException(
            status_code=500,
            detail=f"knowledge_embeddings_failed:{response.status_code}:{response.text}",
        )
    payload = response.json()
    rows = payload if isinstance(payload, list) else []
    records: List[KnowledgeEmbeddingRecord] = []
    for row in rows:
        if not isinstance(row, dict):
            continue
        doc = row.get("world_embedding_documents")
        if not isinstance(doc, dict):
            continue
        try:
            records.append(
                KnowledgeEmbeddingRecord(
                    document_id=str(row["document_id"]),
                    source_kind=str(doc["source_kind"]),
                    source_ref_id=str(doc["source_ref_id"]),
                    source_title=str(doc["source_title"]),
                    content=str(doc["content"]),
                    metadata=dict(doc.get("metadata") or {}),
                    embedding_model=str(row["embedding_model"]),
                    embedding_dimensions=int(row["embedding_dimensions"]),
                    embedding=_parse_embedding(row["embedding"]),
                )
            )
        except Exception:
            continue
    return records
