from __future__ import annotations

import math
from collections import Counter
from typing import Dict, List, Optional

import httpx

from app.knowledge_models import (
    KnowledgeEmbeddingRecord,
    KnowledgeUniverseEdge,
    KnowledgeUniverseNode,
    KnowledgeUniverseResponse,
)
from app.knowledge_repository import fetch_knowledge_embeddings
from app.world_logic import check_secret

_AXIS_SEEDS = (0x13579BDF, 0x2468ACE1, 0x89ABCDEF)
_KIND_COLORS = {
    "canon_claim": "#f97316",
    "lore_entry": "#22c55e",
    "wiki_page": "#3b82f6",
    "chronicle_entry": "#eab308",
    "chat_context": "#ec4899",
}
_KIND_SIZES = {
    "canon_claim": 1.25,
    "lore_entry": 1.1,
    "wiki_page": 1.2,
    "chronicle_entry": 1.35,
    "chat_context": 1.0,
}
_MAX_KNOWLEDGE_UNIVERSE_LIMIT = 2000


def _unit_normalize(values: List[float]) -> List[float]:
    norm = math.sqrt(sum(v * v for v in values))
    if norm <= 1e-9:
        return [0.0 for _ in values]
    return [v / norm for v in values]


def _stable_axis_weight(axis_seed: int, dim_index: int) -> float:
    mixed = (axis_seed ^ ((dim_index + 1) * 0x9E3779B1)) & 0xFFFFFFFF
    mixed ^= (mixed >> 16)
    mixed = (mixed * 0x7FEB352D) & 0xFFFFFFFF
    mixed ^= (mixed >> 15)
    mixed = (mixed * 0x846CA68B) & 0xFFFFFFFF
    mixed ^= (mixed >> 16)
    return (mixed / 0xFFFFFFFF) * 2.0 - 1.0


def _project_embedding_to_3d(values: List[float]) -> tuple[float, float, float]:
    normalized = _unit_normalize(values)
    coords: List[float] = []
    for axis_seed in _AXIS_SEEDS:
        total = 0.0
        for dim_index, value in enumerate(normalized):
            total += value * _stable_axis_weight(axis_seed, dim_index)
        coords.append(total)
    return coords[0], coords[1], coords[2]


def _cosine_similarity(left: List[float], right: List[float]) -> float:
    if not left or not right or len(left) != len(right):
        return 0.0
    left_norm = math.sqrt(sum(v * v for v in left))
    right_norm = math.sqrt(sum(v * v for v in right))
    if left_norm <= 1e-9 or right_norm <= 1e-9:
        return 0.0
    return sum(a * b for a, b in zip(left, right)) / (left_norm * right_norm)


def _truncate_summary(text: str, limit: int = 180) -> str:
    clean = " ".join(str(text or "").split())
    if len(clean) <= limit:
        return clean
    return clean[: limit - 1].rstrip() + "…"


def _scale_nodes(records: List[KnowledgeEmbeddingRecord]) -> List[KnowledgeUniverseNode]:
    raw_points = [_project_embedding_to_3d(record.embedding) for record in records]
    if not raw_points:
        return []

    xs = [point[0] for point in raw_points]
    ys = [point[1] for point in raw_points]
    zs = [point[2] for point in raw_points]
    center_x = sum(xs) / len(xs)
    center_y = sum(ys) / len(ys)
    center_z = sum(zs) / len(zs)
    centered = [(x - center_x, y - center_y, z - center_z) for x, y, z in raw_points]
    max_radius = max((math.sqrt(x * x + y * y + z * z) for x, y, z in centered), default=1.0)
    scale = 1.0 if max_radius <= 1e-9 else 28.0 / max_radius

    nodes: List[KnowledgeUniverseNode] = []
    for record, point in zip(records, centered):
        nodes.append(
            KnowledgeUniverseNode(
                id=record.document_id,
                source_kind=record.source_kind,
                source_ref_id=record.source_ref_id,
                title=record.source_title,
                summary=_truncate_summary(record.content),
                x=round(point[0] * scale, 5),
                y=round(point[1] * scale, 5),
                z=round(point[2] * scale, 5),
                size=_KIND_SIZES.get(record.source_kind, 1.0),
                metadata={
                    **record.metadata,
                    "embedding_model": record.embedding_model,
                    "embedding_dimensions": record.embedding_dimensions,
                    "color": _KIND_COLORS.get(record.source_kind, "#94a3b8"),
                },
            )
        )
    return nodes


def _build_edges(
    records: List[KnowledgeEmbeddingRecord],
    *,
    max_edges_per_node: int,
    similarity_threshold: float,
) -> List[KnowledgeUniverseEdge]:
    edges: List[KnowledgeUniverseEdge] = []
    seen: set[tuple[str, str]] = set()
    for index, record in enumerate(records):
        scored: List[tuple[float, str]] = []
        for other_index, other in enumerate(records):
            if index == other_index:
                continue
            similarity = _cosine_similarity(record.embedding, other.embedding)
            if similarity < similarity_threshold:
                continue
            scored.append((similarity, other.document_id))
        scored.sort(key=lambda item: item[0], reverse=True)
        for similarity, target_id in scored[:max(1, max_edges_per_node)]:
            pair = tuple(sorted((record.document_id, target_id)))
            if pair in seen:
                continue
            seen.add(pair)
            edges.append(
                KnowledgeUniverseEdge(
                    source=pair[0],
                    target=pair[1],
                    weight=round(similarity, 4),
                )
            )
    return edges


async def get_knowledge_universe(
    *,
    world_id: str,
    limit: int,
    embedding_model: Optional[str],
    max_edges_per_node: int,
    similarity_threshold: float,
    x_world_secret: Optional[str],
) -> KnowledgeUniverseResponse:
    check_secret(x_world_secret)
    async with httpx.AsyncClient(timeout=30.0) as client:
        records = await fetch_knowledge_embeddings(
            client,
            world_id=world_id,
            limit=max(1, min(limit, _MAX_KNOWLEDGE_UNIVERSE_LIMIT)),
            embedding_model=embedding_model,
        )

    nodes = _scale_nodes(records)
    edges = _build_edges(
        records,
        max_edges_per_node=max_edges_per_node,
        similarity_threshold=similarity_threshold,
    )
    source_counts = dict(Counter(record.source_kind for record in records))
    return KnowledgeUniverseResponse(
        world_id=world_id,
        node_count=len(nodes),
        edge_count=len(edges),
        source_counts=source_counts,
        nodes=nodes,
        edges=edges,
    )
