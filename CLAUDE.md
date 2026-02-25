# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projet

Sources Markdown des sujets de TD des cours de bases de données de l'IUT d'Aix-Marseille :
- **R1.05** — Introduction aux bases de données et SQL (7 TD)
- **R2.06** — Exploitation d'une base de données (6 TD)

Les sujets sont compilés en PDF via Pandoc + LaTeX. Le but est de remplacer les sources Word par du Markdown versionné sous Git, avec CI pour la compilation PDF et la validation des corrections SQL.

## Commandes essentielles

### Compilation PDF
- `make all` : compile tous les TD en PDF (sortie dans `output/`)
- `make r105` : compile tous les TD de R1.05
- `make r206` : compile tous les TD de R2.06
- `make clean` : supprime les fichiers générés
- `make help` : liste des cibles disponibles

### Tests SQL
- `make test-sql-postgresql-local` : valide avec PostgreSQL local
- `make test-sql-postgresql-docker` : valide avec PostgreSQL via Docker
- `make test-sql-sqlite-local` : valide avec SQLite local (aucune dépendance hormis `sqlite3`)
- `make test-sql-sqlite-docker` : valide avec SQLite dans Docker (image `debian:bookworm-slim`)
- `make test-sql-oracle-local` : valide avec Oracle local (`sqlplus` requis)
- `make test-sql-oracle-docker` : valide avec Oracle Free via Docker (image `gvenzl/oracle-free`, ~1-2 min de démarrage)
- `./scripts/test-sql.sh postgres` : test avec PostgreSQL
- `./scripts/test-sql.sh sqlite` : test avec SQLite
- `./scripts/test-sql.sh oracle` : test avec Oracle (nécessite Oracle installé)

### Figures
- Compiler une figure standalone : `cd docs/r2.06/td3/figures && TEXINPUTS="$(pwd)/../../../../templates:" pdflatex mcd.tex`
- Compiler toutes les figures du TD3 R2.06 : `make r206` (les compile automatiquement avec `TEXINPUTS` correct)

## Architecture

```
docs/r1.05/tdN/              → TD de R1.05 (PDF/docx de référence, corrections SQL pour TD6-TD7)
docs/r2.06/tdN/              → TD de R2.06 (sources Markdown, corrections SQL, figures TikZ)
docs/shared/data/            → Bases de données partagées entre ressources
  gestion-pedagogique/       →   R2.06 TD3/TD5/TD6 (schema.sql, insert.sql, oracle.sql)
  voyages/                   →   R1.05 TD7, R2.06 TD1-TD2 (schema.sql, insert.sql, oracle.sql)
  questionnaire/             →   R2.06 TD4 (oracle.sql)
templates/template.tex       → Template LaTeX Pandoc (reproduit le style des anciens PDF Word)
templates/filters/           → Filtres Lua pour Pandoc (styles personnalisés)
templates/cc-by-nc-sa.svg    → Badge licence Creative Commons (vectoriel, source)
templates/tikz-er2.sty       → Package TikZ pour diagrammes ER (ellipses associations)
templates/pgf-umlcd.sty      → Package TikZ UML class diagrams
scripts/                     → Scripts utilitaires (test-sql.sh, generate-sql-report.py)
.github/workflows/           → CI GitHub Actions (build PDF + test SQL)
output/                      → PDF générés (gitignored)
```

Chaque TD avec des corrections SQL possède un lien symbolique `data/` → `../../shared/data/<nom-bd>/` pour que `test-sql.sh` trouve automatiquement le schéma et les données.

## Pipeline de compilation

Markdown → Pandoc (avec filtre Lua `custom-styles.lua`) → LaTeX (via `template.tex`) → PDF (pdflatex avec `--shell-escape`).

Le flag `--shell-escape` est requis pour que le package LaTeX `svg` puisse invoquer Inkscape afin de convertir le badge CC BY-NC-SA depuis le SVG.

Les figures sont des fichiers LaTeX `standalone` compilés séparément en PDF puis inclus dans le document principal. Elles utilisent les packages `forest` (arbres) et `tikz-er2` (diagrammes MCD).

## Conventions Markdown des sujets

### Métadonnées YAML (en-tête de chaque TD)

```yaml
title: "TD3 : Interrogations en SQL"
course: "Exploitation d'une base de données"
authors:
  - "Rosine Cicchetti"
  - "Lotfi Lakhal"
  - "Mickaël Martin Nevot"
license: "CC BY-NC-SA"
license-holder: "Rosine Cicchetti"
website: "www.mickael-martin-nevot.com"
```

