// autocomplete.js - autocomplétion contextuelle de l'éditeur de requêtes, sans dépendance.
//
// Candidats tirés du schéma réel de la base (tables + colonnes, via engine.getSchema())
// et des mots-clés SQL / opérateurs d'algèbre. Contextuelle :
//   - SQL : après FROM/JOIN -> tables ; « alias. » ou « table. » -> colonnes de cette table ;
//           ailleurs -> colonnes puis tables puis mots-clés.
//   - Algèbre : après « / » -> attributs (+ ET/OU/NON) ; après « ( » ou « , » -> relations ;
//               début d'expression / après « := » -> opérateurs.
//
// La logique de suggestion (suggest, buildAliasMap) est PURE (pas de DOM) et testée par
// scripts/test-autocomplete.mjs. Le reste (popup, position du curseur) est du DOM.

const SQL_KEYWORDS = [
  "SELECT", "DISTINCT", "FROM", "WHERE", "GROUP", "BY", "HAVING", "ORDER", "ASC", "DESC",
  "AND", "OR", "NOT", "IN", "EXISTS", "IS", "NULL", "LIKE", "BETWEEN", "AS", "ON", "USING",
  "JOIN", "INNER", "LEFT", "RIGHT", "FULL", "OUTER", "CROSS", "NATURAL",
  "UNION", "INTERSECT", "EXCEPT", "ALL", "ANY", "CASE", "WHEN", "THEN", "ELSE", "END",
  "WITH", "RECURSIVE", "LIMIT", "OFFSET",
];
const SQL_FUNCTIONS = ["COUNT", "SUM", "AVG", "MIN", "MAX", "ROUND", "COALESCE",
  "UPPER", "LOWER", "LENGTH", "SUBSTR"];
const ALGEBRA_OPERATORS = [
  "SELECTION", "PROJECTION", "RENOMMAGE", "UNION", "INTERSECTION", "DIFFERENCE",
  "JOINTURE", "JOINTURE_NATURELLE", "DIVISION", "ET", "OU", "NON",
];

const IDENT = "[A-Za-z_\\u00C0-\\u024F][A-Za-z0-9_\\u00C0-\\u024F]*";
const TRAILING_WORD = new RegExp(IDENT + "$");
// FROM/JOIN font passer en « contexte tables » ; toute autre clause plus récente
// repasse en « contexte colonnes » (la virgule n'est pas un mot-clé, donc « FROM a, » reste tables).
const CLAUSE_KW = new RegExp(
  "\\b(SELECT|FROM|WHERE|JOIN|ON|GROUP|ORDER|HAVING|BY|AND|OR|NOT|IN|LIKE|BETWEEN|" +
  "SET|VALUES|UNION|EXCEPT|INTERSECT|AS|WITH|USING|CASE|WHEN|THEN|ELSE)\\b", "gi");

// ── Logique de suggestion (pure) ─────────────────────────────────────────────

export function buildAliasMap(sql) {
  const map = {};
  let m;
  const joinRe = new RegExp("\\bJOIN\\s+(" + IDENT + ")(?:\\s+(?:AS\\s+)?(" + IDENT + "))?", "gi");
  while ((m = joinRe.exec(sql)) !== null) map[(m[2] || m[1]).toLowerCase()] = m[1];
  const fromRe = new RegExp(
    "\\bFROM\\s+([\\s\\S]+?)(?=\\bWHERE\\b|\\bGROUP\\b|\\bORDER\\b|\\bHAVING\\b|\\bLIMIT\\b|" +
    "\\bUNION\\b|\\bEXCEPT\\b|\\bINTERSECT\\b|\\bJOIN\\b|\\bON\\b|$)", "gi");
  const itemRe = new RegExp("^\\s*(" + IDENT + ")(?:\\s+(?:AS\\s+)?(" + IDENT + "))?");
  while ((m = fromRe.exec(sql)) !== null) {
    for (const item of m[1].split(",")) {
      const tm = itemRe.exec(item.trim());
      if (tm) map[(tm[2] || tm[1]).toLowerCase()] = tm[1];
    }
  }
  return map;
}

function resolveTable(qualifier, sql, schema) {
  const map = buildAliasMap(sql);
  const q = qualifier.toLowerCase();
  const target = (map[q] || qualifier).toLowerCase();
  return (schema.tables || []).find((t) => t.toLowerCase() === target) || null;
}

