from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass
from html import unescape
from typing import Dict, Iterable, List
from urllib.parse import parse_qsl, urlencode, urljoin, urlparse, urlunparse
from xml.etree import ElementTree

import trafilatura
from rapidfuzz import fuzz

from app.models import (
    ClaimAutoReviewDecision,
    ClaimIngestRequest,
    ClaimIngestResponse,
    ConflictRecord,
    CoveragePreviewResponse,
    InteractionSignalRequest,
    InteractionSignalResponse,
    MigrationDraftRequest,
    MigrationDraftResponse,
    SchemaSuggestRequest,
    SchemaSuggestResponse,
    WebIngestResponse,
)


OFFICIAL_HOST_MARKERS = (
    "touhou-project.news",
    "teamshanghaialice.com",
    "tasofro.net",
    "zunbeer.com",
)


@dataclass
class AutoReviewOutcome:
    next_status: str
    reason: str


def _clean_text(value: str) -> str:
    return re.sub(r"\s+", " ", value or "").strip()


def canonicalize_url(url: str) -> str:
    raw = (url or "").strip()
    if not raw:
        return ""
    parsed = urlparse(raw)
    scheme = (parsed.scheme or "https").lower()
    netloc = (parsed.netloc or "").lower()
    if netloc.startswith("www."):
        netloc = netloc[4:]
    path = re.sub(r"/{2,}", "/", parsed.path or "/")
    if path != "/" and path.endswith("/"):
        path = path[:-1]
    filtered_query = []
    for key, value in parse_qsl(parsed.query, keep_blank_values=False):
        key_norm = key.lower()
        if key_norm.startswith("utm_") or key_norm in {"fbclid", "gclid", "ref", "ref_src"}:
            continue
        filtered_query.append((key, value))
    query = urlencode(filtered_query, doseq=True)
    return urlunparse((scheme, netloc, path, "", query, ""))


def build_claim_fingerprint(req: ClaimIngestRequest) -> str:
    payload = "||".join(
        [
            req.world_id.strip().lower(),
            req.entity_kind.strip().lower(),
            req.entity_id.strip().lower(),
            req.claim_type.strip().lower(),
            _clean_text(req.claim_text.lower()),
        ]
    )
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def build_coverage_preview(world_id: str, items) -> CoveragePreviewResponse:
    missing_or_thin: list[str] = []
    for item in items:
        if not item.exists:
            missing_or_thin.append(f"{item.table}:missing")
        elif item.count == 0:
            missing_or_thin.append(f"{item.table}:empty")
        elif item.count < 5:
            missing_or_thin.append(f"{item.table}:thin")
    return CoveragePreviewResponse(world_id=world_id, items=items, missing_or_thin=missing_or_thin)


def suggest_schema(req: SchemaSuggestRequest) -> SchemaSuggestResponse:
    fields = [field for field in req.observed_fields if field]
    candidate = req.candidate_name.strip().lower()
    if not fields and not req.need.strip():
        return SchemaSuggestResponse(
            decision="reuse_existing",
            reason="Need and fields are both empty, so there is not enough structure to justify schema change.",
        )
    if req.expected_rows <= 3 and not req.requires_history and len(fields) <= 4:
        return SchemaSuggestResponse(
            decision="extend_existing",
            reason="The signal looks sparse and fits better as metadata or a small column extension than a dedicated table.",
            suggested_table="existing_world_table_or_metadata",
            suggested_columns=fields,
        )
    if req.repeats_per_entity >= 2 or req.expected_rows >= 12 or req.requires_history:
        suggested_table = candidate or "world_extension_records"
        return SchemaSuggestResponse(
            decision="create_table",
            reason="The signal is repeated enough that a dedicated table is likely easier to query, validate, and evolve.",
            suggested_table=suggested_table,
            suggested_columns=fields or ["world_id", "entity_id", "payload", "source_ref"],
        )
    return SchemaSuggestResponse(
        decision="extend_existing",
        reason="The signal is meaningful, but still looks better as an extension of existing entity storage than as a new table.",
        suggested_table="existing_world_table_or_metadata",
        suggested_columns=fields,
    )


