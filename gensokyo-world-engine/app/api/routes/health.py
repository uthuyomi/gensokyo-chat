from fastapi import APIRouter

from app import legacy

router = APIRouter()


@router.get("/health")
def health():
    return legacy.health()
