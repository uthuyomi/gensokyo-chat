"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js";

import type { KnowledgeUniverseNode, KnowledgeUniverseResponse } from "@/lib/world/knowledgeUniverse";
import {
  knowledgeKindLabel,
  knowledgeNodeSummary,
  knowledgeNodeTitle,
} from "@/lib/world/knowledgeUniverseLabels";

const FALLBACK_COLOR = "#7c8aa1";
const INITIAL_RENDER_LIMIT = 160;
const RENDER_STEP = 160;
const TOOLTIP_OFFSET = 18;

function metadataColor(node: KnowledgeUniverseNode) {
  const value = node.metadata?.color;
  return typeof value === "string" && value.trim() ? value : FALLBACK_COLOR;
}

function vividNodeColor(node: KnowledgeUniverseNode) {
  const color = new THREE.Color(metadataColor(node));
  const hsl = { h: 0, s: 0, l: 0 };
  color.getHSL(hsl);
  color.setHSL(hsl.h, Math.max(0.68, hsl.s), Math.max(0.56, hsl.l));
  return color;
}

function universeStats(sourceCounts: Record<string, number>) {
  return Object.entries(sourceCounts)
    .sort((left, right) => right[1] - left[1])
    .map(([kind, count]) => ({
      kind,
      count,
      label: knowledgeKindLabel(kind),
    }));
}

function formatMetadataValue(value: unknown): string {
  if (value == null) return "-";
  if (typeof value === "string") return value;
  if (typeof value === "number" || typeof value === "boolean") return String(value);
  try {
    return JSON.stringify(value, null, 2);
  } catch {
    return String(value);
  }
}

