// test-autocomplete.mjs - teste la logique de suggestion contextuelle (pure, sans DOM).
//   node scripts/test-autocomplete.mjs
import { suggest, buildAliasMap, algebraAcceptSuffix, completionAction, contextAttributes } from "../templates/web-td/js/autocomplete.js";

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
// Contextuel : SELECTION(Voyage/ ne propose QUE les attributs de Voyage (pas ceux de Client).
r = suggest("algebra", "SELECTION (Voyage / vi", SCHEMA);
check("/ vi -> VILLEARR (de Voyage), pas VILLE (de Client)", labels(r).includes("VILLEARR") && !labels(r).includes("VILLE"));

// ── Algèbre : séparateur inséré après une relation/attribut accepté ──
check("relation SELECTION -> /", algebraAcceptSuffix("SELECTION(", "table") === "/");
check("relation PROJECTION -> /", algebraAcceptSuffix("PROJECTION (", "table") === "/");
check("relation RENOMMAGE -> /", algebraAcceptSuffix("RENOMMAGE (", "table") === "/");
check("attribut RENOMMAGE -> ' -> '", algebraAcceptSuffix("RENOMMAGE (R1 / NUMAV", "col") === " -> ");
check("attribut SELECTION -> rien", algebraAcceptSuffix("SELECTION (AVION / ", "col") === "");
check("1re relation UNION -> ', '", algebraAcceptSuffix("UNION(", "table") === ", ");
check("2e relation JOINTURE -> ' / '", algebraAcceptSuffix("JOINTURE(A, ", "table") === " / ");
check("2e relation JOINTURE_NATURELLE -> rien", algebraAcceptSuffix("JOINTURE_NATURELLE(A, ", "table") === "");

// ── Bug reproduit : sur un nom DÉJÀ complet, ne pas « proposer NUMAV mais insérer -> ».
//    L'appel explicite doit renvoyer un SÉPARATEUR (insertion directe), jamais une liste
//    proposant le mot déjà tapé.
let a = completionAction("algebra", "RENOMMAGE(R1/VILLEARR", SCHEMA, true);
check("RENOMMAGE + attribut complet -> séparateur ' -> ' (pas de liste)", a.type === "separator" && a.text === " -> ");
a = completionAction("algebra", "SELECTION(VOYAGE", SCHEMA, true);
check("SELECTION + relation complète -> séparateur '/'", a.type === "separator" && a.text === "/");
a = completionAction("algebra", "SELECTION(VOYAGE", SCHEMA, true);
check("jamais de proposition égale au mot déjà tapé", a.type !== "list" || !a.items.some((i) => i.label === "VOYAGE"));
a = completionAction("algebra", "SELECTION(VO", SCHEMA, true);
check("nom partiel -> liste normale (propose VOYAGE)", a.type === "list" && a.items.some((i) => i.label === "VOYAGE"));
a = completionAction("algebra", "SELECTION(VOYAGE/VILLEARR", SCHEMA, true);
check("attribut complet sans séparateur (SELECTION) -> rien", a.type === "none");
a = completionAction("sql", "WHERE ville = 'MAR", SCHEMA, true);
check("dans une chaîne -> rien (action none)", a.type === "none");

// ── Après « / » : uniquement des attributs, jamais de connecteur (quel que soit l'opérateur) ──
for (const ctx of ["SELECTION (VOYAGE / ", "RENOMMAGE (R1 / ", "PROJECTION (R1 / ", "JOINTURE (A, B / "]) {
  check(`${ctx.trim()} -> attributs seuls`, !suggest("algebra", ctx, SCHEMA, true).items.some((i) => i.kind === "kw"));
}
// ── ET/OU/NON ne sont jamais proposés (ni en début d'expression) ──
check("début d'expression -> opérateurs relationnels sans ET/OU/NON",
  !suggest("algebra", "R1 := ", SCHEMA, true).items.some((i) => ["ET", "OU", "NON"].includes(i.label)));

// ── contextAttributes : attributs de l'opérande courant (table de base ET relation intermédiaire) ──
const eq = (a, b) => JSON.stringify(a) === JSON.stringify(b);
check("SELECTION(Voyage/ -> attributs de Voyage",
  eq(contextAttributes("R1 := SELECTION(Voyage/", SCHEMA), ["idV", "dateDep", "villeArr"]));
check("SELECTION(Client/ -> attributs de Client",
  eq(contextAttributes("R1 := SELECTION(Client/", SCHEMA), ["numCl", "nom", "ville"]));
// Relation intermédiaire : PROJECTION restreint le schéma.
check("PROJECTION puis SELECTION(R1/ -> attributs projetés",
  eq(contextAttributes("R1 := PROJECTION(Voyage/idV, dateDep)\nR2 := SELECTION(R1/", SCHEMA), ["idV", "dateDep"]));
