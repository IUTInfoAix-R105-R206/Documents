#!/usr/bin/env python3
"""Nettoie un fichier de correction SQL en retirant les annotations internes.

Transformations :
- ``-- QN - c:X, t:Y`` → ``-- QN``
- Supprime les lignes ``-- @tags ...``, ``-- @difficulty ...``,
  ``-- @title ...``, ``-- @intro ...``, ``-- @section ...``,
  ``-- @instruction ...``
- Retire les suffixes ``-- noqa: ...`` en fin de ligne
- Réduit les séquences de plus de deux lignes vides consécutives

Usage::

    python3 scripts/strip-sql-annotations.py docs/r1.05/td6/td6-correction.sql
    python3 scripts/strip-sql-annotations.py docs/r1.05/td6/td6-correction.sql -o output/r1.05/td6/td6-correction.sql
"""

import argparse
import re
import sys

# -- QN - c:2, t:9  →  -- QN
RE_EXPECTED = re.compile(r'^(-- Q\d+[a-z]?)\s*-\s*c:\d+.*', re.IGNORECASE)

# Lines to drop entirely
RE_ANNOTATION = re.compile(r'^-- @(tags|difficulty|title|intro|section|instruction)\b')

# Trailing -- noqa: ...
RE_NOQA = re.compile(r'\s*-- noqa:\s*\S+\s*$')


def strip_annotations(text):
    """Retourne le texte SQL nettoyé."""
    lines = text.splitlines()
    out = []
    blank_count = 0

    for line in lines:
        # Drop annotation lines
        if RE_ANNOTATION.match(line.lstrip()):
            continue

        # Strip c:t from question headers
        m = RE_EXPECTED.match(line)
        if m:
            line = m.group(1)

        # Strip -- noqa: suffixes
        line = RE_NOQA.sub('', line)

        # Collapse excessive blank lines
        if line.strip() == '':
            blank_count += 1
            if blank_count > 2:
                continue
        else:
            blank_count = 0

        out.append(line)

    # Remove trailing blank lines
    while out and out[-1].strip() == '':
        out.pop()

    return '\n'.join(out) + '\n'


def main():
    parser = argparse.ArgumentParser(
        description='Nettoie les annotations internes d\'un fichier SQL.',
    )
    parser.add_argument('input', help='Fichier SQL source')
    parser.add_argument(
        '-o', '--output',
        help='Fichier de sortie (défaut : stdout)',
    )
    args = parser.parse_args()

    with open(args.input, encoding='utf-8') as f:
        text = f.read()

    result = strip_annotations(text)

    if args.output:
        import os
        os.makedirs(os.path.dirname(args.output) or '.', exist_ok=True)
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(result)
    else:
        sys.stdout.write(result)


if __name__ == '__main__':
    main()