def score_interaction_signal(req: InteractionSignalRequest) -> InteractionSignalResponse:
    score = 0.0
    if req.signal_type:
        score += 0.18
    if req.entity_kind:
        score += 0.14
    if req.entity_id or req.entity_name:
        score += 0.14
    if req.source_text:
        score += 0.18
    if req.reason:
        score += 0.12
    if req.user_message:
        score += 0.10
    if req.proposed_fields:
        score += min(0.14, len(req.proposed_fields) * 0.03)
    score = max(0.0, min(1.0, score))
    should_follow_up_schema = len(req.proposed_fields) >= 4 or "table" in req.reason.lower() or "schema" in req.reason.lower()
    decision = "extend_existing"
    note = "Signal is worth storing as a pending observation."
    if should_follow_up_schema:
        decision = "review_schema"
        note = "Signal suggests a repeated structure and should be reviewed for schema extension."
    return InteractionSignalResponse(
        accepted=score >= 0.35,
        stored=False,
        importance_score=score,
        should_follow_up_schema=should_follow_up_schema,
        schema_decision=decision,
        note=note,
    )


def detect_conflicting_claims(req: ClaimIngestRequest, existing_claims: Iterable[dict]) -> List[str]:
    normalized_incoming = _clean_text(req.claim_text.lower())
    conflicts: List[str] = []
    for claim in existing_claims:
        claim_id = str(claim.get("id") or "")
        existing_text = _clean_text(str(claim.get("claim_text") or "").lower())
        similarity = fuzz.token_set_ratio(normalized_incoming, existing_text) if existing_text else 0
        if claim_id and existing_text and similarity < 92:
            conflicts.append(claim_id)
    return conflicts


def find_near_duplicate_claim(req: ClaimIngestRequest, existing_claims: Iterable[dict], fingerprint: str) -> Dict[str, object]:
    normalized_incoming = _clean_text(req.claim_text.lower())
    for claim in existing_claims:
        existing_fingerprint = str(claim.get("claim_fingerprint") or "")
        if existing_fingerprint and existing_fingerprint == fingerprint:
            return claim
        existing_text = _clean_text(str(claim.get("claim_text") or "").lower())
        similarity = fuzz.token_set_ratio(normalized_incoming, existing_text) if existing_text else 0
        if similarity >= 97:
            return claim
    return {}


def build_claim_ingest_response(*, claim_id: str, linked_sources: int, conflict_ids: List[str], status: str = "pending") -> ClaimIngestResponse:
    return ClaimIngestResponse(
        claim_id=claim_id,
        status=status,
        linked_sources=linked_sources,
        conflict_detected=bool(conflict_ids),
        conflict_ids=conflict_ids,
    )


def normalize_conflicts(rows: Iterable[dict]) -> List[ConflictRecord]:
    records: List[ConflictRecord] = []
    for row in rows:
        members = row.get("world_knowledge_conflict_members")
        claim_ids = []
        if isinstance(members, list):
            claim_ids = [str(member.get("claim_id") or "") for member in members if isinstance(member, dict)]
        records.append(
            ConflictRecord(
                id=str(row.get("id") or ""),
                topic=str(row.get("topic") or ""),
                resolution_status=str(row.get("resolution_status") or ""),
                claim_ids=[claim_id for claim_id in claim_ids if claim_id],
            )
        )
    return records


def extract_web_preview(html: str) -> tuple[str, str]:
    title = ""
    summary = ""
    title_match = re.search(r"<title[^>]*>(.*?)</title>", html, flags=re.IGNORECASE | re.DOTALL)
    if title_match:
        title = unescape(re.sub(r"\s+", " ", title_match.group(1))).strip()
    meta_match = re.search(r'<meta[^>]+name=["\']description["\'][^>]+content=["\'](.*?)["\']', html, flags=re.IGNORECASE | re.DOTALL)
    if meta_match:
        summary = unescape(re.sub(r"\s+", " ", meta_match.group(1))).strip()
    if not summary:
        extracted = trafilatura.extract(html, output_format="txt", include_comments=False, include_tables=False) or ""
        text = extracted or re.sub(r"<[^>]+>", " ", html)
        text = re.sub(r"\s+", " ", unescape(text)).strip()
        summary = text[:280]
    return title[:180], summary[:280]


