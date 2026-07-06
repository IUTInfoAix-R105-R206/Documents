#!/usr/bin/env bash
# publish-web-td.sh - publie un site de TD généré dans le dépôt étudiant.
#
# Usage : publish-web-td.sh <site_dir> <repo_dir> [<sous-dossier>]
#
# Sans sous-dossier : synchronise <site_dir> à la racine de <repo_dir> (--delete,
# sauf .git). Avec sous-dossier : publie le site dans <repo_dir>/<sous-dossier>/
# (utile pour héberger plusieurs pages dans un même dépôt), tout en gardant le
# workflow de déploiement et .nojekyll à la RACINE du dépôt (les workflows GitHub
# Actions doivent être à la racine). Puis commit + push.
set -euo pipefail

SITE_DIR="${1:?Usage: publish-web-td.sh <site_dir> <repo_dir> [subdir]}"
REPO_DIR="${2:?Usage: publish-web-td.sh <site_dir> <repo_dir> [subdir]}"
SUBDIR="${3:-}"

if [ ! -f "$SITE_DIR/index.html" ]; then
  echo "Erreur : $SITE_DIR ne ressemble pas à un site généré (index.html absent)." >&2
  exit 1
fi
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "Erreur : $REPO_DIR n'est pas un dépôt Git (clonez d'abord le dépôt étudiant)." >&2
  exit 1
fi

VERSION="$(git describe --exact-match --tags HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo inconnu)"

# Si le site généré ne contient pas de PDF sujet (ex. artefact indisponible en CI, ou
# build local sans LaTeX), on préserve celui déjà publié dans le dépôt plutôt que de le
# supprimer via --delete.
PDF_KEEP=()
if [ ! -f "$SITE_DIR/sujet.pdf" ]; then
  PDF_KEEP=(--exclude 'sujet.pdf')
fi

if [ -n "$SUBDIR" ]; then
  # Site dans un sous-dossier ; workflow + .nojekyll restent à la racine.
  mkdir -p "$REPO_DIR/$SUBDIR"
  rsync -a --delete --exclude '.git/' --exclude '.github/' "${PDF_KEEP[@]}" "$SITE_DIR"/ "$REPO_DIR/$SUBDIR"/
  if [ -f "$SITE_DIR/.github/workflows/deploy-pages.yml" ]; then
    mkdir -p "$REPO_DIR/.github/workflows"
    cp "$SITE_DIR/.github/workflows/deploy-pages.yml" "$REPO_DIR/.github/workflows/deploy-pages.yml"
  fi
  touch "$REPO_DIR/.nojekyll"
else
  rsync -a --delete --exclude '.git/' "${PDF_KEEP[@]}" "$SITE_DIR"/ "$REPO_DIR"/
fi

# README du dépôt étudiant : en-tête spécifique au TD (titre, lien Pages, sujet
# PDF), corps générique du template conservé pour les sites interactifs.
python3 "$(dirname "$0")/generate-repo-readme.py" "$REPO_DIR"

cd "$REPO_DIR"
git add -A
if git diff --cached --quiet; then
  echo "Aucun changement à publier."
  exit 0
fi

# DRY_RUN=1 : montrer ce qui changerait sans committer ni pousser.
if [ "${DRY_RUN:-0}" = "1" ]; then
  echo "── DRY-RUN : changements qui SERAIENT publiés dans $REPO_DIR${SUBDIR:+/$SUBDIR} ──"
  git diff --cached --stat
  exit 0
fi

git commit -m "Mise à jour du TP (Documents @ $VERSION)"
git push -u origin HEAD
echo "✓ Publié dans $REPO_DIR${SUBDIR:+/$SUBDIR} (push effectué)."
