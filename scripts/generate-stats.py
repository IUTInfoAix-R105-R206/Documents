#!/usr/bin/env python3
"""Génère une page HTML de statistiques des questions SQL (tags, difficulté).

Scanne les fichiers de correction SQL annotés, agrège les statistiques
et produit une page interactive standalone pour GitHub Pages.

Usage:
    python3 scripts/generate-stats.py --docs-dir docs --output site/stats/index.html
"""

import argparse
import importlib.util
import json
import os
import re
from collections import Counter, defaultdict
from pathlib import Path

# ---------------------------------------------------------------------------
# Import de generate-questions.py (nom avec tiret → importlib)
# ---------------------------------------------------------------------------
_spec = importlib.util.spec_from_file_location(
    "generate_questions",
    os.path.join(os.path.dirname(__file__), "generate-questions.py"),
)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
parse_sql = _mod.parse_sql
VALID_TAGS = _mod.VALID_TAGS


# ---------------------------------------------------------------------------
# Lecture des titres YAML (même pattern que generate-index.py)
# ---------------------------------------------------------------------------

def read_td_titles(docs_dir):
    """Lit les titres YAML depuis les fichiers Markdown des TD."""
    titles = {}
    if not docs_dir:
        return titles
    docs_path = Path(docs_dir)
    for md_file in sorted(docs_path.glob("r*/td*/td*.md")):
        name = md_file.stem
        if "-correction" in name or "-teacher" in name:
            continue
        parts = md_file.relative_to(docs_path).parts
        if len(parts) >= 2:
            td_id = f"{parts[0]}/{parts[1]}"
            if td_id in titles:
                continue
            with open(md_file, encoding="utf-8") as f:
                for line in f:
                    m = re.match(r'^title:\s*"(.+)"', line)
                    if m:
                        titles[td_id] = m.group(1)
                        break
    return titles


# ---------------------------------------------------------------------------
# Collecte des questions
# ---------------------------------------------------------------------------

def collect_questions(docs_dir):
    """Scanne tous les fichiers de correction SQL et collecte les questions."""
    docs_path = Path(docs_dir)
    correction_files = sorted(docs_path.glob("r*/td*/td*-correction.sql"))
    titles = read_td_titles(docs_dir)
    questions = []

    for sql_file in correction_files:
        parts = sql_file.relative_to(docs_path).parts
        td_id = f"{parts[0]}/{parts[1]}"
        td_title = titles.get(td_id, td_id)
        resource = parts[0]
        seen_nums = set()

        parsed = parse_sql(str(sql_file))
        for section in parsed["sections"]:
            for item in section["items"]:
                if item["type"] != "question":
                    continue
                # Dédupliquer : certains fichiers répètent QN pour
                # chaque variante (ex: R1.05 TD6 Q18). On ne garde
                # que la première occurrence (celle avec les annotations).
                if item["num"] in seen_nums:
                    continue
                seen_nums.add(item["num"])
                # Ignorer les en-têtes de groupe sans annotations
                # (ex: Q3 suivi de Q3a, Q3b dans R2.06 TD2).
                if not item.get("tags") and not item.get("difficulty"):
                    continue
                variants = []
                for v in item.get("variants", []):
                    if v.get("sql"):
                        variants.append({
                            "label": v.get("label"),
                            "sql": v["sql"],
                        })
                questions.append({
                    "td_id": td_id,
                    "td_title": td_title,
                    "resource": resource,
                    "num": item["num"],
                    "description": item["description"].split("\n")[0],
                    "difficulty": item.get("difficulty"),
                    "tags": item.get("tags", []),
                    "section": section["name"],
                    "variants": variants,
                })

    return questions, titles


# ---------------------------------------------------------------------------
# Agrégation des statistiques
# ---------------------------------------------------------------------------

DIFFICULTY_LABELS = {1: "Facile", 2: "Moyen", 3: "Difficile"}


