from __future__ import annotations

import json
from typing import Any, Dict, List

from openai import AsyncOpenAI

from app.config import (
    DB_MANAGER_AI_ENABLED,
    DB_MANAGER_AI_MAX_INPUT_CHARS,
    DB_MANAGER_AI_MODEL,
    DB_MANAGER_AI_TIMEOUT,
    OPENAI_API_KEY,
)
from app.models import AIClaimCandidate, AIClaimJudgement, AIHarvestPlan, AISignalJudgement, InteractionSignalRequest, SchemaSuggestRequest, SchemaSuggestResponse

_client: AsyncOpenAI | None = None


def ai_available() -> bool:
    return DB_MANAGER_AI_ENABLED and bool((OPENAI_API_KEY or "").strip())


def _ensure_client() -> AsyncOpenAI:
    global _client
    if _client is None:
        _client = AsyncOpenAI(api_key=OPENAI_API_KEY, timeout=DB_MANAGER_AI_TIMEOUT)
    return _client


def _trim_text(value: str, limit: int | None = None) -> str:
    size = limit or DB_MANAGER_AI_MAX_INPUT_CHARS
    text = (value or "").strip()
    if len(text) > size:
        return text[:size]
    return text


def _parse_json_object(content: str) -> Dict[str, Any]:
    raw = (content or "").strip()
    if raw.startswith("```"):
        raw = raw.strip("`")
        if "\n" in raw:
            raw = raw.split("\n", 1)[1]
    if raw.endswith("```"):
        raw = raw[:-3].strip()
    data = json.loads(raw)
    return data if isinstance(data, dict) else {}


