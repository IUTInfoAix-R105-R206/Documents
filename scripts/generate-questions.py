#!/usr/bin/env python3
"""Génère un Markdown de questions de TD depuis un fichier SQL de correction annoté.

Usage:
    python3 generate-questions.py [OPTIONS] CORRECTION_SQL

Options:
    --mode subject|correction   Mode de génération (défaut: subject)
    --intro INTRO.md            Fichier Markdown d'intro à préfixer
    --output FILE               Fichier de sortie (défaut: stdout)

Les annotations reconnues dans le SQL :
    -- @title Titre principal
    -- @intro Texte d'introduction
    -- @section Nom de la section
    -- @instruction Texte d'instruction
    -- QN - c:X, t:Y [= QM]
    -- Description de la question
"""

import re
import sys
import argparse


# ---------------------------------------------------------------------------
# Parsing du fichier SQL annoté
# ---------------------------------------------------------------------------

# Regex pour les lignes de commentaire « -- QN - c:X, t:Y ... »
RE_QUESTION = re.compile(
    r'^--\s+Q(\d+)\s*-\s*c:(\d+),\s*t:(\d+)'
    r'(?:\s+\(([^)]*)\))?'      # valeur attendue optionnelle entre ()
    r'(?:\s+\[=\s*Q(\d+)\])?'   # référence optionnelle [= QM]
    r'\s*$'
)

RE_TAG = re.compile(r'^--\s+@(\w+)\s+(.*?)\s*$')
RE_COMMENT = re.compile(r'^--\s?(.*?)\s*$')
RE_PROMPT = re.compile(r'^PROMPT\s', re.IGNORECASE)
RE_EMPTY = re.compile(r'^\s*$')


def parse_sql(path):
    """Parse un fichier SQL annoté et retourne une structure de questions.

    Retourne un dict avec :
        title       : str
        intro       : str
        sections    : list of dict (name, instruction, questions)

    Chaque question est un dict :
        num         : int
        cols        : int
        rows        : int
        value       : str ou None   (valeur attendue)
        ref         : str ou None   (numéro de question de référence)
        description : str
        variants    : list of dict (label, sql, remarks)
    """
    with open(path, encoding='utf-8') as f:
        lines = f.readlines()

    result = {
        'title': '',
        'intro': '',
        'sections': [],
    }

    current_section = None
    current_question = None
    current_variant = None
    state = 'top'  # top | question_header | variant

    def finish_variant():
        nonlocal current_variant
        if current_variant and current_question:
            # Nettoyer le SQL : retirer les lignes vides de début/fin
            sql = current_variant['sql'].strip()
            current_variant['sql'] = sql
            current_question['variants'].append(current_variant)
            current_variant = None

    def finish_question():
        nonlocal current_question
        finish_variant()
        if current_question and current_section is not None:
            current_section['questions'].append(current_question)
            current_question = None

    def new_section(name, instruction=''):
        nonlocal current_section
        finish_question()
        current_section = {
            'name': name,
            'instruction': instruction,
            'questions': [],
        }
        result['sections'].append(current_section)

    i = 0
    while i < len(lines):
        line = lines[i].rstrip('\n')

        # --- Tags @xxx ---
        m = RE_TAG.match(line)
        if m:
            tag, value = m.group(1), m.group(2)
            if tag == 'title':
                result['title'] = value
            elif tag == 'intro':
                result['intro'] = value
            elif tag == 'section':
                new_section(value)
            elif tag == 'instruction':
                if current_section is not None:
                    current_section['instruction'] = value
            i += 1
            continue

        # --- Ligne QN ---
        m = RE_QUESTION.match(line)
        if m:
            finish_question()
            if current_section is None:
                new_section('')
            num = int(m.group(1))
            cols = int(m.group(2))
            rows = int(m.group(3))
            value = m.group(4)  # peut être None
            ref = m.group(5)    # peut être None
            current_question = {
                'num': num,
                'cols': cols,
                'rows': rows,
                'value': value,
                'ref': ref,
                'description': '',
                'variants': [],
            }
            state = 'question_header'
            i += 1
            continue

        # --- Description de la question (premier commentaire après QN) ---
        if state == 'question_header':
            m_c = RE_COMMENT.match(line)
            if m_c and not RE_TAG.match(line):
                desc_text = m_c.group(1)
                # Vérifier si c'est un label de version → pas une description
                if re.match(r'^Version\s', desc_text) or desc_text.startswith('Remarque'):
                    # Pas de description, c'est déjà une variante
                    state = 'variant'
                    # Ne pas avancer i, on re-traite cette ligne
                    continue
                current_question['description'] = desc_text
                state = 'variant'
                i += 1
                continue
            elif RE_EMPTY.match(line):
                i += 1
                continue
            else:
                state = 'variant'
                continue

        # --- PROMPT → début d'une variante ---
        if RE_PROMPT.match(line):
            finish_variant()
            # Extraire le label depuis le PROMPT
            prompt_match = re.match(r'PROMPT\s+"([^"]+)"', line, re.IGNORECASE)
            label = prompt_match.group(1) if prompt_match else ''
            # Extraire le suffixe après "QN - "
            label_suffix = re.sub(r'^Q\d+\s*-?\s*', '', label).strip()
            if not label_suffix:
                label_suffix = None

            current_variant = {
                'label': label_suffix,
                'sql': '',
                'remarks': [],
            }
            state = 'variant'
            i += 1
            continue

        # --- Remarque(s) ---
        m_c = RE_COMMENT.match(line)
        if m_c and state == 'variant':
            text = m_c.group(1)
            if text.startswith('Remarque'):
                # Remarque : collecter tout le texte, en retirant le préfixe
                remark_text = re.sub(r'^Remarques?\s*:\s*', '', text)
                # Vérifier les lignes de continuation
                j = i + 1
                while j < len(lines):
                    next_line = lines[j].rstrip('\n')
                    m_next = RE_COMMENT.match(next_line)
                    if m_next and not RE_TAG.match(next_line) and not RE_QUESTION.match(next_line):
                        next_text = m_next.group(1)
                        if not next_text:
                            break
                        if (next_text.startswith('Version')
                                or RE_PROMPT.match(next_line)
                                or next_text.startswith('Remarque')):
                            break
                        remark_text += ' ' + next_text
                        j += 1
                    else:
                        break
                if current_variant:
                    current_variant['remarks'].append(remark_text)
                i = j
                continue
            elif text.startswith('Version') or text.startswith('V'):
                # Label de version pour la prochaine variante
                # On ne traite pas ici, le PROMPT qui suit le gère
                i += 1
                continue
            else:
                # Commentaire ordinaire dans le SQL, ignorer
                i += 1
                continue

        # --- Ligne SQL ---
        if current_variant is not None and not RE_EMPTY.match(line):
            current_variant['sql'] += line + '\n'
            i += 1
            continue

        # --- Ligne vide ---
        i += 1

    # Finir le dernier élément
    finish_question()

    return result


