#!/usr/bin/env python3
"""Génère la page d'index HTML pour GitHub Pages.

Scanne les PDF disponibles, lit les titres des TD depuis les sources Markdown,
et génère un index riche avec liens vers sujets, corrigés et rapports de test.

Usage:
  python3 scripts/generate-index.py \\
    --docs-dir docs \\
    --pdf-dir site/pdfs \\
    --reports-summary site/reports/summary.json \\
    --output site/index.html
"""

import argparse
import json
import os
import re
from pathlib import Path

RESOURCE_LABELS = {
    "r1.05": "R1.05 — Introduction aux bases de données et SQL",
    "r2.06": "R2.06 — Exploitation d'une base de données",
}

GUIDE_TITLES = {
    "guide-bonnes-pratiques-sql": "Guide de bonnes pratiques SQL",
}

RESOURCE_ORDER = ["r1.05", "r2.06"]

CSS = """\
    body { font-family: sans-serif; max-width: 720px; margin: 2rem auto;
           padding: 0 1rem; color: #333; }
    h1 { font-size: 1.4rem; color: #2c3e50; }
    h2 { font-size: 1.2rem; margin-top: 1.5rem; color: #2c3e50; }
    ul { list-style: none; padding: 0; }
    li { margin: 0.5rem 0; padding: 0.4rem 0; }
    a { text-decoration: none; color: #0366d6; }
    a:hover { text-decoration: underline; }
    .td-title { font-weight: 500; }
    .td-links { font-size: 0.85rem; color: #666; margin-left: 0.25rem; }
    .td-links a { color: #586069; }
    .td-links a:hover { color: #0366d6; }
    .badge { display: inline-block; font-size: 0.7rem; padding: 0.1rem 0.4rem;
             border-radius: 3px; margin-left: 0.5rem; vertical-align: middle; }
    .badge-oracle { background: #fff3cd; color: #856404; border: 1px solid #ffc107; }
    .badge-ok { background: #d4edda; color: #155724; border: 1px solid #28a745; }
    .badge-warn { background: #fff3cd; color: #856404; border: 1px solid #ffc107; }
    .badge-fail { background: #f8d7da; color: #721c24; border: 1px solid #dc3545; }
    .section-reports { margin-top: 2rem; }
    .footer { margin-top: 2rem; color: #999; font-size: 0.8rem; }"""


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


def scan_pdfs(pdf_dir):
    """Scanne le répertoire de PDFs et retourne les TD disponibles.

    Retourne {td_id: {"subject": path_rel, "correction": path_rel}}.
    Les chemins sont relatifs au pdf_dir parent (pour les liens HTML).
    """
    tds = {}
    if not pdf_dir or not os.path.isdir(pdf_dir):
        return tds
    pdf_path = Path(pdf_dir)
    for pdf in sorted(pdf_path.glob("r*/*.pdf")):
        rel = pdf.relative_to(pdf_path)
        parts = rel.parts  # ("r2.06", "td3.pdf")
        if len(parts) != 2:
            continue
        resource = parts[0]
        filename = parts[1]
        name = filename.removesuffix(".pdf")

        # Ignorer les PDF qui ne correspondent pas au pattern tdN, tdN-correction ou tdN-teacher
        if not re.match(r"^td\d+(-correction|-teacher)?$", name):
            continue

        if name.endswith("-teacher"):
            td_name = name.removesuffix("-teacher")
            td_id = f"{resource}/{td_name}"
            tds.setdefault(td_id, {})["teacher"] = f"pdfs/{rel}"
        elif name.endswith("-correction"):
            td_name = name.removesuffix("-correction")
            td_id = f"{resource}/{td_name}"
            tds.setdefault(td_id, {})["correction"] = f"pdfs/{rel}"
        else:
            td_id = f"{resource}/{name}"
            tds.setdefault(td_id, {})["subject"] = f"pdfs/{rel}"

    return tds


def scan_guides(pdf_dir):
    """Scanne les PDF de guides pratiques (fichiers à la racine de pdf_dir)."""
    guides = {}
    if not pdf_dir or not os.path.isdir(pdf_dir):
        return guides
    pdf_path = Path(pdf_dir)
    for pdf in sorted(pdf_path.glob("*.pdf")):
        name = pdf.stem
        if name in GUIDE_TITLES:
            guides[name] = {
                "title": GUIDE_TITLES[name],
                "path": f"pdfs/{pdf.name}",
            }
    return guides


def read_summary(summary_path):
    """Lit le summary.json des rapports de test (optionnel)."""
    if not summary_path or not os.path.isfile(summary_path):
        return {}
    with open(summary_path, encoding="utf-8") as f:
        return json.load(f)


