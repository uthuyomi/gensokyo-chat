from __future__ import annotations

from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class EmbeddingJob(BaseModel):
    id: str
    world_id: str
    document_id: str
    job_kind: str = "embed"
    status: str
    embedding_model: Optional[str] = None
    error_message: Optional[str] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)


class EmbeddingDocument(BaseModel):
    id: str
    world_id: str
    source_kind: str
    source_ref_id: str
    source_title: str
    content: str
    metadata: Dict[str, Any] = Field(default_factory=dict)


class EmbeddingWorkItem(BaseModel):
    job: EmbeddingJob
    document: EmbeddingDocument


class EmbeddingResult(BaseModel):
    document_id: str
    embedding_model: str
    embedding_dimensions: int
    embedding: List[float]
    content_hash: str
    metadata: Dict[str, Any] = Field(default_factory=dict)