# ---------------------------------------------------------------------------
# Formatage du résultat attendu
# ---------------------------------------------------------------------------

def format_expected(q):
    """Formate le span .expected pour une question."""
    cols = q['cols']
    rows = q['rows']
    value = q['value']
    ref = q['ref']

    col_word = 'attribut' if cols == 1 else 'attributs'
    row_word = 'tuple' if rows == 1 else 'tuples'

    parts = []
    if ref:
        parts.append(f'Q{ref}')

    result_text = f'{cols} {col_word}, {rows} {row_word}'
    if value:
        result_text += f' ({value})'

    parts.append(result_text)
    return '[' + ', '.join(parts) + ']{.expected}'


# ---------------------------------------------------------------------------
# Génération Markdown
# ---------------------------------------------------------------------------

def generate_markdown(parsed, mode='subject'):
    """Génère le Markdown des questions.

    mode = 'subject'    : questions seules
    mode = 'correction' : questions + SQL + remarques
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

        # Instruction en gras
        if section['instruction']:
            out.append(f"**{section['instruction']}**")
            out.append('')

        for q in section['questions']:
            # Definition list : QN\n: description [expected]{.expected}
            expected = format_expected(q)
            out.append(f"Q{q['num']}")
            out.append(f": {q['description']} {expected}")
            out.append('')

            if mode == 'correction' and q['variants']:
                for variant in q['variants']:
                    # Label de la variante
                    if variant['label']:
                        out.append(f"**{variant['label']}.**")
                        out.append('')

                    # Bloc SQL
                    if variant['sql']:
                        out.append('```sql')
                        out.append(variant['sql'])
                        out.append('```')
                        out.append('')

                    # Remarques
                    for remark in variant['remarks']:
                        out.append('::: remarques')
                        out.append(remark)
                        out.append(':::')
                        out.append('')

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
    parser.add_argument('--mode', choices=['subject', 'correction'],
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

        # En mode correction, modifier le titre YAML
        if args.mode == 'correction':
            template_text = re.sub(
                r'^(title:\s*"[^"]*)"',
                r'\1 — Corrigé"',
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
