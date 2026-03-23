import type { SupabaseClient } from "@supabase/supabase-js";

import type { ClientMsg } from "../protocol/messages.js";

export async function authenticateHello(
  supabase: SupabaseClient,
  msg: ClientMsg & { type: "hello" },
): Promise<{ userId: string | null }> {
  const token = msg.auth?.access_token ? String(msg.auth.access_token) : "";
  if (!token) return { userId: null };
  try {
    const { data, error } = await supabase.auth.getUser(token);
    if (error) return { userId: null };
    return { userId: data.user?.id ? String(data.user.id) : null };
  } catch {
    return { userId: null };
  }
}
