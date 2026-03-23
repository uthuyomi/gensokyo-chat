export type GatewayEnv = {
  supabaseUrl: string;
  supabaseServiceRoleKey: string;
  supabaseSchema: string;
  host: string;
  port: number;
  allowAnon: boolean;
};

function required(name: string): string {
  const value = String(process.env[name] || "").trim();
  if (!value) {
    throw new Error(`[event-gateway] ${name} missing`);
  }
  return value;
}

export function loadEnv(): GatewayEnv {
  return {
    supabaseUrl: required("SUPABASE_URL"),
    supabaseServiceRoleKey: required("SUPABASE_SERVICE_ROLE_KEY"),
    supabaseSchema: String(process.env.SUPABASE_SCHEMA || "public").trim() || "public",
    host: String(process.env.GENSOKYO_EVENT_GATEWAY_HOST || "127.0.0.1").trim() || "127.0.0.1",
    port: Number(process.env.GENSOKYO_EVENT_GATEWAY_PORT || "8787"),
    allowAnon: String(process.env.GENSOKYO_EVENT_GATEWAY_ALLOW_ANON || "1").trim() === "1",
  };
}