def generate_index(titles, pdfs, summary, guides, output_file):
    """Génère la page d'index HTML."""
    # Collecter tous les td_ids connus
    all_td_ids = set()
    all_td_ids.update(pdfs.keys())
    all_td_ids.update(summary.keys())

    # Grouper par ressource
    resources = {}
    for td_id in all_td_ids:
        parts = td_id.split("/")
        resource = parts[0] if len(parts) >= 2 else "other"
        resources.setdefault(resource, []).append(td_id)

    # Trier les TDs dans chaque ressource
    for resource in resources:
        resources[resource].sort()

    sections_html = []
    for resource in RESOURCE_ORDER:
        if resource not in resources:
            continue
        label = RESOURCE_LABELS.get(resource, resource)
        items = []

        for td_id in resources[resource]:
            title = titles.get(td_id, td_id)
            pdf_info = pdfs.get(td_id, {})
            report_info = summary.get(td_id)

            # Lien principal (sujet PDF ou juste le titre)
            if "subject" in pdf_info:
                title_html = f'<a href="{pdf_info["subject"]}" class="td-title">{title}</a>'
            else:
                title_html = f'<span class="td-title">{title}</span>'

            # Liens secondaires
            links = []
            if "correction" in pdf_info:
                links.append(f'<a href="{pdf_info["correction"]}">Corrigé</a>')
            if "teacher" in pdf_info:
                links.append(f'<a href="{pdf_info["teacher"]}">Corrigé enseignant</a>')
            if report_info:
                report_file = report_info.get("report_file", "")
                if report_file:
                    links.append(f'<a href="reports/{report_file}">Rapport de test</a>')

            links_html = ""
            if links:
                links_html = f' <span class="td-links">({", ".join(links)})</span>'

            # Badges
            badges = ""
            if report_info:
                total = report_info.get("total", 0)
                passed = report_info.get("pass", 0)
                pct = passed * 100 // total if total > 0 else 0
                if report_info.get("has_oracle_only"):
                    badges += '<span class="badge badge-oracle">Oracle-only</span>'

            items.append(f"<li>{title_html}{links_html}{badges}</li>")

        sections_html.append(
            f"<h2>{label}</h2>\n<ul>\n" + "\n".join(items) + "\n</ul>"
        )

    # Ajouter les ressources non prévues dans RESOURCE_ORDER
    for resource in sorted(resources.keys()):
        if resource in RESOURCE_ORDER:
            continue
        label = RESOURCE_LABELS.get(resource, resource)
        items = []
        for td_id in resources[resource]:
            title = titles.get(td_id, td_id)
            items.append(f"<li>{title}</li>")
        sections_html.append(
            f"<h2>{label}</h2>\n<ul>\n" + "\n".join(items) + "\n</ul>"
        )

    # Section guides pratiques
    guides_section = ""
    if guides:
        items = []
        for guide_id in sorted(guides.keys()):
            info = guides[guide_id]
            items.append(
                f'<li><a href="{info["path"]}">{info["title"]}</a></li>'
            )
        guides_section = (
            "<h2>Guides pratiques</h2>\n<ul>\n"
            + "\n".join(items)
            + "\n</ul>"
        )

    # Section rapport global
    reports_section = ""
    if summary:
        reports_section = (
            '<div class="section-reports">\n'
            "<h2>Tests SQL</h2>\n<ul>\n"
            '<li><a href="reports/">Rapport multi-SGBD (PostgreSQL, SQLite, Oracle)</a></li>\n'
            "</ul>\n</div>"
        )

    # Section statistiques
    stats_section = (
        '<div class="section-reports">\n'
        "<h2>Statistiques</h2>\n<ul>\n"
        '<li><a href="stats/">Statistiques des questions SQL '
        "(tags, difficulté)</a></li>\n"
        "</ul>\n</div>"
    )

    html = f"""<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Bases de données — TD</title>
  <style>{CSS}</style>
</head>
<body>
  <h1>Bases de données — Sujets de TD</h1>
  {"".join(sections_html)}
  {guides_section}
  {reports_section}
  {stats_section}
  <p class="footer">IUT d'Aix-Marseille — Département Informatique</p>
</body>
</html>"""

    os.makedirs(os.path.dirname(output_file) or ".", exist_ok=True)
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"Index écrit dans {output_file}")


def main():
    parser = argparse.ArgumentParser(
        description="Génère la page d'index HTML pour GitHub Pages."
    )
    parser.add_argument("--docs-dir", default="docs",
                        help="Répertoire docs/ pour les titres YAML (défaut: docs)")
    parser.add_argument("--pdf-dir",
                        help="Répertoire contenant les PDF (ex: site/pdfs)")
    parser.add_argument("--reports-summary",
                        help="Chemin vers summary.json des rapports de test")
    parser.add_argument("--output", "-o", required=True,
                        help="Fichier HTML de sortie")
    args = parser.parse_args()

    titles = read_td_titles(args.docs_dir)
    pdfs = scan_pdfs(args.pdf_dir)
    guides = scan_guides(args.pdf_dir)
    summary = read_summary(args.reports_summary)

    generate_index(titles, pdfs, summary, guides, args.output)


if __name__ == "__main__":
    main()