def infer_source_authority(*, source_kind: str, source_url: str, origin: str = "") -> float:
    kind = (source_kind or "").lower()
    url = (source_url or "").lower()
    origin_norm = (origin or "").lower()
    score = 0.45
    host = urlparse(url).hostname or ""
    if any(marker in host for marker in OFFICIAL_HOST_MARKERS):
        score = 0.98
    elif "official" in kind or "official" in origin_norm:
        score = 0.92
    elif "wiki" in kind:
        score = 0.72
    elif "fanon" in kind or "doujin" in kind:
        score = 0.5
    elif url.startswith("https://"):
        score = 0.62
    return max(0.0, min(1.0, score))


def infer_layer_from_source(source_kind: str, source_url: str = "") -> str:
    authority = infer_source_authority(source_kind=source_kind, source_url=source_url)
    kind = (source_kind or "").lower()
    if authority >= 0.95:
        return "official_primary"
    if authority >= 0.75:
        return "official_secondary"
    if "fanon" in kind or "doujin" in kind:
        return "fanon_variant"
    return "fanon_major"


def derive_claim_text(*, title: str, summary: str, entity_kind: str, entity_id: str, topic: str, note: str) -> str:
    pieces = [_clean_text(summary), _clean_text(note)]
    body = next((piece for piece in pieces if piece), "")
    heading = _clean_text(title)
    if heading and body and heading.lower() not in body.lower():
        return f"{heading}: {body}"[:600]
    if body:
        return body[:600]
    label = entity_id or entity_kind or topic or "web_fact"
    return f"{label} に関する出典候補です。"[:600]


def build_source_payload_from_candidate(candidate: Dict[str, object]) -> Dict[str, object]:
    source_kind = str(candidate.get("source_kind") or "web_article")
    source_url = str(candidate.get("url") or "")
    canonical_url = canonicalize_url(source_url)
    authority = infer_source_authority(source_kind=source_kind, source_url=source_url)
    return {
        "source_kind": source_kind,
        "title": str(candidate.get("title") or source_url or "web source"),
        "source_url": source_url,
        "canonical_url": canonical_url or source_url,
        "citation": str(candidate.get("title") or ""),
        "origin": "web_ingest",
        "authority_score": authority,
        "excerpt": str(candidate.get("summary") or ""),
        "metadata": {"queue_id": str(candidate.get("id") or "")},
    }


def build_claim_request_from_candidate(candidate: Dict[str, object]) -> ClaimIngestRequest:
    source = build_source_payload_from_candidate(candidate)
    layer = str(candidate.get("layer") or infer_layer_from_source(str(source["source_kind"]), str(source["source_url"])))
    claim_text = derive_claim_text(
        title=str(candidate.get("title") or ""),
        summary=str(candidate.get("summary") or ""),
        entity_kind=str(candidate.get("entity_kind") or ""),
        entity_id=str(candidate.get("entity_id") or ""),
        topic=str(candidate.get("topic") or ""),
        note=str(candidate.get("note") or ""),
    )
    return ClaimIngestRequest(
        world_id=str(candidate.get("world_id") or "gensokyo_main"),
        entity_kind=str(candidate.get("entity_kind") or "web_entity"),
        entity_id=str(candidate.get("entity_id") or ""),
        topic=str(candidate.get("topic") or ""),
        claim_type=str(candidate.get("claim_type") or "fact"),
        layer=layer,
        claim_text=claim_text,
        confidence=0.72 if layer.startswith("official") else 0.58,
        metadata={"from_web_queue": str(candidate.get("id") or ""), "source_kind": source["source_kind"]},
        sources=[source],
    )


