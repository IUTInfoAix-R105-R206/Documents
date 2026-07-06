#!/usr/bin/env python3
"""Canonicalisation des résultats SQL et hash SHA-256 (côté Python / générateur).

Ce module est la moitié Python d'un **contrat** partagé avec le navigateur : le
fichier `templates/web-td/js/canon.js` implémente exactement le même algorithme
en JavaScript. Les deux doivent produire des hashes bit-à-bit identiques pour un
même résultat de requête, afin que le générateur (Python + sqlite3) puisse
précalculer les hashes attendus et que le navigateur (sql.js WASM) puisse les
vérifier sans jamais recevoir la correction.

Contrat (voir aussi canon.js - toute modification doit être répercutée) :

Séparateurs (échappés dans les valeurs texte, ne peuvent donc pas apparaître) :
    US = "\\x1f"  séparateur de cellules
    RS = "\\x1e"  séparateur de lignes
    GS = "\\x1d"  séparateur en-tête (nombre de colonnes) / corps

canon_cell(v) :
    NULL          -> "\\x00N"                (sentinelle : le texte échappe \\x00, donc inforgeable)
    nombre entier -> chaîne décimale         ("5", "-3", "0")   ; 5, 5.0 et le texte "5" collisionnent (toléré)
    nombre réel   -> arrondi à 6 décimales par arithmétique IEEE identique Py/JS,
                     zéros finaux supprimés  ("6.25", "0.333333")
    texte         -> échappement de \\, \\x00, US, RS, GS
    BLOB          -> "\\x00B"+hex            (le générateur refuse les BLOB de toute façon)

canon_result(ncols, rows, ordered) :
    lignes = [ US.join(canon_cell(c) for c in row) for row in rows ]
    si non ordered : trier lexicographiquement (ordre des points de code = ordre UTF-16 pour le BMP)
    payload = str(ncols) + GS + RS.join(lignes)

hash = SHA-256(UTF-8(payload)) en hexadécimal minuscule.

Le nombre de colonnes est inclus dans le payload (préfixe) ; le nombre de lignes
est implicite. Les *noms* de colonnes ne sont pas hashés (seul leur nombre compte).
"""

import math
import hashlib

US = "\x1f"   # séparateur de cellules
RS = "\x1e"   # séparateur de lignes
GS = "\x1d"   # séparateur en-tête / corps

# Les cellules numériques doivent rester dans cette plage pour que l'arithmétique
# d'arrondi reste en entiers exacts (|v|*1e6 < 1e15 < 2^53) et donc identique JS/Py.
NUMERIC_LIMIT = 1e9


class CanonError(ValueError):
    """Valeur non canonicalisable de façon fiable (BLOB, non-fini, hors plage)."""


def canon_number(v, *, strict=False):
    """Canonicalise un int ou float. strict=True lève CanonError sur cas douteux."""
    if isinstance(v, bool):
        # sqlite3 ne renvoie pas de bool, mais par prudence : True->1, False->0
        v = int(v)
    if isinstance(v, float):
        if math.isnan(v) or math.isinf(v):
            if strict:
                raise CanonError(f"valeur numérique non finie : {v!r}")
            return "\x00X"
        if strict and abs(v) >= NUMERIC_LIMIT:
            raise CanonError(f"valeur numérique hors plage (|v| >= {NUMERIC_LIMIT:g}) : {v!r}")
        if v.is_integer():
            iv = int(v)
            return "0" if iv == 0 else str(iv)
        neg = v < 0.0
        a = abs(v)
        # Arrondi demi-supérieur (away-from-zero) à 6 décimales via arithmétique IEEE.
        # math.floor renvoie un int Python ; String(Math.floor(...)) en JS donne les
        # mêmes chiffres car la valeur est un entier exact (< 2^53).
        r = math.floor(a * 1e6 + 0.5)
        digits = str(r)
        if len(digits) <= 6:
            digits = "0" * (7 - len(digits)) + digits
        int_part = digits[:-6]
        frac = digits[-6:].rstrip("0")
        s = f"{int_part}.{frac}" if frac else int_part
        if neg and s != "0":
            s = "-" + s
        return s
    # int
    if strict and abs(v) >= NUMERIC_LIMIT:
        raise CanonError(f"valeur entière hors plage (|v| >= {NUMERIC_LIMIT:g}) : {v!r}")
    return "0" if v == 0 else str(v)


def escape_text(s):
    """Échappe \\, \\x00 et les séparateurs pour rendre le texte non ambigu."""
    return (s.replace("\\", "\\\\")
             .replace("\x00", "\\0")
             .replace(GS, "\\g")
             .replace(RS, "\\r")
             .replace(US, "\\u"))


def canon_cell(v, *, strict=False):
    """Canonicalise une cellule (None, int, float, str, bytes) en chaîne."""
    if v is None:
        return "\x00N"
    if isinstance(v, (int, float)):
        return canon_number(v, strict=strict)
    if isinstance(v, bytes):
        if strict:
            raise CanonError("BLOB non supporté")
        return "\x00B" + v.hex()
    return escape_text(str(v))


def has_astral(rows):
    """Vrai si une cellule texte contient un caractère hors BMP (>= U+10000).

    Ces caractères se trient différemment en Python (points de code) et en
    JavaScript (unités UTF-16, paires de substitution) ; le générateur refuse
    donc leur présence.
    """
    for row in rows:
        for c in row:
            if isinstance(c, str):
                for ch in c:
                    if ord(ch) >= 0x10000:
                        return True
    return False


def canon_payload(ncols, rows, ordered, *, strict=False):
    """Construit le payload canonique d'un résultat (voir docstring du module)."""
    lines = [US.join(canon_cell(c, strict=strict) for c in row) for row in rows]
    if not ordered:
        lines.sort()
    return f"{ncols}{GS}" + RS.join(lines)


def sha256_hex(text):
    """SHA-256 de l'UTF-8 d'une chaîne, en hexadécimal minuscule."""
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def hash_result(ncols, rows, ordered, *, strict=False):
    """Hash canonique d'un résultat (raccourci canon_payload + sha256)."""
    return sha256_hex(canon_payload(ncols, rows, ordered, strict=strict))
