from __future__ import annotations

from typing import Optional

from persona_core.character_runtime.models import ConversationProfile, SituationAssessment


def resolve_response_speed_mode(
    *,
    assessment: SituationAssessment,
    conversation_profile: Optional[ConversationProfile] = None,
) -> str:
    profile = conversation_profile or ConversationProfile()
    if profile.response_style != "auto":
        return profile.response_style
    if assessment.interaction_type == "playful":
        return "fast"
    if assessment.interaction_type == "sos_support":
        return "deep"
    return "balanced"
