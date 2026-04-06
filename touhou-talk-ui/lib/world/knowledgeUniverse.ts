export type KnowledgeUniverseNode = {
  id: string;
  source_kind: string;
  source_ref_id: string;
  title: string;
  summary: string;
  x: number;
  y: number;
  z: number;
  size: number;
  metadata?: Record<string, unknown>;
};

export type KnowledgeUniverseEdge = {
  source: string;
  target: string;
  weight: number;
};

export type KnowledgeUniverseResponse = {
  world_id: string;
  node_count: number;
  edge_count: number;
  source_counts: Record<string, number>;
  nodes: KnowledgeUniverseNode[];
  edges: KnowledgeUniverseEdge[];
};
