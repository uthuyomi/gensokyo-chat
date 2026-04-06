import DbManagerConsole from "@/components/world/DbManagerConsole";

export const dynamic = "force-dynamic";

export default function DbManagerPage() {
  return <DbManagerConsole worldId="gensokyo_main" />;
}
