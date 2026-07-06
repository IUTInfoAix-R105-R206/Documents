#!/usr/bin/env python3
"""Génère le site web statique d'un TD d'algèbre relationnelle.

L'étudiant écrit une expression en algèbre relationnelle (notation du cours) ;
le navigateur la compile en SQL (algebra.js) et l'exécute (sql.js), puis compare
un hash SHA-256 du résultat au hash attendu — précalculé ici sans jamais embarquer
la correction.

Étapes :
    1. Parse la correction .md (énoncés + blocs d'algèbre de référence).
    2. Construit la base SQLite et, via scripts/algebra-run.mjs (Node), compile +
       exécute + hashe chaque bloc de référence (source de vérité unique : algebra.js).
    3. Émet le site (copie du template + data/ + questions.json avec mode:"algebra").
    4. Émet un sidecar de vérification (jamais publié) + audit anti-fuite.
    5. Signale toute correction qui ne compile/s'exécute pas (drop) ; un drop
       inattendu (hors manifeste theory/expectedDrops) fait échouer la génération.
"""

import os
import re
import sys
import json
import shutil
import argparse
import datetime
import subprocess

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sqlite_compat import filter_schema, filter_insert

RE_SECTION = re.compile(r'^##\s+(.*?)\s*$')
RE_H1 = re.compile(r'^#\s+(.*?)\s*$')
RE_QNUM = re.compile(r'^Q(\d+[a-z]?)\s*$')
RE_DEF = re.compile(r'^:\s?(.*)$')
RE_FENCE = re.compile(r'^```')
RE_SCHEMA_OPEN = re.compile(r'^::::+\s*schema-relationnel\s*$')
RE_DIV_CLOSE = re.compile(r'^::::+\s*$')


def convert_schema_line(l):
    """Convertit une ligne de schéma relationnel Pandoc en HTML.

    `Rel` -> gras ; [pk]{.pk} -> souligné ; [*fk#*]{.fk} -> italique ;
    [*pkfk#*]{.pkfk} -> souligné + italique. Les annotations de domaine
    « : D_XXX » sont retirées et les underscores LaTeX déséchappés.
    """
    l = re.sub(r'\s*:\s*D\\?_[A-Za-z0-9_\\]+', '', l)   # retire les domaines
    l = l.replace('\\_', '_')                           # déséchappe les underscores
    l = re.sub(r'`([^`]+)`', r'<strong>\1</strong>', l)
    l = re.sub(r'\[\*([^\]]*?)\*\]\{\.pkfk\}', r'<u><em>\1</em></u>', l)
    l = re.sub(r'\[\*([^\]]*?)\*\]\{\.fk\}', r'<em>\1</em>', l)
    l = re.sub(r'\[([^\]]*?)\]\{\.pk\}', r'<u>\1</u>', l)
    return l


def relational_schema_html(path, section_marker=None, extra=None):
    """Extrait le(s) bloc(s) `:::: schema-relationnel ... ::::` en lignes HTML.

    Si section_marker est donné, on se limite à la section `# ... marker ...`.
    extra : lignes HTML supplémentaires ajoutées en tête (relations de base non
    présentes dans le bloc, ex. Pilote/Avion/Vol pour l'Airbase étendu du TD2).
    """
    lines = open(path, encoding="utf-8").read().split("\n")
    i = 0
    if section_marker:
        found = False
        while i < len(lines):
            m = RE_H1.match(lines[i])
            if m and section_marker.lower() in m.group(1).lower():
                i += 1
                found = True
                break
            i += 1
        if not found:
            return list(extra or [])
    rels = list(extra or [])
    inside = False
    while i < len(lines):
        if section_marker and RE_H1.match(lines[i]):
            break
        if not inside:
            if RE_SCHEMA_OPEN.match(lines[i]):
                inside = True
        else:
            if RE_DIV_CLOSE.match(lines[i]):
                break
            if lines[i].strip():
                rels.append(convert_schema_line(lines[i].strip()))
        i += 1
    return rels

ALLOWED_TOP_KEYS = {
    "formatVersion", "tdId", "tdLabel", "title", "intro",
    "mode", "database", "canon", "sections", "subjectPdf",
}
ALLOWED_QUESTION_KEYS = {
    "type", "id", "num", "statement", "expectedCols", "expectedRows",
    "expectedLabel", "orderSensitive", "hashesSorted", "hashOrdered",
    "difficulty", "tags", "sameAs",
}


class GenError(Exception):
    pass


def log(msg):
    print(msg, file=sys.stderr)


def expected_label(ncols, nrows):
    a = "attribut" if ncols == 1 else "attributs"
    t = "tuple" if nrows == 1 else "tuples"
    return f"{ncols} {a}, {nrows} {t}"


