# R1.05 - TD6 : Interrogation en SQL

TD6 de la ressource R1.05 (Introduction aux bases de données et SQL).

## Contenu

- `td6.md` : source Markdown du sujet, gabarit des versions générées
- `td6-correction.sql` : corrigé SQL (syntaxe Oracle, annoté pour les tests automatisés)
- `figures/mcd.tex` : MCD TikZ standalone (package `tikz-er2`), compilé en PDF par `make`
- `data/` : lien symbolique vers `../../shared/data/airbase/` (`schema.sql` + `insert.sql`
  pour PostgreSQL/SQLite, `oracle.sql` pour Oracle)

Les fichiers `td6*.gen.md` (sujet, corrigé, corrigé enseignant) sont générés par
`scripts/generate-questions.py`, qui injecte les requêtes du `.sql` dans le gabarit
`td6.md`. Ils sont gitignorés, comme les PDF produits dans `output/`.

## Compilation (depuis la racine du dépôt)

```bash
make output/r1.05/td6/td6.pdf              # sujet
make output/r1.05/td6/td6-correction.pdf   # corrigé étudiant
make output/r1.05/td6/td6-teacher.pdf      # corrigé enseignant (avec remarques)
```

## Tests SQL

```bash
make test-sql-oracle-docker TD=td6     # référence : Oracle est le SGBD cible du cours
make test-sql-sqlite-local TD=td6      # rapide, sans dépendance lourde
make test-sql-postgresql-local TD=td6  # SGBD utilisé par la CI
```

`TD=td6` filtre par nom de répertoire (toutes ressources confondues). Les annotations
`-- QN - c:X, t:Y` du fichier de correction donnent le nombre de colonnes et de lignes
attendues pour chaque question.

## Version web

```bash
make web-td6    # site interactif SQLite WASM (output/web/td6)
```
