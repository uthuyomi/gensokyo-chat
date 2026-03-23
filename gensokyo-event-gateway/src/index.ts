import { loadEnv } from "./config/env.js";
import { createSupabaseAdmin } from "./infrastructure/supabase.js";
import { createHubRegistry } from "./subscriptions/registry.js";
import { startGatewayServer } from "./ws/server.js";

const env = loadEnv();
const supabase = createSupabaseAdmin(env);
const registry = createHubRegistry();

startGatewayServer({
  env,
  supabase,
  registry,
});