def compute_statistics(questions):
    """Calcule les statistiques agrégées."""
    tag_counts = Counter()
    diff_counts = Counter()
    tag_diff_matrix = defaultdict(Counter)
    resources = set()
    td_ids = set()

    for q in questions:
        d = q["difficulty"] or 0
        diff_counts[d] += 1
        resources.add(q["resource"])
        td_ids.add(q["td_id"])
        for t in q["tags"]:
            tag_counts[t] += 1
            tag_diff_matrix[t][d] += 1

    used_tags = {t for t in tag_counts if tag_counts[t] > 0}
    difficulties_with_questions = [d for d in sorted(diff_counts) if d > 0]
    avg_diff = (
        sum(q["difficulty"] for q in questions if q["difficulty"])
        / max(sum(1 for q in questions if q["difficulty"]), 1)
    )

    # Tous les tags : d'abord ceux utilisés par fréquence décroissante,
    # puis ceux à zéro par ordre alphabétique.
    all_tag_counts = tag_counts.most_common()
    unused_tags = sorted(t for t in VALID_TAGS if t not in tag_counts)
    all_tag_counts.extend((t, 0) for t in unused_tags)

    return {
        "tag_counts": all_tag_counts,
        "diff_counts": dict(sorted(diff_counts.items())),
        "tag_diff_matrix": {
            t: dict(v) for t, v in tag_diff_matrix.items()
        },
        "total": len(questions),
        "used_tags": len(used_tags),
        "total_tags": len(VALID_TAGS),
        "num_resources": len(resources),
        "num_tds": len(td_ids),
        "avg_difficulty": round(avg_diff, 1),
        "difficulties": difficulties_with_questions,
    }


# ---------------------------------------------------------------------------
# Génération HTML
# ---------------------------------------------------------------------------

