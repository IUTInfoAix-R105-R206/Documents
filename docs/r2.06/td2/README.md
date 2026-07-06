# R2.06 - TD2 : Jointures externes, partitionnement et synthèse des requêtes

TD2 de la ressource R2.06 (Exploitation d'une base de données).

## Contenu

- `td2.md` : source Markdown du sujet, gabarit des versions générées
- `td2-correction.sql` : corrigé SQL (syntaxe Oracle, annoté pour les tests automatisés)
- `figures/` : figures TikZ standalone (`mcd.tex`), compilées en PDF par `make`
- `data/` : lien symbolique vers `../../shared/data/voyages/` (`schema.sql` + `insert.sql`
  pour PostgreSQL/SQLite, `oracle.sql` pour Oracle)
- `web-td.json` : manifeste de la version web (questions exclues ou aménagées pour SQLite)

Les fichiers `td2*.gen.md` (sujet, corrigé, corrigé enseignant) sont générés par
`scripts/generate-questions.py`, qui injecte les requêtes du `.sql` dans le gabarit
`td2.md`. Ils sont gitignorés, comme les PDF produits dans `output/`.

## Compilation (depuis la racine du dépôt)

```bash
make output/r2.06/td2/td2.pdf              # sujet
make output/r2.06/td2/td2-correction.pdf   # corrigé étudiant
make output/r2.06/td2/td2-teacher.pdf      # corrigé enseignant (avec remarques)
```

## Tests SQL

```bash
make test-sql-oracle-docker TD=td2     # référence : Oracle est le SGBD cible du cours
make test-sql-sqlite-local TD=td2      # rapide, sans dépendance lourde
make test-sql-postgresql-local TD=td2  # SGBD utilisé par la CI
```

`TD=td2` filtre par nom de répertoire (toutes ressources confondues). Les annotations
`-- QN - c:X, t:Y` du fichier de correction donnent le nombre de colonnes et de lignes
attendues pour chaque question.

## Version web

```bash
make web-r206-td2    # site interactif SQLite WASM (output/web/r206-td2)
```
