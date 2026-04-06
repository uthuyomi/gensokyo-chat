import { DEFAULT_LANGUAGE, resolveLanguage, type AppLanguage } from "@/lib/i18n/types";
import { messages } from "@/lib/i18n/messages";

export const LANGUAGE_COOKIE = "touhou_lang";
export const LANGUAGE_STORAGE_KEY = "touhou.language";

export function getMessage(path: string, lang: AppLanguage = DEFAULT_LANGUAGE): unknown {
  const parts = path.split(".");
  let current: unknown = messages[lang];
  for (const part of parts) {
    if (!current || typeof current !== "object" || Array.isArray(current)) return undefined;
    current = (current as Record<string, unknown>)[part];
  }
  return current;
}

export function t(path: string, lang: AppLanguage = DEFAULT_LANGUAGE, fallback?: string): string {
  const value = getMessage(path, lang);
  return typeof value === "string" ? value : fallback ?? path;
}

export function tList(path: string, lang: AppLanguage = DEFAULT_LANGUAGE): string[] {
  const value = getMessage(path, lang);
  return Array.isArray(value) ? value.map((item) => String(item)) : [];
}

export function readLanguageCookieValue(raw: string | null | undefined): AppLanguage {
  return resolveLanguage(String(raw ?? "").trim());
}
