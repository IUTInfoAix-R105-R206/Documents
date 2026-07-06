#!/usr/bin/env python3
"""Génère un rapport HTML comparant les résultats de tests SQL sur plusieurs SGBD.

Usage:
  # Rapport global unique (ancien comportement)
  python3 generate-sql-report.py --output report.html results-*.csv

  # Rapports par TD + index + summary.json
  python3 generate-sql-report.py --output-dir site --docs-dir docs results-*.csv

Format CSV attendu (séparateur ';') :
  Nouveau : td_id;label;dbms;status;expected_cols;expected_rows;actual_cols;actual_rows
  Ancien :  label;dbms;status;expected_cols;expected_rows;actual_cols;actual_rows
"""

import sys
import csv
import os
import json
import re
import argparse
from datetime import datetime, timezone
from pathlib import Path

DBMS_LABELS = {
    "postgres": "PostgreSQL",
    "sqlite":   "SQLite",
    "oracle":   "Oracle",
}

DBMS_SHORT = {
    "postgres": "PG",
    "sqlite":   "SQLite",
    "oracle":   "Oracle",
}

DBMS_CSS = {
    "postgres": "pg",
    "sqlite":   "sqlite",
    "oracle":   "oracle",
}

STATUS_ICONS = {
    "pass":  "✓",
    "fail":  "✗",
    "skip":  "⊘",
    "error": "!",
}

RESOURCE_LABELS = {
    "r1.05": "R1.05 - Introduction aux bases de données et SQL",
    "r2.06": "R2.06 - Exploitation d'une base de données",
}

CSS = """\
    body { font-family: sans-serif; margin: 2rem; color: #333; }
    h1 { color: #2c3e50; margin-bottom: 0.25rem; }
    h2 { color: #2c3e50; margin-top: 2rem; }
    .subtitle { color: #666; margin-bottom: 1.5rem; font-size: 0.9rem; }
    .stats { display: flex; gap: 1rem; margin-bottom: 1.5rem; flex-wrap: wrap; }
    .stat-box { padding: 0.75rem 1.25rem; border-radius: 6px; background: #f0f4f8;
                 border: 1px solid #d0d7de; text-align: center; min-width: 130px; }
    table { border-collapse: collapse; width: 100%; font-size: 0.9rem; margin-bottom: 1.5rem; }
    th { background: #2c3e50; color: white; padding: 0.5rem 0.75rem; text-align: left; }
    td { padding: 0.4rem 0.75rem; border-bottom: 1px solid #e1e4e8; vertical-align: middle; }
    tr:hover { background: #f6f8fa; }
    td.label { font-family: monospace; font-size: 0.85rem; }
    td.expected { color: #666; font-size: 0.85rem; white-space: nowrap; }
    td.pass { color: #1a7f37; font-weight: bold; text-align: center; }
    td.fail { color: #cf222e; text-align: center; }
    td.skip { color: #9a6700; text-align: center; }
    td.error { color: #cf222e; font-style: italic; text-align: center; font-size: 0.85rem; }
    td.missing { color: #999; text-align: center; }
    .pass { color: #1a7f37; }
    .error { color: #cf222e; }
    small { font-weight: normal; font-size: 0.8rem; }
    .footer { margin-top: 1.5rem; color: #666; font-size: 0.8rem; }
    a { color: #0366d6; text-decoration: none; }
    a:hover { text-decoration: underline; }
    .back-link { margin-bottom: 1.5rem; }
    .td-list { list-style: none; padding: 0; }
    .td-list li { margin: 0.5rem 0; padding: 0.5rem 0.75rem; border-radius: 4px; }
    .td-list li:hover { background: #f6f8fa; }
    .td-stats { color: #666; font-size: 0.85rem; margin-left: 1rem; }
    .badge { display: inline-block; font-size: 0.7rem; padding: 0.1rem 0.4rem;
             border-radius: 3px; margin-left: 0.5rem; vertical-align: middle; }
    .badge-ok { background: #d4edda; color: #155724; border: 1px solid #28a745; }
    .badge-warn { background: #fff3cd; color: #856404; border: 1px solid #ffc107; }
    .badge-fail { background: #f8d7da; color: #721c24; border: 1px solid #dc3545; }
    .badge-pg { background: #e3f2fd; color: #1565c0; border: 1px solid #42a5f5; }
    .badge-sqlite { background: #e0f2f1; color: #00695c; border: 1px solid #26a69a; }
    .badge-oracle { background: #fff3e0; color: #e65100; border: 1px solid #ff9800; }"""


