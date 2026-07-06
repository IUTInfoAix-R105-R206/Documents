#!/usr/bin/env python3
"""Génère un site web statique (SQLite WASM) pour un TD SQL.

Le site permet aux étudiants de répondre aux questions du TD directement dans le
navigateur : sql.js exécute leurs requêtes côté client, le résultat s'affiche
dans une table, et un retour automatique compare un hash SHA-256 du résultat au
hash attendu - **précalculé ici sans jamais embarquer la correction**.

Étapes :
    1. Parse le fichier de correction annoté (module `td_correction`).
    2. Construit une base SQLite en mémoire (schema + insert filtrés, UDF TO_DATE).
    3. Pour chaque question, choisit la première variante qui s'exécute (référence),
       vérifie les annotations c:/t:, calcule les hashes canoniques et vérifie que
       toutes les variantes fonctionnelles concordent.
    4. Émet le site complet dans --output (copie du template + data/ + questions.json).
    5. Émet un sidecar de vérification dans --verify-out (solutions + fixtures),
       qui NE DOIT PAS être publié.
    6. Audit anti-fuite : aucun SQL de correction dans le site, clés JSON en liste blanche.

Usage :
    generate-web-td.py CORRECTION.sql --data-dir DIR --output DIR
        --td-id r1.05-td7 --td-label "R1.05 - TD7"
        [--template-dir templates/web-td] [--verify-out DIR]
        [--db-name NAME] [--allow-multiple-hashes]
"""

import os
import re
import sys
import json
import shutil
import sqlite3
import argparse
import datetime
import subprocess

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import td_correction
import webtd_canon as canon
from sqlite_compat import filter_schema, filter_insert
from sql_quantifiers import rewrite_quantifiers

RE_ORDER_BY = re.compile(r'\border\s+by\b', re.IGNORECASE)

# Clés autorisées dans questions.json (audit anti-fuite).
ALLOWED_TOP_KEYS = {
    "formatVersion", "tdId", "tdLabel", "title", "intro",
    "database", "canon", "sections", "subjectPdf",
}
ALLOWED_QUESTION_KEYS = {
    "type", "id", "num", "statement",
    "expectedCols", "expectedRows", "expectedLabel",
    "orderSensitive", "hashesSorted", "hashOrdered",
    "difficulty", "tags", "sameAs", "theoryNote",
}

# Fixtures de parité (cellules + résultats) rehashées par le vérificateur en JS.
CANON_CELL_FIXTURES = [
    {"k": "null"},
    {"k": "int", "v": 0},
    {"k": "int", "v": 5},
    {"k": "int", "v": -3},
    {"k": "real", "v": 6.25},
    {"k": "real", "v": -6.25},
    {"k": "negzero"},
    {"k": "div", "a": 1, "b": 3},
    {"k": "div", "a": 2, "b": 3},
    {"k": "div", "a": 1, "b": 128},
    {"k": "div", "a": 22, "b": 7},
    {"k": "real", "v": 0.1},
    {"k": "text", "v": "MAROC"},
    {"k": "text", "v": "5"},
    {"k": "text", "v": ""},
    {"k": "text", "v": "A|B"},
    {"k": "text", "v": "back\\slash"},
    {"k": "text", "v": "sep\x1fUS\x1eRS\x1dGS"},
    {"k": "text", "v": "ÉTÉ ÀÇÙ"},
]


class GenError(Exception):
    pass


def log(msg):
    print(msg, file=sys.stderr)


def decode_fixture(fx):
    k = fx["k"]
    if k == "null":
        return None
    if k == "int":
        return int(fx["v"])
    if k == "real":
        return float(fx["v"])
    if k == "negzero":
        return -0.0
    if k == "div":
        return fx["a"] / fx["b"]
    if k == "text":
        return fx["v"]
    raise ValueError(k)


def git_version(repo_root):
    def run(args):
        try:
            return subprocess.check_output(
                args, cwd=repo_root, stderr=subprocess.DEVNULL
            ).decode().strip()
        except Exception:
            return None
    return (run(["git", "describe", "--exact-match", "--tags", "HEAD"])
            or run(["git", "rev-parse", "--short", "HEAD"])
            or "inconnu")


