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

const FALLBACK_COLOR = "#94a3b8";

function metadataColor(node: KnowledgeUniverseNode) {
  const value = node.metadata?.color;
  return typeof value === "string" && value.trim() ? value : FALLBACK_COLOR;
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

export default function KnowledgeUniverse(props: {
  worldId?: string;
  limit?: number;
  maxEdgesPerNode?: number;
  similarityThreshold?: number;
}) {
  const worldId = props.worldId || "gensokyo_main";
  const limit = props.limit ?? 240;
  const maxEdgesPerNode = props.maxEdgesPerNode ?? 2;
  const similarityThreshold = props.similarityThreshold ?? 0.32;

  const mountRef = useRef<HTMLDivElement | null>(null);
  const hoveredRef = useRef("");
  const selectedRef = useRef("");
  const [data, setData] = useState<KnowledgeUniverseResponse | null>(null);
  const [error, setError] = useState<string>("");
  const [loading, setLoading] = useState(true);
  const [selectedId, setSelectedId] = useState<string>("");
  const [hoveredId, setHoveredId] = useState<string>("");

  const selectedNode = useMemo(() => {
    const activeId = selectedId || hoveredId;
    if (!data || !activeId) return null;
    return data.nodes.find((node) => node.id === activeId) ?? null;
  }, [data, hoveredId, selectedId]);

  const stats = useMemo(() => universeStats(data?.source_counts || {}), [data]);

  useEffect(() => {
    hoveredRef.current = hoveredId;
  }, [hoveredId]);

  useEffect(() => {
    selectedRef.current = selectedId;
  }, [selectedId]);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError("");
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
        setSelectedId((current) => current || payload.nodes[0]?.id || "");
      })
      .catch((reason) => {
        if (cancelled) return;
        setError(reason instanceof Error ? reason.message : String(reason));
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [limit, maxEdgesPerNode, similarityThreshold, worldId]);

  useEffect(() => {
    const mount = mountRef.current;
    if (!mount || !data || data.nodes.length === 0) return;

    const width = mount.clientWidth || 960;
    const height = mount.clientHeight || 640;
    const scene = new THREE.Scene();
    scene.background = new THREE.Color("#03131a");
    scene.fog = new THREE.FogExp2("#03131a", 0.012);

    const camera = new THREE.PerspectiveCamera(55, width / height, 0.1, 1000);
    camera.position.set(0, 10, 78);

    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    renderer.setSize(width, height);
    mount.innerHTML = "";
    mount.appendChild(renderer.domElement);

    const controls = new OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.08;
    controls.minDistance = 18;
    controls.maxDistance = 180;

    const ambientLight = new THREE.AmbientLight("#9dd6ff", 1.2);
    const pointLight = new THREE.PointLight("#b6fff6", 1.5, 260, 2);
    pointLight.position.set(18, 20, 24);
    scene.add(ambientLight, pointLight);

    const starGeometry = new THREE.BufferGeometry();
    const starVertices: number[] = [];
    for (let i = 0; i < 420; i += 1) {
      starVertices.push(
        (Math.random() - 0.5) * 220,
        (Math.random() - 0.5) * 220,
        (Math.random() - 0.5) * 220,
      );
    }
    starGeometry.setAttribute("position", new THREE.Float32BufferAttribute(starVertices, 3));
    const stars = new THREE.Points(
      starGeometry,
      new THREE.PointsMaterial({ color: "#9be7ff", size: 0.28, transparent: true, opacity: 0.65 }),
    );
    scene.add(stars);

    const sphereGeometry = new THREE.SphereGeometry(1, 16, 16);
    const nodeGroup = new THREE.Group();
    const edgeGroup = new THREE.Group();
    scene.add(edgeGroup, nodeGroup);

    const meshById = new Map<string, THREE.Mesh>();
    const baseScale = 0.65;
    for (const node of data.nodes) {
      const mesh = new THREE.Mesh(
        sphereGeometry,
        new THREE.MeshStandardMaterial({
          color: new THREE.Color(metadataColor(node)),
          emissive: new THREE.Color(metadataColor(node)).multiplyScalar(0.28),
          metalness: 0.12,
          roughness: 0.35,
        }),
      );
      mesh.position.set(node.x, node.y, node.z);
      const scale = baseScale * Math.max(0.9, node.size);
      mesh.scale.setScalar(scale);
      mesh.userData.nodeId = node.id;
      mesh.userData.baseScale = scale;
      nodeGroup.add(mesh);
      meshById.set(node.id, mesh);
    }

    const nodeById = new Map(data.nodes.map((node) => [node.id, node]));
    for (const edge of data.edges) {
      const source = nodeById.get(edge.source);
      const target = nodeById.get(edge.target);
      if (!source || !target) continue;
      const geometry = new THREE.BufferGeometry().setFromPoints([
        new THREE.Vector3(source.x, source.y, source.z),
        new THREE.Vector3(target.x, target.y, target.z),
      ]);
      const material = new THREE.LineBasicMaterial({
        color: "#6ee7f9",
        transparent: true,
        opacity: Math.min(0.5, Math.max(0.11, edge.weight * 0.5)),
      });
      edgeGroup.add(new THREE.Line(geometry, material));
    }

    const raycaster = new THREE.Raycaster();
    const pointer = new THREE.Vector2();

    const applyHighlight = () => {
      for (const [nodeId, mesh] of meshById.entries()) {
        const isActive = nodeId === selectedRef.current || nodeId === hoveredRef.current;
        const material = mesh.material as THREE.MeshStandardMaterial;
        const color = metadataColor(nodeById.get(nodeId)!);
        material.color.set(color);
        material.emissive.set(color).multiplyScalar(isActive ? 0.6 : 0.28);
        const base = Number(mesh.userData.baseScale || baseScale);
        mesh.scale.setScalar(isActive ? base * 1.45 : base);
      }
    };

    const updatePointer = (event: PointerEvent) => {
      const rect = renderer.domElement.getBoundingClientRect();
      pointer.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
      pointer.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
      raycaster.setFromCamera(pointer, camera);
      const hit = raycaster.intersectObjects(nodeGroup.children, false)[0];
      const nodeId = hit?.object?.userData?.nodeId ? String(hit.object.userData.nodeId) : "";
      setHoveredId(nodeId);
    };

    const handleClick = () => {
      if (hoveredRef.current) setSelectedId(hoveredRef.current);
    };

    const handleResize = () => {
      const nextWidth = mount.clientWidth || 960;
      const nextHeight = mount.clientHeight || 640;
      camera.aspect = nextWidth / nextHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(nextWidth, nextHeight);
    };

    renderer.domElement.addEventListener("pointermove", updatePointer);
    renderer.domElement.addEventListener("click", handleClick);
    window.addEventListener("resize", handleResize);

    let frameId = 0;
    const animate = () => {
      frameId = window.requestAnimationFrame(animate);
      nodeGroup.rotation.y += 0.0014;
      edgeGroup.rotation.y += 0.0014;
      controls.update();
      applyHighlight();
      renderer.render(scene, camera);
    };
    animate();

    return () => {
      window.cancelAnimationFrame(frameId);
      window.removeEventListener("resize", handleResize);
      renderer.domElement.removeEventListener("pointermove", updatePointer);
      renderer.domElement.removeEventListener("click", handleClick);
      controls.dispose();
      sphereGeometry.dispose();
      starGeometry.dispose();
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
  }, [data]);

  return (
    <div className="grid min-h-screen grid-cols-1 bg-[#021014] text-[#e8fbff] lg:grid-cols-[minmax(0,1fr)_360px]">
      <div className="relative min-h-[68vh] lg:min-h-screen">
        <div ref={mountRef} className="h-full min-h-[68vh] w-full" />
        <div className="pointer-events-none absolute left-5 top-5 max-w-md rounded-2xl border border-white/10 bg-black/35 px-4 py-3 backdrop-blur-md">
          <div className="text-[11px] uppercase tracking-[0.28em] text-cyan-200/70">Gensokyo Knowledge Universe</div>
          <h1 className="mt-2 text-2xl font-semibold text-white">幻想郷知識宇宙</h1>
          <p className="mt-2 text-sm leading-6 text-cyan-50/78">
            lore、Wiki、年代記、会話文脈をひとつの宇宙へ投影した意味地図だよ。近い点ほど、幻想郷の中で近い話題ってわけさ。
          </p>
        </div>
        {loading ? (
          <div className="absolute inset-0 grid place-items-center bg-[#021014]/70 text-sm tracking-[0.24em] text-cyan-100/80">
            EMBEDDING STARS LOADING
          </div>
        ) : null}
      </div>

      <aside className="border-l border-white/10 bg-[#061b22] p-5">
        <div className="rounded-2xl border border-white/10 bg-white/5 p-4">
          <div className="text-xs uppercase tracking-[0.25em] text-cyan-200/70">World</div>
          <div className="mt-2 text-lg font-semibold">{worldId}</div>
          <div className="mt-4 grid grid-cols-2 gap-3 text-sm">
            <div className="rounded-xl bg-black/20 p-3">
              <div className="text-cyan-200/70">ノード</div>
              <div className="mt-1 text-xl font-semibold">{data?.node_count ?? 0}</div>
            </div>
            <div className="rounded-xl bg-black/20 p-3">
              <div className="text-cyan-200/70">エッジ</div>
              <div className="mt-1 text-xl font-semibold">{data?.edge_count ?? 0}</div>
            </div>
          </div>
        </div>

        <div className="mt-5 rounded-2xl border border-white/10 bg-white/5 p-4">
          <div className="text-xs uppercase tracking-[0.25em] text-cyan-200/70">クラスタ</div>
          <div className="mt-3 space-y-2">
            {stats.map((stat) => (
              <div key={stat.kind} className="flex items-center justify-between rounded-xl bg-black/20 px-3 py-2 text-sm">
                <span>{stat.label}</span>
                <span className="font-semibold text-cyan-100">{stat.count}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="mt-5 rounded-2xl border border-white/10 bg-white/5 p-4">
          <div className="text-xs uppercase tracking-[0.25em] text-cyan-200/70">選択中</div>
          {error ? <div className="mt-3 text-sm text-rose-300">{error}</div> : null}
          {selectedNode ? (
            <div className="mt-3 space-y-3">
              <div>
                <div className="text-lg font-semibold">{knowledgeNodeTitle(selectedNode)}</div>
                <div className="mt-1 text-xs uppercase tracking-[0.2em] text-cyan-200/70">
                  {knowledgeKindLabel(selectedNode.source_kind)}
                </div>
              </div>
              <p className="text-sm leading-6 text-cyan-50/82">{knowledgeNodeSummary(selectedNode)}</p>
              <div className="rounded-xl bg-black/20 p-3 text-xs leading-6 text-cyan-100/78">
                <div>source_ref_id: {selectedNode.source_ref_id}</div>
                <div>
                  xyz: {selectedNode.x.toFixed(2)}, {selectedNode.y.toFixed(2)}, {selectedNode.z.toFixed(2)}
                </div>
              </div>
            </div>
          ) : (
            <div className="mt-3 text-sm text-cyan-50/72">点を選ぶと、そこに結びついた知識の断面が見えるよ。</div>
          )}
        </div>
      </aside>
    </div>
  );
}
