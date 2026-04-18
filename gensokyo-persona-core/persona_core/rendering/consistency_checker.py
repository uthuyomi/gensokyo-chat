from __future__ import annotations

from typing import Any, Dict

from persona_core.character_runtime.models import CharacterAsset, ResolvedCharacterBehavior


def check_character_consistency(
    *,
    asset: CharacterAsset,
    behavior: ResolvedCharacterBehavior,
    reply: str,
) -> Dict[str, Any]:
    text = str(reply or "").strip()
    issues: list[str] = []
    if not text:
        issues.append("empty_reply")
    if "AI" in text and "generic assistant" in text.lower():
        issues.append("generic_assistant_phrase")
    if asset.soul.first_person and asset.soul.first_person not in text and behavior.scene in ("meta", "technical"):
        issues.append("first_person_not_observed")
    if not behavior.humor_allowed and any(token in text for token in ("冗談", "笑", "w")):
        issues.append("humor_in_disallowed_scene")
    return {
        "is_consistent": len(issues) == 0,
        "issues": issues,
    }