// SELECTION préserve le schéma ; RENOMMAGE(R1/ voit donc les attributs de Voyage.
check("SELECTION puis RENOMMAGE(R1/ -> attributs de Voyage",
  eq(contextAttributes("R1 := SELECTION(Voyage/dateDep > '2020')\nR2 := RENOMMAGE(R1/", SCHEMA), ["idV", "dateDep", "villeArr"]));
// JOINTURE : la condition voit les attributs des deux relations.
check("JOINTURE(Voyage, Reservation/ -> attributs des deux", (() => {
  const a = contextAttributes("R1 := JOINTURE(Voyage, Reservation/", SCHEMA);
  return a.includes("dateDep") && a.includes("dateRes");
})());
// RENOMMAGE renomme le schéma résultant.
check("RENOMMAGE renomme le schéma suivi",
  eq(contextAttributes("R1 := RENOMMAGE(Voyage/villeArr -> destination)\nR2 := SELECTION(R1/", SCHEMA), ["idV", "dateDep", "destination"]));

// ── SQL contextuel : colonnes non qualifiées restreintes aux tables du FROM/JOIN ──
r = suggest("sql", "SELECT nom FROM Client WHERE ", SCHEMA, true);
check("WHERE après FROM Client -> colonnes de Client, pas de Voyage",
  labels(r).includes("NOM") && !labels(r).includes("DATEDEP"));
// Le FROM peut être APRÈS le curseur (liste du SELECT) : scope via la requête complète.
r = suggest("sql", "SELECT vi", SCHEMA, false, "SELECT vi FROM Voyage");
check("SELECT vi ... FROM Voyage -> VILLEARR (Voyage) pas VILLE (Client)",
  labels(r).includes("VILLEARR") && !labels(r).includes("VILLE"));
// Plusieurs tables -> union de leurs colonnes.
r = suggest("sql", "SELECT * FROM Client c, Voyage v WHERE ", SCHEMA, true);
check("FROM Client, Voyage -> colonnes des deux, pas de Reservation",
  labels(r).includes("NOM") && labels(r).includes("DATEDEP") && !labels(r).includes("DATERES"));
// Sans FROM connu -> repli sur toutes les colonnes.
r = suggest("sql", "SELECT ", SCHEMA, true);
check("SELECT sans FROM -> repli toutes colonnes", labels(r).includes("NOM") && labels(r).includes("DATEDEP"));

// ── Clause FROM : après FROM/virgule -> tables seules ; après une table -> jointures ──
r = suggest("sql", "SELECT * FROM Voyage, ", SCHEMA, true);
check("FROM Voyage, -> tables seules (aucun mot-clé)", r.items.length > 0 && r.items.every((i) => i.kind === "table"));
r = suggest("sql", "SELECT * FROM ", SCHEMA, true);
check("FROM (vide) -> tables seules", r.items.length > 0 && r.items.every((i) => i.kind === "table"));
r = suggest("sql", "SELECT * FROM Voyage ", SCHEMA, true);
check("FROM Voyage (après table) -> JOIN/WHERE, pas SELECT",
  labels(r).includes("JOIN") && labels(r).includes("WHERE") && !labels(r).includes("SELECT"));

// ── Position d'expression (SELECT, WHERE...) : colonnes + fonctions, pas de table ni clause ──
r = suggest("sql", "SELECT ", SCHEMA, true);
check("SELECT -> DISTINCT + fonctions, pas de table ni démarreur de clause",
  labels(r).includes("DISTINCT") && labels(r).includes("COUNT")
  && !r.items.some((i) => i.kind === "table") && !labels(r).includes("FROM") && !labels(r).includes("WHERE"));
r = suggest("sql", "SELECT ", SCHEMA, true, "SELECT  FROM Voyage");
check("SELECT list scopé Voyage -> colonnes de Voyage, pas de Client ni de table",
  labels(r).includes("VILLEARR") && !labels(r).includes("NOM") && !r.items.some((i) => i.kind === "table"));

// ── Après une colonne dans un WHERE : comparateurs + prédicats (pas de colonnes) ──
r = suggest("sql", "SELECT * FROM Voyage WHERE villeArr ", SCHEMA, true);
check("WHERE colonne -> comparateurs + IN/LIKE/IS, pas de colonne ni DISTINCT",
  labels(r).includes("=") && labels(r).includes("IN") && labels(r).includes("IS")
  && !labels(r).includes("IDV") && !labels(r).includes("DISTINCT"));
r = suggest("sql", "SELECT * FROM Voyage WHERE ", SCHEMA, true);
check("WHERE (début) -> colonnes, pas de comparateur",
  labels(r).includes("VILLEARR") && !labels(r).includes("="));

console.log(`${pass}/${pass + fail} OK - logique d'autocomplétion contextuelle`);
process.exit(fail === 0 ? 0 : 1);