def git_version(repo_root):
    def run(args):
        try:
            return subprocess.check_output(args, cwd=repo_root, stderr=subprocess.DEVNULL).decode().strip()
        except Exception:
            return None
    return (run(["git", "describe", "--exact-match", "--tags", "HEAD"])
            or run(["git", "rev-parse", "--short", "HEAD"]) or "inconnu")


def parse_md(path, section_marker="langage algébrique"):
    """Parse la correction .md. Renvoie (intro, [question...]).

    Chaque question : {num, statement, section, blocks:[{text, kind}]}
    kind ∈ {'reference', 'alternative', 'incorrect'}.
    On ne lit que la région dont le titre `#` contient section_marker.
    """
    lines = open(path, encoding="utf-8").read().split("\n")
    # Trouver le début de la région des requêtes.
    start = None
    for i, l in enumerate(lines):
        m = RE_H1.match(l)
        if m and section_marker.lower() in m.group(1).lower():
            start = i + 1
            break
    if start is None:
        raise GenError(f"section « # ... {section_marker} ... » introuvable dans le .md")

    intro_lines = []
    section = ""
    questions = []
    i = start
    # Intro = paragraphes jusqu'au premier ## ou Qn
    while i < len(lines):
        l = lines[i]
        if RE_SECTION.match(l) or RE_QNUM.match(l) or RE_H1.match(l):
            break
        if l.strip():
            intro_lines.append(l.strip())
        i += 1
    intro = " ".join(intro_lines).strip()

    cur = None            # question en cours
    pending_label = ""    # dernière ligne de prose avant un bloc
    while i < len(lines):
        l = lines[i]
        m1 = RE_H1.match(l)
        if m1:
            break  # fin de la région (nouvelle section de niveau 1)
        ms = RE_SECTION.match(l)
        if ms:
            section = ms.group(1)
            pending_label = ""
            i += 1
            continue
        mq = RE_QNUM.match(l)
        if mq:
            cur = {"num": mq.group(1), "statement": "", "section": section, "blocks": []}
            questions.append(cur)
            pending_label = ""
            # Lire la définition « : ... » et ses continuations
            i += 1
            stmt = []
            if i < len(lines):
                md = RE_DEF.match(lines[i])
                if md:
                    stmt.append(md.group(1).strip())
                    i += 1
                    while i < len(lines) and lines[i].strip() and not RE_QNUM.match(lines[i]) \
                            and not RE_FENCE.match(lines[i]) and not RE_SECTION.match(lines[i]):
                        stmt.append(lines[i].strip())
                        i += 1
            cur["statement"] = " ".join(stmt).strip()
            continue
        if RE_FENCE.match(l):
            # Collecter le bloc jusqu'à la fence fermante
            i += 1
            block_lines = []
            while i < len(lines) and not RE_FENCE.match(lines[i]):
                block_lines.append(lines[i])
                i += 1
            i += 1  # sauter la fence fermante
            text = "\n".join(block_lines).strip()
            label = pending_label.lower()
            if "incorrect" in label:
                kind = "incorrect"
            elif cur and any(b["kind"] in ("reference", "alternative") for b in cur["blocks"]):
                kind = "alternative"
            else:
                kind = "reference"
            if cur is not None and text:
                cur["blocks"].append({"text": text, "kind": kind})
            pending_label = ""
            continue
        if l.strip():
            pending_label = l.strip()
        i += 1

    return intro, questions


