---
title: "TD1 : L'algèbre relationnelle -- Corrigé"
course: "Introduction aux bases de données et SQL"
authors:
  - "Rosine Cicchetti"
  - "Lotfi Lakhal"
  - "Mickaël Martin Nevot"
license: "CC BY-NC-SA"
license-holder: "Rosine Cicchetti"
website: "www.mickael-martin-nevot.com"
---

\setcounter{secnumdepth}{-1}

# Généralités

Voici la convention de nommage proposé dans cet enseignement :

- **mots clefs** : en lettre capitales (*upper case*) ;
- **relation** : première lettre de chaque mot en capitale (*pascal case*) ;
- **attributs** : premier mot en minuscule et première lettre de chaque mot suivant en
  capitale (*camel case*) ;
- **domaine** : en lettre capitales (*upper case*) au format `D_XXX`[^1].

[^1]: Les domaines identiques sont surlignés avec la même couleur.

Pour rappel, les valeurs saisies dans une base de données, comme les chaînes de caractères,
sont sensibles à la casse et, par convention, sont saisies **en lettres capitales**
(*upper case*), sans diacritique, dans le cadre de cet enseignement.

# Schéma relationnel

La base de données exemple, Airbase, utilisée dans les documents de travaux dirigés de cet
enseignement, propose la gestion très simplifiée d'une compagnie aérienne. Ses relations sont
présentées ci-après.

Les clefs primaires sont soulignées et les clefs étrangères en italique suivies d'un #. Les
clefs étrangères font référence aux clefs primaires de même nom.

On considère qu'un vol, référencé par son numéro `numVol`, est effectué par un unique pilote,
de numéro `numPil`, sur un avion identifié par son numéro `numAv`. L'attribut `nomAv`
correspond au modèle de l'avion (voir 3 ci-dessous).

## Schéma relationnel sans domaine

:::: schema-relationnel
`Pilote` ([numPil]{.pk}, nomPil, adresse, salaire)

`Avion` ([numAv]{.pk}, nomAv, capacite, localisation)

