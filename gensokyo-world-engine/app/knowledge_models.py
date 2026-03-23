from __future__ import annotations

from typing import Any, Dict, List

from pydantic import BaseModel, Field


class KnowledgeEmbeddingRecord(BaseModel):
    document_id: str
    source_kind: str
    source_ref_id: str
    source_title: str
    content: str
    metadata: Dict[str, Any] = Field(default_factory=dict)
    embedding_model: str
    embedding_dimensions: int
    embedding: List[float]


class KnowledgeUniverseNode(BaseModel):
    id: str
    source_kind: str
    source_ref_id: str
    title: str
    summary: str
    x: float
    y: float
    z: float
    size: float
    metadata: Dict[str, Any] = Field(default_factory=dict)


class KnowledgeUniverseEdge(BaseModel):
    source: str
    target: str
    weight: float


class KnowledgeUniverseResponse(BaseModel):
    world_id: str
    node_count: int
    edge_count: int
    source_counts: Dict[str, int] = Field(default_factory=dict)
    nodes: List[KnowledgeUniverseNode]
    edges: List[KnowledgeUniverseEdge]