def evaluate_claim_for_auto_review(
    claim: Dict[str, object],
    source_links: Iterable[dict],
    conflict_memberships: Iterable[dict],
    policy: Dict[str, object] | None = None,
) -> AutoReviewOutcome:
    resolved = resolve_policy("auto_review", policy)
    current_status = str(claim.get("status") or "pending")
    if current_status != "pending":
        return AutoReviewOutcome(next_status=current_status, reason="Claim is no longer pending.")

    open_conflicts = 0
    for membership in conflict_memberships:
        conflict = membership.get("world_knowledge_conflicts")
        if isinstance(conflict, dict) and str(conflict.get("resolution_status") or "") == "open":
            open_conflicts += 1
    if open_conflicts:
        return AutoReviewOutcome(next_status="disputed", reason="Open competing claims are attached to this claim.")

    supports = 0
    strongest_authority = 0.0
    for link in source_links:
        if str(link.get("support_type") or "supports") != "supports":
            continue
        supports += 1
        source = link.get("world_knowledge_sources")
        if isinstance(source, dict):
            strongest_authority = max(strongest_authority, float(source.get("authority_score") or 0.0))

    confidence = float(claim.get("confidence") or 0.0)
    layer = str(claim.get("layer") or "")
    primary_min_authority = float(resolved.get("official_primary_min_authority") or 0.95)
    primary_min_confidence = float(resolved.get("official_primary_min_confidence") or 0.8)
    secondary_min_sources = int(resolved.get("official_secondary_min_sources") or 2)
    secondary_min_authority = float(resolved.get("official_secondary_min_authority") or 0.75)
    secondary_min_confidence = float(resolved.get("official_secondary_min_confidence") or 0.78)
    if layer == "official_primary" and strongest_authority >= primary_min_authority and confidence >= primary_min_confidence:
        return AutoReviewOutcome(next_status="accepted", reason="Primary official source and confidence threshold are both strong.")
    if layer in {"official_primary", "official_secondary"} and supports >= secondary_min_sources and strongest_authority >= secondary_min_authority and confidence >= secondary_min_confidence:
        return AutoReviewOutcome(next_status="accepted", reason="Multiple supporting sources and stable official layer support this claim.")
    if strongest_authority < 0.55 and confidence < 0.6:
        return AutoReviewOutcome(next_status="pending", reason="Source authority is still too weak for automatic promotion.")
    return AutoReviewOutcome(next_status="pending", reason="Claim remains pending until stronger corroboration arrives.")


def build_auto_review_decision(
    *,
    claim_id: str,
    previous_status: str,
    next_status: str,
    reason: str,
    applied: bool,
) -> ClaimAutoReviewDecision:
    return ClaimAutoReviewDecision(
        claim_id=claim_id,
        previous_status=previous_status,
        next_status=next_status,
        reason=reason,
        applied=applied,
    )


def _matches_patterns(url: str, patterns: List[str]) -> bool:
    if not patterns:
        return True
    url_norm = url.lower()
    return any(pattern.lower() in url_norm for pattern in patterns if pattern)


def _is_excluded(url: str, patterns: List[str]) -> bool:
    if not patterns:
        return False
    url_norm = url.lower()
    return any(pattern.lower() in url_norm for pattern in patterns if pattern)


def discover_urls_from_document(*, source_kind: str, start_url: str, body: str, include_patterns: List[str], exclude_patterns: List[str], max_urls: int) -> List[str]:
    urls: List[str] = []
    seen: set[str] = set()
    kind = (source_kind or "").lower()

    def push(url: str) -> None:
        normalized = (url or "").strip()
        if not normalized:
            return
        if normalized.startswith("/"):
            normalized = urljoin(start_url, normalized)
        clean = canonicalize_url(normalized)
        parsed = urlparse(clean)
        if parsed.scheme not in {"http", "https"}:
            return
        if clean in seen:
            return
        if not _matches_patterns(clean, include_patterns):
            return
        if _is_excluded(clean, exclude_patterns):
            return
        seen.add(clean)
        urls.append(clean)

    if kind in {"rss", "sitemap"}:
        try:
            root = ElementTree.fromstring(body)
            for elem in root.iter():
                tag = elem.tag.lower()
                if tag.endswith("loc") or tag.endswith("link"):
                    push((elem.text or "").strip())
                    if len(urls) >= max_urls:
                        break
        except ElementTree.ParseError:
            pass

    if len(urls) < max_urls:
        for match in re.finditer(r'href=["\'](.*?)["\']', body, flags=re.IGNORECASE):
            push(match.group(1))
            if len(urls) >= max_urls:
                break

    if len(urls) < max_urls:
        for match in re.finditer(r"https?://[^\s\"'<>]+", body, flags=re.IGNORECASE):
            push(match.group(0))
            if len(urls) >= max_urls:
                break

    return urls[:max_urls]


