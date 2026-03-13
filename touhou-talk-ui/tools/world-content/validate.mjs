import fs from "node:fs";
import path from "node:path";

function fail(msg) {
  console.error(`[world-content] ERROR: ${msg}`);
  process.exitCode = 1;
}

function readJson(filePath) {
  const raw = fs.readFileSync(filePath, "utf8");
  return JSON.parse(raw);
}

function isNonEmptyString(x) {
  return typeof x === "string" && x.trim().length > 0;
}

function validateLocations(root) {
  const p = path.join(root, "locations.json");
  if (!fs.existsSync(p)) {
    fail(`missing locations.json at ${p}`);
    return { locationIds: new Set(), subLocationIds: new Set() };
  }
  const data = readJson(p);
  const locations = Array.isArray(data.locations) ? data.locations : [];
  const subLocations = Array.isArray(data.sub_locations) ? data.sub_locations : [];

  const ids = new Set();
  for (const loc of locations) {
    if (!loc || typeof loc !== "object") continue;
    if (!isNonEmptyString(loc.id)) fail(`location.id missing: ${JSON.stringify(loc)}`);
    if (ids.has(loc.id)) fail(`duplicate location id: ${loc.id}`);
    ids.add(loc.id);
  }

  for (const loc of locations) {
    if (!loc || typeof loc !== "object") continue;
    const neighbors = Array.isArray(loc.neighbors) ? loc.neighbors : [];
    for (const n of neighbors) {
      if (isNonEmptyString(n) && !ids.has(n)) fail(`location ${loc.id} has unknown neighbor: ${n}`);
    }
    const subs = Array.isArray(loc.sub_locations) ? loc.sub_locations : [];
    for (const s of subs) {
      if (!isNonEmptyString(s)) fail(`location ${loc.id} has invalid sub_location id`);
    }
  }

  const subIds = new Set();
  for (const s of subLocations) {
    if (!s || typeof s !== "object") continue;
    if (!isNonEmptyString(s.id)) fail(`sub_location.id missing: ${JSON.stringify(s)}`);
    if (subIds.has(s.id)) fail(`duplicate sub_location id: ${s.id}`);
    subIds.add(s.id);
    if (!isNonEmptyString(s.parent) || !ids.has(s.parent)) fail(`sub_location ${s.id} has unknown parent: ${s.parent}`);
  }

  return { locationIds: ids, subLocationIds: subIds };
}

function validateCharacters(root, locationIds) {
  const p = path.join(root, "characters.json");
  if (!fs.existsSync(p)) {
    fail(`missing characters.json at ${p}`);
    return new Set();
  }
  const data = readJson(p);
  const chars = Array.isArray(data.characters) ? data.characters : [];
  const ids = new Set();
  for (const c of chars) {
    if (!c || typeof c !== "object") continue;
    if (!isNonEmptyString(c.id)) fail(`character.id missing: ${JSON.stringify(c)}`);
    if (ids.has(c.id)) fail(`duplicate character id: ${c.id}`);
    ids.add(c.id);
    if (isNonEmptyString(c.home_location_id) && !locationIds.has(c.home_location_id)) {
      fail(`character ${c.id} has unknown home_location_id: ${c.home_location_id}`);
    }
  }
  return ids;
}

function validateEvents(root, locationIds, characterIds) {
  const dir = path.join(root, "event_defs");
  if (!fs.existsSync(dir) || !fs.statSync(dir).isDirectory()) {
    fail(`missing event_defs directory at ${dir}`);
    return;
  }
  const files = fs.readdirSync(dir).filter((f) => f.endsWith(".json"));
  const seen = new Set();
  for (const f of files) {
    const p = path.join(dir, f);
    const d = readJson(p);
    if (!d || typeof d !== "object") {
      fail(`invalid json: ${p}`);
      continue;
    }
    if (!isNonEmptyString(d.id)) fail(`event id missing: ${p}`);
    if (seen.has(d.id)) fail(`duplicate event id: ${d.id}`);
    seen.add(d.id);
    const loc = typeof d.location_id === "string" ? d.location_id : "";
    if (loc && !locationIds.has(loc)) fail(`event ${d.id} has unknown location_id: ${loc}`);

    const parts = d.participants && typeof d.participants === "object" ? d.participants : {};
    const req = Array.isArray(parts.required) ? parts.required : [];
    for (const id of req) {
      if (isNonEmptyString(id) && !characterIds.has(id)) {
        fail(`event ${d.id} requires unknown character: ${id}`);
      }
    }
    const payload = d.payload && typeof d.payload === "object" ? d.payload : {};
    if (!isNonEmptyString(payload.summary)) fail(`event ${d.id} missing payload.summary`);
  }
}

const ROOT = path.resolve(process.cwd(), "world", "layers", "gensokyo");
console.log(`[world-content] validate: ${ROOT}`);

const { locationIds } = validateLocations(ROOT);
const characterIds = validateCharacters(ROOT, locationIds);
validateEvents(ROOT, locationIds, characterIds);

if (!process.exitCode) {
  console.log("[world-content] OK");
}