CSS = """\
    body { font-family: sans-serif; max-width: 900px; margin: 2rem auto;
           padding: 0 1rem; color: #333; }
    h1 { font-size: 1.4rem; color: #2c3e50; }
    h2 { font-size: 1.2rem; margin-top: 2rem; color: #2c3e50; }
    h3 { font-size: 1rem; color: #2c3e50; margin-top: 1rem; }
    a { text-decoration: none; color: #0366d6; }
    a:hover { text-decoration: underline; }
    .subtitle { color: #666; font-size: 0.9rem; margin-bottom: 1.5rem; }
    .back-link { margin-bottom: 1.5rem; }
    .footer { margin-top: 2rem; color: #999; font-size: 0.8rem; }
    .stats { display: flex; gap: 1rem; margin-bottom: 1.5rem; flex-wrap: wrap; }
    .stat-box { padding: 0.75rem 1.25rem; border-radius: 6px; background: #f0f4f8;
                 border: 1px solid #d0d7de; text-align: center; min-width: 120px; }
    .stat-box strong { display: block; font-size: 1.3rem; color: #2c3e50; }
    .stat-box small { color: #666; font-size: 0.8rem; }
    .bar-row { display: flex; align-items: center; margin: 0.25rem 0;
               cursor: pointer; padding: 0.15rem 0; border-radius: 3px; }
    .bar-row:hover { background: #f6f8fa; }
    .bar-row.active { background: #e3f2fd; }
    .bar-label { width: 150px; font-size: 0.85rem; text-align: right;
                 padding-right: 0.75rem; flex-shrink: 0; }
    .bar { background: #0366d6; color: white; padding: 0.15rem 0.5rem;
           border-radius: 3px; font-size: 0.8rem; min-width: 25px;
           text-align: right; transition: width 0.3s; }
    .bar-row-zero { opacity: 0.5; }
    .bar-zero { font-size: 0.8rem; color: #999; }
    .difficulty-chart { display: flex; gap: 2rem; align-items: flex-end;
                        height: 180px; margin: 1rem 0; justify-content: center; }
    .diff-col { display: flex; flex-direction: column; align-items: center;
                cursor: pointer; width: 120px; }
    .diff-col:hover .diff-bar { opacity: 0.8; }
    .diff-col.active .diff-bar { box-shadow: 0 0 0 3px #2c3e50; }
    .diff-bar { width: 80px; border-radius: 4px 4px 0 0; display: flex;
                align-items: flex-end; justify-content: center;
                padding-bottom: 0.3rem; color: white; font-weight: bold;
                font-size: 0.95rem; transition: height 0.3s; }
    .diff-1 { background: #28a745; }
    .diff-2 { background: #ffc107; color: #333; }
    .diff-3 { background: #dc3545; }
    .diff-label { margin-top: 0.5rem; font-size: 0.85rem; color: #666; }
    .matrix-table { border-collapse: collapse; font-size: 0.9rem; margin: 1rem 0; }
    .matrix-table th { background: #2c3e50; color: white; padding: 0.4rem 0.75rem; }
    .matrix-table td { padding: 0.3rem 0.75rem; border: 1px solid #e1e4e8;
                       text-align: center; }
    .matrix-table td.clickable { cursor: pointer; }
    .matrix-table td.clickable:hover { background: #e3f2fd; }
    .matrix-table tr:hover { background: #f6f8fa; }
    .matrix-table .tag-label { text-align: left; font-size: 0.85rem; }
    .matrix-table .total-col { font-weight: bold; background: #f0f4f8; }
    .question-card { padding: 0.5rem 0; border-bottom: 1px solid #e1e4e8; }
    .question-header { display: flex; align-items: center; gap: 0.5rem; }
    .question-id { font-family: monospace; font-size: 0.85rem; font-weight: bold; }
    .question-desc { margin: 0.25rem 0; font-size: 0.9rem; color: #333; }
    .question-tags { display: flex; gap: 0.3rem; flex-wrap: wrap; margin-top: 0.2rem; }
    .tag-badge { display: inline-block; font-size: 0.7rem; padding: 0.1rem 0.4rem;
                 border-radius: 3px; background: #e3f2fd; color: #1565c0;
                 border: 1px solid #42a5f5; cursor: pointer; }
    .tag-badge:hover { background: #bbdefb; }
    .badge-diff { display: inline-block; font-size: 0.7rem; padding: 0.1rem 0.4rem;
                  border-radius: 3px; }
    .badge-diff-1 { background: #d4edda; color: #155724; border: 1px solid #28a745; }
    .badge-diff-2 { background: #fff3cd; color: #856404; border: 1px solid #ffc107; }
    .badge-diff-3 { background: #f8d7da; color: #721c24; border: 1px solid #dc3545; }
    #filter-controls { margin: 0.5rem 0; display: flex; gap: 0.5rem;
                       align-items: center; flex-wrap: wrap; }
    #filter-controls button { padding: 0.3rem 0.75rem; border: 1px solid #d0d7de;
                              border-radius: 4px; background: #f0f4f8;
                              cursor: pointer; font-size: 0.85rem; }
    #filter-controls button:hover { background: #e1e4e8; }
    #filter-controls select { padding: 0.3rem; border: 1px solid #d0d7de;
                              border-radius: 4px; font-size: 0.85rem; }
    .hidden { display: none; }
    .question-card { cursor: pointer; }
    .question-card:hover { background: #f6f8fa; }
    .question-variants { display: none; margin: 0.4rem 0 0.2rem 0; }
    .question-variants.open { display: block; }
    .variant-block { margin-bottom: 0.5rem; }
    .variant-label { font-size: 0.8rem; font-weight: bold; color: #555; margin-bottom: 0.2rem; }
    .variant-sql { background: #f6f8fa; border: 1px solid #e1e4e8; border-radius: 4px;
                   padding: 0.5rem; font-family: monospace; font-size: 0.8rem;
                   white-space: pre-wrap; overflow-x: auto; color: #24292e; }
    .toggle-indicator { font-size: 0.7rem; color: #888; margin-left: auto; }
    .td-nav { margin: 0.75rem 0; display: flex; gap: 0.4rem; flex-wrap: wrap; }
    .td-nav-item { display: inline-block; font-size: 0.8rem; padding: 0.2rem 0.5rem;
                   border-radius: 3px; border: 1px solid #d0d7de; background: #f0f4f8; }
    .td-nav-item:hover { background: #e1e4e8; text-decoration: none; }
    .td-nav-current { background: #2c3e50; color: white; border-color: #2c3e50; }"""

