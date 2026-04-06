"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { ChevronDownIcon, ChevronUpIcon, SearchIcon, XIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import { useLanguage } from "@/components/i18n/LanguageProvider";
import { cn } from "@/lib/utils";

type Hit = {
  root: HTMLElement;
  highlightEl: HTMLElement;
  text: string;
};

function getThreadViewport(): HTMLElement | null {
  return document.querySelector(".aui-thread-viewport");
}

function findMessageRoots(viewport: HTMLElement): HTMLElement[] {
  return Array.from(
    viewport.querySelectorAll<HTMLElement>(
      '[data-role="user"], [data-role="assistant"]',
    ),
  );
}

function getHighlightEl(root: HTMLElement): HTMLElement {
  const bubble = root.querySelector<HTMLElement>(
    ".aui-user-message-content, .aui-assistant-message-content",
  );
  return bubble ?? root;
}

function normalizeForSearch(s: string) {
  return s.replace(/\s+/g, " ").trim();
}

function collectHits(query: string): Hit[] {
  const q = normalizeForSearch(query);
  if (!q) return [];

  const viewport = getThreadViewport();
  if (!viewport) return [];

  const roots = findMessageRoots(viewport);
  const hits: Hit[] = [];
  for (const root of roots) {
    const highlightEl = getHighlightEl(root);
    const text = normalizeForSearch(highlightEl.innerText || root.innerText || "");
    if (!text) continue;
    if (!text.includes(q)) continue;
    hits.push({ root, highlightEl, text });
  }
  return hits;
}

function flashHighlight(el: HTMLElement) {
  const prevBoxShadow = el.style.boxShadow;
  const prevOutline = el.style.outline;
  const prevOutlineOffset = el.style.outlineOffset;

  el.style.scrollMarginTop = "5rem";
  el.style.outline = "2px solid rgba(56, 189, 248, 0.9)";
  el.style.outlineOffset = "6px";
  el.style.boxShadow =
    "0 0 0 3px rgba(56, 189, 248, 0.25), 0 0 40px rgba(56, 189, 248, 0.22)";

  window.setTimeout(() => {
    el.style.boxShadow = prevBoxShadow;
    el.style.outline = prevOutline;
    el.style.outlineOffset = prevOutlineOffset;
  }, 900);
}

