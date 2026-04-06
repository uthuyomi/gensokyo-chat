export type AppLanguage = "ja" | "en";

export const DEFAULT_LANGUAGE: AppLanguage = "ja";
export const SUPPORTED_LANGUAGES: AppLanguage[] = ["ja", "en"];

export function resolveLanguage(raw: unknown): AppLanguage {
  return raw === "en" ? "en" : DEFAULT_LANGUAGE;
}
