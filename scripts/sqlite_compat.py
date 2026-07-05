#!/usr/bin/env python3
"""Filtres de compatibilité SQLite pour les fichiers de données partagés.

Les fichiers `docs/shared/data/<bd>/{schema,insert}.sql` sont écrits pour être
compatibles PostgreSQL/SQLite, mais deux constructions ne sont pas acceptées par
SQLite et doivent être filtrées avant chargement :

    - ` CASCADE` sur les `DROP TABLE IF EXISTS x CASCADE;`
    - les blocs `ALTER TABLE … ADD CONSTRAINT … ;`

Ce module fournit ces deux filtres comme fonctions pures, réutilisées par :
    - scripts/test-sql.py       (moteur SQLite des tests automatisés)
    - scripts/generate-web-td.py (construction de la base pour le site web)
"""

import re


def filter_schema(text: str) -> str:
    """Retire ` CASCADE` (non supporté par SQLite sur DROP TABLE)."""
    return re.sub(r" CASCADE", "", text, flags=re.IGNORECASE)


def filter_insert(text: str) -> str:
    """Retire les blocs `ALTER TABLE … ADD CONSTRAINT … ;` (non supportés par SQLite)."""
    lines = text.splitlines(keepends=True)
    filtered = []
    skip = False
    for line in lines:
        if re.match(r"^\s*ALTER\s+TABLE.*ADD\s+CONSTRAINT", line, re.IGNORECASE):
            skip = True
        if skip:
            if ";" in line:
                skip = False
            continue
        filtered.append(line)
    return "".join(filtered)
