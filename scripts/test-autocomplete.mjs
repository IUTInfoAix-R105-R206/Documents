// test-autocomplete.mjs - teste la logique de suggestion contextuelle (pure, sans DOM).
//   node scripts/test-autocomplete.mjs
import { suggest, buildAliasMap } from "../templates/web-td/js/autocomplete.js";

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

// ── SQL : contexte tables après FROM/JOIN ──
let r = suggest("sql", "SELECT nom FROM Cl", SCHEMA);
check("FROM Cl -> Client", labels(r).includes("Client") && r.word === "Cl" && r.items[0].kind === "table");

r = suggest("sql", "SELECT * FROM Voyage JOIN Re", SCHEMA);
check("JOIN Re -> Reservation", labels(r)[0] === "Reservation");

// ── SQL : contexte colonnes ailleurs ──
r = suggest("sql", "SELECT n", SCHEMA);
check("SELECT n -> colonnes nom/numCl", labels(r).includes("nom") && labels(r).includes("numCl")
  && r.items[0].kind === "col");

// ── SQL : qualificateur alias. -> colonnes de la table ──
r = suggest("sql", "SELECT * FROM Voyage v WHERE v.", SCHEMA);
check("v. (alias Voyage) -> colonnes Voyage", JSON.stringify(labels(r)) === JSON.stringify(["idV", "dateDep", "villeArr"]));

r = suggest("sql", "SELECT * FROM Voyage v, Reservation r WHERE r.i", SCHEMA);
check("r.i (alias Reservation) -> idV", JSON.stringify(labels(r)) === JSON.stringify(["idV"]));

r = suggest("sql", "SELECT ville FROM Client.", SCHEMA);
check("Client. (table réelle) -> colonnes Client", JSON.stringify(labels(r)) === JSON.stringify(["numCl", "nom", "ville"]));

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

// ── Algèbre : relations après ( ──
r = suggest("algebra", "SELECTION (Vo", SCHEMA);
check("( Vo -> Voyage", labels(r).includes("Voyage") && r.items[0].kind === "table");

// ── Algèbre : attributs après / ──
r = suggest("algebra", "SELECTION (Voyage / vi", SCHEMA);
check("/ vi -> villeArr + ville", labels(r).includes("villeArr") && labels(r).includes("ville"));

console.log(`${pass}/${pass + fail} OK - logique d'autocomplétion contextuelle`);
process.exit(fail === 0 ? 0 : 1);
