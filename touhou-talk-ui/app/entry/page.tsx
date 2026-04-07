import { redirect } from "next/navigation";

import EntryPageContent from "@/components/entry/EntryPageContent";
import { getUser } from "@/lib/supabase-server";

export default async function EntryPage(props: {
  searchParams?: Promise<Record<string, string | string[] | undefined>>;
}) {
  const searchParams = (await props.searchParams) ?? {};
  const from = Array.isArray(searchParams.from)
    ? searchParams.from[0]
    : searchParams.from;

  if (from !== "chat") {
    const user = await getUser();
    if (user) redirect("/chat/session");
  }

  return <EntryPageContent showHeader />;
}
