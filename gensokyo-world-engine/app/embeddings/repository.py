from __future__ import annotations

import hashlib
import json
from typing import Iterable, List, Sequence
from urllib.parse import quote

import httpx

from app.embeddings.models import EmbeddingDocument, EmbeddingJob, EmbeddingResult, EmbeddingWorkItem
from app.postgrest import postgrest_select, postgrest_update, postgrest_upsert_one, table_url


def _vector_literal(values: Sequence[float]) -> str:
    return "[" + ",".join(format(v, ".9g") for v in values) + "]"


def _content_hash(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


async def fetch_pending_work(
    client: httpx.AsyncClient,
    *,
    world_id: str,
    limit: int,
) -> List[EmbeddingWorkItem]:
    jobs_query = (
        f"?select=id,world_id,document_id,job_kind,status,embedding_model,error_message,metadata"
        f"&world_id=eq.{quote(world_id, safe='')}"
        f"&status=eq.pending"
        f"&order=created_at.asc"
        f"&limit={limit}"
    )
    jobs_raw = await postgrest_select(client, "world_embedding_jobs", jobs_query)
    jobs = [EmbeddingJob.model_validate(item) for item in jobs_raw if isinstance(item, dict)]
    if not jobs:
        return []

    document_ids = ",".join(quote(job.document_id, safe="") for job in jobs)
    docs_query = (
        "?select=id,world_id,source_kind,source_ref_id,source_title,content,metadata"
        f"&id=in.({document_ids})"
    )
    docs_raw = await postgrest_select(client, "world_embedding_documents", docs_query)
    docs = {
        doc.id: doc
        for doc in (
            EmbeddingDocument.model_validate(item)
            for item in docs_raw
            if isinstance(item, dict)
        )
    }

    work: List[EmbeddingWorkItem] = []
    for job in jobs:
        doc = docs.get(job.document_id)
        if not doc:
            await mark_job_failed(client, job.id, "embedding_document_missing")
            continue
        work.append(EmbeddingWorkItem(job=job, document=doc))
    return work


async def mark_jobs_processing(client: httpx.AsyncClient, job_ids: Iterable[str], model: str) -> None:
    for job_id in job_ids:
        await postgrest_update(
            client,
            "world_embedding_jobs",
            f"?id=eq.{quote(job_id, safe='')}",
            {
                "status": "processing",
                "embedding_model": model,
                "error_message": None,
            },
        )


async def mark_job_failed(client: httpx.AsyncClient, job_id: str, message: str) -> None:
    await postgrest_update(
        client,
        "world_embedding_jobs",
        f"?id=eq.{quote(job_id, safe='')}",
        {
            "status": "failed",
            "error_message": message[:1000],
        },
    )


async def persist_embedding_result(
    client: httpx.AsyncClient,
    *,
    work_item: EmbeddingWorkItem,
    result: EmbeddingResult,
) -> None:
    row = {
        "id": f"embedding:{result.embedding_model}:{result.document_id}",
        "world_id": work_item.document.world_id,
        "document_id": result.document_id,
        "embedding_model": result.embedding_model,
        "embedding_dimensions": result.embedding_dimensions,
        "embedding": _vector_literal(result.embedding),
        "content_hash": result.content_hash,
        "metadata": result.metadata,
    }
    await postgrest_upsert_one(client, "world_embeddings", row, "document_id,embedding_model")
    await postgrest_update(
        client,
        "world_embedding_jobs",
        f"?id=eq.{quote(work_item.job.id, safe='')}",
        {
            "status": "completed",
            "embedding_model": result.embedding_model,
            "error_message": None,
        },
    )


def build_result(
    *,
    work_item: EmbeddingWorkItem,
    model: str,
    embedding: Sequence[float],
) -> EmbeddingResult:
    return EmbeddingResult(
        document_id=work_item.document.id,
        embedding_model=model,
        embedding_dimensions=len(embedding),
        embedding=list(embedding),
        content_hash=_content_hash(work_item.document.content),
        metadata={
            "source_kind": work_item.document.source_kind,
            "source_ref_id": work_item.document.source_ref_id,
            "source_title": work_item.document.source_title,
            "job_id": work_item.job.id,
        },
    )


async def fetch_embedding_counts(client: httpx.AsyncClient, *, world_id: str) -> List[dict]:
    query = (
        "?select=source_kind,document_count"
        f"&world_id=eq.{quote(world_id, safe='')}"
        "&order=source_kind.asc"
    )
    response = await client.get(table_url("world_embedding_source_counts") + query, headers={
        **client.headers,
        "Accept": "application/json",
    })
    response.raise_for_status()
    data = response.json()
    return data if isinstance(data, list) else []


async def fetch_job_status_counts(client: httpx.AsyncClient, *, world_id: str) -> List[dict]:
    query = (
        "?select=status"
        f"&world_id=eq.{quote(world_id, safe='')}"
    )
    rows = await postgrest_select(client, "world_embedding_jobs", query)
    counts: dict[str, int] = {}
    for row in rows:
        status = str((row or {}).get("status") or "unknown")
        counts[status] = counts.get(status, 0) + 1
    return [{"status": key, "count": value} for key, value in sorted(counts.items())]