JS = """\
let currentFilter = { tag: null, difficulty: null, tdId: null };

function selectTag(tag) {
    currentFilter.tag = (currentFilter.tag === tag) ? null : tag;
    currentFilter.difficulty = null;
    applyFilter();
}

function selectDifficulty(d) {
    currentFilter.difficulty = (currentFilter.difficulty === d) ? null : d;
    currentFilter.tag = null;
    applyFilter();
}

function selectCell(tag, diff) {
    if (currentFilter.tag === tag && currentFilter.difficulty === diff) {
        currentFilter.tag = null;
        currentFilter.difficulty = null;
    } else {
        currentFilter.tag = tag;
        currentFilter.difficulty = diff;
    }
    applyFilter();
}

function clearFilter() {
    currentFilter = { tag: null, difficulty: null, tdId: null };
    document.getElementById('td-filter').value = '';
    applyFilter();
}

function applyTdFilter() {
    currentFilter.tdId = document.getElementById('td-filter').value || null;
    applyFilter();
}

function applyFilter() {
    let filtered = DATA.questions;
    if (currentFilter.tag) {
        filtered = filtered.filter(q => q.tags.includes(currentFilter.tag));
    }
    if (currentFilter.difficulty) {
        filtered = filtered.filter(q => q.difficulty === currentFilter.difficulty);
    }
    if (currentFilter.tdId) {
        filtered = filtered.filter(q => q.td_id === currentFilter.tdId);
    }

    // Update active states
    document.querySelectorAll('.bar-row').forEach(el => {
        el.classList.toggle('active', el.dataset.tag === currentFilter.tag);
    });
    document.querySelectorAll('.diff-col').forEach(el => {
        el.classList.toggle('active',
            parseInt(el.dataset.difficulty) === currentFilter.difficulty);
    });

    // Update label
    let parts = [];
    if (currentFilter.tag) parts.push(currentFilter.tag);
    if (currentFilter.difficulty) parts.push(DIFF_LABELS[currentFilter.difficulty]);
    if (currentFilter.tdId) parts.push(currentFilter.tdId);
    const label = parts.length > 0
        ? parts.join(' + ') + ' \\u2014 ' + filtered.length + ' question(s)'
        : filtered.length + ' question(s)';
    document.getElementById('filter-label').textContent = label;

    renderQuestions(filtered);
    document.getElementById('filter-controls').classList.remove('hidden');
}

const DIFF_LABELS = { 1: 'Facile', 2: 'Moyen', 3: 'Difficile' };
const DIFF_STARS = { 1: '\\u2605', 2: '\\u2605\\u2605', 3: '\\u2605\\u2605\\u2605' };

function renderQuestions(questions) {
    const groups = {};
    const order = [];
    questions.forEach(q => {
        if (!groups[q.td_id]) { groups[q.td_id] = []; order.push(q.td_id); }
        groups[q.td_id].push(q);
    });

    let html = '';
    for (const tdId of order) {
        const qs = groups[tdId];
        html += '<h3>' + qs[0].td_title + '</h3>';
        for (const q of qs) {
            const d = q.difficulty || 0;
            const diffBadge = d > 0
                ? '<span class="badge-diff badge-diff-' + d + '">'
                  + DIFF_STARS[d] + ' ' + DIFF_LABELS[d] + '</span>'
                : '';
            const tagBadges = q.tags.map(t =>
                '<span class="tag-badge" onclick="selectTag(\\'' + t + '\\')">'
                + t + '</span>'
            ).join('');
            const qId = q.td_id.replace('/', '-') + '-q' + q.num;
            const hasVariants = q.variants && q.variants.length > 0;
            const toggle = hasVariants
                ? '<span class="toggle-indicator">\\u25B6 SQL</span>' : '';
            let variantsHtml = '';
            if (hasVariants) {
                variantsHtml = '<div class="question-variants" id="' + qId + '">';
                for (const v of q.variants) {
                    const lbl = v.label ? '<div class="variant-label">' + escapeHtml(v.label) + '</div>' : '';
                    variantsHtml += '<div class="variant-block">' + lbl
                        + '<pre class="variant-sql">' + escapeHtml(v.sql) + '</pre></div>';
                }
                variantsHtml += '</div>';
            }
            const onclick = hasVariants
                ? ' onclick="toggleVariants(\\'' + qId + '\\', this)"' : '';
            html += '<div class="question-card"' + onclick + '>'
                + '<div class="question-header">'
                + '<span class="question-id">'
                + q.resource.toUpperCase() + ' '
                + q.td_id.split('/')[1].toUpperCase()
                + ' \\u2014 Q' + q.num + '</span> '
                + diffBadge + toggle
                + '</div>'
                + '<p class="question-desc">' + escapeHtml(q.description) + '</p>'
                + '<div class="question-tags">' + tagBadges + '</div>'
                + variantsHtml
                + '</div>';
        }
    }
    document.getElementById('question-list').innerHTML = html || '<p>Aucune question.</p>';
}

function escapeHtml(s) {
    const d = document.createElement('div');
    d.textContent = s;
    return d.innerHTML;
}

function toggleVariants(id, card) {
    const el = document.getElementById(id);
    if (!el) return;
    const open = el.classList.toggle('open');
    const indicator = card.querySelector('.toggle-indicator');
    if (indicator) indicator.textContent = open ? '\\u25BC SQL' : '\\u25B6 SQL';
}

document.addEventListener('DOMContentLoaded', function() {
    applyFilter();
});"""


