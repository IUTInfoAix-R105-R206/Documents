// algebra-run.mjs - helper Node du générateur d'algèbre.
//
// Lit un job JSON sur stdin, construit une base SQLite (sql.js) depuis le schéma
// et les données fournis, puis pour chaque bloc d'algèbre : compile via algebra.js,
// exécute, et calcule le hash canonique via canon.js. Renvoie un JSON sur stdout.
//
// algebra.js + canon.js + sql.js sont chargés depuis --web-root (défaut :
// templates/web-td) - mêmes fichiers qu'au navigateur.
//
// Job (stdin) : { schema, insert, questions: [ { id, blocks: [algebraText,...] } ] }
// Sortie (stdout) : { catalog, results: [ { id, blocks: [ {ncols,nrows,hashSorted,error?} ] } ] }

import { createRequire } from "module";
import { readFileSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";

const require = createRequire(import.meta.url);
const here = dirname(fileURLToPath(import.meta.url));

function argVal(name, def) {
  const i = process.argv.indexOf(name);
  return i >= 0 && i + 1 < process.argv.length ? process.argv[i + 1] : def;
}
const webRoot = resolve(argVal("--web-root", resolve(here, "..", "templates", "web-td")));

const { compileAlgebra, AlgebraError } = await import(resolve(webRoot, "js/algebra.js"));
const { hashResult } = await import(resolve(webRoot, "js/canon.js"));
const initSqlJs = require(resolve(webRoot, "vendor/sqljs/sql-wasm.js"));
const SQL = await initSqlJs({ locateFile: () => resolve(webRoot, "vendor/sqljs/sql-wasm.wasm") });

function registerFunctions(db) { db.create_function("TO_DATE", (v, f) => v); }

// ── Lire le job stdin ────────────────────────────────────────────────────────
const chunks = [];
for await (const c of process.stdin) chunks.push(c);
const job = JSON.parse(Buffer.concat(chunks).toString("utf8"));

// ── Construire la base maître + snapshot ─────────────────────────────────────
const master = new SQL.Database();
registerFunctions(master);
master.run(job.schema);
if ((job.insert || "").trim()) master.run(job.insert);
const snapshot = master.export();

// Catalog { Table: [colonnes...] } via PRAGMA table_info
const catalog = {};
{
  const names = [];
  const st = master.prepare("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
  while (st.step()) names.push(st.getAsObject().name);
  st.free();
  for (const t of names) {
    const cols = [];
    const s2 = master.prepare(`PRAGMA table_info(${JSON.stringify(t)})`);
    while (s2.step()) cols.push(s2.getAsObject().name);
    s2.free();
    catalog[t] = cols;
  }
}
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
  } finally { db.close(); }
}

// ── Compiler + exécuter + hasher chaque bloc ─────────────────────────────────
const results = [];
for (const q of job.questions) {
  const blocks = [];
  for (const text of q.blocks) {
    try {
      const { sql } = compileAlgebra(text, catalog);
      const r = runQuery(sql);
      const ncols = r.cols.length, nrows = r.rows.length;
      const hashSorted = await hashResult(ncols, r.rows, false);
      // Garde de déterminisme : le hash trié ne doit pas dépendre de l'ordre d'insertion.
      const d = new SQL.Database(snapshot);
      registerFunctions(d);
      d.run("PRAGMA reverse_unordered_selects=ON");
      let rows2 = [];
      for (const stmt of d.iterateStatements(sql)) { rows2 = []; while (stmt.step()) rows2.push(stmt.get()); }
      d.close();
      const hash2 = await hashResult(ncols, rows2, false);
      const stable = hash2 === hashSorted;
      blocks.push({ ncols, nrows, hashSorted, stable });
    } catch (e) {
      blocks.push({ error: String(e && e.message || e), kind: e instanceof AlgebraError ? "algebra" : "sql" });
    }
  }
  results.push({ id: q.id, blocks });
}

process.stdout.write(JSON.stringify({ catalog, results }));
