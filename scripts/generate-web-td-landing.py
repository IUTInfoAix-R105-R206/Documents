#!/usr/bin/env python3
"""Génère une page web minimale pour un TD : uniquement un lien vers le PDF du sujet.

Destinée aux TD sans contenu interactif (R1.05 TD3/TD4/TD5 : dépendances
fonctionnelles, modèle E/A). Le PDF du sujet est copié dans le site, de sorte
qu'il reste accessible dans le dépôt étudiant même quand le dépôt Documents
deviendra privé.

Émet dans --output : index.html (autonome), sujet.pdf, .nojekyll et le workflow
de déploiement Pages (copié depuis --deploy-workflow).

Usage :
    generate-web-td-landing.py --output DIR --td-label "R1.05 - TD3" \\
        --title "Dépendances fonctionnelles et normalisation" \\
        --pdf output/r1.05/td3/td3.pdf --deploy-workflow templates/web-td/.github/workflows/deploy-pages.yml
"""
import argparse
import html
import os
import shutil
import sys

PAGE = """<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title_attr}</title>
  <style>
    :root {{ color-scheme: light dark; --bg:#f6f7f9; --card:#fff; --ink:#1c2330; --muted:#5c6675; --border:#d9dee6; --accent:#2f6fed; --accent-ink:#fff; }}
    @media (prefers-color-scheme: dark){{ :root{{ --bg:#12151b; --card:#1b2029; --ink:#e7ebf1; --muted:#9aa4b2; --border:#2c333f; --accent:#5b8cff; --accent-ink:#0b0e13; }} }}
    * {{ box-sizing:border-box; }}
    body {{ margin:0; font-family:system-ui,-apple-system,"Segoe UI",Roboto,sans-serif; background:var(--bg); color:var(--ink); line-height:1.5; }}
    main {{ max-width:640px; margin:0 auto; padding:2.5rem 1rem 4rem; }}
    h1 {{ font-size:1.5rem; margin:0 0 .4rem; }}
    p.intro {{ color:var(--muted); margin:.4rem 0 1.6rem; }}
    a.pdf {{ display:inline-flex; align-items:center; gap:.5rem; text-decoration:none;
      background:var(--accent); color:var(--accent-ink); font-weight:600; font-size:1rem;
      border-radius:8px; padding:.7rem 1.2rem; }}
    a.pdf:hover {{ filter:brightness(1.08); }}
    .card {{ background:var(--card); border:1px solid var(--border); border-radius:10px; padding:1.6rem 1.6rem; }}
    footer {{ margin-top:2rem; color:var(--muted); font-size:.82rem; }}
  </style>
</head>
<body>
  <main>
    <div class="card">
      <h1>{heading}</h1>
      <p class="intro">{intro}</p>
      <a class="pdf" href="{pdf_name}" target="_blank" rel="noopener">📄 Ouvrir le sujet (PDF)</a>
    </div>
    <footer>Contenu sous licence CC BY-NC-SA - IUT d'Aix-Marseille.</footer>
  </main>
</body>
</html>
"""


def main():
    ap = argparse.ArgumentParser(description="Génère une page web minimale (lien PDF seul) pour un TD.")
    ap.add_argument("--output", required=True, help="Répertoire du site (écrasé)")
    ap.add_argument("--td-label", required=True, help="Ex. « R1.05 - TD3 »")
    ap.add_argument("--title", required=True, help="Titre du TD (sans le label)")
    ap.add_argument("--pdf", required=True, help="Chemin du PDF du sujet à copier")
    ap.add_argument("--pdf-name", default="sujet.pdf")
    ap.add_argument("--intro", default="Ce TD se fait sur feuille. Le sujet est disponible en PDF :")
    ap.add_argument("--deploy-workflow", default=None,
                    help="Chemin du workflow deploy-pages.yml à copier (pour le déploiement Pages)")
    args = ap.parse_args()

    if not os.path.isfile(args.pdf):
        print(f"✗ ERREUR : PDF introuvable ({args.pdf})", file=sys.stderr)
        sys.exit(1)

    if os.path.exists(args.output):
        shutil.rmtree(args.output)
    os.makedirs(args.output)

    heading = f"{args.td_label} - {args.title}"
    page = PAGE.format(
        title_attr=html.escape(heading, quote=True),
        heading=html.escape(heading),
        intro=html.escape(args.intro),
        pdf_name=html.escape(args.pdf_name, quote=True),
    )
    with open(os.path.join(args.output, "index.html"), "w", encoding="utf-8") as f:
        f.write(page)

    shutil.copyfile(args.pdf, os.path.join(args.output, args.pdf_name))

    # GitHub Pages : désactiver Jekyll + workflow de déploiement (avec réessai).
    open(os.path.join(args.output, ".nojekyll"), "w").close()
    if args.deploy_workflow and os.path.isfile(args.deploy_workflow):
        wf_dir = os.path.join(args.output, ".github", "workflows")
        os.makedirs(wf_dir, exist_ok=True)
        shutil.copyfile(args.deploy_workflow, os.path.join(wf_dir, "deploy-pages.yml"))

    print(f"✓ OK - page minimale générée dans {args.output} (sujet : {args.pdf_name})")


if __name__ == "__main__":
    main()
