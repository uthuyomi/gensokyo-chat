from __future__ import annotations

import json
from pathlib import Path
from typing import Iterable, List

from .models import CharacterAsset


def _read_json(path: Path) -> dict:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload if isinstance(payload, dict) else {}


def discover_character_directories(base_dir: str | Path) -> List[Path]:
    root = Path(base_dir)
    if not root.exists():
        return []
    return [path for path in sorted(root.iterdir()) if path.is_dir()]


def load_character_asset_from_directory(path: str | Path) -> CharacterAsset:
    directory = Path(path)
    if not directory.exists() or not directory.is_dir():
        raise FileNotFoundError(f"character directory not found: {directory}")

    raw: dict = {}
    for name in (
        "profile.json",
        "world.json",
        "control_plane_en.json",
        "prompts.json",
        "gen_params.json",
        "soul.json",
        "style.json",
        "safety.json",
        "situational_behavior.json",
    ):
        file_path = directory / name
        if not file_path.exists():
            continue
        payload = _read_json(file_path)
        key = file_path.stem
        if key == "gen_params":
            raw["gen_params"] = payload
        elif key == "control_plane_en":
            raw["control_plane_en"] = payload
        else:
            raw.update(payload if key == "profile" else {key: payload})

    locales_dir = directory / "locales"
    if locales_dir.exists() and locales_dir.is_dir():
        locales: dict[str, dict] = {}
        for locale_file in sorted(locales_dir.glob("*.json")):
            locale_payload = _read_json(locale_file)
            locale_key = str(locale_payload.get("locale") or locale_file.stem).strip()
            if locale_key:
                locales[locale_key] = locale_payload
        if locales:
            raw["locales"] = locales

    localized_prompts_dir = directory / "localized_prompts"
    if localized_prompts_dir.exists() and localized_prompts_dir.is_dir():
        localized_prompts: dict[str, dict] = {}
        for prompt_file in sorted(localized_prompts_dir.glob("*.json")):
            prompt_payload = _read_json(prompt_file)
            locale_key = str(prompt_payload.get("locale") or prompt_file.stem).strip()
            normalized_payload = dict(prompt_payload)
            normalized_payload.pop("locale", None)
            if locale_key:
                localized_prompts[locale_key] = normalized_payload
        if localized_prompts:
            raw["localized_prompts"] = localized_prompts

    if "id" not in raw:
        raw["id"] = directory.name.lower()

    return CharacterAsset.model_validate(raw)


def load_character_assets(paths: Iterable[str | Path]) -> List[CharacterAsset]:
    assets: list[CharacterAsset] = []
    for path in paths:
        try:
            assets.append(load_character_asset_from_directory(path))
        except Exception:
            continue
    return assets
