// verify-web-td.mjs - preuve que hash Python (générateur) == hash WASM (navigateur).
//
// Rejoue chaque variante de correction (output/web-verify/<td>/solutions.json) à
// travers les OCTETS LIVRÉS du moteur (output/web/<td>/vendor/sqljs/sql-wasm.wasm)
// et le canon.js LIVRÉ (output/web/<td>/js/canon.js), puis compare les hashes
// obtenus à ceux de questions.json. Vérifie aussi la parité des fixtures de
// canonicalisation. Code de sortie ≠ 0 en cas de divergence.
//
// Usage : node scripts/verify-web-td.mjs <site_dir> <verify_dir>

import { createRequire } from "module";
import { readFileSync } from "fs";
import { resolve } from "path";

const require = createRequire(import.meta.url);

const [, , siteDirArg, verifyDirArg] = process.argv;
if (!siteDirArg || !verifyDirArg) {
  console.error("Usage : node verify-web-td.mjs <site_dir> <verify_dir>");
  process.exit(2);
}
const siteDir = resolve(siteDirArg);
const verifyDir = resolve(verifyDirArg);

const RED = "\x1b[31m", GREEN = "\x1b[32m", DIM = "\x1b[2m", NC = "\x1b[0m";
function readJson(p) { return JSON.parse(readFileSync(p, "utf8")); }

// ── Charger le canon.js LIVRÉ (contrat partagé) ──────────────────────────────
const canon = await import(resolve(siteDir, "js/canon.js"));

// ── Charger le moteur sql.js LIVRÉ ───────────────────────────────────────────
const sqlWasmJs = resolve(siteDir, "vendor/sqljs/sql-wasm.js");
const sqlWasmBin = resolve(siteDir, "vendor/sqljs/sql-wasm.wasm");
const initSqlJs = require(sqlWasmJs);
const SQL = await initSqlJs({ locateFile: () => sqlWasmBin });

function registerFunctions(db) {
  db.create_function("TO_DATE", (value, fmt) => value);
}

// Base « maître » depuis les data LIVRÉES → snapshot réutilisé par requête.
const schema = readFileSync(resolve(siteDir, "data/schema.sql"), "utf8");
const insert = readFileSync(resolve(siteDir, "data/insert.sql"), "utf8");
const master = new SQL.Database();
registerFunctions(master);
master.run(schema);
if (insert.trim()) master.run(insert);
const snapshot = master.export();
master.close();

function runQuery(sql) {
  const db = new SQL.Database(snapshot);
  registerFunctions(db);
  try {
    let cols = [], rows = [];
    for (const stmt of db.iterateStatements(sql)) {
      cols = stmt.getColumnNames();
      rows = [];
      while (stmt.step()) rows.push(stmt.get());
    }
    return { cols, rows };
  } finally {
    db.close();
  }
}

// ── Données de référence ─────────────────────────────────────────────────────
const questions = readJson(resolve(siteDir, "questions.json"));
const { solutions } = readJson(resolve(verifyDir, "solutions.json"));
const fixtures = readJson(resolve(verifyDir, "canon-fixtures.json"));

const qById = new Map();
for (const s of questions.sections)
  for (const it of s.items)
    if (it.type === "question") qById.set(it.id, it);

let fails = 0;
let checks = 0;

// ── 1. Parité des fixtures de canonicalisation ───────────────────────────────
function decodeFixture(fx) {
  switch (fx.k) {
    case "null": return null;
    case "int": return fx.v;
    case "real": return fx.v;
    case "negzero": return -0;
    case "div": return fx.a / fx.b;
    case "text": return fx.v;
    default: throw new Error("fixture inconnue: " + fx.k);
  }
}

fixtures.cellFixtures.forEach((fx, i) => {
  checks++;
  const got = canon.canonCell(decodeFixture(fx));
  if (got !== fixtures.cells[i]) {
    fails++;
    console.log(`${RED}✗${NC} fixture cellule[${i}] ${JSON.stringify(fx)} py=${JSON.stringify(fixtures.cells[i])} js=${JSON.stringify(got)}`);
  }
});
for (let i = 0; i < fixtures.resultFixtures.length; i++) {
  checks++;
  const rf = fixtures.resultFixtures[i];
  const rows = rf.rows.map((row) => row.map(decodeFixture));
  const got = await canon.hashResult(rf.ncols, rows, rf.ordered);
  if (got !== fixtures.results[i]) {
    fails++;
    console.log(`${RED}✗${NC} fixture résultat[${i}] py=${fixtures.results[i].slice(0, 12)} js=${got.slice(0, 12)}`);
  }
}
console.log(`${DIM}Fixtures de canonicalisation : ${fixtures.cellFixtures.length} cellules + ${fixtures.resultFixtures.length} résultats${NC}`);

// ── 2. Rejeu de toutes les variantes de correction ───────────────────────────
for (const sol of solutions) {
  const q = qById.get(sol.id);
  if (!q) { fails++; console.log(`${RED}✗${NC} ${sol.id} absent de questions.json`); continue; }

  for (let v = 0; v < sol.variants.length; v++) {
    checks++;
    const sql = sol.variants[v];
    const res = runQuery(sql);
    const ncols = res.cols.length, nrows = res.rows.length;
    const sortedHash = await canon.hashResult(ncols, res.rows, false);
    const orderedHash = q.orderSensitive ? await canon.hashResult(ncols, res.rows, true) : null;

    const problems = [];
    if (ncols !== q.expectedCols) problems.push(`colonnes ${ncols}≠${q.expectedCols}`);
    if (nrows !== q.expectedRows) problems.push(`lignes ${nrows}≠${q.expectedRows}`);
    if (!q.hashesSorted.includes(sortedHash)) problems.push(`hash trié ${sortedHash.slice(0, 10)} absent`);
    if (q.orderSensitive && orderedHash !== q.hashOrdered) problems.push(`hash ordonné ${orderedHash.slice(0, 10)}≠${(q.hashOrdered || "").slice(0, 10)}`);

    const tag = sol.variants.length > 1 ? `${sol.id} v${v + 1}` : sol.id;
    if (problems.length) {
      fails++;
      console.log(`${RED}✗${NC} ${tag} - ${problems.join(", ")}`);
    } else {
      console.log(`${GREEN}✓${NC} ${tag} - ${ncols}c × ${nrows}r, hash ${sortedHash.slice(0, 10)}${q.orderSensitive ? " (ordonné vérifié)" : ""}`);
    }
  }
}

const nq = solutions.length;
console.log("");
if (fails === 0) {
  console.log(`${GREEN}${nq}/${nq} OK${NC} - ${checks} vérifications, hash Python == hash WASM pour toutes les variantes et fixtures.`);
  process.exit(0);
} else {
  console.log(`${RED}ÉCHEC${NC} - ${fails} divergence(s) sur ${checks} vérifications.`);
  process.exit(1);
}
