#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

function usage() {
  process.stderr.write(
    [
      "Usage:",
      "  node tools/env/prune-dotenv.mjs --dotenv .env --keep-file keep.txt --write",
      "",
      "Notes:",
      "- Does NOT print secret values.",
      "- Creates a timestamped backup next to the dotenv file when --write is set.",
    ].join("\n") + "\n",
  );
  process.exit(2);
}

function parseArgs(argv) {
  const args = { dotenv: ".env", keepFile: null, write: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--dotenv") args.dotenv = argv[++i];
    else if (a === "--keep-file") args.keepFile = argv[++i];
    else if (a === "--write") args.write = true;
    else if (a === "--help" || a === "-h") usage();
  }
  if (!args.keepFile) usage();
  return args;
}

function readKeepList(filePath) {
  const txt = fs.readFileSync(filePath, "utf8");
  const keep = new Set();
  for (const raw of txt.split(/\r?\n/g)) {
    const s = raw.trim();
    if (!s || s.startsWith("#")) continue;
    if (/^[A-Z0-9_]+$/.test(s)) keep.add(s);
  }
  return keep;
}

function isAssignment(line) {
  const trimmed = line.trim();
  if (!trimmed || trimmed.startsWith("#")) return null;
  const m = /^([A-Z0-9_]+)\s*=/.exec(trimmed);
  return m?.[1] || null;
}

function main() {
  const { dotenv, keepFile, write } = parseArgs(process.argv.slice(2));
  const dotenvPath = path.resolve(dotenv);
  const keepPath = path.resolve(keepFile);

  const keep = readKeepList(keepPath);
  const src = fs.readFileSync(dotenvPath, "utf8");
  const lines = src.split(/\r?\n/g);

  let kept = 0;
  let removed = 0;
  const out = [];

  for (const line of lines) {
    const key = isAssignment(line);
    if (!key) {
      out.push(line);
      continue;
    }
    if (keep.has(key)) {
      out.push(line);
      kept++;
    } else {
      removed++;
    }
  }

  const outText = out.join("\n");
  const stats = { kept, removed, keepCount: keep.size };

  if (write) {
    const stamp = new Date().toISOString().replace(/[:.]/g, "-");
    const backup = `${dotenvPath}.bak.${stamp}`;
    fs.copyFileSync(dotenvPath, backup);
    fs.writeFileSync(dotenvPath, outText, "utf8");
    process.stdout.write(
      `pruned ${dotenvPath}\nkept=${kept} removed=${removed} keepList=${keep.size}\nbackup=${backup}\n`,
    );
    return;
  }

  process.stdout.write(
    `dry-run ${dotenvPath}\nkept=${kept} removed=${removed} keepList=${keep.size}\n` +
      "Use --write to apply (creates a backup).\n",
  );
}

main();

