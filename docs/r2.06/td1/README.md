# R2.06 - TD1 : Opérateurs ensemblistes, LDD et LCT

TD1 de la ressource R2.06 (Exploitation d'une base de données).

## Contenu

- `td1.md` : source Markdown du sujet, gabarit des versions générées
- `td1-correction.sql` : corrigé SQL (syntaxe Oracle, annoté pour les tests automatisés)
- `figures/` : figures TikZ standalone (`mcd.tex`), compilées en PDF par `make`
- `data/` : lien symbolique vers `../../shared/data/voyages/` (`schema.sql` + `insert.sql`
  pour PostgreSQL/SQLite, `oracle.sql` pour Oracle)

Les fichiers `td1*.gen.md` (sujet, corrigé, corrigé enseignant) sont générés par
`scripts/generate-questions.py`, qui injecte les requêtes du `.sql` dans le gabarit
`td1.md`. Ils sont gitignorés, comme les PDF produits dans `output/`.

## Compilation (depuis la racine du dépôt)

```bash
make output/r2.06/td1/td1.pdf              # sujet
make output/r2.06/td1/td1-correction.pdf   # corrigé étudiant
make output/r2.06/td1/td1-teacher.pdf      # corrigé enseignant (avec remarques)
```

## Tests SQL

```bash
make test-sql-oracle-docker TD=td1     # référence : Oracle est le SGBD cible du cours
make test-sql-sqlite-local TD=td1      # rapide, sans dépendance lourde
make test-sql-postgresql-local TD=td1  # SGBD utilisé par la CI
```

`TD=td1` filtre par nom de répertoire (toutes ressources confondues). Les annotations
`-- QN - c:X, t:Y` du fichier de correction donnent le nombre de colonnes et de lignes
attendues pour chaque question.

Les questions LDD/LMD (créations, mises à jour, transactions) n'ont pas d'annotations
`c:t` : elles ne retournent pas de résultat tabulaire.

## Version web

```bash
make web-r206-td1    # site interactif SQLite WASM (output/web/r206-td1)
```
