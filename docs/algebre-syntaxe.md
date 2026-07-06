# Syntaxe de référence — algèbre relationnelle textuelle

Cette notation est celle **imposée strictement** par le compilateur des pages web
d'algèbre (`templates/web-td/js/algebra.js`). Tout écart est rejeté avec un message
d'erreur ciblé. Les corrections des TD (ex. `docs/r1.05/td1/td1-correction.md`) sont
écrites dans cette syntaxe.

## Principe

Une requête est une **suite d'affectations**, une par ligne. La **dernière relation
affectée** est la réponse.

```
R1 := SELECTION (Avion / capacite > 350)
R2 := PROJECTION (R1 / numAv, nomAv)
```

## Règles lexicales

| Élément            | Forme                              | Exemple                     |
|--------------------|------------------------------------|-----------------------------|
| Affectation        | `:=`                               | `R1 := ...`                 |
| Opérateurs         | MAJUSCULES, sans accent            | `SELECTION`, `DIFFERENCE`   |
| Renommage (flèche) | `->`                               | `numPil -> numPil2`         |
| Booléens           | `ET`, `OU`, `NON`                  | `a > 1 ET b = 2`            |
| Comparateurs       | `=`  `<>`  `<`  `>`  `<=`  `>=`     | `salaire >= 5000`           |
| Chaînes            | apostrophes `'...'`                | `'NICE'`                    |
| Heures             | `HH:MM` (sans apostrophes)         | `heureDep >= 18:00`         |
| Commentaires       | `--` jusqu'en fin de ligne         | `-- pilotes en service`     |
| Noms de relations  | `R1`, `R2`, `R2.1` (lettres/chiffres/`.`) | `R12.3`             |

Sont **rejetés** (avec message d'aide) : `=` pour l'affectation, les opérateurs en
minuscules ou accentués (`sélection`), `AND/OR/NOT` à la place de `ET/OU/NON`, la
flèche Unicode `→` (utiliser `->`).

## Opérateurs

| Opérateur | Syntaxe | Effet |
|-----------|---------|-------|
| `SELECTION` | `SELECTION (R / condition)` | tuples de `R` vérifiant la condition (booléens `ET/OU/NON`, parenthèses) |
| `PROJECTION` | `PROJECTION (R / a1, a2, ...)` | attributs `a1, a2, ...` (ensemble : doublons supprimés) |
| `RENOMMAGE` | `RENOMMAGE (R / ancien -> nouveau, ...)` | renomme des attributs (données inchangées) |
| `UNION` | `UNION (R1, R2)` | union ensembliste (relations compatibles) |
| `INTERSECTION` | `INTERSECTION (R1, R2)` | intersection ensembliste |
| `DIFFERENCE` | `DIFFERENCE (R1, R2)` | différence ensembliste |
| `JOINTURE` | `JOINTURE (R1, R2 / aG op aD [ET ...])` | thêta-jointure : **concatène** les schémas (un attribut de même nom apparaît **deux fois**) |
| `JOINTURE_NATURELLE` | `JOINTURE_NATURELLE (R1, R2)` | jointure naturelle : sur **tous** les attributs de même nom, gardés **une seule** fois |
| `DIVISION` | `DIVISION (dividende, diviseur)` | division relationnelle (attributs du diviseur inférés par nom) |

### JOINTURE vs JOINTURE_NATURELLE

`JOINTURE` est la thêta-jointure formelle : le résultat contient **toutes** les
colonnes des deux relations. Après `JOINTURE (R1, R2 / numPil = numPil)`, l'attribut
`numPil` est présent **deux fois** — le projeter directement est donc **ambigu**
(erreur). Pour le récupérer, renommer un côté :

```
R1 := PROJECTION (Pilote / numPil)
R2 := RENOMMAGE (Vol / numPil -> numPilVol)
R3 := JOINTURE (R1, R2 / numPil = numPilVol)
R4 := PROJECTION (R3 / numPil)          -- sans ambiguïté
```

`JOINTURE_NATURELLE` fusionne les attributs de même nom (une seule occurrence),
ce qui rend leur projection directe possible :

```
R1 := PROJECTION (Pilote / numPil)
R2 := JOINTURE_NATURELLE (R1, Vol)      -- numPil fusionné
R3 := PROJECTION (R2 / numPil)
```

## Erreurs fréquentes signalées

- `Utilisez « := » pour l'affectation (et non « = »)`
- `opérateur « sélection » : écrivez-le en majuscules sans accent : SELECTION`
- `attribut « numPil » ambigu (présent 2 fois, typiquement après une JOINTURE)…`
- `UNION impossible : N attribut(s) à gauche mais M à droite`
- `relation « Rx » non définie`
