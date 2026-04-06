from __future__ import annotations

from typing import Any

from fastapi import Header, HTTPException
from fastapi.responses import JSONResponse

from app.config import DB_MANAGER_SECRET


class Utf8JSONResponse(JSONResponse):
    media_type = "application/json; charset=utf-8"


def health() -> dict[str, bool]:
    return {"ok": True}


def check_secret(x_db_manager_secret: str | None = Header(default=None)) -> None:
    if DB_MANAGER_SECRET and x_db_manager_secret != DB_MANAGER_SECRET:
        raise HTTPException(status_code=403, detail="db_manager_forbidden")


def safe_str(value: Any) -> str:
    return str(value or "").strip()