def build_db(data_dir):
    """Construit une base SQLite en mémoire à partir de schema.sql + insert.sql filtrés."""
    schema = os.path.join(data_dir, "schema.sql")
    insert = os.path.join(data_dir, "insert.sql")
    if not os.path.exists(schema):
        raise GenError(f"schema.sql introuvable dans {data_dir}")
    schema_sql = filter_schema(open(schema, encoding="utf-8").read())
    insert_sql = filter_insert(open(insert, encoding="utf-8").read()) if os.path.exists(insert) else ""

    conn = sqlite3.connect(":memory:")
    conn.create_function("TO_DATE", 2, lambda v, fmt: v, deterministic=True)
    conn.executescript(schema_sql)
    if insert_sql:
        conn.executescript(insert_sql)
    return conn, schema_sql, insert_sql


def exec_query(conn, sql):
    """Exécute une requête et renvoie (ncols, rows). Lève sqlite3.Error si échec."""
    cur = conn.cursor()
    cur.execute(sql)
    rows = cur.fetchall()
    ncols = len(cur.description) if cur.description is not None else 0
    cur.close()
    return ncols, rows


def clean_variant_sql(sql):
    """Retire les annotations noqa et le point-virgule final, puis réécrit les
    comparaisons quantifiées ALL/ANY en équivalents SQLite (même transformation que
    le navigateur via sql-quantifiers.js) pour exécuter la requête."""
    sql = td_correction._strip_noqa(sql).strip()
    sql = sql.rstrip(";").strip()
    return rewrite_quantifiers(sql)


RE_QUERY_START = re.compile(r'^\s*(?:--[^\n]*\n\s*)*\(*\s*(select|with)\b', re.IGNORECASE)


def is_query(sql):
    """Vrai si la requête renvoie des lignes (SELECT / WITH ... SELECT). Les autres
    (CREATE, ALTER, INSERT, UPDATE, DELETE, COMMIT... = LDD/LMD/LCT) n'ont pas de
    résultat à comparer : la question est alors non évaluable (comme dans test-sql)."""
    return bool(RE_QUERY_START.match(clean_variant_sql(sql)))


def expected_label(q):
    """Libellé lisible du résultat attendu (« 1 attribut, 5 tuples »), sans balise."""
    raw = td_correction.format_expected(q).strip()
    m = re.match(r'^\[(.*)\]\{\.expected\}$', raw)
    return m.group(1) if m else raw