export function ThreadSearch(props: { activeSessionId: string | null }) {
  const { activeSessionId } = props;
  const { lang } = useLanguage();
  const copy = useMemo(
    () =>
      lang === "ja"
        ? {
            open: "\u4f1a\u8a71\u5185\u691c\u7d22\u3092\u958b\u304f",
            title: "\u4f1a\u8a71\u5185\u691c\u7d22",
            description:
              "\u3053\u306e\u4f1a\u8a71\u306e\u30e1\u30c3\u30bb\u30fc\u30b8\u3092\u691c\u7d22\u3067\u304d\u307e\u3059\u3002Enter \u3067\u6b21\u3001Shift+Enter \u3067\u524d\u306e\u4e00\u81f4\u7b87\u6240\u3078\u79fb\u52d5\u3057\u307e\u3059\u3002",
            placeholder: "\u4f1a\u8a71\u5185\u3092\u691c\u7d22...",
            hint: "Enter \u3067\u6b21\u3078 / Shift+Enter \u3067\u524d\u3078",
            searchField: "\u4f1a\u8a71\u5185\u691c\u7d22",
            previous: "\u524d\u306e\u4e00\u81f4\u3078",
            next: "\u6b21\u306e\u4e00\u81f4\u3078",
            clear: "\u691c\u7d22\u3092\u30af\u30ea\u30a2",
          }
        : {
            open: "Open in-thread search",
            title: "Search this conversation",
            description:
              "Search messages in the current conversation. Press Enter for next match, or Shift+Enter for previous.",
            placeholder: "Search this conversation...",
            hint: "Enter for next / Shift+Enter for previous",
            searchField: "Conversation search",
            previous: "Previous match",
            next: "Next match",
            clear: "Clear search",
          },
    [lang],
  );

  const rootRef = useRef<HTMLDivElement | null>(null);
  const textareaRef = useRef<HTMLTextAreaElement | null>(null);

  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [hitCount, setHitCount] = useState(0);
  const [hitIndex, setHitIndex] = useState(0);
  const hitsRef = useRef<Hit[]>([]);

  const clearHits = useCallback(() => {
    hitsRef.current = [];
    setHitCount(0);
    setHitIndex(0);
  }, []);

  const hasSession = Boolean(activeSessionId);

  const counterLabel = useMemo(() => {
    if (!query.trim()) return "";
    if (hitCount <= 0) return "0/0";
    const idx = Math.min(Math.max(hitIndex, 0), hitCount - 1);
    return `${idx + 1}/${hitCount}`;
  }, [hitCount, hitIndex, query]);

  const recomputeHits = useCallback(
    (q: string) => {
      if (!hasSession) {
        clearHits();
        return;
      }

      const hits = collectHits(q);
      hitsRef.current = hits;
      setHitCount(hits.length);
      setHitIndex((prev) => {
        if (hits.length <= 0) return 0;
        return Math.min(Math.max(prev, 0), hits.length - 1);
      });
    },
    [clearHits, hasSession],
  );

  const resizeTextarea = useCallback(() => {
    const el = textareaRef.current;
    if (!el) return;
    el.style.height = "auto";
    const max = 160;
    el.style.height = Math.min(el.scrollHeight, max) + "px";
  }, []);

  useEffect(() => {
    const resetId = window.setTimeout(() => {
      setQuery("");
      clearHits();
      setOpen(false);
    }, 0);
    return () => window.clearTimeout(resetId);
  }, [activeSessionId, clearHits]);

  useEffect(() => {
    if (!query.trim()) {
      const resetId = window.setTimeout(() => clearHits(), 0);
      return () => window.clearTimeout(resetId);
    }

    const handle = window.setTimeout(() => recomputeHits(query), 150);
    return () => window.clearTimeout(handle);
  }, [query, recomputeHits, clearHits]);

  useEffect(() => {
    if (!open) return;
    resizeTextarea();
  }, [open, query, resizeTextarea]);

  useEffect(() => {
    if (!open) return;
    const onDown = (e: MouseEvent) => {
      const root = rootRef.current;
      if (!root) return;
      const target = e.target as Node | null;
      if (!target) return;
      if (!root.contains(target)) setOpen(false);
    };
    window.addEventListener("mousedown", onDown);
    return () => window.removeEventListener("mousedown", onDown);
  }, [open]);

  const goTo = useCallback((idx: number) => {
    const hits = hitsRef.current;
    if (!hits.length) return;
    const clamped = Math.min(Math.max(idx, 0), hits.length - 1);
    const hit = hits[clamped];
    setHitIndex(clamped);
    hit.root.scrollIntoView({ behavior: "smooth", block: "center" });
    flashHighlight(hit.highlightEl);
  }, []);

  const goPrev = useCallback(() => {
    if (hitCount <= 0) return;
    const next = hitIndex - 1 < 0 ? hitCount - 1 : hitIndex - 1;
    goTo(next);
  }, [goTo, hitCount, hitIndex]);

  const goNext = useCallback(() => {
    if (hitCount <= 0) return;
    const next = hitIndex + 1 >= hitCount ? 0 : hitIndex + 1;
    goTo(next);
  }, [goTo, hitCount, hitIndex]);

  return (
    <div
      ref={rootRef}
      className="ml-auto flex items-center justify-end"
      data-open={open ? "true" : "false"}
    >
      <div className="relative">
        <Button
          type="button"
          variant="ghost"
          size="icon-sm"
          className={cn(
            "rounded-full",
            open && "bg-muted-foreground/15 hover:bg-muted-foreground/20",
          )}
          onClick={() => {
            if (!hasSession) return;
            setOpen((v) => !v);
            window.setTimeout(() => textareaRef.current?.focus(), 0);
          }}
          disabled={!hasSession}
          aria-label={copy.open}
        >
          <SearchIcon className="size-4" />
        </Button>

        {open ? (
          <div className="absolute right-0 top-full z-50 mt-3 w-[42rem] max-w-[calc(100vw-2rem)] rounded-2xl border border-border/70 bg-background/95 p-4 shadow-xl backdrop-blur">
            <div className="grid gap-3 rounded-2xl border border-border/60 bg-muted/20 px-4 py-3 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-start">
              <div className="min-w-0">
                <div className="flex items-center gap-2 text-sm font-medium text-foreground">
                  <SearchIcon className="size-4 text-muted-foreground" />
                  <span>{copy.title}</span>
                </div>
                <div className="mt-1 text-xs leading-6 text-muted-foreground sm:max-w-[34rem]">
                  {copy.description}
                </div>
              </div>
              <Button
                type="button"
                variant="ghost"
                size="icon-sm"
                className="shrink-0 rounded-full"
                onClick={() => setOpen(false)}
                aria-label={lang === "ja" ? "検索を閉じる" : "Close search"}
              >
                <XIcon className="size-4" />
              </Button>
            </div>

            <div className="mt-3 grid gap-3 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-start">
              <div className="min-w-0">
                <textarea
                  ref={textareaRef}
                  value={query}
                  onChange={(e) => setQuery(e.currentTarget.value)}
                  onKeyDown={(e) => {
                    if ((e.nativeEvent as unknown as { isComposing?: boolean })?.isComposing) return;
                    if (e.key === "Escape") {
                      e.preventDefault();
                      setOpen(false);
                      return;
                    }
                    if (e.key === "Enter") {
                      e.preventDefault();
                      recomputeHits(query);
                      if (e.shiftKey) goPrev();
                      else goNext();
                    }
                  }}
                  placeholder={copy.placeholder}
                  className={cn(
                    "min-h-[56px] w-full resize-none rounded-xl border border-input bg-background/70 px-4 py-3 text-sm text-foreground shadow-xs outline-none",
                    "placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50",
                  )}
                  rows={2}
                  aria-label={copy.searchField}
                />
              </div>

              <div className="flex shrink-0 items-center gap-2 sm:pt-1">
                <Button type="button" variant="ghost" size="icon-sm" className="rounded-full" onClick={goPrev} disabled={hitCount <= 0} aria-label={copy.previous}>
                  <ChevronUpIcon className="size-4" />
                </Button>
                <Button type="button" variant="ghost" size="icon-sm" className="rounded-full" onClick={goNext} disabled={hitCount <= 0} aria-label={copy.next}>
                  <ChevronDownIcon className="size-4" />
                </Button>
                <Button
                  type="button"
                  variant="ghost"
                  size="icon-sm"
                  className="rounded-full"
                  onClick={() => {
                    setQuery("");
                    clearHits();
                    textareaRef.current?.focus();
                  }}
                  aria-label={copy.clear}
                >
                  <XIcon className="size-4" />
                </Button>
              </div>
            </div>

            <div className="mt-3 flex flex-wrap items-center justify-between gap-x-4 gap-y-2 text-xs text-muted-foreground">
              <div>{copy.hint}</div>
              <div className="tabular-nums">{query.trim() ? counterLabel : ""}</div>
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}
