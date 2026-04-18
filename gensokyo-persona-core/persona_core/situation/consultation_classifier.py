from __future__ import annotations

from persona_core.character_runtime.models import SituationAssessment


def is_consultation_like(assessment: SituationAssessment) -> bool:
    return assessment.interaction_type in ("distressed_support", "sos_support", "technical", "info")
