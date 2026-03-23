import { CHARACTERS } from "@/data/characters";
import { LOCATIONS } from "@/lib/map/locations";
import type { KnowledgeUniverseNode } from "@/lib/world/knowledgeUniverse";

const KIND_LABELS_JA: Record<string, string> = {
  canon_claim: "正史設定",
  lore_entry: "世界設定",
  wiki_page: "Wiki項目",
  chronicle_entry: "年代記",
  chat_context: "会話文脈",
};

const EXTRA_LOCATION_LABELS: Record<string, string> = {
  lunar_capital: "月の都",
  backdoor_realm: "後戸の国",
  beast_realm: "獣界",
  blood_pool_hell: "血の池地獄",
  rainbow_dragon_cave: "虹龍洞",
  former_hell: "旧地獄",
  myouren_temple: "命蓮寺",
  suzunaan: "鈴奈庵",
  kourindou: "香霖堂",
  chireiden: "地霊殿",
  divine_spirit_mausoleum: "神霊廟",
  scarlet_devil_mansion: "紅魔館",
};

function prettifyId(value: string) {
  return value.replace(/^wiki_/, "").replace(/^claim_/, "").replace(/^doc:/, "").replace(/_/g, " ").trim();
}

function characterName(characterId: string | null | undefined) {
  if (!characterId) return "";
  return CHARACTERS[characterId]?.name || prettifyId(characterId);
}

function locationName(locationId: string | null | undefined) {
  if (!locationId) return "";
  const direct = LOCATIONS.find((location) => location.id === locationId)?.name;
  if (direct) return direct;
  return EXTRA_LOCATION_LABELS[locationId] || prettifyId(locationId);
}

export function knowledgeKindLabel(kind: string) {
  return KIND_LABELS_JA[kind] || kind;
}

export function knowledgeNodeTitle(node: KnowledgeUniverseNode) {
  const contextType = typeof node.metadata?.context_type === "string" ? node.metadata.context_type : "";
  const characterId = typeof node.metadata?.character_id === "string" ? node.metadata.character_id : "";
  const locationId = typeof node.metadata?.location_id === "string" ? node.metadata.location_id : "";
  const character = characterName(characterId);
  const location = locationName(locationId);

  if (node.source_kind === "chat_context") {
    if (contextType === "character_voice" && character) return `${character}の話し方`;
    if (contextType === "character_location_story" && character && location) return `${character}と${location}`;
    if (contextType === "location_story" && location) return `${location}の空気`;
    if (contextType === "user_participation") return "参加履歴の文脈";
  }

  if (node.source_kind === "canon_claim" && character) return `${character}の正史設定`;
  if (node.source_kind === "canon_claim" && location) return `${location}の正史設定`;
  if (node.source_kind === "wiki_page") return `${node.title}の項目`;
  if (node.source_kind === "chronicle_entry") return `${node.title}の記録`;

  return node.title || prettifyId(node.source_ref_id);
}

export function knowledgeNodeSummary(node: KnowledgeUniverseNode) {
  const contextType = typeof node.metadata?.context_type === "string" ? node.metadata.context_type : "";
  const characterId = typeof node.metadata?.character_id === "string" ? node.metadata.character_id : "";
  const locationId = typeof node.metadata?.location_id === "string" ? node.metadata.location_id : "";
  const character = characterName(characterId);
  const location = locationName(locationId);

  if (node.source_kind === "chat_context") {
    if (contextType === "character_voice" && character) {
      return `${character}が会話するときの口調、温度感、立ち位置をまとめた会話文脈ノードだよ。`;
    }
    if (contextType === "character_location_story" && character && location) {
      return `${character}が${location}にいる時の空気感や振る舞いを表す会話文脈ノードだね。`;
    }
    if (contextType === "location_story" && location) {
      return `${location}という場に漂う雰囲気や、そこで起こりやすい物語の流れをまとめたノードさ。`;
    }
  }

  if (node.source_kind === "canon_claim") {
    return `幻想郷の正史設定を束ねた知識ノードだよ。参照IDは ${node.source_ref_id}。`;
  }
  if (node.source_kind === "lore_entry") {
    return "世界設定、制度、習俗の要点をまとめた lore ノードだね。";
  }
  if (node.source_kind === "wiki_page") {
    return "Wiki 表示用に再編集された項目だよ。原典や設定断片への入口になる。";
  }
  if (node.source_kind === "chronicle_entry") {
    return "年代記として編纂された記録ノードだよ。出来事の流れや余韻を読むための層さ。";
  }

  return node.summary;
}
