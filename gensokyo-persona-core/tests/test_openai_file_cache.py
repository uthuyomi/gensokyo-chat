from __future__ import annotations

import os
import threading
import time
import unittest
from unittest.mock import patch

from persona_core.llm.openai_llm_client import OpenAILLMClient


class _FakeAttachmentMetaStore:
    def __init__(self) -> None:
        self.calls = []

    def update_attachment_meta(self, *, attachment_id: str, meta):
        self.calls.append({"attachment_id": attachment_id, "meta": meta})
        return {"attachment_id": attachment_id, "meta": meta}


class OpenAIFileCacheTests(unittest.TestCase):
    def _make_client(self) -> OpenAILLMClient:
        client = object.__new__(OpenAILLMClient)
        client._attachment_file_cache = {}
        client._attachment_file_cache_lock = threading.Lock()
        client._attachment_meta_store = None
        client._io_audit_store = None
        client.client = None
        return client

    def test_cache_entry_expired_respects_ttl(self) -> None:
        c = self._make_client()
        with patch.dict(os.environ, {"SIGMARIS_OPENAI_FILE_CACHE_TTL_SEC": "10"}, clear=False):
            fresh = {"updated_at_unix": int(time.time()) - 3}
            stale = {"updated_at_unix": int(time.time()) - 20}
            self.assertFalse(c._cache_entry_expired(fresh))
            self.assertTrue(c._cache_entry_expired(stale))

    def test_prepare_native_attachment_reuses_cached_file_id(self) -> None:
        c = self._make_client()
        now = int(time.time())
        item = {
            "type": "input_file",
            "filename": "doc.txt",
            "file_name": "doc.txt",
            "file_data": "Zm9v",
            "mime_type": "text/plain",
            "attachment_id": "att-1",
            "attachment_sha256": "sha-1",
            "attachment_meta": {
                "openai_files": {
                    "user_data": {
                        "file_id": "file-123",
                        "purpose": "user_data",
                        "file_name": "doc.txt",
                        "mime_type": "text/plain",
                        "attachment_sha256": "sha-1",
                        "updated_at_unix": now,
                    }
                }
            },
        }
        with patch.dict(os.environ, {"SIGMARIS_OPENAI_FILE_CACHE_TTL_SEC": "3600"}, clear=False):
            prepared = c._prepare_native_attachment_for_responses(item, force_refresh=False, audit_ctx=None)
        self.assertEqual(prepared.get("file_id"), "file-123")
        self.assertNotIn("file_data", prepared)

    def test_remove_cached_entry_updates_meta_and_memory(self) -> None:
        c = self._make_client()
        c._attachment_meta_store = _FakeAttachmentMetaStore()
        deleted = []
        c._delete_openai_file_best_effort = lambda file_id: deleted.append(file_id)
        item = {
            "attachment_id": "att-2",
            "attachment_meta": {
                "openai_files": {
                    "vision": {"file_id": "file-old", "purpose": "vision", "updated_at_unix": int(time.time())}
                }
            },
            "attachment_sha256": "sha-2",
            "file_name": "image.png",
            "mime_type": "image/png",
        }
        c._attachment_file_cache["att-2:vision:sha-2:image.png:image/png"] = {"file_id": "file-old", "purpose": "vision"}
        with patch.dict(os.environ, {"SIGMARIS_OPENAI_FILE_CLEANUP_ENABLED": "1"}, clear=False):
            c._remove_cached_openai_file_entry(item, "vision", file_id="file-old", delete_remote=True, audit_ctx=None)
        self.assertEqual(c._attachment_file_cache, {})
        self.assertEqual(item["attachment_meta"].get("openai_files"), {})
        self.assertEqual(deleted, ["file-old"])
        self.assertEqual(len(c._attachment_meta_store.calls), 1)

    def test_build_response_input_uses_output_text_for_assistant_history(self) -> None:
        c = self._make_client()
        items = c._build_response_input(
            user_text="latest user turn",
            history=[
                {"role": "user", "content": "hello"},
                {"role": "assistant", "content": "hi there"},
            ],
            native_attachments=None,
        )
        self.assertEqual(items[0]["content"][0]["type"], "input_text")
        self.assertEqual(items[1]["content"][0]["type"], "output_text")
        self.assertEqual(items[2]["role"], "user")
        self.assertEqual(items[2]["content"][-1]["type"], "input_text")


if __name__ == "__main__":
    unittest.main()