def process_question(conn, q, allow_multiple):
    """Exécute les variantes, calcule hashes et vérifications. Renvoie (entry, solution)."""
    num = q["num"]
    qid = "q" + num
    variants = q.get("variants", [])
    sqls = [clean_variant_sql(v["sql"]) for v in variants if is_query(v.get("sql", ""))]
    if not sqls:
        raise GenError(f"Q{num} : aucune requête SQL")

    # Trouver toutes les variantes qui s'exécutent (dans l'ordre).
    working = []   # list of (sql, ncols, rows)
    errors = []
    for sql in sqls:
        try:
            ncols, rows = exec_query(conn, sql)
            working.append((sql, ncols, rows))
        except sqlite3.Error as e:
            errors.append((sql, str(e)))
    if not working:
        detail = "; ".join(e for _, e in errors)
        raise GenError(f"Q{num} : aucune variante exécutable sous SQLite ({detail})")

    ref_sql, ref_ncols, ref_rows = working[0]
    order_sensitive = bool(RE_ORDER_BY.search(ref_sql))

    # Vérifier les annotations c:/t:.
    if q["cols"] is not None and q["cols"] != ref_ncols:
        raise GenError(f"Q{num} : c:{q['cols']} annoté, {ref_ncols} colonnes réelles")
    if q["rows"] is not None and q["rows"] != len(ref_rows):
        raise GenError(f"Q{num} : t:{q['rows']} annoté, {len(ref_rows)} tuples réels")

    # Refuser les caractères hors BMP (tri divergent Py/JS).
    if canon.has_astral(ref_rows):
        raise GenError(f"Q{num} : caractère hors BMP dans le résultat")

    # Hash de référence (strict → lève sur BLOB / non-fini / hors plage).
    try:
        ref_sorted = canon.hash_result(ref_ncols, ref_rows, False, strict=True)
        ref_ordered = canon.hash_result(ref_ncols, ref_rows, True, strict=True) if order_sensitive else None
    except canon.CanonError as e:
        raise GenError(f"Q{num} : {e}")

    # Garde de déterminisme : PRAGMA reverse_unordered_selects doit laisser le hash trié
    # (et ordonné si pertinent) invariant.
    conn.execute("PRAGMA reverse_unordered_selects=ON")
    rncols, rrows = exec_query(conn, ref_sql)
    rev_sorted = canon.hash_result(rncols, rrows, False, strict=True)
    conn.execute("PRAGMA reverse_unordered_selects=OFF")
    if rev_sorted != ref_sorted:
        raise GenError(f"Q{num} : hash trié non déterministe (dépend de l'ordre d'insertion)")
    if order_sensitive:
        rev_ordered = canon.hash_result(rncols, rrows, True, strict=True)
        if rev_ordered != ref_ordered:
            raise GenError(f"Q{num} : ORDER BY non total (ordre ambigu sur clés non uniques)")

    # Concordance des autres variantes fonctionnelles.
    hashes_sorted = [ref_sorted]
    for sql, ncols, rows in working[1:]:
        h = canon.hash_result(ncols, rows, False, strict=True)
        if h != ref_sorted:
            if allow_multiple:
                if h not in hashes_sorted:
                    hashes_sorted.append(h)
            else:
                raise GenError(
                    f"Q{num} : variantes divergentes (hash trié différent) - "
                    f"utilisez --allow-multiple-hashes si intentionnel")

    entry = {
        "type": "question",
        "id": qid,
        "num": num,
        "statement": q.get("description", ""),
        "expectedCols": ref_ncols,
        "expectedRows": len(ref_rows),
        "expectedLabel": expected_label(q),
        "orderSensitive": order_sensitive,
        "hashesSorted": hashes_sorted,
        "hashOrdered": ref_ordered,
        "difficulty": q.get("difficulty"),
        "tags": q.get("tags", []),
        "sameAs": ("q" + q["ref"]) if q.get("ref") else None,
    }
    solution = {
        "id": qid,
        "num": num,
        "orderSensitive": order_sensitive,
        "expectedCols": ref_ncols,
        "expectedRows": len(ref_rows),
        "hashesSorted": hashes_sorted,
        "hashOrdered": ref_ordered,
        "variants": [sql for sql, _, _ in working],
    }
    return entry, solution


def theory_entry(q, note):
    """Item non évaluable (énoncé seul) : en-tête sans SQL, question de cours, ou
    requête Oracle non transposable en SQLite. expectedCols=None → app.js le rend
    via renderTheory (pas d'éditeur, pas d'auto-évaluation)."""
    return {
        "type": "question", "id": "q" + q["num"], "num": q["num"],
        "statement": q.get("description", ""),
        "expectedCols": None, "expectedRows": None, "expectedLabel": None,
        "orderSensitive": False, "hashesSorted": [], "hashOrdered": None,
        "difficulty": None, "tags": [], "sameAs": None, "theoryNote": note,
    }


def build_questions_json(parsed, conn, meta, allow_multiple, oracle_only=None, theory=None):
    oracle_only = oracle_only or set()
    theory = theory or set()
    sections_out = []
    solutions = []
    nquestions = 0
    for section in parsed["sections"]:
        items_out = []
        for item in section["items"]:
            t = item["type"]
            if t in ("instruction", "text"):
                items_out.append({"type": t, "text": item["text"]})
            elif t in ("remark", "remark_teacher"):
                continue  # jamais dans le sujet - non exposé aux étudiants
            elif t == "question":
                num = item["num"]
                has_query = any(is_query(v.get("sql", "")) for v in item.get("variants", []))
                # En-tête sans SQL, question LDD/LMD/LCT (non-SELECT), ou marquée
                # « de cours » → non évaluable (énoncé seul).
                if not has_query or num in theory:
                    items_out.append(theory_entry(
                        item, "Question de cours - pas d'auto-évaluation."))
                    continue
                # Requête Oracle non transposable : tolérée si déclarée, sinon erreur.
                try:
                    entry, solution = process_question(conn, item, allow_multiple)
                except GenError as e:
                    if num in oracle_only:
                        items_out.append(theory_entry(
                            item, "Requête Oracle - non auto-évaluable en ligne (à exécuter sous Oracle)."))
                        log(f"  Q{num} : non évaluable en SQLite ({e}) → rendue non évaluable")
                        continue
                    raise
                items_out.append(entry)
                solutions.append(solution)
                nquestions += 1
        # Ne conserver une section que si elle a du contenu.
        if items_out or section["name"]:
            sections_out.append({"name": section["name"], "items": items_out})

    questions = {
        "formatVersion": 1,
        "tdId": meta["td_id"],
        "tdLabel": meta["td_label"],
        "title": parsed.get("title", ""),
        "intro": parsed.get("intro", ""),
        "database": {
            "name": meta["db_name"],
            "schemaFile": "data/schema.sql",
            "insertFile": "data/insert.sql",
        },
        "canon": {"algo": "sha256", "specVersion": 1},
        "sections": sections_out,
    }
    return questions, solutions, nquestions


