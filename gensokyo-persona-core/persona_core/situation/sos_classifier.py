from __future__ import annotations

from persona_core.character_runtime.models import SituationAssessment


def is_sos_suspected(assessment: SituationAssessment) -> bool:
    return assessment.interaction_type == "sos_support" or assessment.safety_risk == "high"
