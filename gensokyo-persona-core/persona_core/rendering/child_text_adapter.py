from __future__ import annotations


def adapt_text_for_child(text: str, *, enabled: bool) -> str:
    if not enabled:
        return str(text or "")
    out = str(text or "")
    replacements = {
        "具体的": "わかりやすく",
        "抽象的": "むずかしい言いかた",
        "優先": "先にやること",
        "整理": "順番に見る",
        "状況": "ようす",
    }
    for src, dst in replacements.items():
        out = out.replace(src, dst)
    return out