export default function KnowledgeUniverse(props: {
  worldId?: string;
  limit?: number;
  maxEdgesPerNode?: number;
  similarityThreshold?: number;
}) {
  const worldId = props.worldId || "gensokyo_main";
  const limit = props.limit ?? 2000;
  const maxEdgesPerNode = props.maxEdgesPerNode ?? 2;
  const similarityThreshold = props.similarityThreshold ?? 0.32;

  const mountRef = useRef<HTMLDivElement | null>(null);
  const hoveredRef = useRef("");
  const selectedRef = useRef("");
  const [data, setData] = useState<KnowledgeUniverseResponse | null>(null);
  const [error, setError] = useState("");
  const [selectedId, setSelectedId] = useState<string>("");
  const [hoveredId, setHoveredId] = useState<string>("");
  const [renderLimit, setRenderLimit] = useState(INITIAL_RENDER_LIMIT);
  const [tooltipPosition, setTooltipPosition] = useState({ x: 24, y: 24 });
  const loading = !data && !error;

  const visibleData = useMemo<KnowledgeUniverseResponse | null>(() => {
    if (!data) return null;
    const visibleNodes = data.nodes.slice(0, Math.max(1, renderLimit));
    const visibleIds = new Set(visibleNodes.map((node) => node.id));
    const visibleEdges = data.edges.filter(
      (edge) => visibleIds.has(edge.source) && visibleIds.has(edge.target),
    );
    const sourceCounts: Record<string, number> = {};
    for (const node of visibleNodes) {
      sourceCounts[node.source_kind] = (sourceCounts[node.source_kind] || 0) + 1;
    }
    return {
      ...data,
      node_count: visibleNodes.length,
      edge_count: visibleEdges.length,
      source_counts: sourceCounts,
      nodes: visibleNodes,
      edges: visibleEdges,
    };
  }, [data, renderLimit]);

  const activeNode = useMemo(() => {
    const activeId = hoveredId || selectedId;
    if (!visibleData || !activeId) return null;
    return visibleData.nodes.find((node) => node.id === activeId) ?? null;
  }, [hoveredId, selectedId, visibleData]);

  const hoveredNode = useMemo(() => {
    if (!visibleData || !hoveredId) return null;
    return visibleData.nodes.find((node) => node.id === hoveredId) ?? null;
  }, [hoveredId, visibleData]);

  const stats = useMemo(() => universeStats(visibleData?.source_counts || {}), [visibleData]);
  const metadataEntries = useMemo(
    () => Object.entries(activeNode?.metadata || {}).sort((left, right) => left[0].localeCompare(right[0])),
    [activeNode],
  );

  useEffect(() => {
    hoveredRef.current = hoveredId;
  }, [hoveredId]);

  useEffect(() => {
    selectedRef.current = selectedId;
  }, [selectedId]);

  useEffect(() => {
    let cancelled = false;
    void fetch(
      `/api/world/knowledge/universe?world_id=${encodeURIComponent(worldId)}&limit=${limit}&max_edges_per_node=${maxEdgesPerNode}&similarity_threshold=${similarityThreshold}`,
      { cache: "no-store" },
    )
      .then(async (response) => {
        if (!response.ok) {
          const payload = await response.text().catch(() => "");
          throw new Error(payload || `request_failed:${response.status}`);
        }
        return response.json() as Promise<KnowledgeUniverseResponse>;
      })
      .then((payload) => {
        if (cancelled) return;
        setData(payload);
        setError("");
        setRenderLimit(Math.min(INITIAL_RENDER_LIMIT, payload.nodes.length || INITIAL_RENDER_LIMIT));
        setSelectedId((current) => current || payload.nodes[0]?.id || "");
      })
      .catch((reason) => {
        if (cancelled) return;
        setError(reason instanceof Error ? reason.message : String(reason));
        setData(null);
      });

    return () => {
      cancelled = true;
    };
  }, [limit, maxEdgesPerNode, similarityThreshold, worldId]);

  useEffect(() => {
    const mount = mountRef.current;
    if (!mount || !visibleData || visibleData.nodes.length === 0) return;

    const width = mount.clientWidth || 960;
    const height = mount.clientHeight || 640;
    const scene = new THREE.Scene();
    scene.background = new THREE.Color("#16181d");
    scene.fog = new THREE.FogExp2("#16181d", 0.009);

    const camera = new THREE.PerspectiveCamera(48, width / height, 0.1, 1000);
    camera.position.set(0, 6, 88);

    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    renderer.setSize(width, height);
    mount.innerHTML = "";
    mount.appendChild(renderer.domElement);

    const controls = new OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.06;
    controls.enablePan = false;
    controls.autoRotate = false;
    controls.minDistance = 24;
    controls.maxDistance = 180;

    const ambientLight = new THREE.AmbientLight("#d7dee8", 0.85);
    const pointLight = new THREE.PointLight("#a6b6cc", 0.5, 180, 2);
    pointLight.position.set(16, 18, 20);
    scene.add(ambientLight, pointLight);

    const grid = new THREE.GridHelper(220, 22, "#2a2f38", "#22262e");
    grid.position.y = -34;
    grid.material.transparent = true;
    grid.material.opacity = 0.2;
    scene.add(grid);

    const sphereGeometry = new THREE.SphereGeometry(1, 8, 8);
    const nodeGroup = new THREE.Group();
    const edgeGroup = new THREE.Group();
    scene.add(edgeGroup, nodeGroup);

    const meshById = new Map<string, THREE.Mesh>();
    const baseScale = 0.24;
    for (const node of visibleData.nodes) {
      const color = vividNodeColor(node);
      const mesh = new THREE.Mesh(
        sphereGeometry,
        new THREE.MeshStandardMaterial({
          color,
          emissive: color.clone().multiplyScalar(0.16),
          metalness: 0.06,
          roughness: 0.72,
        }),
      );
      mesh.position.set(node.x, node.y, node.z);
      const scale = baseScale * Math.max(0.85, Math.min(node.size, 1.45));
      mesh.scale.setScalar(scale);
      mesh.userData.nodeId = node.id;
      mesh.userData.baseScale = scale;
      nodeGroup.add(mesh);
      meshById.set(node.id, mesh);
    }

    const nodeById = new Map(visibleData.nodes.map((node) => [node.id, node]));
    if (visibleData.edges.length > 0) {
      const edgePositions: number[] = [];
      for (const edge of visibleData.edges) {
        const source = nodeById.get(edge.source);
        const target = nodeById.get(edge.target);
        if (!source || !target) continue;
        edgePositions.push(source.x, source.y, source.z, target.x, target.y, target.z);
      }
      const edgeGeometry = new THREE.BufferGeometry();
      edgeGeometry.setAttribute("position", new THREE.Float32BufferAttribute(edgePositions, 3));
      const edgeMaterial = new THREE.LineBasicMaterial({
        color: "#4d5a6d",
        transparent: true,
        opacity: 0.2,
      });
      edgeGroup.add(new THREE.LineSegments(edgeGeometry, edgeMaterial));
    }

    const raycaster = new THREE.Raycaster();
    raycaster.params.Line = { threshold: 0.8 };
    const pointer = new THREE.Vector2();
    let lastHover = "";
    let lastSelected = "";

    const applyHighlight = () => {
      for (const [nodeId, mesh] of meshById.entries()) {
        const isActive = nodeId === selectedRef.current || nodeId === hoveredRef.current;
        const material = mesh.material as THREE.MeshStandardMaterial;
        const node = nodeById.get(nodeId);
        if (!node) continue;
        const baseColor = vividNodeColor(node);
        material.color.copy(baseColor);
        material.emissive.copy(baseColor).multiplyScalar(isActive ? 0.34 : 0.16);
        const base = Number(mesh.userData.baseScale || baseScale);
        mesh.scale.setScalar(isActive ? base * 1.35 : base);
      }
    };

    const updatePointer = (event: PointerEvent) => {
      const rect = renderer.domElement.getBoundingClientRect();
      const relativeX = event.clientX - rect.left;
      const relativeY = event.clientY - rect.top;
      setTooltipPosition({
        x: Math.min(relativeX + TOOLTIP_OFFSET, rect.width - 300),
        y: Math.min(relativeY + TOOLTIP_OFFSET, rect.height - 220),
      });
      pointer.x = (relativeX / rect.width) * 2 - 1;
      pointer.y = -(relativeY / rect.height) * 2 + 1;
      raycaster.setFromCamera(pointer, camera);
      const hit = raycaster.intersectObjects(nodeGroup.children, false)[0];
      const nodeId = hit?.object?.userData?.nodeId ? String(hit.object.userData.nodeId) : "";
      setHoveredId(nodeId);
    };

    const handleClick = () => {
      if (hoveredRef.current) setSelectedId(hoveredRef.current);
    };

    const handlePointerLeave = () => {
      setHoveredId("");
    };

    const handleResize = () => {
      const nextWidth = mount.clientWidth || 960;
      const nextHeight = mount.clientHeight || 640;
      camera.aspect = nextWidth / nextHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(nextWidth, nextHeight);
    };

    renderer.domElement.addEventListener("pointermove", updatePointer);
    renderer.domElement.addEventListener("pointerleave", handlePointerLeave);
    renderer.domElement.addEventListener("click", handleClick);
    window.addEventListener("resize", handleResize);

    let frameId = 0;
    const animate = () => {
      frameId = window.requestAnimationFrame(animate);
      controls.update();
      if (lastHover !== hoveredRef.current || lastSelected !== selectedRef.current) {
        applyHighlight();
        lastHover = hoveredRef.current;
        lastSelected = selectedRef.current;
      }
      renderer.render(scene, camera);
    };

    applyHighlight();
    animate();

    return () => {
      window.cancelAnimationFrame(frameId);
      window.removeEventListener("resize", handleResize);
      renderer.domElement.removeEventListener("pointermove", updatePointer);
      renderer.domElement.removeEventListener("pointerleave", handlePointerLeave);
      renderer.domElement.removeEventListener("click", handleClick);
      controls.dispose();
      sphereGeometry.dispose();
      renderer.dispose();
      for (const child of edgeGroup.children) {
        const line = child as THREE.Line;
        line.geometry.dispose();
        (line.material as THREE.Material).dispose();
      }
      for (const child of nodeGroup.children) {
        const mesh = child as THREE.Mesh;
        (mesh.material as THREE.Material).dispose();
      }
      mount.innerHTML = "";
    };
  }, [visibleData]);

  return (
    <div className="grid min-h-screen grid-cols-1 bg-[#101217] text-[#d7dde8] lg:grid-cols-[minmax(0,1fr)_420px]">
      <div className="relative min-h-[68vh] border-r border-white/6 bg-[radial-gradient(circle_at_top,#1b1f28_0%,#101217_58%,#0c0e12_100%)] lg:min-h-screen">
        <div ref={mountRef} className="h-full min-h-[68vh] w-full" />
        <div className="pointer-events-none absolute left-5 top-5 max-w-lg rounded-xl border border-white/8 bg-[#161a22]/86 px-4 py-3 shadow-[0_20px_60px_rgba(0,0,0,0.35)] backdrop-blur-md">
          <div className="text-[11px] uppercase tracking-[0.32em] text-slate-400">Knowledge Graph</div>
          <h1 className="mt-2 text-2xl font-semibold text-slate-100">幻想郷ノートグラフ</h1>
          <p className="mt-2 text-sm leading-6 text-slate-400">
            ノードに触れると、その項目の詳細をカーソルの近くへ表示します。静かな Obsidian 風の知識グラフです。
          </p>
        </div>
        {hoveredNode ? (
          <div
            className="pointer-events-none absolute z-20 max-w-[280px] rounded-xl border border-white/10 bg-[#181d26]/96 px-3 py-3 shadow-[0_18px_60px_rgba(0,0,0,0.42)] backdrop-blur-md"
            style={{ left: tooltipPosition.x, top: tooltipPosition.y }}
          >
            <div className="text-[10px] uppercase tracking-[0.24em] text-slate-500">
              {knowledgeKindLabel(hoveredNode.source_kind)}
            </div>
            <div className="mt-1 text-sm font-semibold leading-5 text-slate-100">
              {knowledgeNodeTitle(hoveredNode)}
            </div>
            <div className="mt-2 text-xs leading-5 text-slate-300">{knowledgeNodeSummary(hoveredNode)}</div>
            <div className="mt-2 text-[11px] leading-5 text-slate-500">
              ref: {hoveredNode.source_ref_id}
            </div>
          </div>
        ) : null}
        {loading ? (
          <div className="absolute inset-0 grid place-items-center bg-[#101217]/72 text-xs uppercase tracking-[0.32em] text-slate-400">
            Loading graph
          </div>
        ) : null}
      </div>

      <aside className="border-l border-white/6 bg-[#141820] p-5">
        <div className="rounded-xl border border-white/8 bg-[#1a1f29] p-4 shadow-[0_12px_40px_rgba(0,0,0,0.22)]">
          <div className="text-[11px] uppercase tracking-[0.28em] text-slate-500">Workspace</div>
          <div className="mt-2 text-lg font-semibold text-slate-100">{worldId}</div>
          <div className="mt-4 grid grid-cols-2 gap-3 text-sm">
            <div className="rounded-lg border border-white/6 bg-[#12161d] p-3">
              <div className="text-slate-500">ノード</div>
              <div className="mt-1 text-xl font-semibold text-slate-100">
                {visibleData?.node_count ?? 0}
                <span className="ml-2 text-xs text-slate-500">/ {data?.node_count ?? 0}</span>
              </div>
            </div>
            <div className="rounded-lg border border-white/6 bg-[#12161d] p-3">
              <div className="text-slate-500">エッジ</div>
              <div className="mt-1 text-xl font-semibold text-slate-100">{visibleData?.edge_count ?? 0}</div>
            </div>
          </div>
          <div className="mt-3 flex gap-2">
            <button
              type="button"
              onClick={() => setRenderLimit((current) => Math.min(current + RENDER_STEP, data?.nodes.length || current))}
              disabled={!data || renderLimit >= data.nodes.length}
              className="rounded-md border border-slate-700 bg-[#202633] px-3 py-2 text-xs font-medium text-slate-200 transition hover:border-slate-500 hover:bg-[#252c3a] disabled:cursor-not-allowed disabled:opacity-40"
            >
              追加で表示
            </button>
            <button
              type="button"
              onClick={() => setRenderLimit(data?.nodes.length || renderLimit)}
              disabled={!data || renderLimit >= data.nodes.length}
              className="rounded-md border border-slate-700 bg-transparent px-3 py-2 text-xs font-medium text-slate-300 transition hover:border-slate-500 hover:bg-white/5 disabled:cursor-not-allowed disabled:opacity-40"
            >
              すべて表示
            </button>
          </div>
        </div>

        <div className="mt-5 rounded-xl border border-white/8 bg-[#1a1f29] p-4 shadow-[0_12px_40px_rgba(0,0,0,0.22)]">
          <div className="text-[11px] uppercase tracking-[0.28em] text-slate-500">Clusters</div>
          <div className="mt-3 space-y-2">
            {stats.map((stat) => (
              <div key={stat.kind} className="flex items-center justify-between rounded-lg border border-white/6 bg-[#12161d] px-3 py-2 text-sm">
                <span className="text-slate-300">{stat.label}</span>
                <span className="font-semibold text-slate-100">{stat.count}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="mt-5 rounded-xl border border-white/8 bg-[#1a1f29] p-4 shadow-[0_12px_40px_rgba(0,0,0,0.22)]">
          <div className="text-[11px] uppercase tracking-[0.28em] text-slate-500">
            {hoveredId ? "Hovered" : "Selected"}
          </div>
          {error ? <div className="mt-3 text-sm text-rose-300">{error}</div> : null}
          {activeNode ? (
            <div className="mt-3 space-y-4">
              <div>
                <div className="text-lg font-semibold text-slate-100">{knowledgeNodeTitle(activeNode)}</div>
                <div className="mt-1 text-xs uppercase tracking-[0.18em] text-slate-500">
                  {knowledgeKindLabel(activeNode.source_kind)}
                </div>
              </div>

              <p className="text-sm leading-6 text-slate-300">{knowledgeNodeSummary(activeNode)}</p>

              <div className="rounded-lg border border-white/6 bg-[#12161d] p-3 text-xs leading-6 text-slate-400">
                <div>node_id: {activeNode.id}</div>
                <div>source_ref_id: {activeNode.source_ref_id}</div>
                <div>title: {activeNode.title || "-"}</div>
                <div>summary: {activeNode.summary || "-"}</div>
                <div>
                  xyz: {activeNode.x.toFixed(2)}, {activeNode.y.toFixed(2)}, {activeNode.z.toFixed(2)}
                </div>
                <div>size: {activeNode.size.toFixed(2)}</div>
              </div>

              <div className="rounded-lg border border-white/6 bg-[#12161d] p-3">
                <div className="text-[11px] uppercase tracking-[0.24em] text-slate-500">Metadata</div>
                {metadataEntries.length > 0 ? (
                  <div className="mt-3 space-y-3">
                    {metadataEntries.map(([key, value]) => (
                      <div key={key} className="border-b border-white/6 pb-3 last:border-b-0 last:pb-0">
                        <div className="text-[11px] uppercase tracking-[0.18em] text-slate-500">{key}</div>
                        <pre className="mt-1 overflow-x-auto whitespace-pre-wrap break-words font-mono text-xs leading-6 text-slate-300">
                          {formatMetadataValue(value)}
                        </pre>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="mt-3 text-sm text-slate-400">metadata はありません。</div>
                )}
              </div>
            </div>
          ) : (
            <div className="mt-3 text-sm leading-6 text-slate-400">
              点に触れると、そのノードの情報をここへ表示します。
            </div>
          )}
        </div>
      </aside>
    </div>
  );
}
