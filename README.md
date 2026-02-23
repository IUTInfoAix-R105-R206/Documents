# Exploitation d'une base de données — Sources des TD

Ce dépôt contient les sources des sujets de travaux dirigés du cours
**Exploitation d'une base de données** (IUT d'Aix-Marseille).

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
- `sqlite3` : requis pour `make test-sql-sqlite` (tests SQL sans PostgreSQL ni Docker)

## Compilation

```bash
# Tous les TD
make all

# Un TD spécifique
make td3

# Nettoyer les fichiers générés
make clean

# Aide
make help
```

Les PDF générés sont placés dans `output/`.

## Versionnage automatique

La version affichée dans les PDF est dérivée de git :

- Si le commit courant porte un tag → le tag est utilisé (ex : `V2.0.5`)
- Sinon → le SHA1 court du commit (ex : `93e26fc`)

Pour publier une nouvelle version :

```bash
git tag V2.0.5
make td3   # le PDF affichera "V2.0.5"
```

## Structure du projet

```
├── docs/                      # Sources des TD
│   ├── td3/
│   │   ├── td3-interrogations-sql.md   # Sujet (Markdown)
│   │   ├── td3-correction.sql          # Correction SQL
│   │   └── figures/                    # Figures (TikZ → PDF)
│   │       ├── hierarchie-modules.tex  # Arborescence des modules (forest)
│   │       └── mcd.tex                 # MCD (tikz-er2)
│   └── shared/
│       └── data/
│           ├── schema.sql              # Schéma de la BD de test
│           └── insert.sql              # Jeu de données
├── templates/
│   ├── template.tex                    # Template LaTeX Pandoc
│   ├── cc-by-nc-sa.svg                 # Badge CC BY-NC-SA (vectoriel)
│   ├── tikz-er2.sty                    # Package TikZ pour diagrammes ER
│   ├── pgf-umlcd.sty                   # Package TikZ UML
│   └── filters/
│       └── custom-styles.lua           # Filtre Lua pour styles personnalisés
├── scripts/
│   └── test-sql.sh                     # Validation des corrections SQL
├── .github/workflows/                  # CI/CD
│   ├── build.yml                       # Compilation des PDF
│   └── test-sql.yml                    # Tests SQL (PostgreSQL)
└── Makefile
```

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

La CI exécute chaque requête contre un jeu de données PostgreSQL et vérifie
que le nombre de colonnes (`c:`) et de lignes (`t:`) correspond.

```bash
# Avec PostgreSQL local
make test-sql

# Avec SQLite (aucune dépendance externe hormis sqlite3)
make test-sql-sqlite

# Avec Docker (lance un conteneur PostgreSQL temporaire)
make test-sql-docker
```

## Contribuer

1. Modifier le fichier `.md` du TD concerné
2. Prévisualiser : `make td3` (par exemple)
3. Comparer le PDF généré avec la version précédente
4. Poser un tag si c'est une nouvelle version : `git tag V2.x.y`
5. Commit + push / merge request

## Licence

Les contenus pédagogiques sont sous licence
[CC BY-NC-SA](https://creativecommons.org/licenses/by-nc-sa/4.0/)
— Mickaël Martin Nevot.
