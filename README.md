# Bases de données — Sources des TD

[![Build PDFs](https://github.com/IUTInfoAix-R105-R206/Documents/actions/workflows/build.yml/badge.svg)](https://github.com/IUTInfoAix-R105-R206/Documents/actions/workflows/build.yml)
[![Test SQL Corrections](https://github.com/IUTInfoAix-R105-R206/Documents/actions/workflows/test-sql.yml/badge.svg)](https://github.com/IUTInfoAix-R105-R206/Documents/actions/workflows/test-sql.yml)

Ce dépôt contient les sources des sujets de travaux dirigés des cours de
bases de données de l'IUT d'Aix-Marseille :

- **R1.05** — Introduction aux bases de données et SQL
- **R2.06** — Exploitation d'une base de données

Les sujets sont écrits en **Markdown** et compilés en **PDF** via
[Pandoc](https://pandoc.org/) + LaTeX, permettant un workflow collaboratif
sous Git avec intégration continue.

## Prérequis

```bash
# Ubuntu / Debian
sudo apt-get install build-essential pandoc texlive-latex-base texlive-latex-extra \
  texlive-latex-recommended texlive-fonts-recommended texlive-lang-french \
  texlive-pictures texlive-science texlive-plain-generic lmodern inkscape sqlite3
```

- `inkscape` : requis pour inclure le badge Creative Commons au format SVG lors de la compilation PDF
- `sqlite3` : requis pour `make test-sql-sqlite-local` (tests SQL sans PostgreSQL ni Docker)

## Environnement de développement (Dev Container)

Un [Dev Container](https://containers.dev/) est fourni avec **toutes les dépendances
pré-installées** (Pandoc, LaTeX, Inkscape, SQLite, PostgreSQL client, Docker CLI).
Il suffit de Docker et de VS Code pour démarrer.

### Prérequis

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (ou Docker Engine)
- [VS Code](https://code.visualstudio.com/) avec l'extension
  [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- Alternative : ouvrir le dépôt directement dans
  [GitHub Codespaces](https://github.com/features/codespaces)

### Démarrage

1. Cloner le dépôt et l'ouvrir dans VS Code
2. Cliquer sur **« Reopen in Container »** (ou `Ctrl+Shift+P` → *Dev Containers: Reopen in Container*)
3. Attendre la fin du build (~2-3 min la première fois, Oracle met ~1 min à démarrer)

### Ce qui est inclus

| Composant | Détail |
|---|---|
| **Compilation PDF** | Pandoc, LaTeX (texlive), Inkscape |
| **PostgreSQL 16** | Service Docker, base `gestion_pedagogique` pré-créée |
| **Oracle Free 23.5** | Service Docker, utilisateur `testuser` pré-créé |
| **SQLite 3** | Installé dans le conteneur |
| **SQLTools** | 3 connexions pré-configurées (PostgreSQL, SQLite, Oracle) |
| **Hooks Git** | Pre-commit SQLFluff installé automatiquement |
| **Python 3.13** | Avec SQLFluff et dépendances (via `requirements.txt`) |

### Tester les corrections SQL

Les variables d'environnement sont pré-configurées — les trois SGBD
fonctionnent directement :

```bash
make test-sql-postgresql-local   # PostgreSQL (service Docker)
make test-sql-sqlite-local       # SQLite (local)
make test-sql-oracle-local       # Oracle (service Docker)
```

## Compilation

```bash
# Tous les TD (R1.05 + R2.06)
make all

# Tous les TD d'une ressource
make r105
make r206

# Nettoyer les fichiers générés
make clean

# Aide
make help
```

Les PDF générés sont placés dans `output/r1.05/` et `output/r2.06/`.

## Versionnage automatique

La version affichée dans les PDF est dérivée de git :

- Si le commit courant porte un tag → le tag est utilisé (ex : `v2.0.5`)
- Sinon → le SHA1 court du commit (ex : `93e26fc`)

Pour publier une nouvelle version :

```bash
make bump              # incrémente le patch   (v1.0.0 → v1.0.1)
make bump PART=minor   # incrémente le minor   (v1.0.1 → v1.1.0)
make bump PART=major   # incrémente le major   (v1.1.0 → v2.0.0)
```

La cible `bump` crée un commit vide avec le numéro de version, le tag
correspondant, et pousse les deux sur `origin`.

## Structure du projet

```
├── docs/
│   ├── r1.05/                        # R1.05 — Introduction aux BD et SQL
│   │   ├── td1/                      #   Algèbre relationnelle
│   │   ├── td2/                      #   Concepts relationnels
│   │   ├── td3/                      #   DF et normalisation
│   │   ├── td4/                      #   Modèle E/A
│   │   ├── td5/                      #   Conception E/A
│   │   ├── td6/                      #   Interrogation SQL (BD Airbase)
│   │   └── td7/                      #   SQL interprété (BD Voyages)
│   ├── r2.06/                        # R2.06 — Exploitation d'une BD
│   │   ├── td1/                      #   Opérateurs ensemblistes (BD Voyages)
│   │   ├── td2/                      #   Jointures externes (BD Voyages)
│   │   ├── td3/                      #   Interrogations SQL (BD Gestion péda.)
│   │   │   └── figures/              #   Figures TikZ (MCD, hiérarchie)
│   │   ├── td4/                      #   Récursif, division (BD Questionnaire)
│   │   ├── td5/                      #   SQL avancé (BD Gestion péda.)
│   │   └── td6/                      #   Vues, tables système (BD Gestion péda.)
│   └── shared/
│       └── data/
│           ├── gestion-pedagogique/  # Schéma partagé R2.06 TD3/TD5/TD6
│           ├── voyages/              # Schéma partagé R1.05 TD7, R2.06 TD1-TD2
│           └── questionnaire/        # Schéma R2.06 TD4
├── templates/
│   ├── template.tex                  # Template LaTeX Pandoc
│   ├── cc-by-nc-sa.svg              # Badge CC BY-NC-SA (vectoriel)
│   ├── tikz-er2.sty                 # Package TikZ pour diagrammes ER
│   ├── pgf-umlcd.sty               # Package TikZ UML
│   └── filters/
│       └── custom-styles.lua        # Filtre Lua pour styles personnalisés
├── scripts/
│   ├── test-sql.sh                  # Validation des corrections SQL
│   └── generate-sql-report.py       # Génération du rapport HTML multi-SGBD
├── .github/workflows/               # CI/CD
│   ├── build.yml                    # Compilation des PDF
│   └── test-sql.yml                 # Tests SQL (PostgreSQL, SQLite, Oracle)
└── Makefile
```

## Bases de données

| Base de données | Utilisée par |
|---|---|
| **Airbase** (Pilote, Avion, Vol) | R1.05 TD1-TD2-TD6 |
| **Voyages** (Voyage, Client, Planning...) | R1.05 TD7, R2.06 TD1-TD2 |
| **Gestion pédagogique** (Etudiant, Professeur, Module...) | R2.06 TD3-TD5-TD6 |
| **Questionnaire** (Etudiant, Question, Theme...) | R2.06 TD4 |

Chaque TD avec des corrections SQL possède un lien symbolique `data/` pointant
vers le sous-dossier approprié dans `docs/shared/data/`.

## Conventions du Markdown

### Résultats attendus (en bleu italique)

```markdown
Q1
: Texte de la question. [2 attributs, 9 tuples]{.expected}
```

### Schéma relationnel

```markdown
`Etudiant` ([numEt]{.pk}, nomEt, [*code#*]{.fk})
```

- `{.pk}` → clef primaire (souligné)
- `{.fk}` → clef étrangère (italique)
- `{.pkfk}` → clef primaire + étrangère (souligné + italique)

### Remarques

```markdown
::: remarques
*Remarques*
Contenu des remarques...
:::
```

### Figures TikZ

Les figures sont des fichiers LaTeX `standalone` dans `figures/`. Elles sont
compilées séparément (avec `TEXINPUTS` pointant vers `templates/` pour charger
`tikz-er2.sty`) et incluses en tant que PDF dans le document principal.

Les figures larges (MCD, hiérarchie) sont intégrées en mode paysage via
`\begin{sidewaysfigure}...\end{sidewaysfigure}` directement dans le Markdown.

Les références aux figures utilisent du LaTeX brut inline :

```markdown
La figure est présentée en `figure~\ref{fig:mcd}`{=latex}.
```

## Validation SQL (CI)

Les fichiers de correction SQL contiennent des annotations de résultats
attendus :

```sql
-- Q1 - c:2, t:9
-- Description de la requête
SELECT ...
```

La CI exécute chaque requête contre un jeu de données et vérifie
que le nombre de colonnes (`c:`) et de lignes (`t:`) correspond.

```bash
# Avec PostgreSQL local
make test-sql-postgresql-local

# Avec PostgreSQL dans Docker
make test-sql-postgresql-docker

# Avec SQLite local (aucune dépendance externe hormis sqlite3)
make test-sql-sqlite-local

# Avec SQLite dans Docker
make test-sql-sqlite-docker

# Avec Oracle local (sqlplus requis)
make test-sql-oracle-local

# Avec Oracle Free dans Docker
make test-sql-oracle-docker
```

## Lint SQL (SQLFluff)

Le projet utilise [SQLFluff](https://sqlfluff.com/) pour garantir un style
SQL cohérent dans les fichiers de correction. La configuration est dans
`.sqlfluff` (dialecte Oracle, règles adaptées au contexte pédagogique).

```bash
# Vérifier le style (utilisé par la CI)
make lint-sql

# Corriger automatiquement
make fix-sql

# Installer le hook pre-commit (une seule fois)
make install-hooks
```

Le hook pre-commit lance `sqlfluff fix` automatiquement sur les fichiers
`.sql` stagés avant chaque commit. Si SQLFluff n'est pas installé
localement, le hook est ignoré sans bloquer.

Installation de SQLFluff : `pip install sqlfluff`

## Contribuer

Consultez le [guide de contribution](CONTRIBUTING.md) pour le détail du
processus. En résumé :

1. Installer les hooks : `make install-hooks`
2. Créer une branche : `git checkout -b fix/description`
3. Modifier le fichier `.md` du TD concerné
4. Prévisualiser : `make r206` (par exemple)
5. Commit + push + créer une pull request

## Licence

Les contenus pédagogiques sont sous licence
[CC BY-NC-SA](https://creativecommons.org/licenses/by-nc-sa/4.0/)
— Mickaël Martin Nevot.