def audit_no_leak(site_dir, solutions, questions):
    """Vérifie qu'aucun SQL de correction n'apparaît dans le site et que les clés
    de questions.json sont en liste blanche."""
    def norm(s):
        return re.sub(r"\s+", " ", s).strip().lower()

    # 1. Clés de questions.json.
    extra = set(questions) - ALLOWED_TOP_KEYS
    if extra:
        raise GenError(f"Audit : clés inattendues au niveau racine : {extra}")
    for section in questions["sections"]:
        for item in section["items"]:
            if item.get("type") == "question":
                bad = set(item) - ALLOWED_QUESTION_KEYS
                if bad:
                    raise GenError(f"Audit : clés inattendues dans une question : {bad}")

    # 2. Aucun SQL de variante (normalisé) présent dans un fichier du site.
    site_texts = {}
    for root, _, files in os.walk(site_dir):
        for fn in files:
            if fn.lower().endswith(".pdf"):
                continue  # sujet PDF (binaire, ne contient pas la correction)
            path = os.path.join(root, fn)
            try:
                site_texts[path] = norm(open(path, encoding="utf-8", errors="ignore").read())
            except Exception:
                pass
    for sol in solutions:
        for sql in sol["variants"]:
            nsql = norm(sql)
            if len(nsql) < 12:
                continue  # trop court pour être un marqueur fiable
            for path, text in site_texts.items():
                if nsql in text:
                    raise GenError(
                        f"Audit ANTI-FUITE : la requête de {sol['id']} apparaît dans {path}")


def emit_site(template_dir, site_dir, schema_sql, insert_sql, questions, pdf_src=None):
    if os.path.exists(site_dir):
        shutil.rmtree(site_dir)
    shutil.copytree(template_dir, site_dir)
    # Les données SQLite-propres (filtrées) - le navigateur n'a pas de logique de compat.
    data_dir = os.path.join(site_dir, "data")
    os.makedirs(data_dir, exist_ok=True)
    with open(os.path.join(data_dir, "schema.sql"), "w", encoding="utf-8") as f:
        f.write(schema_sql)
    with open(os.path.join(data_dir, "insert.sql"), "w", encoding="utf-8") as f:
        f.write(insert_sql)
    # PDF du sujet (facultatif) : copié dans le site pour rester accessible même
    # quand le dépôt Documents sera privé. Seul le SUJET est publié (pas la correction).
    if pdf_src:
        shutil.copyfile(pdf_src, os.path.join(site_dir, questions["subjectPdf"]))
    with open(os.path.join(site_dir, "questions.json"), "w", encoding="utf-8") as f:
        json.dump(questions, f, ensure_ascii=False, indent=2)
    # GitHub Pages : désactiver Jekyll (préserve les fichiers commençant par _).
    open(os.path.join(site_dir, ".nojekyll"), "w").close()


def emit_verify(verify_dir, solutions):
    os.makedirs(verify_dir, exist_ok=True)
    with open(os.path.join(verify_dir, "solutions.json"), "w", encoding="utf-8") as f:
        json.dump({"solutions": solutions}, f, ensure_ascii=False, indent=2)

    # Fixtures de canonicalisation (cellules + résultats) avec hashes Python.
    cells = [canon.canon_cell(decode_fixture(fx)) for fx in CANON_CELL_FIXTURES]
    result_fixtures = [
        {"ncols": 2, "ordered": False,
         "rows": [[{"k": "int", "v": 1}, {"k": "real", "v": 6.25}],
                  [{"k": "int", "v": 2}, {"k": "null"}]]},
        {"ncols": 1, "ordered": True,
         "rows": [[{"k": "text", "v": "B"}], [{"k": "text", "v": "A"}]]},
        {"ncols": 1, "ordered": False, "rows": []},
    ]
    results = []
    for rf in result_fixtures:
        rows = [[decode_fixture(c) for c in row] for row in rf["rows"]]
        results.append(canon.hash_result(rf["ncols"], rows, rf["ordered"]))
    with open(os.path.join(verify_dir, "canon-fixtures.json"), "w", encoding="utf-8") as f:
        json.dump({
            "cellFixtures": CANON_CELL_FIXTURES,
            "cells": cells,
            "resultFixtures": result_fixtures,
            "results": results,
        }, f, ensure_ascii=False, indent=2)


