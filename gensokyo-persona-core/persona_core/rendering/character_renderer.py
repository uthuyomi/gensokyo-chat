from __future__ import annotations

from typing import Any, Dict, Tuple

from persona_core.character_runtime.models import CharacterAsset, CharacterLocaleProfile, ResolvedCharacterBehavior, SafetyOverlay, SituationAssessment
from .child_text_adapter import adapt_text_for_child
from .consistency_checker import check_character_consistency
from .safety_rewriter import rewrite_reply_for_safety


def render_character_reply(
    *,
    asset: CharacterAsset,
    assessment: SituationAssessment,
    behavior: ResolvedCharacterBehavior,
    safety: SafetyOverlay,
    locale_profile: CharacterLocaleProfile,
    resolved_locale: str,
    reply: str,
) -> Tuple[str, Dict[str, Any]]:
    text = str(reply or "").strip()
    text = rewrite_reply_for_safety(text, safety=safety)
    text = adapt_text_for_child(
        text,
        enabled=assessment.target_age == "child" and str(resolved_locale).lower().startswith("ja"),
    )
    consistency = check_character_consistency(
        asset=asset,
        behavior=behavior,
        reply=text,
    )
    return text, {
        "consistency": consistency,
        "resolved_locale": resolved_locale,
        "locale_style_snapshot": locale_profile.model_dump(),
    }
