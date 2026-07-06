#!/usr/bin/env python3
"""Parsing partagé des fichiers SQL de correction annotés.

Ce module regroupe la logique de reconnaissance des annotations
(`-- QN - c:X, t:Y`, `@section`, `@difficulty`, `@tags`, variantes `PROMPT`, …)
et le formatage du résultat attendu. Il est réutilisé par :

    - scripts/generate-questions.py  (génération Markdown des sujets/corrigés)
    - scripts/generate-web-td.py     (génération du site web SQLite WASM)

Les annotations reconnues dans le SQL :
    -- @title Titre principal
    -- @intro Texte d'introduction
    -- @section Nom de la section
    -- @instruction Texte d'instruction (rendu en gras)
    -- @text Paragraphe de texte libre dans une section
    -- @remark Remarque pédagogique (visible étudiants et enseignants)
    -- @remark_teacher Remarque enseignant uniquement (masquée en mode subject)
    -- @difficulty N   Difficulté de la question (0-5), rattachée à la question courante
    -- @tags t1, t2    Thèmes abordés (liste prédéfinie), rattachés à la question courante
    -- @+ Continuation du dernier tag (@instruction, @text, @remark, @remark_teacher)
    -- QN - c:X, t:Y [(valeur)] [= QM]   Question avec résultat attendu complet
    -- QN - t:Y                           Question avec nombre de tuples seulement
    -- QN                                 Question sans résultat attendu (DDL)
    -- QN - texte expected brut           Question avec expected personnalisé
    -- Description (multi-lignes, commentaires consécutifs après QN)
"""

import re
import sys


# ---------------------------------------------------------------------------
# Parsing du fichier SQL annoté
# ---------------------------------------------------------------------------

# Label question : chiffres + lettre optionnelle (Q3, Q3a, Q12b, etc.)
QNUM = r'(\d+[a-z]?)'

# Regex pour les lignes QN - essayés dans l'ordre de spécificité décroissante
RE_QUESTION_FULL = re.compile(
    r'^--\s+Q' + QNUM + r'\s*-\s*c:(\d+),\s*t:(\d+)'
    r'(?:\s+\(([^)]*)\))?'      # valeur attendue optionnelle entre ()
    r'(?:\s+\[=\s*Q' + QNUM + r'\])?'   # référence optionnelle [= QM]
    r'\s*$'
)
RE_QUESTION_TUPLES = re.compile(r'^--\s+Q' + QNUM + r'\s*-\s*t:(\d+)\s*$')
RE_QUESTION_RAW = re.compile(r'^--\s+Q' + QNUM + r'\s*-\s*(.+?)\s*$')
RE_QUESTION_BARE = re.compile(r'^--\s+Q' + QNUM + r'\s*$')

RE_TAG = re.compile(r'^--\s+@(\w+)\s+(.*?)\s*$')
RE_TAG_CONT = re.compile(r'^--\s+@\+(?:\s+(.*?))?\s*$')
RE_COMMENT = re.compile(r'^--\s?(.*?)\s*$')
RE_PROMPT = re.compile(r'^PROMPT\s', re.IGNORECASE)
RE_EMPTY = re.compile(r'^\s*$')

VALID_TAGS = {
    'projection', 'sélection', 'jointure', 'jointure-externe',
    'imbrication', 'semi-jointure', 'anti-jointure', 'groupement', 'division',
    'union', 'intersection', 'différence', 'sous-requête',
    'exists', 'not-exists', 'tri', 'distinct', 'null',
    'vue', 'ddl', 'dml', 'transaction', 'récursion',
    'calcul-vertical', 'calcul-horizontal', 'extrémum', 'cte',
}


def match_question(line):
    """Essaie de reconnaître une ligne QN. Retourne un dict question ou None."""
    m = RE_QUESTION_FULL.match(line)
    if m:
        return {
            'type': 'question',
            'num': m.group(1),
            'cols': int(m.group(2)),
            'rows': int(m.group(3)),
            'value': m.group(4),
            'ref': m.group(5),
            'raw_expected': None,
            'description': '',
            'variants': [],
            'difficulty': None,
            'tags': [],
        }

    m = RE_QUESTION_TUPLES.match(line)
    if m:
        return {
            'type': 'question',
            'num': m.group(1),
            'cols': None,
            'rows': int(m.group(2)),
            'value': None,
            'ref': None,
            'raw_expected': None,
            'description': '',
            'variants': [],
            'difficulty': None,
            'tags': [],
        }

    # Bare QN doit être testé avant RAW pour ne pas capturer « Q11 » comme raw
    m = RE_QUESTION_BARE.match(line)
    if m:
        return {
            'type': 'question',
            'num': m.group(1),
            'cols': None,
            'rows': None,
            'value': None,
            'ref': None,
            'raw_expected': None,
            'description': '',
            'variants': [],
            'difficulty': None,
            'tags': [],
        }

    m = RE_QUESTION_RAW.match(line)
    if m:
        return {
            'type': 'question',
            'num': m.group(1),
            'cols': None,
            'rows': None,
            'value': None,
            'ref': None,
            'raw_expected': m.group(2),
            'description': '',
            'variants': [],
            'difficulty': None,
            'tags': [],
        }

    return None


