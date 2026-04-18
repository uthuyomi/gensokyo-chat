export type SessionMessageRouteContext = {
  params: Promise<{ sessionId: string }>;
};

export type SessionMessageStage =
  | "validate-request"
  | "load-context"
  | "upload-attachments"
  | "persist-user-message"
  | "delegate-runtime";

export type PersonaChatResponse = { reply: string; meta?: Record<string, unknown> };

export type PersonaToolPolicy = {
  attachment_mode?: "context_only" | "sdk_first";
  web_search_mode?: "off" | "auto" | "required";
  allow_web_search?: boolean;
  prefer_native_attachments?: boolean;
};

export type Phase04Attachment = {
  type: "upload";
  attachment_id: string;
  file_name: string;
  mime_type: string;
  kind: string;
  parsed_excerpt?: string;
};

export type Phase04LinkAnalysis = {
  type: "link_analysis";
  url: string;
  provider: "web_fetch" | "web_search" | "github_repo_search";
  results: Array<{
    title?: string;
    snippet?: string;
    url?: string;
    repository_url?: string;
    name?: string;
    owner?: string;
  }>;
};

export type RelationshipScoreResponse = {
  delta?: { trust?: number; familiarity?: number } | null;
  confidence?: number | null;
  reasons?: string[] | null;
  scopeHints?: string[] | null;
  memory?: {
    topics_add?: string[] | null;
    emotions_add?: string[] | null;
    recurring_issues_add?: string[] | null;
    traits_add?: string[] | null;
  } | null;
};

export type RelationshipState = { trust: number; familiarity: number };
export type UserMemoryState = {
  topics: string[];
  emotions: string[];
  recurring_issues: string[];
  traits: string[];
};

export type ParsedSessionMessageRequestBody = {
  characterId: string;
  text: string;
  coreModeRaw: FormDataEntryValue | null;
  sceneMode: "chat" | "continue";
  sceneTurnCount: number;
  files: File[];
  urls: string[];
};