def read_report(filename):
    """Lit un fichier CSV de résultats.

    Auto-détecte le format (avec ou sans td_id).
    Retourne (dbms, [{td_id, label, status, ...}]).
    """
    entries = []
    dbms = None
    with open(filename, newline="", encoding="utf-8") as f:
        reader = csv.reader(f, delimiter=";")
        header = next(reader)
        has_td_id = len(header) >= 1 and header[0] == "td_id"

        for row in reader:
            if has_td_id:
                if len(row) < 8:
                    continue
                td_id, label, d, status = row[0], row[1], row[2], row[3]
                exp_cols, exp_rows = row[4], row[5]
                actual_cols, actual_rows = row[6], row[7]
            else:
                if len(row) < 7:
                    continue
                td_id = "global"
                label, d, status = row[0], row[1], row[2]
                exp_cols, exp_rows = row[3], row[4]
                actual_cols, actual_rows = row[5], row[6]

            dbms = d
            entries.append({
                "td_id":       td_id,
                "label":       label,
                "status":      status,
                "exp_cols":    exp_cols,
                "exp_rows":    exp_rows,
                "actual_cols": actual_cols,
                "actual_rows": actual_rows,
            })
    return dbms, entries


def group_by_td(entries):
    """Groupe les entrées par td_id, préservant l'ordre d'apparition.

    Retourne (ordre_td_ids, {td_id: {label: entry}}).
    """
    groups = {}
    order = []
    for entry in entries:
        td_id = entry["td_id"]
        if td_id not in groups:
            groups[td_id] = {}
            order.append(td_id)
        groups[td_id][entry["label"]] = entry
    return order, groups


def read_td_titles(docs_dir):
    """Lit les titres YAML depuis les fichiers Markdown des TD."""
    titles = {}
    if not docs_dir:
        return titles
    docs_path = Path(docs_dir)
    for md_file in sorted(docs_path.glob("r*/td*/td*.md")):
        parts = md_file.relative_to(docs_path).parts
        if len(parts) >= 2:
            td_id = f"{parts[0]}/{parts[1]}"
            with open(md_file, encoding="utf-8") as f:
                for line in f:
                    m = re.match(r'^title:\s*"(.+)"', line)
                    if m:
                        titles[td_id] = m.group(1)
                        break
    return titles


def cell_html(entry):
    """Retourne le HTML d'une cellule de résultat."""
    status = entry["status"]
    icon = STATUS_ICONS.get(status, "?")
    if status == "pass":
        detail = ""
    elif status == "error":
        detail = "<br><small>syntaxe non supportée</small>"
    elif status == "fail":
        detail = (
            f"<br><small>"
            f"{entry['actual_cols']}c × {entry['actual_rows']}r"
            f"</small>"
        )
    else:
        detail = ""
    return f'<td class="{status}">{icon}{detail}</td>'


def compute_stats(data):
    """Calcule les statistiques pour un dict {label: entry}."""
    total = len(data)
    passed = sum(1 for v in data.values() if v["status"] == "pass")
    errors = sum(1 for v in data.values() if v["status"] == "error")
    failed = sum(1 for v in data.values() if v["status"] == "fail")
    skipped = sum(1 for v in data.values() if v["status"] == "skip")
    tested = total - skipped
    return {"total": total, "pass": passed, "error": errors, "fail": failed,
            "skip": skipped, "tested": tested}


