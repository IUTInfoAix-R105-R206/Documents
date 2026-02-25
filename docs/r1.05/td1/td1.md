---
title: "TD1 : L'algèbre relationnelle"
course: "Introduction aux bases de données et SQL"
authors:
  - "Rosine Cicchetti"
  - "Lotfi Lakhal"
  - "Mickaël Martin Nevot"
license: "CC BY-NC-SA"
license-holder: "Rosine Cicchetti"
website: "www.mickael-martin-nevot.com"
---

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

Q2
: Quels sont les numéros et noms des avions localisés à Nice ?

Q3
: Quels sont les numéros des pilotes en service et les villes de départ de leurs vols ?

Q4
: Quel sont les noms des pilotes domiciliés à Paris ayant un salaire d'au moins 5000 ?

## Utilisation des opérateurs ensemblistes

Q5
: Quels sont les numéros et noms d'avions localisés à Nice ou dont la capacité est
strictement inférieure à 350 passagers ?

Q6
: Donnez la liste des vols au départ de Nice allant à Paris à partir de 18 heures.

Q7
: Quels sont les numéros des pilotes qui ne sont pas en service ?

Q8
: Quels sont les numéros et villes de départ des vols effectués par les pilotes de numéro
100 ou 204 ?

## Expression des jointures

Q9
: Donnez les numéros des vols effectués au départ de Nice par des pilotes parisiens.

Q10
: Quels sont les numéros, villes de départ, et villes d'arrivée des vols effectués par un
avion qui n'est pas localisé à Nice ?

Q11
: Quels sont les noms et adresses des pilotes assurant au moins un vol au départ de Nice
avec des avions de capacité de plus de 300 places ?

Q12
: Quels sont les noms des pilotes domiciliés à Paris assurant des vols au départ de Nice
avec des A320 ?

Q13
: Quels sont les numéros des vols effectués par des pilotes niçois au départ ou à l'arrivée
de Nice avec des avions localisés à Paris ?

Q14
: Quels sont, à l'exception des pilotes nommés Durand, les noms de pilotes en service ?

Q15
: Quels sont les horaires de départ des vols desservant les villes d'arrivée des vols au
départ de Paris ?

Q16
: Quels sont les numéros et noms des pilotes habitant dans les mêmes villes que les pilotes
nommés Martin ?

Q17
: Quels sont les numéros des avions localisés dans la même ville que l'avion numéro 100 ?

## Requêtes complexes

Q18
: Quelles sont les villes de départ de vols dans lesquelles ne réside aucun pilote ?

Q19
: Quels sont les noms des pilotes n'effectuant pas de vol au départ de Lyon ?

Q20
: Donnez les numéros et noms des pilotes homonymes.

Q21
: Quelles sont les villes où habitent des pilotes et où sont localisés des avions ?

Q22
: Quels sont les noms des pilotes qui effectuent des vols au départ de leur ville de
résidence ?

## Question bonus

Q23
: Après avoir tenté de répondre à la question suivante, expliquez les difficultés
rencontrées : quels sont les numéros, noms et salaires des pilotes domiciliés dans les
mêmes villes que les pilotes nommés Martin tout en ayant un salaire supérieur à eux ?
