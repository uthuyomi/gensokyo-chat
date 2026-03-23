from __future__ import annotations

import argparse
import asyncio
import json
import sys
from pathlib import Path

import httpx


ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))


from app.config import auth_headers, require_supabase  # noqa: E402
from app.embeddings.config import (  # noqa: E402
    WORLD_EMBEDDING_BATCH_SIZE,
    WORLD_EMBEDDING_JOB_LIMIT,
    WORLD_EMBEDDING_MODEL,
    WORLD_EMBEDDING_WORLD_ID,
)
from app.embeddings.repository import fetch_embedding_counts, fetch_job_status_counts  # noqa: E402
from app.embeddings.service import WorldEmbeddingService, preview_pending_work  # noqa: E402


async def _run(args: argparse.Namespace) -> int:
    require_supabase()
    headers = auth_headers()
    timeout = httpx.Timeout(60.0, connect=20.0)
    async with httpx.AsyncClient(headers=headers, timeout=timeout) as client:
        if args.preview:
            items = await preview_pending_work(
                postgrest_client=client,
                world_id=args.world_id,
                limit=args.preview,
            )
            payload = [
                {
                    "job_id": item.job.id,
                    "document_id": item.document.id,
                    "source_kind": item.document.source_kind,
                    "source_ref_id": item.document.source_ref_id,
                    "source_title": item.document.source_title,
                }
                for item in items
            ]
            print(json.dumps(payload, ensure_ascii=False, indent=2))
            return 0

        service = WorldEmbeddingService(
            postgrest_client=client,
            model=args.model or WORLD_EMBEDDING_MODEL,
            batch_size=args.batch_size or WORLD_EMBEDDING_BATCH_SIZE,
            job_limit=args.job_limit or WORLD_EMBEDDING_JOB_LIMIT,
        )
        result = await service.run_once(world_id=args.world_id)
        counts = await fetch_embedding_counts(client, world_id=args.world_id)
        job_counts = await fetch_job_status_counts(client, world_id=args.world_id)
        print(
            json.dumps(
                {
                    "run": result,
                    "documents": counts,
                    "jobs": job_counts,
                },
                ensure_ascii=False,
                indent=2,
            )
        )
        return 0 if result.get("failed", 0) == 0 else 1


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Embed queued world documents into world_embeddings.",
    )
    parser.add_argument(
        "--world-id",
        default=WORLD_EMBEDDING_WORLD_ID,
        help="World id to process. Defaults to WORLD_EMBEDDING_WORLD_ID or gensokyo_main.",
    )
    parser.add_argument(
        "--model",
        default=None,
        help="Embedding model override. Defaults to WORLD_EMBEDDING_MODEL.",
    )
    parser.add_argument(
        "--batch-size",
        type=int,
        default=None,
        help="Batch size override. Defaults to WORLD_EMBEDDING_BATCH_SIZE.",
    )
    parser.add_argument(
        "--job-limit",
        type=int,
        default=None,
        help="Job limit override. Defaults to WORLD_EMBEDDING_JOB_LIMIT.",
    )
    parser.add_argument(
        "--preview",
        type=int,
        default=0,
        help="Preview pending jobs instead of embedding them.",
    )
    args = parser.parse_args()
    return asyncio.run(_run(args))


if __name__ == "__main__":
    raise SystemExit(main())
