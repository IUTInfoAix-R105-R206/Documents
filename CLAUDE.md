# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projet

Sources Markdown des sujets de TD du cours **"Exploitation d'une base de données"** (IUT d'Aix-Marseille), compilés en PDF via Pandoc + LaTeX. Le but est de remplacer les sources Word par du Markdown versionné sous Git, avec CI pour la compilation PDF et la validation des corrections SQL.

## Commandes essentielles

### Compilation PDF
- `make all` : compile tous les TD en PDF (sortie dans `output/`)
- `make td3` : compile uniquement le TD3
- `make clean` : supprime les fichiers générés
- `make help` : liste des cibles disponibles

### Tests SQL
- `make test-sql` : valide les corrections SQL (PostgreSQL par défaut)
- `./scripts/test-sql.sh postgres` : test avec PostgreSQL
- `./scripts/test-sql.sh sqlite` : test avec SQLite
- `./scripts/test-sql.sh oracle` : test avec Oracle (nécessite Oracle installé)

### Figures
- Compiler une figure standalone : `cd docs/td3/figures && pdflatex hierarchie-modules.tex`
- Compiler toutes les figures du TD3 : `make td3` (les compile automatiquement)

## Architecture

```
docs/tdN/                    → Sources Markdown + corrections SQL + figures TikZ
docs/shared/data/            → Schéma et jeu de données partagés (schema.sql, insert.sql)
templates/template.tex       → Template LaTeX Pandoc (reproduit le style des anciens PDF Word)
templates/filters/           → Filtres Lua pour Pandoc (styles personnalisés)
templates/cc-by-nc-sa.png    → Badge licence Creative Commons
scripts/                     → Scripts utilitaires (test-sql.sh)
.github/workflows/           → CI GitHub Actions (build PDF + test SQL)
output/                      → PDF générés (gitignored)
```

## Pipeline de compilation

Markdown → Pandoc (avec filtre Lua `custom-styles.lua`) → LaTeX (via `template.tex`) → PDF (pdflatex).

Les figures sont des fichiers LaTeX `standalone` compilés séparément en PDF puis inclus dans le document principal. Elles utilisent les packages `forest` (arbres) et `tikz` (diagrammes MCD).

## Conventions Markdown des sujets

### Métadonnées YAML (en-tête de chaque TD)

```yaml
title: "TD3 : Interrogations en SQL"
version: "V2.0.4"
course: "Exploitation d'une base de données"
authors: ["Rosine Cicchetti", "Lotfi Lakhal", "Mickaël Martin Nevot"]
license: "CC BY-NC-SA"
license-holder: "Mickaël Martin Nevot"
website: "www.mickael-martin-nevot.com"
```

### Styles personnalisés (spans Pandoc → LaTeX via filtre Lua)

- `[texte]{.expected}` → résultat attendu en bleu italique
- `[attr]{.pk}` → clef primaire (souligné)
- `[*attr#*]{.fk}` → clef étrangère (italique)
- `[*attr#*]{.pkfk}` → clef primaire + étrangère (souligné + italique)

### Blocs personnalisés (divs Pandoc)

- `::: remarques ... :::` → bloc de remarques
- `:::: schema-relationnel ... ::::` → schéma relationnel

### Questions de TD

Utiliser des listes de définitions Pandoc :

```markdown
Q1
: Texte de la question. [2 attributs, 9 tuples]{.expected}
```

## Conventions des corrections SQL

Les annotations de résultat attendu dans les fichiers de correction suivent le format :

```sql
-- Q1 - c:2, t:9
-- Description de la requête
PROMPT "Q1 - Version algébrique";
SELECT ...;
```

- `c:N` = nombre de colonnes attendues
- `t:N` = nombre de lignes attendues
- `PROMPT` = séparateur entre variantes (spécifique Oracle, ignoré en CI PostgreSQL)

## Dépendances système

Ubuntu/Debian :
```bash
sudo apt-get install build-essential pandoc texlive-latex-base texlive-latex-extra \
  texlive-latex-recommended texlive-fonts-recommended texlive-lang-french \
  texlive-pictures texlive-science texlive-plain-generic lmodern
```

Pour les tests SQL : PostgreSQL, SQLite, ou Oracle selon disponibilité.

## Gestion multi-SGBD

Le projet utilise une stratégie multi-SGBD pour équilibrer les contraintes pédagogiques et techniques :

- **Cible pédagogique** : Oracle (syntaxe des corrections SQL, utilisé dans le cours)
- **CI/Tests automatisés** : PostgreSQL (léger, disponible sur GitHub Actions)
- **Tests locaux** : SQLite ou PostgreSQL selon disponibilité
- **Adaptations nécessaires entre SGBD** :
  - `EXCEPT` (PostgreSQL/SQLite) vs `MINUS` (Oracle)
  - `PROMPT` (Oracle-only, ignoré dans les tests automatisés)
  - Division réelle : SQLite nécessite `* 1.0` pour forcer le résultat en virgule flottante

## CI/CD (GitHub Actions)

### Workflow build.yml
- Déclenché à chaque push/PR sur `docs/`, `templates/`, `Makefile`
- Compile tous les TD en PDF avec `make all`
- Publie les PDF comme artefacts (rétention : 30 jours)
- Déploie sur GitHub Pages (branche main uniquement, accessible sous `/pdfs`)

### Workflow test-sql.yml
- Déclenché à chaque modification des fichiers de correction SQL ou données
- Lance un conteneur PostgreSQL 16
- Charge le schéma et les données de test
- Exécute `./scripts/test-sql.sh postgres`
- Vérifie que chaque requête retourne le nombre attendu de colonnes et lignes

## Règles de développement

- **Données** : les valeurs dans la base de données sont en MAJUSCULES sans diacritiques (convention du cours)
- **SQL** : les corrections suivent la syntaxe Oracle (le cours utilise Oracle)
- **Corrections SQL** : doivent inclure les annotations `-- QN - c:X, t:Y` pour les tests automatisés
- **Figures** : doivent rester en format texte (TikZ/forest) pour être diffables et versionnables
- **Output** : ne jamais modifier les fichiers dans `output/` (générés automatiquement par `make`)
- **Tests** : toute nouvelle requête SQL doit être validée avec `make test-sql` avant commit

## Jeu de données de test

### Contenu
- **56 étudiants** (27 sans notes, 45 de 2e année, 11 de 1re année)
- **17 professeurs**
- **31 modules** (hiérarchie de PPNINFO aux matières feuilles)
- **121 enseignements**
- **79 notes**

### Fichiers
- `docs/shared/data/gestion-pedagogique-oracle.sql` — Script Oracle original (schéma + données), référence
- `docs/shared/data/schema.sql` — Schéma adapté pour PostgreSQL/SQLite
- `docs/shared/data/insert.sql` — INSERT standards + ALTER TABLE pour la FK circulaire

### Validation locale rapide
```bash
# Avec SQLite
sqlite3 /tmp/test.db < docs/shared/data/schema.sql
sqlite3 /tmp/test.db < docs/shared/data/insert.sql
sqlite3 /tmp/test.db "SELECT COUNT(*) FROM Etudiant;"  # → 56

# Avec PostgreSQL
psql -U test -d gestion_pedagogique -f docs/shared/data/schema.sql
psql -U test -d gestion_pedagogique -f docs/shared/data/insert.sql
```

### État de validation
Toutes les corrections du TD3 (Q1-Q26) ont été validées avec les résultats attendus du sujet.