function lastClauseKeyword(text) {
  let last = null, m;
  CLAUSE_KW.lastIndex = 0;
  while ((m = CLAUSE_KW.exec(text)) !== null) last = m[1].toUpperCase();
  return last;
}

// Relations et attributs proposés en MAJUSCULES (SQLite et le compilateur d'algèbre
// sont insensibles à la casse) ; les mots-clés/opérateurs sont déjà en majuscules.
const upTables = (schema) => (schema.tables || []).map((x) => ({ label: x.toUpperCase(), kind: "table" }));
const upCols = (list) => (list || []).map((x) => ({ label: x.toUpperCase(), kind: "col" }));

function sqlCandidates(textBefore, start, qualifier, schema) {
  const tables = upTables(schema);
  const cols = upCols(schema.allColumns);
  const kw = [...SQL_KEYWORDS, ...SQL_FUNCTIONS].map((x) => ({ label: x, kind: "kw" }));
  if (qualifier) {
    const table = resolveTable(qualifier, textBefore, schema);
    const list = table && schema.columns[table] ? schema.columns[table] : (schema.allColumns || []);
    return upCols(list);
  }
  const ctx = lastClauseKeyword(textBefore.slice(0, start));
  if (ctx === "FROM" || ctx === "JOIN") return [...tables, ...kw];
  return [...cols, ...tables, ...kw];
}

function algebraCandidates(textBefore, start, schema) {
  const tables = upTables(schema);
  const cols = upCols(schema.allColumns);
  const ops = ALGEBRA_OPERATORS.map((x) => ({ label: x, kind: "kw" }));
  const before = textBefore.slice(0, start);
  const trimmed = before.replace(/\s+$/, "");
  if (trimmed === "" || trimmed.endsWith(":=")) return ops;
  let j = start - 1;
  while (j >= 0 && /\s/.test(textBefore[j])) j--;
  const prev = j >= 0 ? textBefore[j] : "";
  if (prev === "/") return [...cols, { label: "ET", kind: "kw" }, { label: "OU", kind: "kw" }, { label: "NON", kind: "kw" }];
  if (prev === "(" || prev === ",") return [...tables, ...cols];
  return [...ops, ...tables, ...cols];
}

// Vrai si le curseur est dans une chaîne « non fermée » (échappement SQL '' géré).
function inString(text) {
  let inStr = false;
  for (let i = 0; i < text.length; i++) {
    if (text[i] !== "'") continue;
    if (inStr && text[i + 1] === "'") { i++; continue; } // '' échappé
    inStr = !inStr;
  }
  return inStr;
}

// Renvoie { start, word, items:[{label, kind}] } ; items filtrés par préfixe (casse ignorée).
export function suggest(mode, textBefore, schema, force = false) {
  if (inString(textBefore)) return { start: textBefore.length, word: "", items: [] };
  const wm = TRAILING_WORD.exec(textBefore);
  const word = wm ? wm[0] : "";
  const start = textBefore.length - word.length;
  let qualifier = null;
  if (start >= 1 && textBefore[start - 1] === ".") {
    const qm = TRAILING_WORD.exec(textBefore.slice(0, start - 1));
    if (qm) qualifier = qm[0];
  }
  if (!force && !qualifier && word.length < 1) return { start, word, items: [] };
  const raw = mode === "algebra"
    ? algebraCandidates(textBefore, start, schema)
    : sqlCandidates(textBefore, start, qualifier, schema);
  const w = word.toLowerCase();
  const seen = new Set();
  const items = [];
  for (const it of raw) {
    const low = it.label.toLowerCase();
    if (!low.startsWith(w)) continue;
    if (low === w && !qualifier) continue; // mot déjà tapé en entier : rien à ajouter
    if (seen.has(low)) continue;
    seen.add(low);
    items.push(it);
    if (items.length >= 40) break;
  }
  return { start, word, items };
}

// ── Popup (DOM) ──────────────────────────────────────────────────────────────

const KIND_LABEL = { table: "table", col: "colonne", kw: "mot-clé" };