La version affichée dans le PDF est dérivée de git par le Makefile :
- Si le commit courant a un tag → le tag est utilisé (ex : `V2.0.5`)
- Sinon → le SHA1 court (ex : `93e26fc`)

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

### Figures

Les figures flottent naturellement (comportement LaTeX par défaut). Ne pas forcer leur placement.

**Référencer une figure dans le texte** — utiliser du LaTeX brut inline avec la syntaxe `{=latex}` pour que `~` et `\ref` soient interprétés correctement :

```markdown
La figure est présentée en `figure~\ref{fig:mcd}`{=latex}.
```

**Figure standard** (portrait) :

```markdown
![Légende](figures/fichier.pdf){#fig:id width=90%}
```

**Figure large en paysage** — utiliser un bloc LaTeX brut directement dans le Markdown :

```markdown
\begin{sidewaysfigure}
\centering
\includegraphics[width=\textheight]{figures/mcd.pdf}
\caption{Légende}
\label{fig:mcd}
\end{sidewaysfigure}
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
  texlive-pictures texlive-science texlive-plain-generic lmodern inkscape sqlite3
```

- `inkscape` : requis pour la compilation des SVG via le package LaTeX `svg`
- `sqlite3` : requis pour `make test-sql-sqlite-local` (tests SQL sans PostgreSQL ni Docker)

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
- **Attention CI** : Inkscape doit être installé dans l'environnement CI pour le badge SVG

### Workflow test-sql.yml
- Déclenché à chaque modification des fichiers de correction SQL ou données
- Lance un conteneur PostgreSQL 16
- Charge le schéma et les données de test
- Exécute `./scripts/test-sql.sh postgres`
- Vérifie que chaque requête retourne le nombre attendu de colonnes et lignes

## Problèmes résolus et solutions techniques

### Compilation Pandoc
- **Chemins relatifs des templates** : Le Makefile utilise `cd docs/r2.06/td3` avant d'appeler Pandoc, donc les chemins doivent être relatifs à ce répertoire (`../../../templates/...`)
- **Filtre Lua et caractères spéciaux** :
  - Utiliser `pandoc.utils.stringify()` au lieu de `pandoc.write()` (compatibilité)
  - Échapper les caractères LaTeX spéciaux (`#`, `$`, `%`, `&`, `_`, etc.) avec la fonction `escape_latex()`
  - Critique pour les clés étrangères notées avec `#` (ex: `specProf#`)
- **Shell-escape** : `--pdf-engine-opt=-shell-escape` est passé à Pandoc pour que le package `svg` puisse invoquer Inkscape

### Versionnage dynamique (Makefile)
La version affichée dans les PDF est calculée automatiquement :
```makefile
GIT_VERSION := $(shell git describe --exact-match --tags HEAD 2>/dev/null || git rev-parse --short HEAD)
```
Passée à Pandoc via `--variable=version:$(GIT_VERSION)`, elle écrase la valeur YAML du fichier Markdown.

### Badge Creative Commons
- Fichier source vectoriel : `templates/cc-by-nc-sa.svg` (officiel CC BY-NC-SA depuis le kit presse CC)
- Inclus dans le template via `\includesvg[height=Xpt]{...}` (package `svg`)
- Inkscape est invoqué automatiquement lors de la compilation (nécessite `--shell-escape`)

### Mise en forme PDF
Le template LaTeX reproduit l'apparence d'un document professionnel :
- **Marges** : `body={160mm,250mm}, left=25mm, top=20mm`
- **Questions (listes de définitions)** : `style=sameline` pour que le numéro apparaisse sur la même ligne
- **Figures** : comportement flottant LaTeX naturel (`tbp`) — ne pas forcer avec `H` (crée des espaces blancs)
- **Figures larges** : `sidewaysfigure` (package `rotating`) pour les diagrammes en paysage (MCD, hiérarchie)
- **Espacements** : `\parskip=6pt`, `\parindent=0pt` (style sans indentation)
- **Tableaux** : police `\small`, `\arraystretch=1.3` pour meilleure lisibilité
- **Captions** : police small, label en gras, espacement réduit

### Figures TikZ et packages personnalisés
- `tikz-er2.sty` et `pgf-umlcd.sty` sont dans `templates/` — chargés via `TEXINPUTS`
- La règle Makefile pour les figures standalone définit `TEXINPUTS="$(CURDIR)/$(TEMPLATE_DIR):"` avant `pdflatex`
- Le MCD utilise `tikz-er2` avec associations en **ellipses** (défaut tikz-er2, convention préférée)

