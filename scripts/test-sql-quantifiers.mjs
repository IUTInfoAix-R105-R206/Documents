// test-sql-quantifiers.mjs - prouve que le réécriveur ALL/ANY JS produit exactement
// la même sortie que son jumeau Python (scripts/sql_quantifiers.py).
//   node scripts/test-sql-quantifiers.mjs
import { rewriteQuantifiers } from "../templates/web-td/js/sql-quantifiers.js";
import { execFileSync } from "node:child_process";

const FIXTURES = [
  "SELECT cat FROM t WHERE n >= ALL(SELECT n FROM t)",
  "SELECT cat FROM t WHERE n > ALL (SELECT n FROM t)",
  "SELECT cat FROM t WHERE n <= ALL (SELECT n FROM t)",
  "SELECT cat FROM t WHERE n < ANY (SELECT n FROM t)",
  "SELECT cat FROM t WHERE n >= any (select n from t)",
  "SELECT x FROM t WHERE v = ANY (SELECT v FROM u WHERE k > 3)",
  "SELECT x FROM t WHERE v <> ALL (SELECT v FROM u)",
  "SELECT sal FROM emp WHERE sal >= ALL (SELECT e.sal FROM emp e WHERE e.dept = 3)",
  "SELECT p FROM r WHERE nb >= ALL (SELECT COUNT(*) AS nb FROM r GROUP BY p)",
  "SELECT a FROM t WHERE a > (SELECT 1)",                    // pas de quantificateur
  "SELECT a FROM t WHERE lbl = 'ALL ANY' AND a >= ALL (SELECT a FROM t)", // 'ALL' dans une chaîne
  "SELECT a FROM t WHERE x >= ALL (SELECT y FROM u WHERE z IN (SELECT w FROM v))", // sous-req imbriquée
];

const jsOut = FIXTURES.map(rewriteQuantifiers);
const pyOut = JSON.parse(execFileSync("python3", [
  "-c",
  "import sys,json; sys.path.insert(0,'scripts'); from sql_quantifiers import rewrite_quantifiers as r; print(json.dumps([r(x) for x in json.load(sys.stdin)]))",
], { input: JSON.stringify(FIXTURES), encoding: "utf-8" }));

let ok = 0, ko = 0;
FIXTURES.forEach((f, i) => {
  if (jsOut[i] === pyOut[i]) { ok++; }
  else {
    ko++;
    console.log(`✗ divergence fixture ${i}:\n  IN : ${f}\n  JS : ${jsOut[i]}\n  PY : ${pyOut[i]}`);
  }
});
console.log(`${ok}/${FIXTURES.length} OK - sortie JS == sortie Python`);
process.exit(ko === 0 ? 0 : 1);
