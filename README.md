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

- Si le commit courant porte un tag → le tag est utilisé (ex : `V2.0.5`)
- Sinon → le SHA1 court du commit (ex : `93e26fc`)

Pour publier une nouvelle version :

```bash
git tag V2.0.5
make r206   # les PDF afficheront "V2.0.5"
```

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

## Contribuer

1. Modifier le fichier `.md` du TD concerné
2. Prévisualiser : `make r206` (par exemple)
3. Comparer le PDF généré avec la version précédente
4. Poser un tag si c'est une nouvelle version : `git tag V2.x.y`
5. Commit + push / merge request

## Licence

Les contenus pédagogiques sont sous licence
[CC BY-NC-SA](https://creativecommons.org/licenses/by-nc-sa/4.0/)
— Mickaël Martin Nevot.
