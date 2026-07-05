#!/usr/bin/env bash
# publish-web-td.sh — publie un site de TD généré dans le dépôt étudiant.
#
# Usage : publish-web-td.sh <site_dir> <repo_dir>
#
# Synchronise le contenu de <site_dir> dans <repo_dir> (dépôt Git déjà cloné du
# dépôt étudiant), puis commit + push. Le site (README.md compris) est la source
# de vérité : --delete retire du dépôt étudiant ce qui n'existe plus côté site,
# sauf le dossier .git.
set -euo pipefail

SITE_DIR="${1:?Usage: publish-web-td.sh <site_dir> <repo_dir>}"
REPO_DIR="${2:?Usage: publish-web-td.sh <site_dir> <repo_dir>}"

if [ ! -f "$SITE_DIR/index.html" ]; then
  echo "Erreur : $SITE_DIR ne ressemble pas à un site généré (index.html absent)." >&2
  exit 1
fi
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "Erreur : $REPO_DIR n'est pas un dépôt Git (clonez d'abord le dépôt étudiant)." >&2
  exit 1
fi

# Version du dépôt source (pour le message de commit).
VERSION="$(git describe --exact-match --tags HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo inconnu)"

# Synchronisation : on préserve uniquement le dossier .git du dépôt étudiant.
rsync -a --delete \
  --exclude '.git/' \
  "$SITE_DIR"/ "$REPO_DIR"/

cd "$REPO_DIR"
git add -A
if git diff --cached --quiet; then
  echo "Aucun changement à publier."
  exit 0
fi
git commit -m "Mise à jour du TP (Documents @ $VERSION)"
# -u origin HEAD : fonctionne au premier push (dépôt vide, sans upstream) comme aux suivants.
git push -u origin HEAD
echo "✓ Publié dans $REPO_DIR (push effectué)."
