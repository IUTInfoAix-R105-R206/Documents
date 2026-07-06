# R2.06 - TD6 : Vues, tables système et rappels SQL

TD6 de la ressource R2.06 (Exploitation d'une base de données).

## Contenu

- `td6.md` : source Markdown du sujet, gabarit des versions générées
- `td6-correction.sql` : corrigé SQL (syntaxe Oracle, annoté pour les tests automatisés)
- `figures/` : figures TikZ standalone (`mcd.tex`, `hierarchie-modules.tex`), compilées en PDF par `make`
- `data/` : lien symbolique vers `../../shared/data/gestion-pedagogique/` (`schema.sql` + `insert.sql`
  pour PostgreSQL/SQLite, `oracle.sql` pour Oracle)

Les fichiers `td6*.gen.md` (sujet, corrigé, corrigé enseignant) sont générés par
`scripts/generate-questions.py`, qui injecte les requêtes du `.sql` dans le gabarit
`td6.md`. Ils sont gitignorés, comme les PDF produits dans `output/`.

## Compilation (depuis la racine du dépôt)

```bash
make output/r2.06/td6/td6.pdf              # sujet
make output/r2.06/td6/td6-correction.pdf   # corrigé étudiant
make output/r2.06/td6/td6-teacher.pdf      # corrigé enseignant (avec remarques)
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
make web-r206-td6    # page minimale avec lien vers le PDF du sujet
```