def _render_stat_boxes(stats, td_links=None):
    """Génère les stat-boxes HTML."""
    total = stats["total"]
    avg_diff = stats["avg_difficulty"]
    used_tags = stats["used_tags"]
    total_tags = stats["total_tags"]
    num_tds = stats["num_tds"]

    boxes = (
        f'<div class="stat-box"><strong>{total}</strong>'
        f'<small>Questions</small></div>'
        f'<div class="stat-box"><strong>{avg_diff}</strong>'
        f'<small>Difficulté moy.</small></div>'
        f'<div class="stat-box"><strong>{used_tags}/{total_tags}</strong>'
        f'<small>Tags utilisés</small></div>'
    )
    if num_tds > 1:
        num_res = stats["num_resources"]
        boxes += (
            f'<div class="stat-box"><strong>{num_tds}</strong>'
            f'<small>TD ({num_res} ressources)</small></div>'
        )
    return f'<div class="stats">{boxes}</div>'


def _render_bar_chart(tag_counts):
    """Génère le graphique de barres des tags."""
    max_count = tag_counts[0][1] if tag_counts else 1
    rows = []
    for tag, count in tag_counts:
        if count > 0:
            pct = count * 100 // max_count
            rows.append(
                f'<div class="bar-row" data-tag="{tag}" '
                f'onclick="selectTag(\'{tag}\')">'
                f'<span class="bar-label">{tag}</span>'
                f'<div class="bar" style="width: {max(pct, 3)}%;">'
                f'{count}</div></div>'
            )
        else:
            rows.append(
                f'<div class="bar-row bar-row-zero" data-tag="{tag}" '
                f'onclick="selectTag(\'{tag}\')">'
                f'<span class="bar-label">{tag}</span>'
                f'<span class="bar-zero">0</span></div>'
            )
    return "\n".join(rows)


