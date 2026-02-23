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
  texlive-pictures texlive-science texlive-plain-generic lmodern
```

## Compilation

```bash
# Tous les TD
make all

# Un TD spécifique
make td3

# Aide
make help
```

Les PDF générés sont placés dans `output/`.

## Structure du projet

```
├── docs/                      # Sources des TD
│   ├── td3/
│   │   ├── td3-interrogations-sql.md   # Sujet (Markdown)
│   │   ├── td3-correction.sql          # Correction SQL
│   │   └── figures/                    # Figures (TikZ → PDF)
│   └── shared/
│       └── data/
│           ├── schema.sql              # Schéma de la BD de test
│           └── insert.sql              # Jeu de données
├── templates/
│   ├── template.tex                    # Template LaTeX Pandoc
│   └── filters/
│       └── custom-styles.lua           # Filtre pour styles personnalisés
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
compilées séparément et incluses en tant que PDF dans le document principal.
Cela permet de les modifier et versionner comme du code.

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
# Lancer les tests localement (nécessite PostgreSQL)
make test-sql
```

## Contribuer

1. Modifier le fichier `.md` du TD concerné
2. Prévisualiser : `make td3` (par exemple)
3. Comparer le PDF généré avec la version précédente
4. Commit + push / merge request

## Licence

Les contenus pédagogiques sont sous licence
[CC BY-NC-SA](https://creativecommons.org/licenses/by-nc-sa/4.0/)
— Mickaël Martin Nevot.
