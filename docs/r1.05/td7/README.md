# R1.05 - TD7 : Interrogation en SQL interprété

TD7 de la ressource R1.05 (Introduction aux bases de données et SQL).

## Contenu

- `td7.md` : source Markdown du sujet, gabarit des versions générées
- `td7-correction.sql` : corrigé SQL (syntaxe Oracle, annoté pour les tests automatisés)
- `figures/mcd.tex` : MCD TikZ standalone (package `tikz-er2`), compilé en PDF par `make`
- `data/` : lien symbolique vers `../../shared/data/voyages/` (`schema.sql` + `insert.sql`
  pour PostgreSQL/SQLite, `oracle.sql` pour Oracle)

Les fichiers `td7*.gen.md` (sujet, corrigé, corrigé enseignant) sont générés par
`scripts/generate-questions.py`, qui injecte les requêtes du `.sql` dans le gabarit
`td7.md`. Ils sont gitignorés, comme les PDF produits dans `output/`.

## Compilation (depuis la racine du dépôt)

```bash
make output/r1.05/td7/td7.pdf              # sujet
make output/r1.05/td7/td7-correction.pdf   # corrigé étudiant
make output/r1.05/td7/td7-teacher.pdf      # corrigé enseignant (avec remarques)
```

## Tests SQL

```bash
make test-sql-oracle-docker TD=td7     # référence : Oracle est le SGBD cible du cours
make test-sql-sqlite-local TD=td7      # rapide, sans dépendance lourde
make test-sql-postgresql-local TD=td7  # SGBD utilisé par la CI
```

`TD=td7` filtre par nom de répertoire (toutes ressources confondues). Les annotations
`-- QN - c:X, t:Y` du fichier de correction donnent le nombre de colonnes et de lignes
attendues pour chaque question.

## Version web

```bash
make web-td7    # site interactif SQLite WASM (output/web/td7)
```
