# R2.06 - TD3 : Interrogations en SQL

TD3 de la ressource R2.06 (Exploitation d'une base de données).

## Contenu

- `td3.md` : source Markdown du sujet, gabarit des versions générées
- `td3-correction.sql` : corrigé SQL (syntaxe Oracle, annoté pour les tests automatisés)
- `figures/` : figures TikZ standalone (`mcd.tex`, `hierarchie-modules.tex`), compilées en PDF par `make`
- `data/` : lien symbolique vers `../../shared/data/gestion-pedagogique/` (`schema.sql` + `insert.sql`
  pour PostgreSQL/SQLite, `oracle.sql` pour Oracle)

Les fichiers `td3*.gen.md` (sujet, corrigé, corrigé enseignant) sont générés par
`scripts/generate-questions.py`, qui injecte les requêtes du `.sql` dans le gabarit
`td3.md`. Ils sont gitignorés, comme les PDF produits dans `output/`.

## Compilation (depuis la racine du dépôt)

```bash
make output/r2.06/td3/td3.pdf              # sujet
make output/r2.06/td3/td3-correction.pdf   # corrigé étudiant
make output/r2.06/td3/td3-teacher.pdf      # corrigé enseignant (avec remarques)
```

## Tests SQL

```bash
make test-sql-oracle-docker TD=td3     # référence : Oracle est le SGBD cible du cours
make test-sql-sqlite-local TD=td3      # rapide, sans dépendance lourde
make test-sql-postgresql-local TD=td3  # SGBD utilisé par la CI
```

`TD=td3` filtre par nom de répertoire (toutes ressources confondues). Les annotations
`-- QN - c:X, t:Y` du fichier de correction donnent le nombre de colonnes et de lignes
attendues pour chaque question.

## Version web

```bash
make web-r206-td3    # site interactif SQLite WASM (output/web/r206-td3)
```
