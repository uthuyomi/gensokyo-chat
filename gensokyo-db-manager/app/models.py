from __future__ import annotations

from typing import Any, Dict, List, Literal

from pydantic import BaseModel, Field


LayerType = Literal["official_primary", "official_secondary", "fanon_major", "fanon_variant", "local_extension"]
ClaimStatus = Literal["pending", "accepted", "disputed", "rejected"]


class CoverageItem(BaseModel):
    table: str
    count: int = 0
    exists: bool = True
    note: str = ""


class CoveragePreviewResponse(BaseModel):
    world_id: str
    items: List[CoverageItem]
    missing_or_thin: List[str]


class SchemaSuggestRequest(BaseModel):
    world_id: str = "gensokyo_main"
    need: str = ""
    candidate_name: str = ""
    observed_fields: List[str] = Field(default_factory=list)
    expected_rows: int = 0
    repeats_per_entity: int = 0
    requires_history: bool = False
    context: Dict[str, Any] = Field(default_factory=dict)


class SchemaSuggestResponse(BaseModel):
    decision: Literal["reuse_existing", "extend_existing", "create_table"]
    reason: str
    suggested_table: str = ""
    suggested_columns: List[str] = Field(default_factory=list)
    stored: bool = False


class InteractionSignalRequest(BaseModel):
    world_id: str = "gensokyo_main"
    signal_type: str = "missing_fact"
    entity_kind: str = ""
    entity_id: str = ""
    entity_name: str = ""
    source_text: str = ""
    source_url: str = ""
    observed_in: str = "user_interaction"
    reason: str = ""
    user_message: str = ""
    assistant_message: str = ""
    proposed_fields: List[str] = Field(default_factory=list)
    metadata: Dict[str, Any] = Field(default_factory=dict)


class InteractionSignalResponse(BaseModel):
    accepted: bool
    stored: bool
    importance_score: float
    should_follow_up_schema: bool
    schema_decision: str
    note: str


class ClaimSourceInput(BaseModel):
    source_kind: str
    title: str
    source_url: str = ""
    citation: str = ""
    origin: str = ""
    authority_score: float = 0.5
    published_at: str = ""
    excerpt: str = ""
    support_type: Literal["supports", "contradicts", "contextual"] = "supports"
    metadata: Dict[str, Any] = Field(default_factory=dict)


class ClaimIngestRequest(BaseModel):
    world_id: str = "gensokyo_main"
    entity_kind: str
    entity_id: str = ""
    topic: str = ""
    claim_type: str = "fact"
    layer: LayerType = "official_primary"
    claim_text: str
    confidence: float = 0.8
    temporal_scope: str = ""
    metadata: Dict[str, Any] = Field(default_factory=dict)
    sources: List[ClaimSourceInput] = Field(default_factory=list)


class ClaimIngestResponse(BaseModel):
    claim_id: str
    status: ClaimStatus
    linked_sources: int
    conflict_detected: bool
    conflict_ids: List[str] = Field(default_factory=list)


class ClaimReviewRequest(BaseModel):
    status: ClaimStatus
    reviewer: str = "system"
    note: str = ""


class ClaimAutoReviewRequest(BaseModel):
    world_id: str = "gensokyo_main"
    limit: int = 25
    reviewer: str = "auto-review"
    dry_run: bool = False


class ClaimAutoReviewDecision(BaseModel):
    claim_id: str
    previous_status: ClaimStatus
    next_status: ClaimStatus
    reason: str
    applied: bool


class ConflictRecord(BaseModel):
    id: str
    topic: str
    resolution_status: str
    claim_ids: List[str] = Field(default_factory=list)


class WebIngestRequest(BaseModel):
    world_id: str = "gensokyo_main"
    url: str
    source_kind: str = "web_article"
    entity_kind: str = ""
    entity_id: str = ""
    topic: str = ""
    claim_type: str = "fact"
    layer: LayerType = "official_secondary"
    extract_as_claim: bool = True
    note: str = ""


class WebIngestResponse(BaseModel):
    accepted: bool
    stored: bool
    fetched: bool
    title: str = ""
    summary: str = ""
    suggested_signal: str = ""


class DiscoverySourceRequest(BaseModel):
    world_id: str = "gensokyo_main"
    source_name: str
    source_kind: Literal["rss", "sitemap", "index_page", "manual_list"] = "rss"
    start_url: str
    entity_kind: str = ""
    entity_id: str = ""
    topic: str = ""
    claim_type: str = "fact"
    layer: LayerType = "official_secondary"
    include_patterns: List[str] = Field(default_factory=list)
    exclude_patterns: List[str] = Field(default_factory=list)
    max_urls_per_run: int = 20
    metadata: Dict[str, Any] = Field(default_factory=dict)


class DiscoveryRunRequest(BaseModel):
    world_id: str = "gensokyo_main"
    limit: int = 5
    dry_run: bool = False


class DiscoveryPresetInstallRequest(BaseModel):
    world_id: str = "gensokyo_main"
    preset_name: Literal["official_touhou"] = "official_touhou"
    overwrite_existing: bool = False


class AIClaimCandidate(BaseModel):
    entity_kind: str
    entity_id: str = ""
    topic: str = ""
    claim_type: str = "fact"
    layer: LayerType = "official_secondary"
    claim_text: str
    confidence: float = 0.6
    temporal_scope: str = ""
    reason: str = ""


class AIClaimJudgement(BaseModel):
    should_store: bool = True
    status_hint: ClaimStatus = "pending"
    layer: LayerType | None = None
    confidence: float | None = None
    reason: str = ""
    schema_signal: str = ""


class AISignalJudgement(BaseModel):
    accepted: bool
    importance_score: float
    schema_decision: str
    note: str


class AIHarvestTask(BaseModel):
    task_type: Literal["coverage_gap", "source_refresh", "entity_backfill", "topic_backfill"]
    entity_kind: str = ""
    entity_id: str = ""
    topic: str = ""
    priority: float = 0.5
    reason: str = ""
    suggested_source_name: str = ""
    suggested_start_url: str = ""
    source_kind: Literal["rss", "sitemap", "index_page", "manual_list"] = "index_page"
    include_patterns: List[str] = Field(default_factory=list)
    exclude_patterns: List[str] = Field(default_factory=list)


class AIHarvestPlan(BaseModel):
    world_id: str
    tasks: List[AIHarvestTask] = Field(default_factory=list)


class MigrationDraftRequest(BaseModel):
    world_id: str = "gensokyo_main"
    proposal_name: str
    table_name: str
    columns: List[str] = Field(default_factory=list)
    with_timestamps: bool = True
    with_world_id: bool = True


class MigrationDraftResponse(BaseModel):
    table_name: str
    sql: str
