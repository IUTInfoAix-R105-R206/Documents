// test-autocomplete.mjs - teste la logique de suggestion contextuelle (pure, sans DOM).
//   node scripts/test-autocomplete.mjs
import { suggest, buildAliasMap, algebraAcceptSuffix } from "../templates/web-td/js/autocomplete.js";

const SCHEMA = {
  tables: ["Client", "Voyage", "Reservation"],
  columns: {
    Client: ["numCl", "nom", "ville"],
    Voyage: ["idV", "dateDep", "villeArr"],
    Reservation: ["numCl", "idV", "dateRes"],
  },
  allColumns: ["numCl", "nom", "ville", "idV", "dateDep", "villeArr", "dateRes"],
};

let pass = 0, fail = 0;
const labels = (r) => r.items.map((i) => i.label);
function check(name, cond) {
  if (cond) { pass++; } else { fail++; console.log(`  ✗ ${name}`); }
}

// ── SQL : contexte tables après FROM/JOIN (relations en MAJUSCULES) ──
let r = suggest("sql", "SELECT nom FROM Cl", SCHEMA);
check("FROM Cl -> CLIENT", labels(r).includes("CLIENT") && r.word === "Cl" && r.items[0].kind === "table");

r = suggest("sql", "SELECT * FROM Voyage JOIN Re", SCHEMA);
check("JOIN Re -> RESERVATION", labels(r)[0] === "RESERVATION");

// ── SQL : contexte colonnes ailleurs (attributs en MAJUSCULES) ──
r = suggest("sql", "SELECT n", SCHEMA);
check("SELECT n -> colonnes NOM/NUMCL", labels(r).includes("NOM") && labels(r).includes("NUMCL")
  && r.items[0].kind === "col");

// ── SQL : qualificateur alias. -> colonnes de la table ──
r = suggest("sql", "SELECT * FROM Voyage v WHERE v.", SCHEMA);
check("v. (alias Voyage) -> colonnes Voyage", JSON.stringify(labels(r)) === JSON.stringify(["IDV", "DATEDEP", "VILLEARR"]));

r = suggest("sql", "SELECT * FROM Voyage v, Reservation r WHERE r.i", SCHEMA);
check("r.i (alias Reservation) -> IDV", JSON.stringify(labels(r)) === JSON.stringify(["IDV"]));

r = suggest("sql", "SELECT ville FROM Client.", SCHEMA);
check("Client. (table réelle) -> colonnes Client", JSON.stringify(labels(r)) === JSON.stringify(["NUMCL", "NOM", "VILLE"]));

// ── Pas de complétion dans une chaîne non fermée ──
check("dans une chaîne -> aucune complétion", suggest("sql", "WHERE ville = 'MAR", SCHEMA, true).items.length === 0);
check("chaîne fermée -> complétion normale", suggest("sql", "WHERE ville = 'MAR' AND n", SCHEMA).items.length > 0);

// ── SQL : mot vide sans force -> rien ; avec force -> propositions ──
check("SELECT (espace) sans force -> vide", suggest("sql", "SELECT ", SCHEMA).items.length === 0);
check("SELECT (espace) avec force -> non vide", suggest("sql", "SELECT ", SCHEMA, true).items.length > 0);

// ── buildAliasMap ──
let m = buildAliasMap("SELECT * FROM Voyage V, Planning P WHERE V.idV = P.idV");
check("aliasMap virgule", m.v === "Voyage" && m.p === "Planning");
m = buildAliasMap("SELECT * FROM Voyage V INNER JOIN Reservation R ON V.idV = R.idV");
check("aliasMap JOIN", m.v === "Voyage" && m.r === "Reservation");

// ── Algèbre : opérateurs après := ──
r = suggest("algebra", "R1 := SEL", SCHEMA);
check("R1 := SEL -> SELECTION", labels(r)[0] === "SELECTION");

// ── Algèbre : relations après ( (en MAJUSCULES) ──
r = suggest("algebra", "SELECTION (Vo", SCHEMA);
check("( Vo -> VOYAGE", labels(r).includes("VOYAGE") && r.items[0].kind === "table");

// ── Algèbre : attributs après / (en MAJUSCULES) ──
r = suggest("algebra", "SELECTION (Voyage / vi", SCHEMA);
check("/ vi -> VILLEARR + VILLE", labels(r).includes("VILLEARR") && labels(r).includes("VILLE"));

// ── Algèbre : séparateur inséré après une relation/attribut accepté ──
check("relation SELECTION -> /", algebraAcceptSuffix("SELECTION(", "table") === "/");
check("relation PROJECTION -> /", algebraAcceptSuffix("PROJECTION (", "table") === "/");
check("relation RENOMMAGE -> /", algebraAcceptSuffix("RENOMMAGE (", "table") === "/");
check("attribut RENOMMAGE -> ' -> '", algebraAcceptSuffix("RENOMMAGE (R1 / NUMAV", "col") === " -> ");
check("attribut SELECTION -> rien", algebraAcceptSuffix("SELECTION (AVION / ", "col") === "");
check("1re relation UNION -> ', '", algebraAcceptSuffix("UNION(", "table") === ", ");
check("2e relation JOINTURE -> ' / '", algebraAcceptSuffix("JOINTURE(A, ", "table") === " / ");
check("2e relation JOINTURE_NATURELLE -> rien", algebraAcceptSuffix("JOINTURE_NATURELLE(A, ", "table") === "");

// ── Algèbre : relation/attribut exact gardé sur appel explicite (Ctrl+Espace) ──
check("exact relation gardé avec force", suggest("algebra", "SELECTION (VOYAGE", SCHEMA, true).items.some((i) => i.label === "VOYAGE"));
check("exact relation ignoré sans force", !suggest("algebra", "SELECTION (VOYAGE", SCHEMA, false).items.some((i) => i.label === "VOYAGE"));

console.log(`${pass}/${pass + fail} OK - logique d'autocomplétion contextuelle`);
process.exit(fail === 0 ? 0 : 1);
