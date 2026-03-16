#!/usr/bin/env node
import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

function repoRoot() {
  return execSync("git rev-parse --show-toplevel", { encoding: "utf8" }).trim();
}

function gitFiles(rootDir) {
  const out = execSync("git ls-files", { encoding: "utf8", cwd: rootDir });
  return out
    .split(/\r?\n/g)
    .map((s) => s.trim())
    .filter(Boolean);
}

function classifyScope(filePath) {
  const p = filePath.replace(/\\/g, "/");
  if (p.startsWith("gensokyo-persona-core/")) return "gensokyo-persona-core";
  if (p.startsWith("gensokyo-world-engine/")) return "gensokyo-world-engine";
  if (p.startsWith("gensokyo-event-gateway/")) return "gensokyo-event-gateway";
  if (p.startsWith("touhou-talk-ui/")) return "touhou-talk-ui";
  if (p.startsWith("tools/")) return "tools";
  if (p.startsWith("supabase/")) return "supabase";
  if (p.startsWith(".github/")) return ".github";
  return "root";
}

function isTexty(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  return [
    ".js",
    ".cjs",
    ".mjs",
    ".ts",
    ".tsx",
    ".py",
    ".md",
    ".yml",
    ".yaml",
    ".toml",
    ".json",
    ".sql",
    ".txt",
    ".env",
    ".example",
  ].includes(ext);
}

function safeReadText(absPath, maxBytes = 1024 * 1024) {
  try {
    const st = fs.statSync(absPath);
    if (!st.isFile()) return null;
    if (st.size > maxBytes) return null;
    return fs.readFileSync(absPath, "utf8");
  } catch {
    return null;
  }
}

function extractEnvKeys(text) {
  const keys = new Set();
  const patterns = [
    /process\.env\.([A-Z0-9_]+)/g,
    /process\.env\[['"]([A-Z0-9_]+)['"]\]/g,
    /os\.getenv\(\s*['"]([A-Z0-9_]+)['"]/g,
    /os\.environ\.get\(\s*['"]([A-Z0-9_]+)['"]/g,
    /os\.environ\[['"]([A-Z0-9_]+)['"]\]/g,
    /Deno\.env\.get\(\s*['"]([A-Z0-9_]+)['"]/g,
    // Common helper wrappers in this repo
    /_env_flag\(\s*['"]([A-Z0-9_]+)['"]/g,
    /\b_env\(\s*['"]([A-Z0-9_]+)['"]/g,
    /\benv\(\s*['"]([A-Z0-9_]+)['"]/g,
    /\b_bool_env\(\s*['"]([A-Z0-9_]+)['"]/g,
    /\bbool_env\(\s*['"]([A-Z0-9_]+)['"]/g,
  ];
  for (const re of patterns) {
    for (const m of text.matchAll(re)) {
      const k = String(m[1] || "").trim();
      if (k) keys.add(k);
    }
  }
  return keys;
}

function parseDotenvKeys(dotenvText) {
  const keys = new Set();
  for (const raw of dotenvText.split(/\r?\n/g)) {
    const line = raw.trim();
    if (!line || line.startsWith("#")) continue;
    const m = /^([A-Z0-9_]+)\s*=/.exec(line);
    if (m?.[1]) keys.add(m[1]);
  }
  return keys;
}

function formatList(items) {
  return items.length ? items.map((s) => `- ${s}`).join("\n") : "- (none)";
}

function main() {
  const root = repoRoot();
  const argv = process.argv.slice(2);
  const dotenvRel = argv.includes("--dotenv")
    ? argv[argv.indexOf("--dotenv") + 1]
    : ".env";
  const jsonOut = argv.includes("--json");

  const dotenvAbs = path.join(root, dotenvRel);
  const dotenvText = fs.existsSync(dotenvAbs) ? safeReadText(dotenvAbs, 5 * 1024 * 1024) : null;
  const dotenvKeys = dotenvText ? parseDotenvKeys(dotenvText) : new Set();

  const usedByScope = new Map(); // scope -> Set(keys)
  const keyToFiles = new Map(); // key -> Set(sample files)

  for (const rel of gitFiles(root)) {
    if (!isTexty(rel)) continue;
    // Avoid scanning vendored build outputs if they are tracked (rare, but just in case)
    if (rel.includes("/.next/") || rel.includes("/dist-") || rel.includes("/node_modules/")) continue;
    const abs = path.join(root, rel);
    const txt = safeReadText(abs);
    if (!txt) continue;
    const keys = extractEnvKeys(txt);
    if (!keys.size) continue;
    const scope = classifyScope(rel);
    if (!usedByScope.has(scope)) usedByScope.set(scope, new Set());
    for (const k of keys) {
      usedByScope.get(scope).add(k);
      if (!keyToFiles.has(k)) keyToFiles.set(k, new Set());
      const set = keyToFiles.get(k);
      if (set.size < 5) set.add(rel);
    }
  }

  const usedKeys = new Set();
  for (const set of usedByScope.values()) for (const k of set) usedKeys.add(k);

  const scopes = Array.from(usedByScope.keys()).sort();
  const dotenvKeyList = Array.from(dotenvKeys).sort();
  const usedKeyList = Array.from(usedKeys).sort();

  const inEnvButUnused = dotenvKeyList.filter((k) => !usedKeys.has(k));
  const usedButMissing = usedKeyList.filter((k) => !dotenvKeys.has(k));

  const usedInTouhou = new Set(usedByScope.get("touhou-talk-ui") || []);
  const usedInCore = new Set(usedByScope.get("gensokyo-persona-core") || []);
  const usedInBoth = usedKeyList.filter((k) => usedInTouhou.has(k) && usedInCore.has(k));

  const result = {
    dotenv: { path: dotenvRel, keys: dotenvKeyList },
    usedKeys: usedKeyList,
    usedByScope: Object.fromEntries(
      scopes.map((s) => [s, Array.from(usedByScope.get(s) || []).sort()]),
    ),
    inEnvButUnused,
    usedButMissing,
    usedInBoth,
    samples: Object.fromEntries(
      Array.from(keyToFiles.entries())
        .sort((a, b) => a[0].localeCompare(b[0]))
        .map(([k, v]) => [k, Array.from(v.values())]),
    ),
  };

  if (jsonOut) {
    process.stdout.write(JSON.stringify(result, null, 2));
    return;
  }

  const header = [];
  header.push(`# Env audit`);
  header.push(``);
  header.push(`- dotenv file: \`${dotenvRel}\``);
  header.push(`- keys in dotenv: ${dotenvKeyList.length}`);
  header.push(`- keys referenced in repo: ${usedKeyList.length}`);
  header.push(``);

  const sections = [];
  sections.push(`## Unused (present in dotenv but not referenced)\n${formatList(inEnvButUnused)}`);
  sections.push(``);
  sections.push(`## Missing (referenced but not present in dotenv)\n${formatList(usedButMissing)}`);
  sections.push(``);
  sections.push(`## Used by scope`);
  for (const s of scopes) {
    const list = Array.from(usedByScope.get(s) || []).sort();
    sections.push(`### ${s}\n${formatList(list)}`);
    sections.push(``);
  }
  sections.push(`## Used in both (core + touhou-talk-ui)\n${formatList(usedInBoth)}`);
  sections.push(``);

  process.stdout.write([...header, ...sections].join("\n"));
}

main();