### MCD — conventions de nommage et placement des cardinalités
- **Attributs** : noms camelCase du schéma relationnel (`numEt`, `heureCMPrev`, `coefCC`…), pas les anciens noms `H_Cours_Prev`
- **Cardinalités** : placées via des **ancres de bord** des entités (ex: `mat.south`, `etud.north`, `mat.315`) plutôt que le centre, pour que `pos=0.1` tombe dans l'espace entre entité et association — les valeurs `pos` sont ajustées manuellement par lien

### Makefile
Les règles de compilation spécifient explicitement tous les paramètres Pandoc au lieu de réutiliser `PANDOC_OPTS`, pour permettre l'ajustement correct des chemins relatifs lors du `cd docs/r2.06/td3`.

## Règles de développement

- **Données** : les valeurs dans la base de données sont en MAJUSCULES sans diacritiques (convention du cours)
- **SQL** : les corrections suivent la syntaxe Oracle (le cours utilise Oracle)
- **Corrections SQL** : doivent inclure les annotations `-- QN - c:X, t:Y` pour les tests automatisés
- **Figures TikZ** : doivent rester en format texte pour être diffables et versionnables
- **Placement des figures** : ne pas forcer avec `H` ; référencer les figures avec `` `figure~\ref{fig:X}`{=latex} `` dans le texte ; figures larges en `sidewaysfigure`
- **Output** : ne jamais modifier les fichiers dans `output/` (générés automatiquement par `make`)
- **Tests** : toute nouvelle requête SQL doit être validée avec `make test-sql-postgresql-local` (ou `make test-sql-sqlite-local`) avant commit
- **Template LaTeX** : éviter de redéfinir complètement les environnements standards (utiliser `\AtBeginEnvironment` de `etoolbox`)

## Jeux de données de test

### Gestion pédagogique (R2.06 TD3/TD5/TD6)
- **56 étudiants** (27 sans notes, 45 de 2e année, 11 de 1re année)
- **17 professeurs**, **31 modules**, **121 enseignements**, **79 notes**
- Fichiers : `docs/shared/data/gestion-pedagogique/{oracle.sql,schema.sql,insert.sql}`

### Voyages (R1.05 TD7, R2.06 TD1-TD2)
- Fichiers : `docs/shared/data/voyages/{oracle.sql,schema.sql,insert.sql}`

### Questionnaire (R2.06 TD4)
- Fichiers : `docs/shared/data/questionnaire/oracle.sql`
- Adaptations PostgreSQL/SQLite à créer

### Validation locale
La validation locale doit être faite avec oracle dans un conteneur docker car les sujets sont écrits pour lui en premier lieu.

### État de validation
Toutes les corrections du TD3 R2.06 (Q1-Q26) ont été validées avec les résultats attendus du sujet.

## État actuel du projet

### Fonctionnel
- ✅ Structure multi-ressource (R1.05, R2.06) avec données partagées
- ✅ Compilation Markdown → PDF via Pandoc + LaTeX
- ✅ Makefile avec cibles par ressource (r105, r206, all, clean)
- ✅ Filtre Lua pour styles personnalisés (pk, fk, pkfk, expected)
- ✅ Figures TikZ (hiérarchie modules, MCD avec tikz-er2)
- ✅ Template LaTeX reproduisant le style professionnel
- ✅ Badge CC BY-NC-SA vectoriel (SVG via package `svg` + Inkscape)
- ✅ Versionnage dynamique depuis git (tag ou SHA1 court)
- ✅ Jeux de données complets (gestion-pedagogique, voyages, questionnaire)
- ✅ Script de test SQL multi-BD fonctionnel (test-sql.sh)
- ✅ CI GitHub Actions (build PDF + test SQL PostgreSQL/SQLite/Oracle)
- ✅ Corrections SQL R2.06 TD3 validées (Q1-Q26)
- ✅ Corrections SQL importées pour tous les TD R2.06 (TD1-TD6)
- ✅ Corrections SQL importées pour R1.05 TD6-TD7

### À faire
- **Conversions Markdown** : convertir les sujets R2.06 TD2/TD4/TD5/TD6 de Word vers Markdown (même modèle que TD3)
- **Conversions Markdown R1.05** : convertir les sujets R1.05 de Word/PDF vers Markdown
- **Annotations c:t manquantes** : compléter les annotations `-- QN - c:X, t:Y` pour R1.05 TD6 (0/28) et R2.06 TD1 (10/20)
- **Adaptations PostgreSQL/SQLite** : créer schema.sql + insert.sql pour les BD Questionnaire et Airbase
- **SAE** : intégrer S1.04 et S2.04 quand prêts
- **Tests CI** : valider les workflows GitHub Actions avec la nouvelle structure
