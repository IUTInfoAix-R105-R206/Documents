#!/usr/bin/env python3
"""Génère un Markdown de questions de TD depuis un fichier SQL de correction annoté.

Usage:
    python3 generate-questions.py [OPTIONS] CORRECTION_SQL

Options:
    --mode subject|correction   Mode de génération (défaut: subject)
    --template TEMPLATE.md      Fichier Markdown avec bloc ::: questions à remplacer
    --output FILE               Fichier de sortie (défaut: stdout)

Le parsing des annotations (`-- QN - c:X, t:Y`, `@section`, `@difficulty`, `@tags`,
variantes `PROMPT`, …) et le formatage du résultat attendu sont fournis par le
module partagé `td_correction`.
"""

import re
import sys
import argparse

from td_correction import parse_sql, format_expected, _strip_noqa


# ---------------------------------------------------------------------------
# Génération Markdown
# ---------------------------------------------------------------------------

def _render_remark(remark, mode, out):
    """Rend une remarque en Markdown si le mode le permet."""
    rtype = remark['type']
    if rtype == 'remark' and mode in ('correction', 'teacher'):
        out.append('::: remarques')
        out.append(remark['text'])
        out.append(':::')
        out.append('')
    elif rtype == 'remark_teacher' and mode == 'teacher':
        out.append('::: remarques-enseignant')
        out.append(remark['text'])
        out.append(':::')
        out.append('')


def generate_markdown(parsed, mode='subject'):
    """Génère le Markdown des questions.

    mode = 'subject'    : questions seules
    mode = 'correction' : questions + SQL + remarques étudiants
    mode = 'teacher'    : questions + SQL + toutes les remarques
    """
    out = []

    # Titre principal (heading #)
    if parsed['title']:
        out.append(f"# {parsed['title']}")
        out.append('')

    # Introduction
    if parsed['intro']:
        out.append(parsed['intro'])
        out.append('')

    for section in parsed['sections']:
        # Heading ##
        if section['name']:
            out.append(f"## {section['name']}")
            out.append('')

        for item in section['items']:
            if item['type'] == 'instruction':
                out.append(f"**{item['text']}**")
                out.append('')

            elif item['type'] == 'text':
                out.append(item['text'])
                out.append('')

            elif item['type'] in ('remark', 'remark_teacher'):
                _render_remark(item, mode, out)

            elif item['type'] == 'question':
                q = item
                expected = format_expected(q)
                desc_lines = q['description'].split('\n')
                first_line = desc_lines[0] if desc_lines else ''

                out.append(f"Q{q['num']}")
                out.append(f": {first_line}{expected}")

                # Lignes de description supplémentaires (multi-lignes)
                for desc_line in desc_lines[1:]:
                    out.append(desc_line)
                out.append('')

                if mode in ('correction', 'teacher') and q['variants']:
                    for variant in q['variants']:
                        # Label de la variante
                        if variant['label']:
                            out.append(f"**{variant['label']}.**")
                            out.append('')

                        # Bloc SQL
                        if variant['sql']:
                            out.append('```sql')
                            out.append(_strip_noqa(variant['sql']))
                            out.append('```')
                            out.append('')

                        # Remarques
                        for remark in variant['remarks']:
                            _render_remark(remark, mode, out)

                    # Remarques post-variants (hors PROMPT)
                    for remark in q.get('post_remarks', []):
                        _render_remark(remark, mode, out)

    return '\n'.join(out)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Génère un Markdown de questions depuis un SQL annoté."
    )
    parser.add_argument('sql', metavar='CORRECTION_SQL',
                        help='Fichier SQL de correction annoté')
    parser.add_argument('--mode', choices=['subject', 'correction', 'teacher'],
                        default='subject',
                        help='Mode de génération (défaut: subject)')
    parser.add_argument('--template', metavar='TEMPLATE.md', default=None,
                        help='Fichier Markdown avec bloc ::: questions à remplacer')
    parser.add_argument('--output', metavar='FILE', default=None,
                        help='Fichier de sortie (défaut: stdout)')

    args = parser.parse_args()

    # Parser le SQL
    parsed = parse_sql(args.sql)

    # Générer le Markdown des questions
    questions_md = generate_markdown(parsed, mode=args.mode)

    # Assembler la sortie
    if args.template:
        with open(args.template, encoding='utf-8') as f:
            template_text = f.read()

        # En mode correction/teacher, modifier le titre YAML
        if args.mode == 'correction':
            template_text = re.sub(
                r'^(title:\s*"[^"]*)"',
                r'\1 — Corrigé"',
                template_text,
                count=1,
                flags=re.MULTILINE,
            )
        elif args.mode == 'teacher':
            template_text = re.sub(
                r'^(title:\s*"[^"]*)"',
                r'\1 — Corrigé enseignant"',
                template_text,
                count=1,
                flags=re.MULTILINE,
            )

        # Remplacer le bloc ::: questions par le contenu généré
        output = re.sub(
            r'::: questions\s*\n:::',
            questions_md,
            template_text,
        )
    else:
        output = questions_md

    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(output)
    else:
        sys.stdout.write(output)


if __name__ == '__main__':
    main()