// Coordonnées (px) du curseur dans le textarea, via un div-miroir.
function caretCoords(textarea, position) {
  const div = document.createElement("div");
  const s = getComputedStyle(textarea);
  const props = ["boxSizing", "width", "paddingTop", "paddingRight", "paddingBottom",
    "paddingLeft", "borderTopWidth", "borderRightWidth", "borderBottomWidth",
    "borderLeftWidth", "fontStyle", "fontVariant", "fontWeight", "fontStretch",
    "fontSize", "fontFamily", "lineHeight", "letterSpacing", "textAlign",
    "textTransform", "wordSpacing", "tabSize"];
  for (const p of props) div.style[p] = s[p];
  Object.assign(div.style, {
    position: "absolute", visibility: "hidden", whiteSpace: "pre-wrap",
    wordWrap: "break-word", overflow: "hidden", top: "0", left: "0",
  });
  div.textContent = textarea.value.slice(0, position);
  const span = document.createElement("span");
  span.textContent = textarea.value.slice(position) || ".";
  div.appendChild(span);
  document.body.appendChild(div);
  const top = span.offsetTop + (parseInt(s.borderTopWidth) || 0);
  const left = span.offsetLeft + (parseInt(s.borderLeftWidth) || 0);
  const height = parseInt(s.lineHeight) || Math.round((parseInt(s.fontSize) || 14) * 1.3);
  document.body.removeChild(div);
  return { top, left, height };
}

export function attachAutocomplete(textarea, opts) {
  const popup = document.createElement("ul");
  popup.className = "ac-popup";
  popup.style.display = "none";
  document.body.appendChild(popup);
  let items = [], active = -1, anchorStart = 0;

  const isOpen = () => popup.style.display !== "none";
  function close() { popup.style.display = "none"; items = []; active = -1; }

  function render() {
    popup.replaceChildren();
    items.forEach((it, i) => {
      const li = document.createElement("li");
      li.className = "ac-item" + (i === active ? " ac-active" : "");
      const label = document.createElement("span");
      label.className = "ac-label"; label.textContent = it.label;
      const kind = document.createElement("span");
      kind.className = "ac-kind ac-kind-" + it.kind; kind.textContent = KIND_LABEL[it.kind] || it.kind;
      li.append(label, kind);
      li.addEventListener("mousedown", (e) => { e.preventDefault(); accept(i); });
      popup.appendChild(li);
    });
    const cur = popup.children[active];
    if (cur) cur.scrollIntoView({ block: "nearest" });
  }

  function position() {
    const c = caretCoords(textarea, textarea.selectionStart);
    const r = textarea.getBoundingClientRect();
    popup.style.left = (window.scrollX + r.left + c.left - textarea.scrollLeft) + "px";
    popup.style.top = (window.scrollY + r.top + c.top - textarea.scrollTop + c.height) + "px";
  }

  function update(force = false) {
    if (textarea.selectionStart !== textarea.selectionEnd) return close();
    const pos = textarea.selectionStart;
    const res = suggest(opts.getMode(), textarea.value.slice(0, pos), opts.getSchema(), force);
    if (!res.items.length) return close();
    items = res.items; anchorStart = res.start; active = 0;
    render();
    popup.style.display = "block";
    position();
  }

  function accept(i) {
    if (i < 0 || i >= items.length) return;
    const pos = textarea.selectionStart;
    const insert = items[i].label;
    textarea.value = textarea.value.slice(0, anchorStart) + insert + textarea.value.slice(pos);
    textarea.selectionStart = textarea.selectionEnd = anchorStart + insert.length;
    close();
    textarea.focus();
    if (opts.onInsert) opts.onInsert();
  }

  function handleKeydown(e) {
    if (!isOpen()) {
      if ((e.ctrlKey || e.metaKey) && (e.key === " " || e.code === "Space")) {
        e.preventDefault(); update(true); return true;
      }
      return false;
    }
    switch (e.key) {
      case "ArrowDown": e.preventDefault(); active = (active + 1) % items.length; render(); return true;
      case "ArrowUp": e.preventDefault(); active = (active - 1 + items.length) % items.length; render(); return true;
      case "Enter":
        if (e.ctrlKey || e.metaKey) { close(); return false; } // Ctrl+Entrée : exécuter
        e.preventDefault(); accept(active); return true;
      case "Tab": e.preventDefault(); accept(active); return true;
      case "Escape": e.preventDefault(); close(); return true;
      default: return false;
    }
  }

  textarea.addEventListener("input", () => update(false));
  textarea.addEventListener("blur", () => setTimeout(close, 120));
  return { handleKeydown, update, close, isOpen };
}
