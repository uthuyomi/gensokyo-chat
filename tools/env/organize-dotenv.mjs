#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

function usage() {
  process.stderr.write(
    [
      "Usage:",
      "  node tools/env/organize-dotenv.mjs --audit .git/env_audit.json --dotenv .env --write",
      "",
      "Notes:",
      "- Rewrites dotenv by scope and drops unused assignments.",
      "- Does NOT print secret values.",
      "- Creates a timestamped backup next to the dotenv file when --write is set.",
    ].join("\n") + "\n",
  );
  process.exit(2);
}

function parseArgs(argv) {
  const args = { audit: null, dotenv: ".env", write: false, out: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--audit") args.audit = argv[++i];
    else if (a === "--dotenv") args.dotenv = argv[++i];
    else if (a === "--out") args.out = argv[++i];
    else if (a === "--write") args.write = true;
    else if (a === "--help" || a === "-h") usage();
  }
  if (!args.audit) usage();
  if (args.write && args.out) usage();
  return args;
}

function isAssignment(line) {
  const trimmed = line.trim();
  if (!trimmed || trimmed.startsWith("#")) return null;
  const m = /^([A-Z0-9_]+)\s*=/.exec(trimmed);
  return m?.[1] || null;
}

function main() {
  const { audit, dotenv, write, out } = parseArgs(process.argv.slice(2));
  const auditPath = path.resolve(audit);
  const dotenvPath = path.resolve(dotenv);

  let auditText = fs.readFileSync(auditPath, "utf8");
  // Strip UTF-8 BOM if present (PowerShell Out-File may add it)
  if (auditText.charCodeAt(0) === 0xfeff) auditText = auditText.slice(1);
  const a = JSON.parse(auditText);
  const dotenvKeys = new Set(a.dotenv?.keys || []);
  const unused = new Set(a.inEnvButUnused || []);
  const usedByScope = a.usedByScope || {};

  const keep = new Set(Array.from(dotenvKeys).filter((k) => !unused.has(k)));

  const src = fs.readFileSync(dotenvPath, "utf8");
  const lines = src.split(/\r?\n/g);

  const preamble = [];
  const kv = new Map(); // key -> raw line (keep last)
  let seenFirstAssign = false;

  for (const line of lines) {
    const k = isAssignment(line);
    if (!seenFirstAssign) {
      if (!k) {
        preamble.push(line);
        continue;
      }
      seenFirstAssign = true;
    }
    if (!k) continue;
    if (!keep.has(k)) continue;
    kv.set(k, line);
  }

  const scopeOrder = ["shared", "gensokyo-persona-core", "touhou-talk-ui", "other"];
  const groups = new Map(scopeOrder.map((s) => [s, []]));

  function addToGroup(group, key) {
    groups.get(group).push(key);
  }

  const coreSet = new Set(usedByScope["gensokyo-persona-core"] || []);
  const uiSet = new Set(usedByScope["touhou-talk-ui"] || []);
  const otherSets = new Set();
  for (const [scope, keys] of Object.entries(usedByScope)) {
    if (scope === "gensokyo-persona-core" || scope === "touhou-talk-ui") continue;
    for (const k of keys || []) otherSets.add(k);
  }

  const keys = Array.from(kv.keys()).sort();
  for (const k of keys) {
    const inCore = coreSet.has(k);
    const inUi = uiSet.has(k);
    if (inCore && inUi) addToGroup("shared", k);
    else if (inCore) addToGroup("gensokyo-persona-core", k);
    else if (inUi) addToGroup("touhou-talk-ui", k);
    else if (otherSets.has(k)) addToGroup("other", k);
    else addToGroup("other", k);
  }

  const outLines = [];
  // Keep preamble but trim trailing empty lines to avoid huge gaps
  while (preamble.length && preamble[preamble.length - 1].trim() === "") preamble.pop();
  outLines.push(...preamble);
  if (outLines.length) outLines.push("");

  const headers = {
    shared: "# [shared] used by both gensokyo-persona-core and touhou-talk-ui",
    "gensokyo-persona-core": "# [gensokyo-persona-core] backend",
    "touhou-talk-ui": "# [touhou-talk-ui] frontend/desktop wrapper",
    other: "# [other] tools / workflows / misc",
  };

  for (const scope of scopeOrder) {
    const list = groups.get(scope) || [];
    if (!list.length) continue;
    outLines.push(headers[scope]);
    for (const k of list) outLines.push(kv.get(k));
    outLines.push("");
  }
  while (outLines.length && outLines[outLines.length - 1].trim() === "") outLines.pop();
  outLines.push("");

  const outText = outLines.join("\n");
  const kept = kv.size;
  const removed = Array.from(dotenvKeys).filter((k) => unused.has(k)).length;

  if (write) {
    const stamp = new Date().toISOString().replace(/[:.]/g, "-");
    const backup = `${dotenvPath}.bak.${stamp}`;
    fs.copyFileSync(dotenvPath, backup);
    fs.writeFileSync(dotenvPath, outText, "utf8");
    process.stdout.write(`organized ${dotenvPath}\nkept=${kept} removed=${removed}\nbackup=${backup}\n`);
    return;
  }

  if (out) {
    fs.writeFileSync(path.resolve(out), outText, "utf8");
    process.stdout.write(`wrote ${path.resolve(out)}\nkept=${kept} removed=${removed}\n`);
    return;
  }

  process.stdout.write(`dry-run ${dotenvPath}\nkept=${kept} removed=${removed}\nUse --write or --out.\n`);
}

main();
