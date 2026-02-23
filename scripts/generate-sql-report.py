#!/usr/bin/env python3
"""Génère un rapport HTML comparant les résultats de tests SQL sur plusieurs SGBD.

Usage: python3 generate-sql-report.py [--output FILE] results-DBMS.csv ...

Format CSV attendu (séparateur ';') :
  label;dbms;status;expected_cols;expected_rows;actual_cols;actual_rows
"""

import sys
import csv
import os
import argparse
from datetime import datetime, timezone

DBMS_LABELS = {
    "postgres": "PostgreSQL",
    "sqlite":   "SQLite",
    "oracle":   "Oracle",
}

STATUS_ICONS = {
    "pass":  "✓",
    "fail":  "✗",
    "skip":  "⊘",
    "error": "!",
}


def read_report(filename):
    """Lit un fichier CSV de résultats ; retourne (dbms, {label: entry})."""
    data = {}
    dbms = None
    with open(filename, newline="", encoding="utf-8") as f:
        reader = csv.reader(f, delimiter=";")
        next(reader)  # skip header
        for row in reader:
            if len(row) < 7:
                continue
            label, d, status, exp_cols, exp_rows, actual_cols, actual_rows = row[:7]
            dbms = d
            data[label] = {
                "status":       status,
                "exp_cols":     exp_cols,
                "exp_rows":     exp_rows,
                "actual_cols":  actual_cols,
                "actual_rows":  actual_rows,
            }
    return dbms, data


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


def generate_html(reports, output_file=None):
    """Génère le rapport HTML à partir des données de plusieurs SGBD."""
    # Collecter tous les labels dans l'ordre d'apparition
    all_labels = []
    seen = set()
    for _dbms, data in reports:
        for label in data:
            if label not in seen:
                all_labels.append(label)
                seen.add(label)

    dbms_list = [d for d, _ in reports]
    dbms_names = [DBMS_LABELS.get(d, d) for d in dbms_list]

    # Statistiques par SGBD
    stats_html_parts = []
    for dbms, data in reports:
        total = len(data)
        passed = sum(1 for v in data.values() if v["status"] == "pass")
        errors = sum(1 for v in data.values() if v["status"] == "error")
        pct = passed * 100 // total if total > 0 else 0
        label = DBMS_LABELS.get(dbms, dbms)
        stats_html_parts.append(
            f'<div class="stat-box">'
            f"<strong>{label}</strong><br>"
            f'<span class="pass">{passed} ✓</span> / {total}'
            f" ({pct}%)"
            + (f'<br><small class="error">{errors} erreur(s) SQL</small>' if errors else "")
            + "</div>"
        )
    stats_html = "".join(stats_html_parts)

    # En-tête de tableau
    header_cells = "<th>Requête</th><th>Attendu</th>"
    for name in dbms_names:
        header_cells += f"<th>{name}</th>"

    # Lignes du tableau
    rows_html = []
    for label in all_labels:
        # Récupérer la valeur attendue depuis n'importe quel SGBD
        expected = "—"
        for _dbms, data in reports:
            if label in data:
                e = data[label]
                expected = f"{e['exp_cols']}c × {e['exp_rows']}r"
                break

        cells = f'<td class="label">{label}</td>'
        cells += f'<td class="expected">{expected}</td>'
        for _dbms, data in reports:
            if label in data:
                cells += cell_html(data[label])
            else:
                cells += '<td class="missing">—</td>'
        rows_html.append(f"<tr>{cells}</tr>")

    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    html = f"""<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Rapport SQL — Corrections</title>
  <style>
    body {{ font-family: sans-serif; margin: 2rem; color: #333; }}
    h1 {{ color: #2c3e50; margin-bottom: 0.25rem; }}
    .subtitle {{ color: #666; margin-bottom: 1.5rem; font-size: 0.9rem; }}
    .stats {{ display: flex; gap: 1rem; margin-bottom: 1.5rem; flex-wrap: wrap; }}
    .stat-box {{ padding: 0.75rem 1.25rem; border-radius: 6px; background: #f0f4f8;
                 border: 1px solid #d0d7de; text-align: center; min-width: 130px; }}
    table {{ border-collapse: collapse; width: 100%; font-size: 0.9rem; }}
    th {{ background: #2c3e50; color: white; padding: 0.5rem 0.75rem; text-align: left; }}
    td {{ padding: 0.4rem 0.75rem; border-bottom: 1px solid #e1e4e8; vertical-align: middle; }}
    tr:hover {{ background: #f6f8fa; }}
    td.label {{ font-family: monospace; font-size: 0.85rem; }}
    td.expected {{ color: #666; font-size: 0.85rem; white-space: nowrap; }}
    td.pass {{ color: #1a7f37; font-weight: bold; text-align: center; }}
    td.fail {{ color: #cf222e; text-align: center; }}
    td.skip {{ color: #9a6700; text-align: center; }}
    td.error {{ color: #cf222e; font-style: italic; text-align: center; font-size: 0.85rem; }}
    td.missing {{ color: #999; text-align: center; }}
    .pass {{ color: #1a7f37; }}
    .error {{ color: #cf222e; }}
    small {{ font-weight: normal; font-size: 0.8rem; }}
    .footer {{ margin-top: 1.5rem; color: #666; font-size: 0.8rem; }}
  </style>
</head>
<body>
  <h1>Rapport des corrections SQL</h1>
  <p class="subtitle">Comparaison des résultats sur {len(reports)} SGBD</p>
  <div class="stats">{stats_html}</div>
  <table>
    <thead><tr>{header_cells}</tr></thead>
    <tbody>
      {"".join(rows_html)}
    </tbody>
  </table>
  <p class="footer">Généré le {now}</p>
</body>
</html>"""

    if output_file:
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(html)
        print(f"Rapport écrit dans {output_file}", file=sys.stderr)
    else:
        print(html)


def main():
    parser = argparse.ArgumentParser(
        description="Génère un rapport HTML des tests SQL multi-SGBD."
    )
    parser.add_argument("reports", nargs="+", help="Fichiers CSV de résultats")
    parser.add_argument("--output", "-o", help="Fichier HTML de sortie")
    args = parser.parse_args()

    reports = []
    for filename in args.reports:
        if not os.path.exists(filename):
            print(f"Avertissement : fichier introuvable : {filename}", file=sys.stderr)
            continue
        dbms, data = read_report(filename)
        if dbms and data:
            reports.append((dbms, data))
        else:
            print(f"Avertissement : fichier vide ou invalide : {filename}", file=sys.stderr)

    if not reports:
        print("Erreur : aucun fichier de rapport valide trouvé.", file=sys.stderr)
        sys.exit(1)

    generate_html(reports, args.output)


if __name__ == "__main__":
    main()