def build_web_ingest_response(*, stored: bool, fetched: bool, title: str, summary: str) -> WebIngestResponse:
    return WebIngestResponse(
        accepted=fetched,
        stored=stored,
        fetched=fetched,
        title=title,
        summary=summary,
        suggested_signal="missing_fact" if fetched else "",
    )


def build_migration_draft(req: MigrationDraftRequest) -> MigrationDraftResponse:
    table = req.table_name.strip()
    column_lines: List[str] = []
    if req.with_world_id:
        column_lines.append("  world_id text not null,")
    column_lines.append("  id uuid primary key default gen_random_uuid(),")
    for column in req.columns:
        name = column.strip().lower()
        if not name:
            continue
        column_lines.append(f"  {name} text,")
    column_lines.append("  metadata jsonb not null default '{}'::jsonb,")
    if req.with_timestamps:
        column_lines.append("  created_at timestamptz not null default now(),")
        column_lines.append("  updated_at timestamptz not null default now()")
    else:
        column_lines[-1] = column_lines[-1].rstrip(",")
    sql = "\n".join(
        [
            f"-- Proposal: {req.proposal_name}",
            "create extension if not exists pgcrypto;",
            "",
            f"create table if not exists public.{table} (",
            *column_lines,
            ");",
        ]
    )
    return MigrationDraftResponse(table_name=table, sql=sql)


def classify_error_category(detail: str) -> str:
    text = (detail or "").lower()
    if "timeout" in text:
        return "timeout"
    if "429" in text or "rate" in text:
        return "rate_limit"
    if "403" in text or "401" in text:
        return "permission"
    if "404" in text:
        return "not_found"
    if "parse" in text or "xml" in text or "html" in text:
        return "parse"
    if "connect" in text or "network" in text:
        return "network"
    return "unknown"


def default_manager_policies() -> Dict[str, Dict[str, object]]:
    return {
        "auto_review": {
            "enabled": True,
            "official_primary_min_authority": 0.95,
            "official_primary_min_confidence": 0.8,
            "official_secondary_min_sources": 2,
            "official_secondary_min_authority": 0.75,
            "official_secondary_min_confidence": 0.78,
        },
        "discovery": {
            "enabled": True,
            "max_sources_per_run": 5,
            "max_urls_per_source": 20,
        },
        "embedding_refresh": {
            "enabled": True,
            "trigger_statuses": ["accepted"],
        },
    }


def resolve_policy(policy_key: str, stored: Dict[str, object] | None = None) -> Dict[str, object]:
    base = default_manager_policies().get(policy_key, {}).copy()
    if isinstance(stored, dict):
        base.update(stored)
    return base


def build_audit_report(
    *,
    world_id: str,
    coverage,
    claims: List[dict],
    sources: List[dict],
    signals: List[dict],
    conflicts: List[dict],
) -> Dict[str, object]:
    claim_status_counts: Dict[str, int] = {}
    layer_counts: Dict[str, int] = {}
    source_kind_counts: Dict[str, int] = {}
    signal_status_counts: Dict[str, int] = {}
    conflict_status_counts: Dict[str, int] = {}
    duplicate_claim_fingerprints = 0
    duplicate_source_urls = 0

    seen_fingerprints: set[str] = set()
    seen_source_urls: set[str] = set()

    for claim in claims:
        status = str(claim.get("status") or "unknown")
        layer = str(claim.get("layer") or "unknown")
        claim_status_counts[status] = claim_status_counts.get(status, 0) + 1
        layer_counts[layer] = layer_counts.get(layer, 0) + 1
        fingerprint = str(claim.get("claim_fingerprint") or "")
        if fingerprint:
            if fingerprint in seen_fingerprints:
                duplicate_claim_fingerprints += 1
            else:
                seen_fingerprints.add(fingerprint)

    for source in sources:
        kind = str(source.get("source_kind") or "unknown")
        source_kind_counts[kind] = source_kind_counts.get(kind, 0) + 1
        canonical_url = str(source.get("canonical_url") or "")
        if canonical_url:
            if canonical_url in seen_source_urls:
                duplicate_source_urls += 1
            else:
                seen_source_urls.add(canonical_url)

    for signal in signals:
        status = str(signal.get("status") or "unknown")
        signal_status_counts[status] = signal_status_counts.get(status, 0) + 1

    for conflict in conflicts:
        status = str(conflict.get("resolution_status") or "unknown")
        conflict_status_counts[status] = conflict_status_counts.get(status, 0) + 1

    total_claims = len(claims)
    accepted_claims = claim_status_counts.get("accepted", 0)
    pending_claims = claim_status_counts.get("pending", 0)
    disputed_claims = claim_status_counts.get("disputed", 0)

    return {
        "world_id": world_id,
        "coverage": coverage.model_dump() if hasattr(coverage, "model_dump") else coverage,
        "totals": {
            "claims": total_claims,
            "sources": len(sources),
            "signals": len(signals),
            "conflicts": len(conflicts),
        },
        "claim_status_counts": claim_status_counts,
        "layer_counts": layer_counts,
        "source_kind_counts": source_kind_counts,
        "signal_status_counts": signal_status_counts,
        "conflict_status_counts": conflict_status_counts,
        "duplicate_indicators": {
            "claim_fingerprint_collisions": duplicate_claim_fingerprints,
            "source_canonical_url_collisions": duplicate_source_urls,
        },
        "health_flags": {
            "pending_claim_backlog": pending_claims,
            "open_conflicts": conflict_status_counts.get("open", 0),
            "accepted_ratio": (accepted_claims / total_claims) if total_claims else 0.0,
            "disputed_ratio": (disputed_claims / total_claims) if total_claims else 0.0,
        },
    }


