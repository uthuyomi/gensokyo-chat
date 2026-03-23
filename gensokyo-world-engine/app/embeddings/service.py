from __future__ import annotations

from typing import List

import httpx
from openai import AsyncOpenAI

from app.embeddings.config import (
    OPENAI_API_KEY,
    WORLD_EMBEDDING_BATCH_SIZE,
    WORLD_EMBEDDING_JOB_LIMIT,
    WORLD_EMBEDDING_MODEL,
    require_openai_api_key,
)
from app.embeddings.models import EmbeddingWorkItem
from app.embeddings.repository import (
    build_result,
    fetch_pending_work,
    mark_job_failed,
    mark_jobs_processing,
    persist_embedding_result,
)


class WorldEmbeddingService:
    def __init__(
        self,
        *,
        postgrest_client: httpx.AsyncClient,
        openai_client: AsyncOpenAI | None = None,
        model: str = WORLD_EMBEDDING_MODEL,
        batch_size: int = WORLD_EMBEDDING_BATCH_SIZE,
        job_limit: int = WORLD_EMBEDDING_JOB_LIMIT,
    ) -> None:
        self._postgrest = postgrest_client
        self._model = model
        self._batch_size = max(1, batch_size)
        self._job_limit = max(1, job_limit)
        self._openai = openai_client

    def _ensure_openai(self) -> AsyncOpenAI:
        if self._openai is None:
            require_openai_api_key()
            self._openai = AsyncOpenAI(api_key=OPENAI_API_KEY)
        return self._openai

    async def run_once(self, *, world_id: str) -> dict:
        work = await fetch_pending_work(
            self._postgrest,
            world_id=world_id,
            limit=self._job_limit,
        )
        if not work:
            return {
                "world_id": world_id,
                "model": self._model,
                "processed": 0,
                "failed": 0,
            }

        openai_client = self._ensure_openai()
        processed = 0
        failed = 0

        for start in range(0, len(work), self._batch_size):
            batch = work[start : start + self._batch_size]
            await mark_jobs_processing(self._postgrest, (item.job.id for item in batch), self._model)
            try:
                response = await openai_client.embeddings.create(
                    model=self._model,
                    input=[item.document.content for item in batch],
                )
                vectors = [item.embedding for item in response.data]
                if len(vectors) != len(batch):
                    raise RuntimeError(
                        f"embedding_count_mismatch:{len(vectors)}:{len(batch)}"
                    )
                for work_item, vector in zip(batch, vectors):
                    result = build_result(
                        work_item=work_item,
                        model=self._model,
                        embedding=vector,
                    )
                    await persist_embedding_result(
                        self._postgrest,
                        work_item=work_item,
                        result=result,
                    )
                    processed += 1
            except Exception as exc:
                message = str(exc) or exc.__class__.__name__
                for work_item in batch:
                    await mark_job_failed(self._postgrest, work_item.job.id, message)
                    failed += 1

        return {
            "world_id": world_id,
            "model": self._model,
            "processed": processed,
            "failed": failed,
        }


async def preview_pending_work(
    *,
    postgrest_client: httpx.AsyncClient,
    world_id: str,
    limit: int = 10,
) -> List[EmbeddingWorkItem]:
    return await fetch_pending_work(postgrest_client, world_id=world_id, limit=limit)
