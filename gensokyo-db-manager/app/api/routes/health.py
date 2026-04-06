from fastapi import APIRouter

from app import legacy
from app.scheduler import scheduler_status

router = APIRouter()


@router.get("/health")
def health():
    payload = legacy.health()
    payload["scheduler"] = scheduler_status()
    return payload