def build_alerts(report: Dict[str, object], recent_jobs: List[dict]) -> List[Dict[str, object]]:
    alerts: List[Dict[str, object]] = []
    health = report.get("health_flags") if isinstance(report.get("health_flags"), dict) else {}
    pending_backlog = int(health.get("pending_claim_backlog") or 0) if isinstance(health, dict) else 0
    open_conflicts = int(health.get("open_conflicts") or 0) if isinstance(health, dict) else 0
    duplicate_claims = int(((report.get("duplicate_indicators") or {}) if isinstance(report.get("duplicate_indicators"), dict) else {}).get("claim_fingerprint_collisions") or 0)

    if pending_backlog >= 50:
        alerts.append({"level": "warning", "kind": "pending_backlog", "message": f"Pending claims backlog is high: {pending_backlog}"})
    if open_conflicts >= 10:
        alerts.append({"level": "warning", "kind": "open_conflicts", "message": f"Open conflicts need review: {open_conflicts}"})
    if duplicate_claims > 0:
        alerts.append({"level": "info", "kind": "duplicates", "message": f"Duplicate claim fingerprints detected: {duplicate_claims}"})

    for job in recent_jobs[:5]:
        status = str(job.get("status") or "")
        if status.endswith("errors") or status == "failed":
            alerts.append(
                {
                    "level": "warning",
                    "kind": "job_failure",
                    "message": f"Recent job {job.get('job_type')} finished with status {status}.",
                    "run_id": str(job.get("id") or ""),
                }
            )
    return alerts


def default_source_registry(world_id: str = "gensokyo_main") -> List[Dict[str, object]]:
    return [
        {
            "world_id": world_id,
            "source_name": "Touhou Project News RSS",
            "source_kind": "rss",
            "start_url": "https://touhou-project.news/feed/",
            "topic": "official_news",
            "entity_kind": "",
            "entity_id": "",
            "include_patterns": ["touhou-project.news"],
            "exclude_patterns": ["/tag/", "/category/"],
            "layer": "official_primary",
        },
        {
            "world_id": world_id,
            "source_name": "Team Shanghai Alice Index",
            "source_kind": "index_page",
            "start_url": "https://www16.big.or.jp/~zun/",
            "topic": "official_site",
            "entity_kind": "",
            "entity_id": "",
            "include_patterns": ["big.or.jp/~zun", "www16.big.or.jp/~zun"],
            "exclude_patterns": [],
            "layer": "official_primary",
        },
        {
            "world_id": world_id,
            "source_name": "Tasofro News Index",
            "source_kind": "index_page",
            "start_url": "https://tasofro.net/",
            "topic": "official_collab",
            "entity_kind": "",
            "entity_id": "",
            "include_patterns": ["tasofro.net"],
            "exclude_patterns": ["/contact", "/privacy"],
            "layer": "official_primary",
        },
    ]
