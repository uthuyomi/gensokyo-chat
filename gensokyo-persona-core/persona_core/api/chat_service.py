from __future__ import annotations

from typing import Any, Dict, Iterable, Optional

from persona_core.runtime.character_chat_runtime import CharacterChatRuntime


class CharacterChatService:
    def __init__(self, *, runtime: CharacterChatRuntime) -> None:
        self._runtime = runtime

    def chat(self, **kwargs: Any) -> tuple[str, Dict[str, Any]]:
        return self._runtime.generate(**kwargs)

    def chat_stream(self, **kwargs: Any) -> tuple[Iterable[str], Dict[str, Any]]:
        return self._runtime.generate_stream(**kwargs)

    def list_characters(self) -> list[dict[str, Any]]:
        return self._runtime.list_characters()

    def get_character(self, character_id: str) -> dict[str, Any]:
        return self._runtime.get_character(character_id)
