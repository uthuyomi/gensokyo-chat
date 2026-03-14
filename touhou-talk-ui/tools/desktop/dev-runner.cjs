const { spawn } = require("node:child_process");
const fs = require("node:fs");
const http = require("node:http");
const os = require("node:os");
const path = require("node:path");

function clampPort(n, fallback) {
  const v = Number(n);
  if (!Number.isFinite(v) || v <= 0) return fallback;
  return Math.min(65535, Math.max(1024, Math.trunc(v)));
}

function defaultUserDataDir() {
  const base =
    String(process.env.LOCALAPPDATA ?? "").trim() ||
    String(process.env.APPDATA ?? "").trim() ||
    os.homedir();
  return path.join(base, "TouhouTalkDesktopDev");
}

function ensureEnvTemplate(envPath) {
  if (fs.existsSync(envPath)) return;
  const tpl = [
    "# Touhou Talk Desktop env (dev local only)",
    "",
    "# Supabase",
    "NEXT_PUBLIC_SUPABASE_URL=",
    "NEXT_PUBLIC_SUPABASE_ANON_KEY=",
    "SUPABASE_SERVICE_ROLE_KEY=",
    "",
    "# Backend Persona OS URL (FastAPI / sigmaris_core)",
    "SIGMARIS_CORE_URL=http://127.0.0.1:8000",
    "",
    "# Optional: force port",
    "TOUHOU_DESKTOP_PORT=3789",
    "",
  ].join("\n");
  fs.mkdirSync(path.dirname(envPath), { recursive: true });
  fs.writeFileSync(envPath, tpl, "utf8");
}

function waitForHttpOk(url, timeoutMs) {
  const startedAt = Date.now();
  return new Promise((resolve) => {
    const tick = () => {
      const req = http.get(url, (res) => {
        res.resume();
        resolve(res.statusCode && res.statusCode >= 200 && res.statusCode < 500);
      });
      req.on("error", () => {
        if (Date.now() - startedAt > timeoutMs) return resolve(false);
        setTimeout(tick, 300);
      });
      req.setTimeout(1500, () => req.destroy());
    };
    tick();
  });
}

function resolveElectronBin(projectRoot) {
  // `require("electron")` returns the platform-specific executable path when run in Node.
  try {
    const p = require("electron");
    if (typeof p === "string" && p.trim()) return p.trim();
  } catch {}

  // Fallback: npm .bin (may require `shell: true` on Windows in some setups)
  if (process.platform === "win32") return path.join(projectRoot, "node_modules", ".bin", "electron.cmd");
  return path.join(projectRoot, "node_modules", ".bin", "electron");
}

async function main() {
  const projectRoot = path.resolve(__dirname, "..", "..");
  const devScript = path.join(projectRoot, "tools", "dev.mjs");
  const electronMain = path.join(projectRoot, "tools", "desktop", "main.cjs");
  const electronBin = resolveElectronBin(projectRoot);

  const port = clampPort(process.env.TOUHOU_DESKTOP_DEV_PORT ?? process.env.PORT, 3000);
  const userDataDir = String(process.env.TOUHOU_DESKTOP_USERDATA_DIR ?? "").trim() || defaultUserDataDir();
  const envPath =
    String(process.env.TOUHOU_DESKTOP_ENV_PATH ?? "").trim() || path.join(userDataDir, "touhou-talk.env");

  fs.mkdirSync(userDataDir, { recursive: true });
  ensureEnvTemplate(envPath);

  const desktopEnv = {
    ...process.env,
    TOUHOU_DESKTOP_USERDATA_DIR: userDataDir,
    TOUHOU_DESKTOP_ENV_PATH: envPath,
    TOUHOU_DESKTOP_DEV_URL: `http://127.0.0.1:${port}`,
  };

  const nextProc = spawn(process.execPath, [devScript, "--port", String(port)], {
    cwd: projectRoot,
    env: desktopEnv,
    stdio: "inherit",
  });

  const cleanup = () => {
    try {
      if (!nextProc.killed) nextProc.kill();
    } catch {}
  };
  process.on("exit", cleanup);
  process.on("SIGINT", () => process.exit(130));
  process.on("SIGTERM", () => process.exit(143));

  nextProc.on("exit", (code) => {
    process.exit(code ?? 1);
  });

  const ok = await waitForHttpOk(`http://127.0.0.1:${port}/entry`, 30000);
  if (!ok) {
    console.error(`[desktop:dev] Next dev server did not respond on http://127.0.0.1:${port}`);
    process.exit(1);
  }

  const electronProc = spawn(electronBin, [electronMain], {
    cwd: projectRoot,
    env: desktopEnv,
    stdio: "inherit",
  });

  electronProc.on("exit", (code) => {
    try {
      if (!nextProc.killed) nextProc.kill();
    } catch {}
    process.exit(code ?? 0);
  });
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
