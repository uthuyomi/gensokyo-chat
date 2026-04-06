from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

from openai import OpenAI

ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from persona_core.storage.env_loader import load_dotenv
from persona_core.storage.supabase_rest import SupabaseConfig, SupabaseRESTClient
from persona_core.storage.supabase_store import SupabasePersonaDB


def _cache_ttl_sec(raw: Optional[str]) -> int:
    try:
        value = int(raw or os.getenv("SIGMARIS_OPENAI_FILE_CACHE_TTL_SEC", "604800") or "604800")
    except Exception:
        value = 604800
    return max(0, value)


def _iter_attachment_rows(
    db: SupabasePersonaDB,
    *,
    attachment_id: Optional[str],
    user_id: Optional[str],
    limit: int,
    batch_size: int,
) -> List[Dict[str, Any]]:
    if attachment_id:
        return db.list_attachments(attachment_id=attachment_id, limit=1, offset=0)

    rows: List[Dict[str, Any]] = []
    offset = 0
    remaining = max(0, int(limit))
    while remaining > 0:
        page_size = min(max(1, int(batch_size)), remaining)
        page = db.list_attachments(user_id=user_id, limit=page_size, offset=offset)
        if not page:
            break
        rows.extend(page)
        offset += len(page)
        remaining -= len(page)
        if len(page) < page_size:
            break
    return rows


def _stale_entries(row: Dict[str, Any], *, ttl_sec: int, now_unix: int) -> List[Dict[str, Any]]:
    meta = row.get("meta") if isinstance(row.get("meta"), dict) else {}
    openai_files = meta.get("openai_files") if isinstance(meta.get("openai_files"), dict) else {}
    out: List[Dict[str, Any]] = []
    for purpose, entry in openai_files.items():
        if not isinstance(entry, dict):
            continue
        updated = entry.get("updated_at_unix")
        file_id = str(entry.get("file_id") or "").strip()
        expired = False
        if not file_id:
            expired = True
        elif ttl_sec > 0:
            if not isinstance(updated, (int, float)):
                expired = True
            else:
                expired = (now_unix - int(updated)) > ttl_sec
        if expired:
            out.append(
                {
                    "attachment_id": str(row.get("attachment_id") or ""),
                    "purpose": str(purpose),
                    "file_id": file_id or None,
                    "file_name": str(row.get("file_name") or ""),
                    "mime_type": str(row.get("mime_type") or ""),
                    "updated_at_unix": int(updated) if isinstance(updated, (int, float)) else None,
                }
            )
    return out


def _cleanup_row(
    *,
    db: SupabasePersonaDB,
    row: Dict[str, Any],
    stale: List[Dict[str, Any]],
    client: Optional[OpenAI],
    delete_remote: bool,
) -> Dict[str, Any]:
    meta = dict(row.get("meta")) if isinstance(row.get("meta"), dict) else {}
    openai_files = dict(meta.get("openai_files")) if isinstance(meta.get("openai_files"), dict) else {}
    deleted_remote: List[str] = []
    failed_remote: List[Dict[str, str]] = []

    for item in stale:
        purpose = str(item.get("purpose") or "").strip()
        file_id = str(item.get("file_id") or "").strip()
        if purpose:
            openai_files.pop(purpose, None)
        if delete_remote and client is not None and file_id:
            try:
                client.files.delete(file_id)
                deleted_remote.append(file_id)
            except Exception as e:
                failed_remote.append({"file_id": file_id, "error": str(e)})

    meta["openai_files"] = openai_files
    db.update_attachment_meta(attachment_id=str(row.get("attachment_id") or ""), meta=meta)
    return {
        "attachment_id": str(row.get("attachment_id") or ""),
        "removed_entries": len(stale),
        "deleted_remote_file_ids": deleted_remote,
        "remote_delete_errors": failed_remote,
    }


def main() -> int:
    load_dotenv(override=False)

    parser = argparse.ArgumentParser(description="Inspect or clean stale OpenAI file cache entries for attachments.")
    parser.add_argument("--attachment-id", help="Inspect or clean a single attachment_id")
    parser.add_argument("--user-id", help="Limit to a single user_id")
    parser.add_argument("--limit", type=int, default=500, help="Maximum attachment rows to scan")
    parser.add_argument("--batch-size", type=int, default=100, help="Page size for attachment scan")
    parser.add_argument("--ttl-sec", type=int, default=None, help="Override stale TTL seconds")
    parser.add_argument("--cleanup-stale", action="store_true", help="Remove stale openai_files entries from metadata")
    parser.add_argument("--delete-remote", action="store_true", help="Delete stale remote OpenAI files too")
    parser.add_argument("--dry-run", action="store_true", help="Do not mutate metadata or remote files")
    args = parser.parse_args()

    cfg = SupabaseConfig.from_env()
    if cfg is None:
        raise SystemExit("Supabase is not configured")

    db = SupabasePersonaDB(SupabaseRESTClient(cfg))
    ttl_sec = _cache_ttl_sec(str(args.ttl_sec) if args.ttl_sec is not None else None)
    rows = _iter_attachment_rows(
        db,
        attachment_id=args.attachment_id,
        user_id=args.user_id,
        limit=max(1, int(args.limit)),
        batch_size=max(1, int(args.batch_size)),
    )

    now_unix = __import__("time").time()
    findings: List[Dict[str, Any]] = []
    for row in rows:
        stale = _stale_entries(row, ttl_sec=ttl_sec, now_unix=int(now_unix))
        if stale:
            findings.append(
                {
                    "attachment_id": str(row.get("attachment_id") or ""),
                    "user_id": str(row.get("user_id") or ""),
                    "file_name": str(row.get("file_name") or ""),
                    "stale_entries": stale,
                }
            )

    result: Dict[str, Any] = {
        "scanned_rows": len(rows),
        "stale_attachment_count": len(findings),
        "ttl_sec": ttl_sec,
        "cleanup_requested": bool(args.cleanup_stale),
        "dry_run": bool(args.dry_run),
        "findings": findings,
    }

    if args.cleanup_stale and findings and not args.dry_run:
        client = OpenAI(api_key=os.getenv("OPENAI_API_KEY")) if args.delete_remote else None
        cleanup_results: List[Dict[str, Any]] = []
        row_map = {str(row.get("attachment_id") or ""): row for row in rows}
        for finding in findings:
            aid = str(finding.get("attachment_id") or "")
            row = row_map.get(aid)
            if not isinstance(row, dict):
                continue
            cleanup_results.append(
                _cleanup_row(
                    db=db,
                    row=row,
                    stale=(finding.get("stale_entries") if isinstance(finding.get("stale_entries"), list) else []),
                    client=client,
                    delete_remote=bool(args.delete_remote),
                )
            )
        result["cleanup_results"] = cleanup_results

    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