def generate_stats_html(reports_data):
    """Génère le bloc de statistiques par SGBD."""
    parts = []
    for dbms, data in reports_data:
        s = compute_stats(data)
        tested = s["tested"]
        passed = s["pass"]
        errors = s["error"]
        skipped = s["skip"]
        pct = passed * 100 // tested if tested > 0 else 0
        label = DBMS_LABELS.get(dbms, dbms)
        parts.append(
            f'<div class="stat-box">'
            f"<strong>{label}</strong><br>"
            f'<span class="pass">{passed} ✓</span> / {tested}'
            f" ({pct}%)"
            + (f'<br><small class="error">{errors} erreur(s) SQL</small>' if errors else "")
            + (f'<br><small>{skipped} ignoré(s)</small>' if skipped else "")
            + "</div>"
        )
    return f'<div class="stats">{"".join(parts)}</div>'


def generate_table_html(all_labels, reports_data):
    """Génère le tableau HTML de résultats."""
    dbms_names = [DBMS_LABELS.get(d, d) for d, _ in reports_data]

    header_cells = "<th>Requête</th><th>Attendu</th>"
    for name in dbms_names:
        header_cells += f"<th>{name}</th>"

    rows_html = []
    for label in all_labels:
        expected = "-"
        for _dbms, data in reports_data:
            if label in data:
                e = data[label]
                expected = f"{e['exp_cols']}c × {e['exp_rows']}r"
                break

        cells = f'<td class="label">{label}</td>'
        cells += f'<td class="expected">{expected}</td>'
        for _dbms, data in reports_data:
            if label in data:
                cells += cell_html(data[label])
            else:
                cells += '<td class="missing">-</td>'
        rows_html.append(f"<tr>{cells}</tr>")

    return (
        f"<table>\n"
        f"    <thead><tr>{header_cells}</tr></thead>\n"
        f"    <tbody>\n      {''.join(rows_html)}\n    </tbody>\n"
        f"  </table>"
    )


def collect_labels(reports_data):
    """Collecte tous les labels dans l'ordre d'apparition."""
    labels = []
    seen = set()
    for _dbms, data in reports_data:
        for label in data:
            if label not in seen:
                labels.append(label)
                seen.add(label)
    return labels


def td_report_filename(td_id):
    """Convertit un td_id (ex: r2.06/td3) en nom de fichier (ex: r2.06-td3.html)."""
    return td_id.replace("/", "-") + ".html"


# ---------------------------------------------------------------------------
# Rapport global unique (ancien comportement)
# ---------------------------------------------------------------------------

def generate_global_report(reports, output_file=None):
    """Génère le rapport HTML global (toutes les requêtes dans un seul tableau)."""
    flat = []
    for dbms, entries in reports:
        data = {}
        for entry in entries:
            data[entry["label"]] = entry
        flat.append((dbms, data))

    all_labels = collect_labels(flat)
    stats = generate_stats_html(flat)
    table = generate_table_html(all_labels, flat)
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    html = f"""<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Rapport SQL - Corrections</title>
  <style>{CSS}</style>
</head>
<body>
  <h1>Rapport des corrections SQL</h1>
  <p class="subtitle">Comparaison des résultats sur {len(flat)} SGBD</p>
  {stats}
  {table}
  <p class="footer">Généré le {now}</p>
</body>
</html>"""

    if output_file:
        os.makedirs(os.path.dirname(output_file) or ".", exist_ok=True)
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(html)
        print(f"Rapport écrit dans {output_file}", file=sys.stderr)
    else:
        print(html)


# ---------------------------------------------------------------------------
# Rapports par TD
# ---------------------------------------------------------------------------

def generate_td_report_html(td_id, title, reports_data, now):
    """Génère le HTML d'un rapport individuel pour un TD."""
    all_labels = collect_labels(reports_data)
    stats = generate_stats_html(reports_data)
    table = generate_table_html(all_labels, reports_data)

    return f"""<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Rapport SQL - {title}</title>
  <style>{CSS}</style>
</head>
<body>
  <p class="back-link"><a href="index.html">&larr; Retour à l'index</a></p>
  <h1>{title}</h1>
  <p class="subtitle">Résultats des tests SQL pour {td_id}</p>
  {stats}
  {table}
  <p class="footer">Généré le {now}</p>
</body>
</html>"""