def _render_diff_chart(diff_counts, difficulties):
    """Génère l'histogramme de difficulté."""
    max_count = max(
        (diff_counts.get(d, 0) for d in difficulties), default=1
    )
    cols = []
    for d in difficulties:
        count = diff_counts.get(d, 0)
        height_pct = count * 100 // max(max_count, 1)
        label = DIFFICULTY_LABELS.get(d, str(d))
        cols.append(
            f'<div class="diff-col" data-difficulty="{d}" '
            f'onclick="selectDifficulty({d})">'
            f'<div class="diff-bar diff-{d}" '
            f'style="height: {max(height_pct, 5)}%;">{count}</div>'
            f'<span class="diff-label">{label}</span></div>'
        )
    return "\n".join(cols)


def _render_matrix(tag_counts, tag_diff_matrix, difficulties):
    """Génère la matrice tag×difficulté."""
    rows = []
    for tag, count in tag_counts:
        cells = f'<td class="tag-label">{tag}</td>'
        for d in difficulties:
            n = tag_diff_matrix.get(tag, {}).get(d, 0)
            cls = "clickable" if n > 0 else ""
            click = (
                f'onclick="selectCell(\'{tag}\', {d})"' if n > 0 else ""
            )
            cells += f'<td class="{cls}" {click}>{n or ""}</td>'
        cells += f'<td class="total-col">{count}</td>'
        rows.append(f"<tr>{cells}</tr>")

    diff_headers = "".join(
        f"<th>{DIFFICULTY_LABELS.get(d, d)}</th>" for d in difficulties
    )
    return diff_headers, "\n".join(rows)


def _render_td_nav(td_list, current_td_id=None):
    """Génère la navigation entre TD (pour les pages par-TD)."""
    items = []
    for td_id, td_title, filename in td_list:
        label = td_id.upper().replace("/", " ")
        if td_id == current_td_id:
            items.append(
                f'<span class="td-nav-item td-nav-current">'
                f'{label}</span>'
            )
        else:
            items.append(
                f'<a href="{filename}" class="td-nav-item">'
                f'{label}</a>'
            )
    return '<div class="td-nav">' + " ".join(items) + '</div>'


def generate_html(questions, stats, title=None, subtitle=None,
                  back_link=None, back_text=None, td_filter=True,
                  td_nav_html=""):
    """Génère une page HTML de statistiques (globale ou par-TD)."""
    tag_counts = stats["tag_counts"]
    diff_counts = stats["diff_counts"]
    difficulties = stats["difficulties"]
    tag_diff_matrix = stats["tag_diff_matrix"]

    if not title:
        title = "Statistiques des questions SQL"
    if not subtitle:
        total = stats["total"]
        num_tds = stats["num_tds"]
        num_res = stats["num_resources"]
        subtitle = (
            f"{total} questions &mdash; {num_tds} TD "
            f"&mdash; {num_res} ressources"
        )
    if not back_link:
        back_link = "../index.html"
    if not back_text:
        back_text = "Retour à l'index"

    page_title = title.replace("&mdash;", "—")
    stat_boxes = _render_stat_boxes(stats)
    bar_chart = _render_bar_chart(tag_counts)
    diff_chart = _render_diff_chart(diff_counts, difficulties)
    diff_headers, matrix_body = _render_matrix(
        tag_counts, tag_diff_matrix, difficulties,
    )

    # TD filter (only on global page)
    td_filter_html = ""
    if td_filter:
        td_ids = sorted({q["td_id"] for q in questions})
        td_options = "".join(
            f'<option value="{td}">{td}</option>' for td in td_ids
        )
        td_filter_html = (
            f'<select id="td-filter" onchange="applyTdFilter()">'
            f'<option value="">Tous les TD</option>'
            f'{td_options}</select>'
        )

    data_json = json.dumps(
        {"questions": questions}, ensure_ascii=False, separators=(",", ":")
    )

    return f"""<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Statistiques — {page_title}</title>
  <style>{CSS}</style>
</head>
<body>
  <p class="back-link"><a href="{back_link}">&larr; {back_text}</a></p>
  <h1>{title}</h1>
  <p class="subtitle">{subtitle}</p>
  {td_nav_html}

  {stat_boxes}

  <h2>Répartition par difficulté</h2>
  <div class="difficulty-chart">
    {diff_chart}
  </div>

  <h2>Matrice tags &times; difficulté</h2>
  <table class="matrix-table">
    <thead><tr><th>Tag</th>{diff_headers}<th>Total</th></tr></thead>
    <tbody>
      {matrix_body}
    </tbody>
  </table>

  <h2>Fréquence des tags</h2>
  <div class="chart-container">
    {bar_chart}
  </div>

  <h2>Questions <span id="filter-label"></span></h2>
  <div id="filter-controls" class="hidden">
    <button onclick="clearFilter()">Tout afficher</button>
    {td_filter_html}
  </div>
  <div id="question-list"></div>

  <p class="footer">IUT d'Aix-Marseille &mdash; Département Informatique</p>

  <script>
  const DATA = {data_json};
  {JS}
  </script>
</body>
</html>"""


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def td_report_filename(td_id):
    """Convertit un td_id (ex: r2.06/td3) en nom de fichier."""
    return td_id.replace("/", "-") + ".html"


