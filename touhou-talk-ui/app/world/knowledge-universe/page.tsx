import KnowledgeUniverse from "@/components/world/KnowledgeUniverse";

export const dynamic = "force-dynamic";

export default function KnowledgeUniversePage() {
  return <KnowledgeUniverse worldId="gensokyo_main" limit={240} maxEdgesPerNode={2} similarityThreshold={0.32} />;
}
