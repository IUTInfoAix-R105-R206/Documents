---
title: "TD2 : Concepts relationnels et langage algébrique"
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

# Objectifs

Cette deuxième séance de travaux dirigés est consacrée à l'expression de divisions et à la
compréhension des concepts relationnels.

# Exercice n° 1 : base de données AIRBASE

Considérons la base de données exemple AIRBASE, avec les relations supplémentaires
suivantes :

:::: schema-relationnel
`FORMATION` ([NUMPIL]{.pk} : D\_NUMPIL, [DATE]{.pk} : D\_DATE, APPRECIATION : D\_APPRECIATION, [*TYPE\_F#*]{.fk} : D\_TYPE\_F)

`STAGE` ([TYPE\_F]{.pk} : D\_TYPE\_F, NOMAV : D\_NOMAV, CATEGORIE : D\_CATEGORIE)
::::

où les clés primaires sont soulignées et les clés étrangères sont en italique gras.

La relation `FORMATION` permet de stocker les différentes formations effectuées par les
pilotes de la compagnie. Le couple (`NUMPIL`, `DATE`) constitue la clé primaire de cette
relation. En effet, l'attribut `DATE` correspond à la date de début de la formation, or à une
date donnée, un pilote ne peut effectuer (au plus) qu'une formation.

La relation `STAGE` répertorie les types de formations proposées aux pilotes. Un stage est
caractérisé par le type d'appareil (`NOMAV`) sur lequel il se déroule et par une catégorie dont
les valeurs peuvent être : \{'De nuit', 'Instruments', …\}.

D'après la **structure du schéma relationnel** donné, on vous demande de répondre aux
questions suivantes et de **justifier vos réponses** :

Q1
: Est-il possible qu'un même pilote effectue plusieurs fois une formation sur le même
type d'appareil ?

Q2
: Plusieurs pilotes peuvent-ils suivre la même formation (même type de formation à
la même date) ?

Q3
: Quelles sont toutes les contraintes d'intégrité structurelles mises en jeu lors d'une
opération d'insertion dans la relation `FORMATION` ?

Formulez les requêtes suivantes en langage algébrique :

Q4
: Donnez le numéro et le nom des avions conduits par tous les pilotes de la
compagnie.

Q5
: Existe-t-il des villes desservies par tous les types d'appareil (`NOMAV`) ? Si oui, donnez
le nom de ces villes.

Q6
: Sur quels types d'appareil (`NOMAV`), le pilote Dupont a-t-il reçu une formation ?

Q7
: Quel est le nom des pilotes ayant eu une formation pour tous les types d'appareil ?

Q8
: Existe-t-il des villes desservies à partir de n'importe quelle ville de départ ?

Q9
: Quels sont les noms et adresses des pilotes ayant reçu des formations sur, au moins,
les mêmes appareils que le pilote 104 ?

Q10
: Quels sont les noms et adresses des pilotes n'ayant pas reçu de formation ?

# Exercice n° 2 : agence immobilière

Une agence assure la gestion et la location des appartements que lui confient des
propriétaires. Elle doit gérer essentiellement des informations sur les propriétaires, les
locataires et les appartements.

Outre la gestion administrative et financière, une tâche importante est de pouvoir,
lorsqu'un client se présente, lui proposer l'ensemble des appartements vacants répondant
à ses critères de choix (e.g. type, localisation, loyer…).

Pour assurer sa gestion, l'agence utilise une base de données relationnelle dont une partie
du schéma vous est donnée ci-après.

*Définition des domaines*

| NOM DOMAINE | SIGNIFICATION | TYPE SYNTAXIQUE |
|---|---|---|
| D\_NUM | Identifiant des appartements | valeurs entières |
| D\_TYPE | Type des appartements | chaînes parmi : \{Studio, Villa, T1, T2, T3, …\} |
| D\_ADR | Adresse des appartements | chaînes |
| D\_VILLE | Ville des appartements | chaînes |
| D\_SURFACE | Surface en m² des appartements | valeurs entières |
| D\_LOYER | Montant du loyer des appartements | valeurs réelles |
| D\_CODE | Identifiant des contacts de l'agence | valeurs entières |
| D\_NOM | Nom des contacts de l'agence | chaînes |
| D\_PRENOM | Prénom des contacts de l'agence | chaînes |

*Définition des relations :*

:::: schema-relationnel
`APPART` ([NUM]{.pk} : D\_NUM, TYPE : D\_TYPE, ADR : D\_ADR, VILLE : D\_VILLE, SURFACE : D\_SURFACE, LOYER : D\_LOYER, [*CODE#*]{.fk} : D\_CODE)

`PROPRIO` ([CODEP]{.pk} : D\_CODE, NOM : D\_NOM, PRENOM : D\_PRENOM)

`LOCATAIRE` ([CODEL]{.pk} : D\_CODE, NOM : D\_NOM, PRENOM : D\_PRENOM, [*NUM#*]{.fk} : D\_NUM)
::::

::: remarques
- Les clefs primaires sont soulignées et les clefs étrangères sont en gras et en italique.
- L'attribut `CODE` dans la relation `APPART` référence la clef primaire de la relation
  `PROPRIO`.
- Toute personne en contact avec l'agence, qu'elle soit propriétaire et/ou locataire, se
  voit attribuer un code unique qui l'identifie.
:::

Q11
: Avec la modélisation relationnelle proposée, un locataire peut-il louer plusieurs
appartements différents ? Pourquoi ?

Q12
: Existe-t-il des opérations de mise à jour sur la relation `PROPRIO` pouvant remettre
en cause l'intégrité de référence ? Si oui, donnez-en un exemple précis, pour chaque
type d'opération.

Q13
: Tel que le schéma relationnel est défini, la base peut-elle contenir des redondances
de données ? Si oui, lesquelles ?

Formulez en langage algébrique les requêtes suivantes :

Q14
: Quels sont les appartements (numéro et type) du propriétaire Jean Martin ?

Q15
: Y a-t-il un locataire qui soit en même temps propriétaire ? Si oui donnez son nom.

Q16
: Quels sont les propriétaires (code et nom) n'ayant aucun appartement à Aix ?

Q17
: Donnez toutes les informations sur les appartements inoccupés.

Q18
: Quels sont les propriétaires (nom, prénom) qui ont des appartements de tous les
types ?

Q19
: Quels sont les locataires (code) qui ne sont pas propriétaires ?