def generate_per_td_pages(questions, output_dir):
    """Génère les pages de statistiques par TD."""
    # Grouper les questions par td_id
    td_groups = {}
    td_order = []
    for q in questions:
        td_id = q["td_id"]
        if td_id not in td_groups:
            td_groups[td_id] = []
            td_order.append(td_id)
        td_groups[td_id].append(q)

    # Préparer la navigation
    td_list = [
        (td_id, td_groups[td_id][0]["td_title"], td_report_filename(td_id))
        for td_id in td_order
    ]

    for td_id in td_order:
        td_questions = td_groups[td_id]
        td_title = td_questions[0]["td_title"]
        td_stats = compute_statistics(td_questions)
        filename = td_report_filename(td_id)
        nav_html = _render_td_nav(td_list, current_td_id=td_id)

        html = generate_html(
            td_questions, td_stats,
            title=f"{td_title}",
            subtitle=f"{td_stats['total']} questions &mdash; "
                     f"{td_id.upper().replace('/', ' ')}",
            back_link="index.html",
            back_text="Vue globale",
            td_filter=False,
            td_nav_html=nav_html,
        )

        filepath = os.path.join(output_dir, filename)
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(html)
        print(f"  {filename} ({td_stats['total']} questions)")


def main():
    parser = argparse.ArgumentParser(
        description="Génère la page de statistiques des questions SQL."
    )
    parser.add_argument(
        "--docs-dir", default="docs",
        help="Répertoire docs/ contenant les TD (défaut: docs)",
    )
    parser.add_argument(
        "--output", "-o", required=True,
        help="Fichier HTML de sortie (ex: site/stats/index.html)",
    )
    args = parser.parse_args()

    questions, _titles = collect_questions(args.docs_dir)
    stats = compute_statistics(questions)
    output_dir = os.path.dirname(args.output) or "."
    os.makedirs(output_dir, exist_ok=True)

    # Liens vers les pages par TD dans la vue globale
    td_ids = sorted({q["td_id"] for q in questions})
    td_links = []
    for td_id in td_ids:
        td_qs = [q for q in questions if q["td_id"] == td_id]
        td_title = td_qs[0]["td_title"]
        filename = td_report_filename(td_id)
        n = len(td_qs)
        label = td_id.upper().replace("/", " ")
        td_links.append(
            f'<a href="{filename}" class="td-nav-item">'
            f'{label} ({n})</a>'
        )
    td_nav_html = (
        '<h2>Par TD</h2>'
        '<div class="td-nav">' + " ".join(td_links) + '</div>'
    )

    # Page globale
    html = generate_html(
        questions, stats, td_nav_html=td_nav_html,
    )
    with open(args.output, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"Statistiques écrites dans {args.output} "
          f"({stats['total']} questions)")

    # Pages par TD
    generate_per_td_pages(questions, output_dir)


if __name__ == "__main__":
    main()