def generate_report_index_html(td_order, summary, dbms_names, now, titles=None):
    """Génère le HTML de l'index des rapports par TD.

    Si titles est fourni, les TD sans corrections SQL sont aussi listés.
    """
    # Collecter tous les td_ids connus (SQL + docs)
    all_td_ids = set(td_order)
    if titles:
        all_td_ids.update(titles.keys())

    # Grouper les TDs par ressource
    resources = {}
    resource_order = []
    for td_id in sorted(all_td_ids):
        parts = td_id.split("/")
        resource = parts[0] if len(parts) >= 2 else "global"
        if resource not in resources:
            resources[resource] = []
            resource_order.append(resource)
        resources[resource].append(td_id)

    sections_html = []
    for resource in resource_order:
        label = RESOURCE_LABELS.get(resource, resource)
        items = []
        for td_id in resources[resource]:
            if td_id in summary:
                s = summary[td_id]
                title = s["title"]
                report_file = s["report_file"]
                tested = s["tested"]
                passed = s["pass"]
                pct = passed * 100 // tested if tested > 0 else 0

                if pct == 100:
                    pct_badge = f'<span class="badge badge-ok">Global {pct}%</span>'
                elif pct >= 70:
                    pct_badge = f'<span class="badge badge-warn">Global {pct}%</span>'
                else:
                    pct_badge = f'<span class="badge badge-fail">Global {pct}%</span>'

                # Badges par SGBD
                dbms_badges = ""
                for dbms_key, dbms_s in s["dbms"].items():
                    dbms_tested = dbms_s["tested"]
                    dbms_passed = dbms_s["pass"]
                    dbms_pct = dbms_passed * 100 // dbms_tested if dbms_tested > 0 else 0
                    short = DBMS_SHORT.get(dbms_key, dbms_key)
                    css_class = f"badge-{DBMS_CSS.get(dbms_key, 'oracle')}"
                    if dbms_pct == 100:
                        dbms_badges += f' <span class="badge {css_class}">{short} ✓</span>'
                    else:
                        dbms_badges += f' <span class="badge {css_class}">{short} {dbms_pct}%</span>'

                items.append(
                    f'<li>'
                    f'<a href="{report_file}">{title}</a>'
                    f" {pct_badge}{dbms_badges}"
                    f'<span class="td-stats">{passed}/{tested} tests</span>'
                    f"</li>"
                )
            else:
                title = titles.get(td_id, td_id) if titles else td_id
                items.append(
                    f'<li>'
                    f'<span>{title}</span>'
                    f'<span class="td-stats">Pas de corrections SQL</span>'
                    f"</li>"
                )

        sections_html.append(
            f"<h2>{label}</h2>\n"
            f'<ul class="td-list">\n'
            + "\n".join(items)
            + "\n</ul>"
        )

    global_tested = sum(s["tested"] for s in summary.values())
    global_pass = sum(s["pass"] for s in summary.values())
    global_pct = global_pass * 100 // global_tested if global_tested > 0 else 0

    return f"""<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Rapports SQL - Index</title>
  <style>{CSS}</style>
</head>
<body>
  <h1>Rapports des corrections SQL</h1>
  <p class="subtitle">Comparaison sur {len(dbms_names)} SGBD ({", ".join(dbms_names)}) &mdash; {global_pass}/{global_tested} tests ({global_pct}%)</p>
  {"".join(sections_html)}
  <p class="footer">Généré le {now}</p>
</body>
</html>"""


