// verify-web-td-algebra.mjs - preuve que le compilateur+hash LIVRÉ reproduit les
// hashes de questions.json (chemin navigateur).
//
// Rejoue chaque bloc de référence (solutions.json) à travers le algebra.js +
// canon.js + sql.js LIVRÉS, et compare c/t + hashesSorted à questions.json.
//
// Usage : node scripts/verify-web-td-algebra.mjs <site_dir> <verify_dir>

import { createRequire } from "module";
import { readFileSync } from "fs";
import { resolve } from "path";

const require = createRequire(import.meta.url);
const [, , siteArg, verifyArg] = process.argv;
if (!siteArg || !verifyArg) {
  console.error("Usage : node verify-web-td-algebra.mjs <site_dir> <verify_dir>");
  process.exit(2);
}
const site = resolve(siteArg), verify = resolve(verifyArg);
const RED = "\x1b[31m", GREEN = "\x1b[32m", NC = "\x1b[0m";
const readJson = (p) => JSON.parse(readFileSync(p, "utf8"));

const { compileAlgebra } = await import(resolve(site, "js/algebra.js"));
const { hashResult } = await import(resolve(site, "js/canon.js"));
const initSqlJs = require(resolve(site, "vendor/sqljs/sql-wasm.js"));
const SQL = await initSqlJs({ locateFile: () => resolve(site, "vendor/sqljs/sql-wasm.wasm") });

function reg(db) { db.create_function("TO_DATE", (v, f) => v); }

const questions = readJson(resolve(site, "questions.json"));
const catalog = questions.database.catalog;
const master = new SQL.Database(); reg(master);
master.run(readFileSync(resolve(site, "data/schema.sql"), "utf8"));
const ins = readFileSync(resolve(site, "data/insert.sql"), "utf8");
if (ins.trim()) master.run(ins);
const snap = master.export(); master.close();

function runQuery(sql) {
  const db = new SQL.Database(snap); reg(db);
  try {
    let cols = [], rows = [];
    for (const stmt of db.iterateStatements(sql)) { cols = stmt.getColumnNames(); rows = []; while (stmt.step()) rows.push(stmt.get()); }
    return { cols, rows };
  } finally { db.close(); }
}

const qById = new Map();
for (const s of questions.sections) for (const it of s.items) if (it.type === "question") qById.set(it.id, it);
const { solutions } = readJson(resolve(verify, "solutions.json"));

let fails = 0, checks = 0;
for (const sol of solutions) {
  const q = qById.get(sol.id);
  if (!q) { fails++; console.log(`${RED}✗${NC} ${sol.id} absent de questions.json`); continue; }
  for (let v = 0; v < sol.blocks.length; v++) {
    checks++;
    const block = sol.blocks[v].text;
    try {
      const { sql } = compileAlgebra(block, catalog);
      const r = runQuery(sql);
      const ncols = r.cols.length, nrows = r.rows.length;
      const h = await hashResult(ncols, r.rows, false);
      const problems = [];
      if (ncols !== q.expectedCols) problems.push(`colonnes ${ncols}≠${q.expectedCols}`);
      if (nrows !== q.expectedRows) problems.push(`lignes ${nrows}≠${q.expectedRows}`);
      if (!q.hashesSorted.includes(h)) problems.push(`hash ${h.slice(0, 10)} absent`);
      const tag = sol.blocks.length > 1 ? `${sol.id} v${v + 1}` : sol.id;
      if (problems.length) { fails++; console.log(`${RED}✗${NC} ${tag} - ${problems.join(", ")}`); }
      else console.log(`${GREEN}✓${NC} ${tag} - ${ncols}c × ${nrows}r, hash ${h.slice(0, 10)}`);
    } catch (e) {
      fails++; console.log(`${RED}✗${NC} ${sol.id} v${v + 1} - compile/exec: ${e.message || e}`);
    }
  }
}

const nq = solutions.length;
console.log("");
if (fails === 0) {
  console.log(`${GREEN}${nq}/${nq} OK${NC} - ${checks} vérifications, compilateur+hash LIVRÉ == questions.json.`);
  process.exit(0);
} else {
  console.log(`${RED}ÉCHEC${NC} - ${fails} divergence(s) sur ${checks} vérifications.`);
  process.exit(1);
}