def main():
    ap = argparse.ArgumentParser(description="Génère un site web statique SQLite WASM pour un TD.")
    ap.add_argument("correction", metavar="CORRECTION.sql")
    ap.add_argument("--data-dir", required=True)
    ap.add_argument("--output", required=True, help="Répertoire du site (écrasé)")
    ap.add_argument("--td-id", required=True)
    ap.add_argument("--td-label", required=True)
    ap.add_argument("--template-dir",
                    default=os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                                         "templates", "web-td"))
    ap.add_argument("--verify-out", default=None)
    ap.add_argument("--db-name", default=None)
    ap.add_argument("--allow-multiple-hashes", action="store_true")
    ap.add_argument("--manifest", default=None,
                    help="JSON facultatif : {\"oracleOnlyQuestions\":[...], \"theoryQuestions\":[...]}. "
                         "oracleOnly = tolère une question dont aucune variante ne tourne sous SQLite "
                         "(rendue non évaluable) ; theory = force l'énoncé seul.")
    ap.add_argument("--pdf", default=None,
                    help="Chemin du PDF du sujet à copier dans le site (facultatif). "
                         "Ignoré avec un avertissement si le fichier est absent.")
    ap.add_argument("--pdf-name", default="sujet.pdf",
                    help="Nom du PDF dans le site (défaut : sujet.pdf).")
    args = ap.parse_args()

    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    db_name = args.db_name or os.path.basename(os.path.normpath(args.data_dir))
    verify_dir = args.verify_out or os.path.join(
        os.path.dirname(os.path.normpath(args.output).rstrip("/")) or ".",
        "..", "web-verify", os.path.basename(os.path.normpath(args.output)))

    log(f"→ Parsing {args.correction}")
    parsed = td_correction.parse_sql(args.correction)

    log(f"→ Construction de la base SQLite depuis {args.data_dir}")
    conn, schema_sql, insert_sql = build_db(args.data_dir)

    meta = {
        "td_id": args.td_id,
        "td_label": args.td_label,
        "db_name": db_name,
        "version": git_version(repo_root),
        "generated_at": datetime.datetime.now(datetime.timezone.utc)
                        .replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    }

    manifest = json.load(open(args.manifest, encoding="utf-8")) if args.manifest and os.path.exists(args.manifest) else {}
    oracle_only = set(str(x) for x in manifest.get("oracleOnlyQuestions", []))
    theory = set(str(x) for x in manifest.get("theoryQuestions", []))

    log("→ Exécution des corrections et calcul des hashes")
    questions, solutions, nq = build_questions_json(
        parsed, conn, meta, args.allow_multiple_hashes, oracle_only, theory)
    conn.close()

    pdf_src = None
    if args.pdf:
        if os.path.isfile(args.pdf):
            questions["subjectPdf"] = args.pdf_name
            pdf_src = args.pdf
            log(f"→ Sujet PDF : {args.pdf} → {args.pdf_name}")
        else:
            log(f"⚠ PDF introuvable ({args.pdf}) - page générée sans lien vers le sujet")

    log(f"→ Émission du site dans {args.output}")
    emit_site(args.template_dir, args.output, schema_sql, insert_sql, questions, pdf_src)

    log(f"→ Émission du sidecar de vérification dans {verify_dir}")
    emit_verify(verify_dir, solutions)

    log("→ Audit anti-fuite")
    audit_no_leak(args.output, solutions, questions)

    log(f"✓ OK - {nq} questions générées, site prêt dans {args.output}")


if __name__ == "__main__":
    try:
        main()
    except GenError as e:
        log(f"✗ ERREUR : {e}")
        sys.exit(1)
