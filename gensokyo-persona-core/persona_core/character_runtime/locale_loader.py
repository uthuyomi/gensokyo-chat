from __future__ import annotations

from typing import Dict, Tuple

from .models import CharacterAsset, CharacterLocaleProfile


def _normalize_locale(value: str | None) -> str:
    locale = str(value or "").strip()
    return locale or "ja-JP"


def resolve_locale_profile(
    *,
    asset: CharacterAsset,
    requested_locale: str | None,
) -> Tuple[str, CharacterLocaleProfile]:
    locales: Dict[str, CharacterLocaleProfile] = dict(asset.locales or {})
    if not locales:
        fallback = CharacterLocaleProfile(
            locale=asset.default_locale or "ja-JP",
            first_person=asset.soul.first_person,
            second_person_default=asset.soul.second_person_default,
        )
        return fallback.locale, fallback

    requested = _normalize_locale(requested_locale)
    if requested in locales:
        return requested, locales[requested]

    requested_lang = requested.split("-", 1)[0].lower()
    for locale_key, profile in locales.items():
        if locale_key.split("-", 1)[0].lower() == requested_lang:
            return locale_key, profile

    default_locale = asset.default_locale if asset.default_locale in locales else None
    if default_locale:
        return default_locale, locales[default_locale]

    if "ja-JP" in locales:
        return "ja-JP", locales["ja-JP"]

    first_key = next(iter(locales.keys()))
    return first_key, locales[first_key]