async def _ask_json(*, system: str, user: str, max_completion_tokens: int = 1600) -> Dict[str, Any]:
    if not ai_available():
        return {}
    client = _ensure_client()
    response = await client.chat.completions.create(
        model=DB_MANAGER_AI_MODEL,
        max_completion_tokens=max_completion_tokens,
        messages=[
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
    )
    content = (response.choices[0].message.content or "").strip()
    try:
        return _parse_json_object(content)
    except Exception:
        return {}


async def ai_extract_claim_candidates(
    *,
    world_id: str,
    source_url: str,
    title: str,
    summary: str,
    body: str,
    entity_kind: str,
    entity_id: str,
    topic: str,
    default_layer: str,
    default_claim_type: str,
) -> List[AIClaimCandidate]:
    if not ai_available():
        return []
    system = (
        "You extract structured knowledge claims from source text.\n"
        "Return STRICT JSON only.\n"
        "Schema:\n"
        "{\n"
        '  "claims": [\n'
        "    {\n"
        '      "entity_kind": string,\n'
        '      "entity_id": string,\n'
        '      "topic": string,\n'
        '      "claim_type": string,\n'
        '      "layer": "official_primary" | "official_secondary" | "fanon_major" | "fanon_variant" | "local_extension",\n'
        '      "claim_text": string,\n'
        '      "confidence": number,\n'
        '      "temporal_scope": string,\n'
        '      "reason": string\n'
        "    }\n"
        "  ]\n"
        "}\n"
        "Rules:\n"
        "- Extract up to 4 meaningful claims.\n"
        "- Keep claim_text short, factual, and paraphrased.\n"
        "- Do not invent details not supported by the text.\n"
        "- If the text is weak, return an empty claims array.\n"
    )
    user = (
        f"WORLD_ID: {world_id}\n"
        f"SOURCE_URL: {source_url}\n"
        f"TITLE: {title}\n"
        f"SUMMARY: {summary}\n"
        f"ENTITY_KIND: {entity_kind}\n"
        f"ENTITY_ID: {entity_id}\n"
        f"TOPIC: {topic}\n"
        f"DEFAULT_LAYER: {default_layer}\n"
        f"DEFAULT_CLAIM_TYPE: {default_claim_type}\n\n"
        f"BODY:\n{_trim_text(body)}"
    )
    obj = await _ask_json(system=system, user=user, max_completion_tokens=1800)
    raw_claims = obj.get("claims")
    results: List[AIClaimCandidate] = []
    if isinstance(raw_claims, list):
        for item in raw_claims[:4]:
            if not isinstance(item, dict):
                continue
            try:
                results.append(AIClaimCandidate(**item))
            except Exception:
                continue
    return results


async def ai_judge_claim(req: Dict[str, Any], existing_claims: List[dict]) -> AIClaimJudgement | None:
    if not ai_available():
        return None
    system = (
        "You decide whether a knowledge claim should be stored in a multi-layer world database.\n"
        "Return STRICT JSON only.\n"
        "Schema:\n"
        "{\n"
        '  "should_store": boolean,\n'
        '  "status_hint": "pending" | "accepted" | "disputed" | "rejected",\n'
        '  "layer": "official_primary" | "official_secondary" | "fanon_major" | "fanon_variant" | "local_extension" | null,\n'
        '  "confidence": number | null,\n'
        '  "reason": string,\n'
        '  "schema_signal": string\n'
        "}\n"
        "Rules:\n"
        "- Prefer pending when evidence exists but certainty is incomplete.\n"
        "- Use rejected if the claim is too weak or empty.\n"
        "- Use disputed if it clearly conflicts with existing claims.\n"
        "- Do not invent evidence.\n"
    )
    user = (
        f"CLAIM:\n{json.dumps(req, ensure_ascii=False)}\n\n"
        f"EXISTING_CLAIMS:\n{json.dumps(existing_claims[:8], ensure_ascii=False)}"
    )
    obj = await _ask_json(system=system, user=user, max_completion_tokens=900)
    if not obj:
        return None
    try:
        return AIClaimJudgement(**obj)
    except Exception:
        return None


async def ai_judge_signal(req: InteractionSignalRequest) -> AISignalJudgement | None:
    if not ai_available():
        return None
    system = (
        "You judge whether an interaction signal is worth storing for DB expansion.\n"
        "Return STRICT JSON only.\n"
        "Schema:\n"
        "{\n"
        '  "accepted": boolean,\n'
        '  "importance_score": number,\n'
        '  "schema_decision": "reuse_existing" | "extend_existing" | "review_schema" | "create_table",\n'
        '  "note": string\n'
        "}\n"
    )
    user = json.dumps(req.model_dump(), ensure_ascii=False)
    obj = await _ask_json(system=system, user=user, max_completion_tokens=700)
    if not obj:
        return None
    try:
        return AISignalJudgement(**obj)
    except Exception:
        return None


async def ai_schema_suggest(req: SchemaSuggestRequest) -> SchemaSuggestResponse | None:
    if not ai_available():
        return None
    system = (
        "You decide whether a database schema should reuse existing structures, extend them, or create a new table.\n"
        "Return STRICT JSON only.\n"
        "Schema:\n"
        "{\n"
        '  "decision": "reuse_existing" | "extend_existing" | "create_table",\n'
        '  "reason": string,\n'
        '  "suggested_table": string,\n'
        '  "suggested_columns": string[]\n'
        "}\n"
        "Prefer reuse unless repeated structure and query needs justify a new table.\n"
    )
    user = json.dumps(req.model_dump(), ensure_ascii=False)
    obj = await _ask_json(system=system, user=user, max_completion_tokens=900)
    if not obj:
        return None
    try:
        return SchemaSuggestResponse(**obj)
    except Exception:
        return None


async def ai_plan_harvest(
    *,
    world_id: str,
    audit_report: Dict[str, Any],
    active_sources: List[dict],
    source_registry: List[dict],
) -> AIHarvestPlan | None:
    if not ai_available():
        return None
    system = (
        "You are a harvest planner for a multi-layer world knowledge database.\n"
        "Your job is to decide what missing information should be collected next and which source should be used.\n"
        "Return STRICT JSON only.\n"
        "Schema:\n"
        "{\n"
        '  "world_id": string,\n'
        '  "tasks": [\n'
        "    {\n"
        '      "task_type": "coverage_gap" | "source_refresh" | "entity_backfill" | "topic_backfill",\n'
        '      "entity_kind": string,\n'
        '      "entity_id": string,\n'
        '      "topic": string,\n'
        '      "priority": number,\n'
        '      "reason": string,\n'
        '      "suggested_source_name": string,\n'
        '      "suggested_start_url": string,\n'
        '      "source_kind": "rss" | "sitemap" | "index_page" | "manual_list",\n'
        '      "include_patterns": string[],\n'
        '      "exclude_patterns": string[]\n'
        "    }\n"
        "  ]\n"
        "}\n"
        "Rules:\n"
        "- Prefer official and already-known sources.\n"
        "- Do not invent impossible URLs.\n"
        "- Output up to 6 tasks.\n"
        "- Use topic_backfill when the gap is broad.\n"
    )
    user = json.dumps(
        {
            "world_id": world_id,
            "audit_report": audit_report,
            "active_sources": active_sources[:12],
            "source_registry": source_registry,
        },
        ensure_ascii=False,
    )
    obj = await _ask_json(system=system, user=user, max_completion_tokens=1600)
    if not obj:
        return None
    try:
        return AIHarvestPlan(**obj)
    except Exception:
        return None
