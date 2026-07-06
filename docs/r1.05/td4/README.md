# R1.05 - TD4 : Modèle Entité/Association et traduction relationnelle

TD4 de la ressource R1.05 (Introduction aux bases de données et SQL).

## Contenu

- `td4.md` : source Markdown du sujet
- `figures/*.mcd` : sources Mocodo des MCD (gestion artistique 1 et 2, gestion sportive 1 et 2)
- `figures/*_geo.json` : géométrie figée de chaque figure, versionnée et relue via `--reuse_geo`

Pas encore de corrigé versionné : la conversion depuis le PDF original reste à faire.

## Figures Mocodo

Pipeline : `.mcd` -> Mocodo -> `.svg` -> Inkscape -> `.pdf`, orchestré par `make`.
Le style commun (palette bleu/jaune, police Latin Modern Roman) est défini dans
`templates/mocodo-colors.json` et `templates/mocodo-shapes.json`.

Après modification d'un `.mcd` : relancer `mocodo` sans `--reuse_geo` pour recalculer
la géométrie, l'ajuster à la main si besoin, puis committer le `_geo.json`.
Détails dans le `CLAUDE.md` du dépôt (section « Figures Mocodo »).

## Compilation (depuis la racine du dépôt)

```bash
make output/r1.05/td4/td4.pdf
```

## Version web

```bash
make web-td4    # page minimale avec lien vers le PDF du sujet
```
