---
title: "TD2 : Concepts relationnels et langage algébrique -- Corrigé"
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

# Exercice n° 1 : base de données AIRBASE

Q1
: Est-il possible qu'un même pilote effectue plusieurs fois une formation sur le même
type d'appareil ?

Il n'existe dans le schéma aucune contrainte interdisant qu'un même pilote fasse plusieurs
formations sur le même type d'appareil ou même fasse plusieurs fois le même stage de
formation (mais à des dates différentes).

Q2
: Plusieurs pilotes peuvent-ils suivre la même formation (même type de formation à
la même date) ?

Oui car l'attribut `NUMPIL` faisant partie de la clef primaire, les tuples décrivant le suivi
d'une même formation par plusieurs pilotes différents seront de toutes façons distincts (ils
diffèrent par la valeur de `NUMPIL`).

Q3
: Quelles sont toutes les contraintes d'intégrité structurelles mises en jeu lors d'une
opération d'insertion dans la relation `FORMATION` ?

Lors de l'insertion d'un nouveau tuple dans la relation, il faut :

- que la valeur donnée à chaque attribut soit une valeur admissible pour cet attribut, i.e.
  elle doit appartenir à son domaine sémantique (CI de domaine) ;
- que le couple de valeurs attribuées à (`NUMPIL`, `DATE`) n'existe pas déjà dans la relation
  et que les valeurs de ces deux attributs soient spécifiées, i.e. les valeurs manquantes ou
  nulles sont interdites (CI de relation) ;
- que la valeur attribuée à `NUMPIL` existe déjà dans la relation `PILOTE` (le pilote doit être
  créé) et que celle de `TYPE_F` existe dans la relation `STAGE` (CI de référence).

Q4
: Donnez le numéro et le nom des avions conduits par tous les pilotes de la
compagnie.

```
R4.1 := PROJECTION (PILOTE / NUMPIL)
R4.2 := PROJECTION (VOL / NUMPIL, NUMAV)
R4.3 := DIVISION (R4.2, R4.1 / NUMPIL, NUMPIL)
R4.4 := JOINTURE_NATURELLE (R4.3, AVION)
R4.5 := PROJECTION (R4.4 / NUMAV, NOMAV)
```

Q5
: Existe-t-il des villes desservies par tous les types d'appareil (`NOMAV`) ? Si oui, donnez
le nom de ces villes.

```
R5.1 := PROJECTION (AVION / NOMAV)
R5.2 := JOINTURE (VOL, AVION / NUMAV = NUMAV)
R5.3 := PROJECTION (R5.2 / VILLE_ARR, NOMAV)
R5.4 := DIVISION (R5.3, R5.1 / NOMAV, NOMAV)
```

Q6
: Sur quels types d'appareil (`NOMAV`), le pilote Dupont a-t-il reçu une formation ?

```
R6.1 := SELECTION (PILOTE / NOMPIL = 'DUPONT')
R6.2 := JOINTURE (FORMATION, R6.1 / NUMPIL = NUMPIL)
R6.3 := JOINTURE (STAGE, R6.2 / TYPE_F = TYPE_F)
R6.4 := PROJECTION (R6.3 / NOMAV)
```

Q7
: Quel est le nom des pilotes ayant eu une formation pour tous les types d'appareil ?

```
R7.1 := PROJECTION (AVION / NOMAV)
R7.2 := JOINTURE (FORMATION, STAGE / TYPE_F = TYPE_F)
R7.3 := PROJECTION (R7.2 / NUMPIL, NOMAV)
R7.4 := DIVISION (R7.3, R7.1 / NOMAV, NOMAV)
R7.5 := JOINTURE (PILOTE, R7.4 / NUMPIL = NUMPIL)
R7.6 := PROJECTION (R7.5 / NOMPIL)
```

Q8
: Existe-t-il des villes desservies à partir de n'importe quelle ville de départ ?

```
R8.1 := PROJECTION (VOL / VILLE_DEP)
R8.2 := PROJECTION (VOL / VILLE_DEP, VILLE_ARR)
R8.3 := DIVISION (R8.2, R8.1 / VILLE_DEP, VILLE_DEP)
```

Q9
: Quels sont les noms et adresses des pilotes ayant reçu des formations sur, au moins,
les mêmes appareils que le pilote 104 ?

```
R9.1 := SELECTION (FORMATION / NUMPIL = 104)
R9.2 := JOINTURE (R9.1, STAGE / TYPE_F = TYPE_F)
R9.3 := PROJECTION (R9.2 / NOMAV)
R9.4 := JOINTURE (FORMATION, STAGE / TYPE_F = TYPE_F)
R9.5 := PROJECTION (R9.4 / NUMPIL, NOMAV)
R9.6 := DIVISION (R9.5, R9.3 / NOMAV, NOMAV)
R9.7 := JOINTURE (PILOTE, R9.6 / NUMPIL = NUMPIL)
R9.8 := PROJECTION (R9.7 / NOMPIL, ADR)
```

