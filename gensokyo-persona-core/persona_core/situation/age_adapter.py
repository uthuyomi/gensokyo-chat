from __future__ import annotations

from typing import Any, Dict, Optional

from persona_core.character_runtime.models import UserProfile


def adapt_user_profile_for_age(user_profile: Optional[Dict[str, Any]]) -> UserProfile:
    return UserProfile.model_validate(user_profile or {})