def generate_per_td_reports(reports, output_dir, titles):
    """Génère les rapports par TD + index + summary.json."""
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    os.makedirs(output_dir, exist_ok=True)

    # Grouper les entrées par (td_id, dbms)
    # Structure cible : {td_id: [(dbms, {label: entry}), ...]}
    td_data = {}   # {td_id: {dbms: {label: entry}}}
    td_order = []

    for dbms, entries in reports:
        _order, grouped = group_by_td(entries)
        for td_id in _order:
            if td_id not in td_data:
                td_data[td_id] = {}
                td_order.append(td_id)
            td_data[td_id][dbms] = grouped[td_id]

    # Collecter les noms de SGBD dans l'ordre d'apparition
    dbms_seen = []
    for dbms, _ in reports:
        if dbms not in dbms_seen:
            dbms_seen.append(dbms)
    dbms_names = [DBMS_LABELS.get(d, d) for d in dbms_seen]

    summary = {}

    for td_id in td_order:
        title = titles.get(td_id, td_id)
        report_file = td_report_filename(td_id)

        # Construire la liste ordonnée (dbms, data) pour ce TD
        reports_data = [(d, td_data[td_id][d]) for d in dbms_seen if d in td_data[td_id]]

        # Générer le rapport HTML
        html = generate_td_report_html(td_id, title, reports_data, now)
        filepath = os.path.join(output_dir, report_file)
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(html)
        print(f"  {report_file}", file=sys.stderr)

        # Statistiques globales pour ce TD (tous SGBD confondus)
        total_all = 0
        pass_all = 0
        error_all = 0
        fail_all = 0
        skip_all = 0
        tested_all = 0
        dbms_stats = {}

        for dbms, data in reports_data:
            s = compute_stats(data)
            dbms_stats[dbms] = s
            total_all += s["total"]
            pass_all += s["pass"]
            error_all += s["error"]
            fail_all += s["fail"]
            skip_all += s["skip"]
            tested_all += s["tested"]

        summary[td_id] = {
            "title":       title,
            "report_file": report_file,
            "total":       total_all,
            "pass":        pass_all,
            "error":       error_all,
            "fail":        fail_all,
            "skip":        skip_all,
            "tested":      tested_all,
            "dbms":        dbms_stats,
        }

    # Index des rapports
    index_html = generate_report_index_html(td_order, summary, dbms_names, now, titles)
    index_path = os.path.join(output_dir, "index.html")
    with open(index_path, "w", encoding="utf-8") as f:
        f.write(index_html)
    print(f"  index.html", file=sys.stderr)

    # summary.json
    summary_path = os.path.join(output_dir, "summary.json")
    with open(summary_path, "w", encoding="utf-8") as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)
    print(f"  summary.json", file=sys.stderr)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Génère un rapport HTML des tests SQL multi-SGBD."
    )
    parser.add_argument("reports", nargs="+", help="Fichiers CSV de résultats")
    parser.add_argument("--output", "-o",
                        help="Fichier HTML de sortie (rapport global unique)")
    parser.add_argument("--output-dir",
                        help="Répertoire de sortie pour les rapports par TD")
    parser.add_argument("--docs-dir",
                        help="Répertoire docs/ pour lire les titres YAML des TD")
    args = parser.parse_args()

    reports = []
    for filename in args.reports:
        if not os.path.exists(filename):
            print(f"Avertissement : fichier introuvable : {filename}",
                  file=sys.stderr)
            continue
        dbms, entries = read_report(filename)
        if dbms and entries:
            reports.append((dbms, entries))
        else:
            print(f"Avertissement : fichier vide ou invalide : {filename}",
                  file=sys.stderr)

    if not reports:
        print("Erreur : aucun fichier de rapport valide trouvé.", file=sys.stderr)
        sys.exit(1)

    titles = read_td_titles(args.docs_dir)

    if args.output_dir:
        print("Génération des rapports par TD :", file=sys.stderr)
        generate_per_td_reports(reports, args.output_dir, titles)

    if args.output:
        generate_global_report(reports, args.output)

    if not args.output_dir and not args.output:
        generate_global_report(reports)


if __name__ == "__main__":
    main()