Q10
: Quels sont les noms et adresses des pilotes n'ayant pas reçu de formation ?

```
R10.1 := PROJECTION (FORMATION / NUMPIL)
R10.2 := PROJECTION (PILOTE / NUMPIL)
R10.3 := DIFFERENCE (R10.2, R10.1)
R10.4 := JOINTURE (R10.3, PILOTE / NUMPIL = NUMPIL)
R10.5 := PROJECTION (R10.4 / NOMPIL, ADR)
```

# Exercice n° 2 : agence immobilière

Q11
: Avec la modélisation relationnelle proposée, un locataire peut-il louer plusieurs
appartements différents ? Pourquoi ?

Non, car dans la relation `LOCATAIRE` l'attribut `NUM` correspond au numéro de
l'appartement loué. Or, pour chaque tuple, cet attribut ne peut admettre qu'au plus une
valeur (Cf. Première forme normale).

Q12
: Existe-t-il des opérations de mise à jour sur la relation `PROPRIO` pouvant remettre
en cause l'intégrité de référence ? Si oui, donnez-en un exemple précis, pour chaque
type d'opération.

La relation `PROPRIO` ne contient aucune clef étrangère. Donc les opérations d'insertion ou
de modification ne mettent jamais en jeu une contrainte de référence. Par contre, la clef
primaire de cette relation est associée à une clef étrangère `CODE` dans la relation `APPART`.
Ainsi, si on supprime un propriétaire, il faut au préalable s'assurer qu'il n'existe dans
`APPART` aucun appartement appartenant au propriétaire considéré.

Par exemple, si les seules valeurs de `CODE` dans `APPART` sont : \{1, 5, 8, 17\}, il sera
impossible de supprimer les propriétaires dont l'identifiant correspond à une de ces
valeurs. On pourra par contre supprimer tous les autres sans problème.

Q13
: Tel que le schéma relationnel est défini, la base peut-elle contenir des redondances
de données ? Si oui, lesquelles ?

Oui. En fait la base peut contenir des redondances lorsqu'une même personne est à la fois
locataire et propriétaire. Dans ce cas, ses nom et prénom seront dupliqués dans les
relations `PROPRIO` et `LOCATAIRE`.

Q14
: Quels sont les appartements (numéro et type) du propriétaire Jean Martin ?

```
R14.1 := SELECTION (PROPRIO / NOM = 'MARTIN')
R14.2 := SELECTION (R14.1 / PRENOM = 'JEAN')
R14.3 := JOINTURE (R14.2, APPART / CODEP = CODE)
R14.4 := PROJECTION (R14.3 / NUM, TYPE)
```

Q15
: Y a-t-il un locataire qui soit en même temps propriétaire ? Si oui donnez son nom.

```
R15.1 := PROJECTION (LOCATAIRE / CODEL, NOM, PRENOM)
R15.2 := INTERSECTION (R15.1, PROPRIO)
R15.3 := PROJECTION (R15.2 / NOM)
```

ou

```
R15.1 := RENOMMAGE (PROPRIO / NOM -> NOMP, PRENOM -> PRENOMP)
R15.2 := JOINTURE (LOCATAIRE, R15.1 / CODEL = CODEP)
R15.3 := PROJECTION (R15.2 / NOM)
```

Q16
: Quels sont les propriétaires (code et nom) n'ayant aucun appartement à Aix ?

```
R16.1 := SELECTION (APPART / VILLE = 'AIX')
R16.2 := PROJECTION (R16.1 / CODE)
R16.3 := PROJECTION (PROPRIO / CODEP)
R16.4 := DIFFERENCE (R16.3, R16.2)
R16.5 := RENOMMAGE (PROPRIO / CODEP -> CODEP2)
R16.6 := JOINTURE (R16.4, R16.5 / CODEP = CODEP2)
R16.7 := PROJECTION (R16.6 / CODEP, NOM)
```

Q17
: Donnez toutes les informations sur les appartements inoccupés.

```
R17.1 := PROJECTION (LOCATAIRE / NUM)
R17.2 := PROJECTION (APPART / NUM)
R17.3 := DIFFERENCE (R17.2, R17.1)
R17.4 := JOINTURE_NATURELLE (APPART, R17.3)
```

Q18
: Quels sont les propriétaires (nom, prénom) qui ont des appartements de tous les
types ?

```
R18.1 := PROJECTION (APPART / TYPE)
R18.2 := PROJECTION (APPART / CODE, TYPE)
R18.3 := DIVISION (R18.2, R18.1 / TYPE, TYPE)
R18.4 := JOINTURE (PROPRIO, R18.3 / CODEP = CODE)
R18.5 := PROJECTION (R18.4 / NOM, PRENOM)
```

Q19
: Quels sont les locataires (code) qui ne sont pas propriétaires ?

```
R19.1 := PROJECTION (LOCATAIRE / CODEL)
R19.2 := PROJECTION (PROPRIO / CODEP)
R19.3 := DIFFERENCE (R19.1, R19.2)
```