`Vol` ([numVol]{.pk}, [*numPil#*]{.fk}, [*numAv#*]{.fk}, villeDep, villeArr, heureDep, heureArr)
::::

## Schéma relationnel avec domaine

:::: schema-relationnel
`Pilote` ([numPil]{.pk} : D\_NUMPIL, nomPil : D\_NOMPIL, adresse : D\_VILLE, salaire : D\_SAL)

`Avion` ([numAv]{.pk} : D\_NUMAV, nomAv : D\_NOMAV, capacite : D\_CAP, localisation : D\_VILLE)

`Vol` ([numVol]{.pk} : D\_NUMVOL, [*numPil#*]{.fk} : D\_NUMPIL, [*numAv#*]{.fk} : D\_NUMAV, villeDep : D\_VILLE, villeArr : D\_VILLE, heureDep : D\_HEURE, heureArr : D\_HEURE)
::::

# Tuples

Voici des exemples de tuples de la base de données Airbase.

| `Pilote` | numPil | nomPil | adresse   | salaire |
|:--------:|:------:|:------:|:---------:|:-------:|
|          | 100    | MARTIN | MARSEILLE | 5000    |
|          | 101    | DUPRE  | PARIS     | 6000    |
|          | 102    | DUBOIS | MARSEILLE | 7000    |
|          | 103    | DUVAL  | MARSEILLE | 5000    |
|          | 104    | MARTIN | PARIS     | 6000    |
|          | …      | …      | …         | …       |
|          | 204    | DURAND | BORDEAUX  | 7000    |
|          | …      | …      | …         | …       |

: Extrait de l'extension de la relation `Pilote` de la base de données Airbase

| `Avion` | numAv | nomAv | capacite | localisation |
|:-------:|:-----:|:-----:|:--------:|:------------:|
|         | 100   | A320  | 350      | MARSEILLE    |
|         | 101   | B787  | 500      | PARIS        |
|         | …     | …     | …        | …            |

: Extrait de l'extension de la relation `Avion` de la base de données Airbase

\shorthandoff{:}

| `Vol` | numVol | *numPil#* | *numAv#* | villeDep  | villeArr | heureDep | heureArr |
|:-----:|:------:|:---------:|:--------:|:---------:|:--------:|:--------:|:--------:|
|       | 1      | 100       | 100      | MARSEILLE | PARIS    | 12:00    | 13:20    |
|       | 2      | 100       | 101      | PARIS     | BORDEAUX | 14:00    | 15:00    |
|       | 3      | 101       | 100      | PARIS     | BORDEAUX | 16:00    | 17:30    |
|       | 4      | 204       | 105      | LYON      | BREST    | 06:30    | 08:00    |
|       | …      | …         | …        | …         | …        | …        | …        |

: Extrait de l'extension de la relation `Vol` de la base de données Airbase

\shorthandon{:}

# Requêtes avec le langage algébrique

Formulez, en algèbre relationnelle, sur la base de données exemple, les requêtes d'interrogation
suivantes.

## Expression des projections et sélections

Q1
: Donnez la liste des avions dont la capacité est strictement supérieure à 350 passagers.

```
R1.1 := SELECTION (Avion / capacite > 350)
```

Q2
: Quels sont les numéros et noms des avions localisés à Nice ?

```
R2.1 := SELECTION (Avion / localisation = 'NICE')
R2.2 := PROJECTION (R2.1 / numAv, nomAv)
```

Q3
: Quels sont les numéros des pilotes en service et les villes de départ de leurs vols ?

```
R3.1 := PROJECTION (Vol / numPil, villeDep)
```

Q4
: Quel sont les noms des pilotes domiciliés à Paris ayant un salaire d'au moins 5000 ?

```
R4.1 := SELECTION (Pilote / adresse = 'PARIS')
R4.2 := SELECTION (R4.1 / salaire >= 5000)
R4.3 := PROJECTION (R4.2 / nomPil)
```

## Utilisation des opérateurs ensemblistes

Q5
: Quels sont les numéros et noms d'avions localisés à Nice ou dont la capacité est
strictement inférieure à 350 passagers ?

```
-- Avions localisés à Nice.
R5.1 := SELECTION (Avion / localisation = 'NICE')
-- Avions de capacité strictement inférieure à 350.
R5.2 := SELECTION (Avion / capacite < 350)
R5.3 := UNION (R5.1, R5.2)
R5.4 := PROJECTION (R5.3 / numAv, nomAv)
```

Q6
: Donnez la liste des vols au départ de Nice allant à Paris à partir de 18 heures.

```
R6.1 := SELECTION (Vol / villeDep = 'NICE')
R6.2 := SELECTION (Vol / villeArr = 'PARIS')
R6.3 := SELECTION (Vol / heureDep >= 18:00)
R6.4 := INTERSECTION (R6.1, R6.2)
R6.5 := INTERSECTION (R6.3, R6.4)
```

Version alternative (sans opérateur ensembliste) :

```
R6.1 := SELECTION (Vol / villeDep = 'NICE')
R6.2 := SELECTION (R6.1 / villeArr = 'PARIS')
R6.3 := SELECTION (R6.2 / heureDep >= 18:00)
```

Q7
: Quels sont les numéros des pilotes qui ne sont pas en service ?

```
-- Tous les pilotes de la compagnie.
R7.1 := PROJECTION (Pilote / numPil)
-- Pilotes en service.
R7.2 := PROJECTION (Vol / numPil)
R7.3 := DIFFERENCE (R7.1, R7.2)
```

Q8
: Quels sont les numéros et villes de départ des vols effectués par les pilotes de numéro
100 ou 204 ?

```
R8.1 := SELECTION (Vol / numPil = 100)
R8.2 := SELECTION (Vol / numPil = 204)
R8.3 := UNION (R8.1, R8.2)
R8.4 := PROJECTION (R8.3 / numVol, villeDep)
```

## Expression des jointures

Q9
: Donnez les numéros des vols effectués au départ de Nice par des pilotes parisiens.

```
R9.1 := SELECTION (Pilote / adresse = 'PARIS')
R9.2 := SELECTION (Vol / villeDep = 'NICE')
R9.3 := JOINTURE (R9.1, R9.2 / numPil = numPil)
R9.4 := PROJECTION (R9.3 / numVol)
```

Q10
: Quels sont les numéros, villes de départ, et villes d'arrivée des vols effectués par un
avion qui n'est pas localisé à Nice ?

```
R10.1 := SELECTION (Avion / localisation <> 'NICE')
R10.2 := PROJECTION (R10.1 / numAv)
R10.3 := JOINTURE (R10.2, Vol / numAv = numAv)
R10.4 := PROJECTION (R10.3 / numVol, villeDep, villeArr)
```

Q11
: Quels sont les noms et adresses des pilotes assurant au moins un vol au départ de Nice
avec des avions de capacité de plus de 300 places ?

```
R11.1 := SELECTION (Vol / villeDep = 'NICE')
R11.2 := SELECTION (Avion / capacite > 300)
R11.3 := JOINTURE (R11.1, R11.2 / numAv = numAv)
R11.4 := PROJECTION (R11.3 / numPil)
R11.5 := JOINTURE (R11.4, Pilote / numPil = numPil)
R11.6 := PROJECTION (R11.5 / nomPil, adresse)
```

Q12
: Quels sont les noms des pilotes domiciliés à Paris assurant des vols au départ de Nice
avec des A320 ?

```
R12.1 := SELECTION (Vol / villeDep = 'NICE')
R12.2 := SELECTION (Avion / nomAv = 'A320')
R12.3 := JOINTURE (R12.1, R12.2 / numAv = numAv)
R12.4 := SELECTION (Pilote / adresse = 'PARIS')
R12.5 := JOINTURE (R12.3, R12.4 / numPil = numPil)
R12.6 := PROJECTION (R12.5 / nomPil)
```

Q13
: Quels sont les numéros des vols effectués par des pilotes niçois au départ ou à l'arrivée
de Nice avec des avions localisés à Paris ?

```
R13.1 := SELECTION (Vol / villeDep = 'NICE')
R13.2 := SELECTION (Vol / villeArr = 'NICE')
R13.3 := UNION (R13.1, R13.2)
R13.4 := SELECTION (Avion / localisation = 'PARIS')
R13.5 := JOINTURE (R13.4, R13.3 / numAv = numAv)
R13.6 := SELECTION (Pilote / adresse = 'NICE')
R13.7 := JOINTURE (R13.5, R13.6 / numPil = numPil)
R13.8 := PROJECTION (R13.7 / numVol)
```

Q14
: Quels sont, à l'exception des pilotes nommés Durand, les noms de pilotes en service ?

```
R14.1 := SELECTION (Pilote / nomPil <> 'DURAND')
R14.2 := PROJECTION (R14.1 / numPil, nomPil)
R14.3 := RENOMMAGE (Vol / numPil -> numPilVol)
R14.4 := JOINTURE (R14.2, R14.3 / numPil = numPilVol)
R14.5 := PROJECTION (R14.4 / nomPil)
```

Q15
: Quels sont les horaires de départ des vols desservant les villes d'arrivée des vols au
départ de Paris ?

```
R15.1 := SELECTION (Vol / villeDep = 'PARIS')
R15.2 := PROJECTION (R15.1 / villeArr)
R15.3 := JOINTURE (Vol, R15.2 / villeDep = villeArr)
R15.4 := PROJECTION (R15.3 / heureDep)
```

Q16
: Quels sont les numéros et noms des pilotes habitant dans les mêmes villes que les pilotes
nommés Martin ?

```
R16.1 := SELECTION (Pilote / nomPil = 'MARTIN')
R16.2 := PROJECTION (R16.1 / adresse)
R16.3 := SELECTION (Pilote / nomPil <> 'MARTIN')
R16.4 := JOINTURE (R16.2, R16.3 / adresse = adresse)
R16.5 := PROJECTION (R16.4 / numPil, nomPil)
```

Q17
: Quels sont les numéros des avions localisés dans la même ville que l'avion numéro 100 ?

```
R17.1 := SELECTION (Avion / numAv = 100)
R17.2 := PROJECTION (R17.1 / localisation)
R17.3 := SELECTION (Avion / numAv <> 100)
R17.4 := JOINTURE (R17.2, R17.3 / localisation = localisation)
R17.5 := PROJECTION (R17.4 / numAv)
```

## Requêtes complexes

Q18
: Quelles sont les villes de départ de vols dans lesquelles ne réside aucun pilote ?

```
R18.1 := PROJECTION (Vol / villeDep)
R18.2 := PROJECTION (Pilote / adresse)
R18.3 := DIFFERENCE (R18.1, R18.2)
```

Q19
: Quels sont les noms des pilotes n'effectuant pas de vol au départ de Lyon ?

```
R19.1 := SELECTION (Vol / villeDep = 'LYON')
R19.2 := JOINTURE (Pilote, R19.1 / numPil = numPil)
R19.3 := PROJECTION (R19.2 / nomPil)
R19.4 := PROJECTION (Pilote / nomPil)
R19.5 := DIFFERENCE (R19.4, R19.3)
```

Q20
: Donnez les numéros et noms des pilotes homonymes.

```
R20.1 := PROJECTION (Pilote / numPil, nomPil)
R20.2 := RENOMMAGE (R20.1 / numPil -> numPil2, nomPil -> nomPil2)
R20.3 := JOINTURE (R20.1, R20.2 / nomPil = nomPil2 ET numPil <> numPil2)
R20.4 := PROJECTION (R20.3 / numPil, nomPil)
```

Q21
: Quelles sont les villes où habitent des pilotes et où sont localisés des avions ?

```
R21.1 := PROJECTION (Pilote / adresse)
R21.2 := PROJECTION (Avion / localisation)
R21.3 := INTERSECTION (R21.1, R21.2)
```

Q22
: Quels sont les noms des pilotes qui effectuent des vols au départ de leur ville de
résidence ?

```
R22.1 := PROJECTION (Pilote / numPil, adresse)
R22.2 := PROJECTION (Vol / numPil, villeDep)
R22.3 := INTERSECTION (R22.1, R22.2)
R22.4 := JOINTURE (R22.3, Pilote / numPil = numPil)
R22.5 := PROJECTION (R22.4 / nomPil)
```

## Question bonus

Q23
: Après avoir tenté de répondre à la question suivante, expliquez les difficultés
rencontrées : quels sont les numéros, noms et salaires des pilotes domiciliés dans les
mêmes villes que les pilotes nommés Martin tout en ayant un salaire supérieur à eux ?

```
R23.1 := SELECTION (Pilote / nomPil = 'MARTIN')
R23.2 := PROJECTION (R23.1 / numPil, adresse)
R23.3 := JOINTURE (Pilote, R23.2 / adresse = adresse)
-- Pilotes gagnant plus qu'un nommé Martin.
R23.4 := PROJECTION (R23.3 / numPil, nomPil, salaire, numPil)
R23.5 := PROJECTION (R23.1 / numPil, salaire)
-- Utilisation de >-Jointure, non =-jointure (non équijointure).
R23.6 := JOINTURE (Pilote, R23.5 / salaire > salaire)
-- Pilotes habitant la même ville qu'un nommé Martin.
R23.7 := PROJECTION (R23.4 / numPil, nomPil, salaire, numPil)
R23.8 := INTERSECTION (R23.3, R23.5)
R23.9 := PROJECTION (R23.8 / numPil, nomPil, salaire)
```

Remarque : dans l'hypothèse où cela serait permis, on projette non seulement les attributs
demandés, `numPil`, `nomPil`, `salaire`, des pilotes recherchés par la requête, mais aussi
ceux, `numPil`, des pilotes Martin, dans l'ordre des attributs des jointures. De cette
manière, on tient en compte dans chaque comparaison du salaire et de l'adresse de chaque
même Martin.

Version incorrecte :

```
R23.1 := SELECTION (Pilote / nomPil = 'MARTIN')
R23.2 := PROJECTION (R23.1 / adresse)
R23.3 := JOINTURE (Pilote, R23.2 / adresse = adresse)
R23.4 := PROJECTION (R23.3 / numPil, nomPil, salaire)
R23.5 := PROJECTION (R23.1 / salaire)
R23.6 := JOINTURE (Pilote, R23.5 / salaire > salaire)
R23.7 := PROJECTION (R23.4 / numPil, nomPil, salaire)
R23.8 := INTERSECTION (R23.3, R23.5)
```

Remarque : cette requête retourne les pilotes vivant dans les villes où habitent les Martin,
ayant un salaire supérieur au salaire le plus bas des Martin (pas le plus haut !).

Autre version incorrecte :

```
R23.1 := SELECTION (Pilote / nomPil = 'MARTIN')
R23.2 := PROJECTION (R23.1 / adresse)
R23.3 := PROJECTION (R23.1 / salaire)
R23.4 := JOINTURE (Pilote, R23.2 / adresse = adresse)
R23.5 := JOINTURE (R23.4, R23.3 / salaire > salaire)
R23.6 := PROJECTION (R23.5 / numPil, nomPil, salaire)
```