def is_desc_stopper(text):
    """Vérifie si un texte de commentaire marque la fin d'une description."""
    return re.match(r'^Version\s', text)


def parse_sql(path):
    """Parse un fichier SQL annoté et retourne une structure de questions.

    Retourne un dict avec :
        title       : str
        intro       : str
        sections    : list of dict (name, items)

    Chaque section contient une liste items de types mélangés :
        {'type': 'instruction', 'text': str}
        {'type': 'text', 'text': str}
        {'type': 'remark', 'text': str}
        {'type': 'remark_teacher', 'text': str}
        {'type': 'question', 'num': int, 'cols': int|None, 'rows': int|None,
         'value': str|None, 'ref': str|None, 'raw_expected': str|None,
         'description': str, 'variants': list of dict (label, sql, remarks),
         'post_remarks': list of dict (type, text),
         'difficulty': int|None, 'tags': list of str}
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
    last_tag_target = None   # pour @+ : ('title'|'intro'|'instruction'|'text'|'remark'|'remark_teacher', item_ref)
    state = 'top'            # top | question_header | variant

    def finish_variant():
        nonlocal current_variant
        if current_variant and current_question:
            sql = current_variant['sql'].strip()
            current_variant['sql'] = sql
            current_question['variants'].append(current_variant)
        current_variant = None

    def finish_question():
        nonlocal current_question
        finish_variant()
        if current_question and current_section is not None:
            current_section['items'].append(current_question)
            current_question = None

    def new_section(name):
        nonlocal current_section
        finish_question()
        current_section = {
            'name': name,
            'items': [],
        }
        result['sections'].append(current_section)

    i = 0
    while i < len(lines):
        line = lines[i].rstrip('\n')

        # --- Tag @+ continuation ---
        m = RE_TAG_CONT.match(line)
        if m:
            cont_text = m.group(1) or ''
            if last_tag_target:
                tag_type, tag_ref = last_tag_target
                # Pour @text : retour à la ligne (contenu bloc Markdown)
                # Pour les autres (@instruction, @title, @intro) : espace (continuation de phrase)
                if not cont_text:
                    sep = '\n\n'       # -- @+ vide → saut de paragraphe
                elif tag_type == 'text':
                    sep = '\n'         # @text : chaque @+ est une nouvelle ligne
                else:
                    sep = ' '          # @instruction/title/intro : continuation de phrase
                if tag_type == 'title':
                    result['title'] += sep + cont_text
                elif tag_type == 'intro':
                    result['intro'] += sep + cont_text
                elif tag_type in ('instruction', 'text', 'remark', 'remark_teacher') \
                        and tag_ref is not None:
                    tag_ref['text'] += sep + cont_text
            i += 1
            continue

        # --- Tags @xxx ---
        m = RE_TAG.match(line)
        if m:
            tag, value = m.group(1), m.group(2)
            if tag == 'title':
                result['title'] = value
                last_tag_target = ('title', None)
            elif tag == 'intro':
                result['intro'] = value
                last_tag_target = ('intro', None)
            elif tag == 'section':
                new_section(value)
                last_tag_target = None
            elif tag == 'instruction':
                if current_section is None:
                    new_section('')
                finish_question()
                item = {'type': 'instruction', 'text': value}
                current_section['items'].append(item)
                last_tag_target = ('instruction', item)
            elif tag == 'text':
                if current_section is None:
                    new_section('')
                finish_question()
                item = {'type': 'text', 'text': value}
                current_section['items'].append(item)
                last_tag_target = ('text', item)
            elif tag == 'difficulty':
                if current_question is not None:
                    level = int(value)
                    if not 0 <= level <= 5:
                        print(f"WARNING: {path}: @difficulty {value} hors [0-5]",
                              file=sys.stderr)
                    current_question['difficulty'] = level
                last_tag_target = None
            elif tag == 'tags':
                if current_question is not None:
                    tags = [t.strip() for t in value.split(',')]
                    unknown = set(tags) - VALID_TAGS
                    if unknown:
                        print(f"WARNING: {path}: tags inconnus: "
                              f"{', '.join(sorted(unknown))}",
                              file=sys.stderr)
                    current_question['tags'] = tags
                last_tag_target = None
            elif tag in ('remark', 'remark_teacher'):
                remark = {'type': tag, 'text': value}
                if current_variant is not None:
                    current_variant['remarks'].append(remark)
                elif current_question is not None:
                    # Remarque hors variant mais dans une question
                    current_question.setdefault('post_remarks', []).append(remark)
                else:
                    # Remarque hors question → item de section
                    if current_section is None:
                        new_section('')
                    current_section['items'].append(remark)
                last_tag_target = (tag, remark)
            i += 1
            continue

        # --- Ligne QN ---
        q = match_question(line)
        if q is not None:
            finish_question()
            if current_section is None:
                new_section('')
            current_question = q
            last_tag_target = None
            state = 'question_header'
            i += 1
            continue

        # --- Description multi-lignes (commentaires consécutifs après QN) ---
        if state == 'question_header':
            m_c = RE_COMMENT.match(line)
            if m_c and not RE_TAG.match(line) and not RE_TAG_CONT.match(line):
                desc_text = m_c.group(1)
                # Si c'est un label de version ou une remarque → pas une description
                if is_desc_stopper(desc_text):
                    state = 'variant'
                    continue  # re-traiter cette ligne
                # Collecter toutes les lignes de description consécutives
                desc_lines = [desc_text]
                j = i + 1
                while j < len(lines):
                    next_line = lines[j].rstrip('\n')
                    # Arrêter sur tag, QN, PROMPT
                    if RE_TAG.match(next_line) or RE_TAG_CONT.match(next_line):
                        break
                    if match_question(next_line) is not None:
                        break
                    if RE_PROMPT.match(next_line):
                        break
                    m_next = RE_COMMENT.match(next_line)
                    if m_next:
                        next_text = m_next.group(1)
                        if is_desc_stopper(next_text):
                            break
                        desc_lines.append(next_text)
                        j += 1
                    else:
                        # Ligne non-commentaire (vide ou SQL) → fin de la description
                        break
                current_question['description'] = '\n'.join(desc_lines)
                state = 'variant'
                i = j
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
            # Extraire le suffixe après "QN - " (ex: "Q3a - V1" → "V1")
            label_suffix = re.sub(r'^Q\d+[a-z]?\s*-?\s*', '', label).strip()
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

        # --- Commentaires dans un variant ---
        m_c = RE_COMMENT.match(line)
        if m_c and state == 'variant':
            text = m_c.group(1)
            if text.startswith('Version') or text.startswith('V'):
                # Label de version - le PROMPT qui suit le gère
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
    # Expected brut (texte personnalisé, ex: Q20 multi-tables)
    if q.get('raw_expected'):
        return ' ' + q['raw_expected']

    cols = q['cols']
    rows = q['rows']

    # Pas de résultat attendu (question DDL)
    if cols is None and rows is None:
        return ''

    ref = q['ref']
    value = q['value']

    parts = []
    if ref:
        parts.append(f'Q{ref}')

    pieces = []
    if cols is not None:
        col_word = 'attribut' if cols == 1 else 'attributs'
        pieces.append(f'{cols} {col_word}')
    if rows is not None:
        row_word = 'tuple' if rows == 1 else 'tuples'
        pieces.append(f'{rows} {row_word}')

    result_text = ', '.join(pieces)
    if value:
        result_text += f' ({value})'

    parts.append(result_text)
    return ' [' + ', '.join(parts) + ']{.expected}'


# ---------------------------------------------------------------------------
# Nettoyage des annotations sqlfluff noqa
# ---------------------------------------------------------------------------

_NOQA_LINE_RE = re.compile(r'^--\s*noqa:\s*\S+.*$')
_NOQA_SUFFIX_RE = re.compile(r'\s*--\s*noqa:\s*\S+')


def _strip_noqa(sql):
    """Retire les annotations sqlfluff noqa du SQL pour le rendu."""
    lines = []
    for line in sql.split('\n'):
        if _NOQA_LINE_RE.match(line.strip()):
            continue
        line = _NOQA_SUFFIX_RE.sub('', line)
        lines.append(line)
    return '\n'.join(lines)
