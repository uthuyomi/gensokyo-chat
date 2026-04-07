import { redirect } from "next/navigation";

import EntryPageContent from "@/components/entry/EntryPageContent";
import { getUser } from "@/lib/supabase-server";

export default async function HomePage() {
  const user = await getUser();
  if (user) redirect("/chat/session");
  return <EntryPageContent />;
}
