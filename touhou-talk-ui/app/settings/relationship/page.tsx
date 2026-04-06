import { Suspense } from "react";
import { cookies } from "next/headers";

import { LANGUAGE_COOKIE, readLanguageCookieValue } from "@/lib/i18n";
import RelationshipSettingsClient from "./RelationshipSettingsClient";

export const dynamic = "force-dynamic";

export default async function RelationshipSettingsPage() {
  const cookieStore = await cookies();
  const lang = readLanguageCookieValue(cookieStore.get(LANGUAGE_COOKIE)?.value ?? undefined);

  return (
    <div className="mx-auto flex w-full max-w-3xl flex-col px-6 py-10">
      <Suspense fallback={<div className="text-muted-foreground text-sm">{lang === "ja" ? "読み込み中…" : "Loading…"}</div>}>
        <RelationshipSettingsClient />
      </Suspense>
    </div>
  );
}
