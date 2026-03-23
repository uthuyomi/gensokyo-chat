import { createClient, type SupabaseClient } from "@supabase/supabase-js";

import type { GatewayEnv } from "../config/env.js";

export function createSupabaseAdmin(env: GatewayEnv): SupabaseClient {
  return createClient(env.supabaseUrl, env.supabaseServiceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    global: {
      headers: {
        "Accept-Profile": env.supabaseSchema,
        "Content-Profile": env.supabaseSchema,
      },
    },
  });
}
