#!/usr/bin/env python3
"""Réécrit les comparaisons quantifiées Oracle/SQL standard (ALL / ANY / SOME) en
équivalents que SQLite comprend, pour que les pages web interactives puissent
exécuter ces requêtes (référence ET saisie étudiant).

Équivalences (ensemble non vide, sans NULL) :
    x >  ALL (S)  ->  x >  (SELECT MAX(c) FROM (S))
    x >= ALL (S)  ->  x >= (SELECT MAX(c) FROM (S))
    x <  ALL (S)  ->  x <  (SELECT MIN(c) FROM (S))
    x <= ALL (S)  ->  x <= (SELECT MIN(c) FROM (S))
    x >  ANY (S)  ->  x >  (SELECT MIN(c) FROM (S))   (ANY = SOME)
    x <  ANY (S)  ->  x <  (SELECT MAX(c) FROM (S))
    x =  ANY (S)  ->  x IN (S)
    x <> ALL (S)  ->  x NOT IN (S)

Jumeau JS : templates/web-td/js/sql-quantifiers.js (sortie identique, testée).
Portée : sous-requête mono-colonne (colonne simple nommée). Les cas `= ALL`,
`<> ANY` (rares) et les sous-requêtes à projection complexe sont laissés tels quels.
"""
import re

_CMP = ("<=", ">=", "<>", "!=", "<", ">", "=")  # plus longs d'abord
_QUANT = re.compile(r"\b(ALL|ANY|SOME)\b", re.IGNORECASE)
_IDENT = r"[A-Za-z_][A-Za-z0-9_]*"


def _find_balanced(s, open_idx):
    """Index du `)` appariant le `(` à open_idx (chaînes '...' ignorées)."""
    depth, i, in_str = 0, open_idx, False
    while i < len(s):
        c = s[i]
        if in_str:
            if c == "'":
                if i + 1 < len(s) and s[i + 1] == "'":
                    i += 2
                    continue
                in_str = False
        elif c == "'":
            in_str = True
        elif c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def _first_top_level_from(body):
    """Index du FROM de premier niveau dans body (hors parenthèses/chaînes), ou -1."""
    depth, i, in_str = 0, 0, False
    while i < len(body):
        c = body[i]
        if in_str:
            if c == "'":
                if i + 1 < len(body) and body[i + 1] == "'":
                    i += 2
                    continue
                in_str = False
        elif c == "'":
            in_str = True
        elif c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
        elif depth == 0 and body[i:i + 4].upper() == "FROM" \
                and (i == 0 or not (body[i - 1].isalnum() or body[i - 1] == "_")) \
                and (i + 4 >= len(body) or not (body[i + 4].isalnum() or body[i + 4] == "_")):
            return i
        i += 1
    return -1


def _proj_colname(subq):
    """Nom de la colonne projetée si la sous-requête est `SELECT [DISTINCT] col FROM ...`."""
    m = re.match(r"\s*SELECT\s+", subq, re.IGNORECASE)
    if not m:
        return None
    body = subq[m.end():]
    md = re.match(r"DISTINCT\s+", body, re.IGNORECASE)
    if md:
        body = body[md.end():]
    f = _first_top_level_from(body)
    if f < 0:
        return None
    proj = body[:f].strip()
    m = re.search(r"\bAS\s+(" + _IDENT + r")\s*$", proj, re.IGNORECASE)
    if m:
        return m.group(1)
    m = re.fullmatch(r"(" + _IDENT + r")(?:\.(" + _IDENT + r"))?", proj)
    if m:
        return m.group(2) or m.group(1)
    return None


def _build(op, kw, subq):
    if op == "=" and kw in ("ANY", "SOME"):
        return f"IN ({subq})"
    if op in ("<>", "!=") and kw == "ALL":
        return f"NOT IN ({subq})"
    if op in ("<", "<=", ">", ">="):
        if kw == "ALL":
            agg = "MAX" if op in (">", ">=") else "MIN"
        else:  # ANY / SOME
            agg = "MIN" if op in (">", ">=") else "MAX"
        name = _proj_colname(subq)
        if not name:
            return None  # projection non triviale : on laisse tel quel
        return f"{op} (SELECT {agg}({name}) FROM ({subq}))"
    return None


def rewrite_quantifiers(sql):
    """Renvoie sql avec les comparaisons ALL/ANY/SOME réécrites pour SQLite."""
    out, i = [], 0
    for m in _QUANT.finditer(sql):
        if m.start() < i:
            continue  # déjà consommé par une réécriture précédente
        kw = m.group(1).upper()
        # opérateur de comparaison juste avant (en sautant les espaces)
        j = m.start() - 1
        while j >= 0 and sql[j].isspace():
            j -= 1
        op = op_start = None
        for cand in _CMP:
            L = len(cand)
            if j - L + 1 >= 0 and sql[j - L + 1:j + 1] == cand:
                op, op_start = cand, j - L + 1
                break
        if not op:
            continue
        # '(' après le mot-clé
        k = m.end()
        while k < len(sql) and sql[k].isspace():
            k += 1
        if k >= len(sql) or sql[k] != "(":
            continue
        close = _find_balanced(sql, k)
        if close < 0:
            continue
        repl = _build(op, kw, sql[k + 1:close])
        if repl is None:
            continue
        out.append(sql[i:op_start])
        out.append(repl)
        i = close + 1
    out.append(sql[i:])
    return "".join(out)
