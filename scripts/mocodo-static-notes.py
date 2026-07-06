#!/usr/bin/env python3
"""Rend statiques les notes de patte des SVG générés par Mocodo.

Mocodo n'affiche les notes de patte (ex : rôles « Est gagnant » / « Est battu »)
qu'en infobulle interactive (onmouseover), invisible dans un PDF. Ce script
réécrit les SVG passés en argument pour afficher la note en italique à la
suite de la cardinalité.
"""

import re
import sys
from pathlib import Path

NOTE_PATTERN = re.compile(
    r"(?P<head><text [^>]*?)"
    r" onmouseover=\"show_\w+\(evt,'(?P<note>[^']*)'\)\""
    r" onmouseout=\"hide_\w+\(evt\)\""
    r" style=\"cursor: pointer;\">"
    r"(?P<text>[^<]*)</text>"
)

# Éléments d'infobulle : script ECMAScript et calques masqués. Inkscape
# ignore visibility="hidden", donc le bandeau sombre apparaîtrait en PDF.
SCRIPT_PATTERN = re.compile(r"<script type=\"text/ecmascript\">.*?</script>\n?", re.DOTALL)
OVERLAY_PATTERN = re.compile(r"<(rect|text) id=\"(top|bottom)_(overlay|note)_\w+\"[^>]*>(</text>)?\n?")


def make_static(match: re.Match) -> str:
    return (
        f"{match.group('head')}>{match.group('text')}"
        f" <tspan font-style=\"italic\">{match.group('note')}</tspan></text>"
    )


def main() -> None:
    for arg in sys.argv[1:]:
        path = Path(arg)
        svg = path.read_text(encoding="utf8")
        svg = NOTE_PATTERN.sub(make_static, svg)
        svg = SCRIPT_PATTERN.sub("", svg)
        svg = OVERLAY_PATTERN.sub("", svg)
        path.write_text(svg, encoding="utf8")


if __name__ == "__main__":
    main()
