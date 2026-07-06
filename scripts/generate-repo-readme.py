#!/usr/bin/env python3
"""Génère le README.md d'un dépôt étudiant de TD au moment de la publication.

Appelé par publish-web-td.sh après la synchronisation rsync (avant commit) :
construit un en-tête spécifique au TD (titre, lien vers la page GitHub Pages,
sujet PDF) et conserve le corps générique du README du template web
("TP SQL en ligne") quand le site est interactif.

Cas gérés :
- site unique à la racine du dépôt (interactif ou page minimale à lien PDF) ;
- plusieurs pages dans des sous-dossiers (ex. R1.05/TD2 : airbase/ et
  immobilier/), avec un index.html de présentation maintenu à la racine.

L'adresse GitHub Pages est déduite du remote « origin » du dépôt.

Usage : generate-repo-readme.py <repo_dir>
"""

import html
import json
import re
import subprocess
import sys
from pathlib import Path

RES_LABELS = {
    "IUTInfoAix-R105": "ressource R1.05, Introduction aux bases de données et SQL",
    "IUTInfoAix-R206": "ressource R2.06, Exploitation d'une base de données",
}

AUTO_NOTE = (
    "Ce dépôt est généré automatiquement depuis le dépôt "
    "[Documents](https://github.com/IUTInfoAix-R105-R206/Documents) : "
    "toute modification manuelle sera écrasée à la prochaine publication."
)

LICENSE_LINE = "Contenu sous licence **CC BY-NC-SA**."


def org_and_repo(repo_dir: Path):
    url = subprocess.check_output(
        ["git", "-C", str(repo_dir), "remote", "get-url", "origin"], text=True
    ).strip()
    m = re.search(r"github\.com[/:]([^/:]+)/([^/]+?)(?:\.git)?/?$", url)
    if not m:
        sys.exit(f"Remote origin non reconnu : {url}")
    return m.group(1), m.group(2)


def page_meta(page_dir: Path):
    """Titre et nature d'une page publiée (questions.json, sinon <title>)."""
    questions = page_dir / "questions.json"
    if questions.exists():
        data = json.loads(questions.read_text(encoding="utf8"))
        heading = " - ".join(p for p in (data.get("tdLabel", ""), data.get("title", "")) if p)
        return {"heading": heading, "short": data.get("title", "") or heading,
                "interactive": True, "pdf": (page_dir / "sujet.pdf").exists()}
    index = page_dir / "index.html"
    if index.exists():
        m = re.search(r"<title>([^<]+)</title>", index.read_text(encoding="utf8"))
        if m:
            heading = html.unescape(m.group(1)).strip()
            return {"heading": heading, "short": heading, "interactive": False,
                    "pdf": (page_dir / "sujet.pdf").exists()}
    return None


def generic_body(readme_path: Path) -> str:
    """Sections d'usage du README générique du template (à partir de « ## Utilisation »)."""
    if not readme_path.exists():
        return ""
    text = readme_path.read_text(encoding="utf8")
    pos = text.find("## Utilisation")
    return text[pos:].rstrip() + "\n" if pos >= 0 else ""


def main():
    repo_dir = Path(sys.argv[1]).resolve()
    org, repo = org_and_repo(repo_dir)
    pages_url = f"https://{org.lower()}.github.io/{repo}/"
    res_label = RES_LABELS.get(org, org)

    root_meta = page_meta(repo_dir)
    subpages = []
    for child in sorted(repo_dir.iterdir()):
        if child.is_dir() and child.name not in {".git", ".github"} and (child / "index.html").exists():
            meta = page_meta(child)
            if meta:
                meta["subdir"] = child.name
                subpages.append(meta)

    lines = []
    body = ""
    if subpages:
        heading = root_meta["heading"] if root_meta else f"{org.split('-')[-1]} - {repo}"
        lines += [f"# {heading}", "",
                  f"TP de bases de données de l'IUT d'Aix-Marseille ({res_label}).", ""]
        if root_meta:
            lines.append(f"- **[Page d'accueil du TD]({pages_url})**")
        for page in subpages:
            suffix = f" ([sujet PDF]({page['subdir']}/sujet.pdf))" if page["pdf"] else ""
            lines.append(f"- **[{page['short']}]({pages_url}{page['subdir']}/)**{suffix}")
    elif root_meta:
        verb = "Faire le TP dans le navigateur" if root_meta["interactive"] else "Ouvrir la page du TD"
        lines += [f"# {root_meta['heading']}", "",
                  f"TP de bases de données de l'IUT d'Aix-Marseille ({res_label}).", "",
                  f"- **[{verb}]({pages_url})**"]
        if root_meta["pdf"]:
            lines.append("- [Sujet PDF](sujet.pdf)")
        if root_meta["interactive"]:
            body = generic_body(repo_dir / "README.md")
    else:
        sys.exit(f"Aucune page publiée trouvée dans {repo_dir}")

    lines += ["", AUTO_NOTE, ""]
    if body:
        lines += [body.rstrip(), ""]
    else:
        lines += [LICENSE_LINE, ""]

    (repo_dir / "README.md").write_text("\n".join(lines), encoding="utf8")
    print(f"README généré : {repo_dir / 'README.md'}")


if __name__ == "__main__":
    main()