def run_algebra(node_bin, script, web_root, schema_sql, insert_sql, jobs):
    payload = json.dumps({"schema": schema_sql, "insert": insert_sql, "questions": jobs})
    proc = subprocess.run([node_bin, script, "--web-root", web_root],
                          input=payload.encode("utf-8"),
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        raise GenError(f"algebra-run.mjs a échoué :\n{proc.stderr.decode('utf-8', 'replace')}")
    return json.loads(proc.stdout.decode("utf-8"))


def emit_site(template_dir, site_dir, schema_sql, insert_sql, questions_json, pdf_src=None):
    if os.path.exists(site_dir):
        shutil.rmtree(site_dir)
    shutil.copytree(template_dir, site_dir)
    data_dir = os.path.join(site_dir, "data")
    os.makedirs(data_dir, exist_ok=True)
    with open(os.path.join(data_dir, "schema.sql"), "w", encoding="utf-8") as f:
        f.write(schema_sql)
    with open(os.path.join(data_dir, "insert.sql"), "w", encoding="utf-8") as f:
        f.write(insert_sql)
    # PDF du sujet (facultatif) : copié dans le site pour rester accessible même
    # quand le dépôt Documents sera privé. Seul le SUJET est publié (pas la correction).
    if pdf_src:
        shutil.copyfile(pdf_src, os.path.join(site_dir, questions_json["subjectPdf"]))
    with open(os.path.join(site_dir, "questions.json"), "w", encoding="utf-8") as f:
        json.dump(questions_json, f, ensure_ascii=False, indent=2)
    open(os.path.join(site_dir, ".nojekyll"), "w").close()


def audit_no_leak(site_dir, solutions, questions_json):
    def norm(s):
        return re.sub(r"\s+", " ", s).strip().lower()
    extra = set(questions_json) - ALLOWED_TOP_KEYS
    if extra:
        raise GenError(f"Audit : clés racines inattendues : {extra}")
    for sec in questions_json["sections"]:
        for it in sec["items"]:
            if it.get("type") == "question":
                bad = set(it) - ALLOWED_QUESTION_KEYS
                if bad:
                    raise GenError(f"Audit : clés inattendues dans une question : {bad}")
    texts = {}
    for root, _, files in os.walk(site_dir):
        for fn in files:
            if fn.lower().endswith(".pdf"):
                continue  # sujet PDF (binaire, ne contient pas la correction)
            p = os.path.join(root, fn)
            try:
                texts[p] = norm(open(p, encoding="utf-8", errors="ignore").read())
            except Exception:
                pass
    for sol in solutions:
        for b in sol["blocks"]:
            nb = norm(b["text"])
            if len(nb) < 12:
                continue
            for p, t in texts.items():
                if nb in t:
                    raise GenError(f"Audit ANTI-FUITE : l'algèbre de {sol['id']} apparaît dans {p}")


def main():
    ap = argparse.ArgumentParser(description="Génère un site web d'algèbre relationnelle.")
    ap.add_argument("correction", metavar="CORRECTION.md")
    ap.add_argument("--data-dir", required=True)
    ap.add_argument("--output", required=True)
    ap.add_argument("--verify-out", required=True)
    ap.add_argument("--td-id", required=True)
    ap.add_argument("--td-label", required=True)
    ap.add_argument("--title", default="Algèbre relationnelle")
    ap.add_argument("--db-name", default=None)
    ap.add_argument("--manifest", default=None)
    ap.add_argument("--section-marker", default="langage algébrique",
                    help="Sous-chaîne du titre # de la région à générer (ex. 'Exercice n° 1')")
    ap.add_argument("--schema-md", default=None,
                    help="Fichier .md d'où extraire le schéma relationnel (défaut : la correction)")
    ap.add_argument("--schema-extra", default=None,
                    help="Lignes HTML de schéma ajoutées en tête (séparées par |), ex. relations de base")
    ap.add_argument("--template-dir",
                    default=os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                                         "templates", "web-td"))
    ap.add_argument("--node", default="node")
    ap.add_argument("--pdf", default=None,
                    help="Chemin du PDF du sujet à copier dans le site (facultatif). "
                         "Ignoré avec un avertissement si le fichier est absent.")
    ap.add_argument("--pdf-name", default="sujet.pdf",
                    help="Nom du PDF dans le site (défaut : sujet.pdf).")
    args = ap.parse_args()

    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    db_name = args.db_name or os.path.basename(os.path.normpath(args.data_dir))
    manifest = json.load(open(args.manifest, encoding="utf-8")) if args.manifest and os.path.exists(args.manifest) else {}
    theory = set(str(x) for x in manifest.get("theoryQuestions", []))
    expected_drops = set(str(x) for x in manifest.get("expectedDrops", []))

    log(f"→ Parsing {args.correction}")
    intro, questions = parse_md(args.correction, args.section_marker)

    schema_sql = filter_schema(open(os.path.join(args.data_dir, "schema.sql"), encoding="utf-8").read())
    insert_path = os.path.join(args.data_dir, "insert.sql")
    insert_sql = filter_insert(open(insert_path, encoding="utf-8").read()) if os.path.exists(insert_path) else ""

    # Jobs : uniquement les questions non-théoriques ayant au moins un bloc de référence/alternative.
    jobs = []
    for q in questions:
        if q["num"] in theory:
            continue
        blocks = [b for b in q["blocks"] if b["kind"] in ("reference", "alternative")]
        if not blocks:
            continue
        jobs.append({"id": "q" + q["num"], "blocks": [b["text"] for b in blocks]})

    log(f"→ Compilation + exécution + hash via algebra-run.mjs ({len(jobs)} questions)")
    run_script = os.path.join(repo_root, "scripts", "algebra-run.mjs")
    out = run_algebra(args.node, run_script, args.template_dir, schema_sql, insert_sql, jobs)
    catalog = out["catalog"]
    by_id = {r["id"]: r for r in out["results"]}

    # Assembler questions.json + solutions + rapport de drops.
    sections_map = {}
    order = []
    solutions = []
    drops = []
    nq = 0
    for q in questions:
        qid = "q" + q["num"]
        sec = q["section"]
        if sec not in sections_map:
            sections_map[sec] = []
            order.append(sec)
        if q["num"] in theory:
            sections_map[sec].append({"type": "question", "id": qid, "num": q["num"],
                                      "statement": q["statement"], "expectedCols": None,
                                      "expectedRows": None, "expectedLabel": "question de cours",
                                      "orderSensitive": False, "hashesSorted": [], "hashOrdered": None,
                                      "difficulty": None, "tags": [], "sameAs": None})
            continue
        res = by_id.get(qid)
        ref_blocks = [b for b in q["blocks"] if b["kind"] in ("reference", "alternative")]
        if not res or not res["blocks"]:
            drops.append((q["num"], "aucun bloc de référence"))
            continue
        ref = res["blocks"][0]
        if "error" in ref:
            drops.append((q["num"], ref["error"]))
            continue
        # Alternatives : même hash trié que la référence.
        hashes = [ref["hashSorted"]]
        for k, alt in enumerate(res["blocks"][1:], start=1):
            if "error" in alt:
                drops.append((q["num"], f"variante {k+1} : {alt['error']}"))
                continue
            if alt["hashSorted"] != ref["hashSorted"]:
                drops.append((q["num"], f"variante {k+1} : hash différent de la référence"))
                continue
        if not ref.get("stable", True):
            drops.append((q["num"], "hash non déterministe"))
            continue
        sections_map[sec].append({
            "type": "question", "id": qid, "num": q["num"], "statement": q["statement"],
            "expectedCols": ref["ncols"], "expectedRows": ref["nrows"],
            "expectedLabel": expected_label(ref["ncols"], ref["nrows"]),
            "orderSensitive": False, "hashesSorted": hashes, "hashOrdered": None,
            "difficulty": None, "tags": [], "sameAs": None,
        })
        solutions.append({"id": qid, "num": q["num"], "blocks": ref_blocks,
                          "expectedCols": ref["ncols"], "expectedRows": ref["nrows"],
                          "hashesSorted": hashes})
        nq += 1

    # Vérifier les drops inattendus.
    unexpected = [(n, why) for (n, why) in drops if n not in expected_drops]
    for n, why in drops:
        tag = "attendu" if n in expected_drops else "INATTENDU"
        log(f"   • Q{n} non générée ({tag}) : {why}")
    if unexpected:
        raise GenError(f"{len(unexpected)} correction(s) inattendue(s) en échec : "
                       + ", ".join(f"Q{n}" for n, _ in unexpected))

    # Pas d'horodatage ni de version dans questions.json : la sortie doit être
    # stable pour un contenu inchangé (l'auto-publication ne republie alors que
    # les pages réellement modifiées).
    questions_json = {
        "formatVersion": 1, "tdId": args.td_id, "tdLabel": args.td_label,
        "title": args.title, "intro": intro, "mode": "algebra",
        "database": {"name": db_name, "schemaFile": "data/schema.sql",
                     "insertFile": "data/insert.sql", "catalog": catalog,
                     "relationalSchema": relational_schema_html(
                         args.schema_md or args.correction,
                         args.section_marker if args.schema_md else None,
                         (args.schema_extra.split("|") if args.schema_extra else None))},
        "canon": {"algo": "sha256", "specVersion": 1},
        "sections": [{"name": s, "items": sections_map[s]} for s in order if sections_map[s]],
    }

    pdf_src = None
    if args.pdf:
        if os.path.isfile(args.pdf):
            questions_json["subjectPdf"] = args.pdf_name
            pdf_src = args.pdf
            log(f"→ Sujet PDF : {args.pdf} → {args.pdf_name}")
        else:
            log(f"⚠ PDF introuvable ({args.pdf}) — page générée sans lien vers le sujet")

    log(f"→ Émission du site dans {args.output}")
    emit_site(args.template_dir, args.output, schema_sql, insert_sql, questions_json, pdf_src)

    os.makedirs(args.verify_out, exist_ok=True)
    with open(os.path.join(args.verify_out, "solutions.json"), "w", encoding="utf-8") as f:
        json.dump({"solutions": solutions}, f, ensure_ascii=False, indent=2)

    log("→ Audit anti-fuite")
    audit_no_leak(args.output, solutions, questions_json)

    log(f"✓ OK — {nq} questions générées, {len(theory)} question(s) de cours, "
        f"{len(drops)} drop(s). Site : {args.output}")


if __name__ == "__main__":
    try:
        main()
    except GenError as e:
        log(f"✗ ERREUR : {e}")
        sys.exit(1)
