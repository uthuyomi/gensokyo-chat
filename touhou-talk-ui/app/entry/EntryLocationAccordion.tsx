"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";
import { useLanguage } from "@/components/i18n/LanguageProvider";

type EntryCharacter = {
  id: string;
  name: string;
  title: string;
  promptVersion?: string;
  layer: string;
  locationId: string;
  locationName: string;
  world?: {
    map: string;
    location: string;
  };
  ui: {
    avatar?: string;
    chatBackground?: string;
    placeholder?: string;
  };
};

type EntryLocationGroup = {
  id: string;
  name: string;
  count: number;
  characters: EntryCharacter[];
};

export type EntryLayerGroup = {
  layer: string;
  label: string;
  locations: EntryLocationGroup[];
};

function Chip({ children }: { children: React.ReactNode }) {
  return (
    <span className="inline-flex items-center rounded-full border border-border bg-secondary px-3 py-1 text-[11px] font-medium text-secondary-foreground">
      {children}
    </span>
  );
}

function layerLabel(layer: string, lang: "ja" | "en") {
  if (layer === "gensokyo") return lang === "en" ? "Gensokyo" : "幻想郷";
  if (layer === "deep") return lang === "en" ? "Former Hell" : "地底";
  if (layer === "higan") return lang === "en" ? "Higan" : "彼岸";
  return layer;
}

function buildNextPath(ch: EntryCharacter) {
  const layer = ch.world?.map ? String(ch.world.map) : "";
  const loc = ch.world?.location ? String(ch.world.location) : "";
  const sp = new URLSearchParams();
  sp.set("char", ch.id);
  if (layer) sp.set("layer", layer);
  if (loc) sp.set("loc", loc);
  return `/chat/session?${sp.toString()}`;
}

function CharacterCard({
  ch,
  visible,
}: {
  ch: EntryCharacter;
  visible: boolean;
}) {
  const { t, lang } = useLanguage();
  const nextPath = buildNextPath(ch);
  const href = `/entry/require-login?next=${encodeURIComponent(nextPath)}`;

  return (
    <Link
      href={href}
      className={`group overflow-hidden rounded-2xl border border-border bg-card text-card-foreground shadow-sm transition-all duration-700 ease-out ${
        visible ? "translate-y-0 opacity-100" : "translate-y-6 opacity-0"
      } hover:-translate-y-0.5 hover:bg-card/90`}
    >
      <div className="relative aspect-[4/5] w-full">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src={ch.ui.avatar ?? ""}
          alt={ch.name}
          className="absolute inset-0 h-full w-full object-cover opacity-95 transition-transform duration-300 group-hover:scale-[1.03]"
          loading="lazy"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-black/20" />
      </div>

      <div className="border-t border-border p-4">
        <div className="flex flex-wrap items-center gap-2">
          <Chip>{layerLabel(ch.layer, lang)}</Chip>
          <Chip>{ch.locationName}</Chip>
          <Chip>{t("entry.location.roleplayChip")}</Chip>
          {ch.promptVersion ? <Chip>{ch.promptVersion}</Chip> : null}
        </div>

        <div className="mt-3 text-lg font-semibold leading-tight">{ch.name}</div>
        <div className="mt-1 text-sm text-muted-foreground">{ch.title}</div>

        <div className="mt-3 text-xs leading-relaxed text-muted-foreground">{t("entry.location.cardHint")}</div>
      </div>
    </Link>
  );
}

function LayerSection({ layer }: { layer: EntryLayerGroup }) {
  const { t, lang } = useLanguage();
  const ref = useRef<HTMLDivElement | null>(null);
  const [visibleIndices, setVisibleIndices] = useState<number[]>([]);

  useEffect(() => {
    if (!ref.current) return;

    const threshold = window.innerWidth <= 767 ? 0.05 : window.innerWidth <= 1023 ? 0.1 : 0.3;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (!entry.isIntersecting) return;
        const total = layer.locations.flatMap((loc) => loc.characters).length;
        for (let i = 0; i < total; i += 1) {
          setTimeout(() => {
            setVisibleIndices((prev) => (prev.includes(i) ? prev : [...prev, i]));
          }, i * 300);
        }
        observer.disconnect();
      },
      { threshold },
    );

    observer.observe(ref.current);
    return () => observer.disconnect();
  }, [layer]);

  return (
    <section ref={ref} className="space-y-4">
      <div className="flex items-center gap-3">
        <div className="h-px flex-1 bg-border" />
        <div className="text-xs font-medium text-muted-foreground">{layerLabel(layer.layer, lang)}</div>
        <div className="h-px flex-1 bg-border" />
      </div>

      {layer.locations.length === 0 ? (
        <div className="rounded-2xl border border-border bg-card p-6 text-sm text-muted-foreground shadow-sm">
          {t("entry.location.emptyLayer")}
        </div>
      ) : (
        <div className="grid grid-cols-2 gap-2 sm:grid-cols-3 sm:gap-3 lg:grid-cols-4">
          {layer.locations
            .flatMap((loc) => loc.characters)
            .map((ch, index) => (
              <CharacterCard key={ch.id} ch={ch} visible={visibleIndices.includes(index)} />
            ))}
        </div>
      )}
    </section>
  );
}

export default function EntryLocationAccordion({ layers }: { layers: EntryLayerGroup[] }) {
  return (
    <div id="locations" className="mt-8 space-y-10">
      {layers.map((layer) => (
        <LayerSection key={layer.layer} layer={layer} />
      ))}
    </div>
  );
}
