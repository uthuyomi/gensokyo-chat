from __future__ import annotations

from typing import Any, Dict, Optional

from persona_core.character_runtime.models import ResponseStrategy, SituationAssessment
from persona_core.strategy.response_strategy import build_response_strategy


def select_response_strategy(
    *,
    assessment: SituationAssessment,
    conversation_profile: Optional[Dict[str, Any]] = None,
) -> ResponseStrategy:
    return build_response_strategy(
        assessment=assessment,
        conversation_profile=conversation_profile,
    )
