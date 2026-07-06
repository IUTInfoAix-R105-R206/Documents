# R2.06 - TD4 : Recherche récursive, division et requêtes complexes

TD4 de la ressource R2.06 (Exploitation d'une base de données).

## Contenu

- `td4.md` : source Markdown du sujet, gabarit des versions générées
- `td4-correction.sql` : corrigé SQL (syntaxe Oracle, annoté pour les tests automatisés)
- `figures/` : figures TikZ standalone (`mcd.tex`, `hierarchie-themes.tex`), compilées en PDF par `make`
- `data/` : lien symbolique vers `../../shared/data/questionnaire/` (`schema.sql` + `insert.sql`
  pour PostgreSQL/SQLite, `oracle.sql` pour Oracle)

Les fichiers `td4*.gen.md` (sujet, corrigé, corrigé enseignant) sont générés par
`scripts/generate-questions.py`, qui injecte les requêtes du `.sql` dans le gabarit
`td4.md`. Ils sont gitignorés, comme les PDF produits dans `output/`.

## Compilation (depuis la racine du dépôt)

```bash
make output/r2.06/td4/td4.pdf              # sujet
make output/r2.06/td4/td4-correction.pdf   # corrigé étudiant
make output/r2.06/td4/td4-teacher.pdf      # corrigé enseignant (avec remarques)
```

## Tests SQL

```bash
make test-sql-oracle-docker TD=td4     # référence : Oracle est le SGBD cible du cours
make test-sql-sqlite-local TD=td4      # rapide, sans dépendance lourde
make test-sql-postgresql-local TD=td4  # SGBD utilisé par la CI
```

`TD=td4` filtre par nom de répertoire (toutes ressources confondues). Les annotations
`-- QN - c:X, t:Y` du fichier de correction donnent le nombre de colonnes et de lignes
attendues pour chaque question.

## Version web

```bash
make web-r206-td4    # site interactif SQLite WASM (output/web/r206-td4)
```
