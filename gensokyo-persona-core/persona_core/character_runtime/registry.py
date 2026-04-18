from __future__ import annotations

import threading
from pathlib import Path
from typing import Dict, Optional

from .loader import discover_character_directories, load_character_asset_from_directory
from .models import CharacterAsset


class CharacterRegistry:
    def __init__(self, *, characters_dir: Optional[Path] = None) -> None:
        self._characters_dir = characters_dir or (Path(__file__).resolve().parents[1] / "characters")
        self._lock = threading.Lock()
        self._loaded = False
        self._assets: Dict[str, CharacterAsset] = {}

    def _iter_character_directories(self) -> list[Path]:
        candidates = discover_character_directories(self._characters_dir)
        return [path for path in candidates if (path / "profile.json").exists()]

    def _ensure_loaded(self) -> None:
        if self._loaded:
            return
        with self._lock:
            if self._loaded:
                return
            assets: Dict[str, CharacterAsset] = {}
            for directory in self._iter_character_directories():
                try:
                    asset = load_character_asset_from_directory(directory)
                    assets[asset.id] = asset
                except Exception:
                    continue
            self._assets = assets
            self._loaded = True

    def get(self, character_id: str) -> Optional[CharacterAsset]:
        self._ensure_loaded()
        return self._assets.get(str(character_id or "").strip().lower())

    def list_ids(self) -> list[str]:
        self._ensure_loaded()
        return sorted(self._assets.keys())

    def list_assets(self) -> list[CharacterAsset]:
        self._ensure_loaded()
        return [self._assets[key] for key in sorted(self._assets.keys())]

    def iter_character_directories(self) -> list[Path]:
        return self._iter_character_directories()


_REGISTRY: Optional[CharacterRegistry] = None


def get_character_registry() -> CharacterRegistry:
    global _REGISTRY
    if _REGISTRY is None:
        _REGISTRY = CharacterRegistry()
    return _REGISTRY
