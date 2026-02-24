---
title: "TD1 : Opérateurs ensemblistes, LDD et LCT"
course: "Exploitation d'une base de données"
authors:
  - "Rosine Cicchetti"
  - "Lotfi Lakhal"
  - "Mickaël Martin Nevot"
license: "CC BY-NC-SA"
license-holder: "Mickaël Martin Nevot"
website: "www.mickael-martin-nevot.com"
---

# Rappel : Prise en main d'un éditeur Oracle

Utilisez une des deux solutions ci-dessous.

## Oracle Live SQL

Vous pouvez utiliser directement, sans installation ou configuration, l'interpréteur en ligne :
[https://livesql.oracle.com](https://livesql.oracle.com).

## Oracle Cloud Free Tier

Mettez en place une solution d'hébergement en ligne d'un SGBD Oracle. Vous pouvez pour cela
consulter le document `Vade-Mecum mise en place d'un hébergement Oracle Cloud Free Tier`.

Ajouter ensuite une base de données nommée `zenetude-bd`.

# Rappel : Généralités

Voici la convention de nommage proposé dans cet enseignement :

- **mots clefs** : en lettre capitales (*upper case*) ;
- **relation** : première lettre de chaque mot en capitale (*pascal case*) ;
- **attributs** : premier mot en minuscule et première lettre de chaque mot suivant en capitale (*camel case*) ;
- **domaine** : en lettre capitales (*upper case*) au format `D_XXX`[^1].

[^1]: Les domaines identiques sont surlignés avec la même couleur.

Pour rappel, les valeurs saisies dans une base de données, comme les chaînes de caractères, sont
sensibles à la casse et, par convention, sont saisies **en lettres capitales** (*upper case*), sans
diacritique, dans le cadre de cet enseignement.

# Rappel : Base de données exemple

La base de données exemple, Voyage, utilisée dans les documents de travaux dirigés de cet
enseignement, permet à un réseau d'agences de voyage de gérer les clients, les voyages ainsi que
leurs options, la planification des voyages et les réservations des clients.

## Dictionnaire de données

La base de données Voyage a été élaborée à partir du dictionnaire des données suivant[^2] :

[^2]: Les types syntaxiques, utilisés pour la description des domaines, sont disponibles dans Oracle.

: Dictionnaire des données de la base de données exemple

| Attribut | Description | Domaine | Remarques |
|---|---|---|---|
| `idV` | Identifiant d'un voyage | `D_IDV : NUMBER(6,0)` | Valeurs uniques |
| `villeArr` | Ville d'arrivée d'un voyage | `D_VILLE : VARCHAR2(20)` | |
| `paysArr` | Pays d'arrivée d'un voyage | `D_PAYS : VARCHAR2(20)` | |
| `villeDep` | Ville de départ d'un voyage | `D_VILLE : VARCHAR2(20)` | |
| `hotel` | Nom d'un hôtel | `D_HOTEL : VARCHAR2(20)` | |
| `nbEtoiles` | Nombre d'étoiles d'un hôtel | `D_NBETOILE : NUMBER(1,0)` | |
| `duree` | Nombre de jours d'un voyage | `D_DUREE : NUMBER(2,0)` | |
| `dateDep` | Date de départ | `D_DATE : DATE` | |
| `tarif` | Prix unitaire du voyage | `D_TARIF : NUMBER(6,2)` | |
| `numCl` | Numéro d'un client | `D_NUMCL : NUMBER(6,0)` | Valeurs uniques |
| `nom` | Nom d'un client | `D_NOM : VARCHAR2(25)` | |
| `prenom` | Prénom d'un client | `D_PRENOM : VARCHAR2(20)` | |
| `adresse` | Adresse d'un client | `D_ADRESSE : VARCHAR2(40)` | |
| `cp` | Code postal d'un client | `D_CP : VARCHAR2(5)` | |
| `ville` | Ville de résidence d'un client | `D_VILLE : VARCHAR2(20)` | |
| `categorie` | Catégorie d'un client | `D_CATEGORIE : VARCHAR2(15)` | |
| `nbPers` | Nombre de personnes | `D_NBPERS : NUMBER(2,0)` | |
| `dateRes` | Date de réservation | `D_DATE : DATE` | |
| `code` | Code d'une option | `D_CODE : NUMBER(3,0)` | Valeurs uniques |
| `libelle` | Libellé d'une option | `D_LIBELLE : VARCHAR2(20)` | Valeurs uniques |
| `prix` | Prix d'une option | `D_TARIF : NUMBER(6,2)` | |

::: remarques
Chaque voyage a une destination composée d'une ville et d'un pays d'arrivée, une ville de départ, le
nom de l'hôtel où sont accueillis les clients, son nombre d'étoiles et la durée du voyage en jour.

Pour chaque voyage, plusieurs départs sont planifiés, généralement longtemps à l'avance. Le tarif
unitaire, pour une personne, varie selon la période.

Les clients sont identifiés par un numéro et ont différentes caractéristiques dont leur catégorie.

Les clients effectuent des réservations pour des voyages planifiés. Le nombre de personnes et la
date de réservation sont conservés pour chaque réservation.

Enfin, des options peuvent être proposées pour les voyages (visite guidée, safari découverte, safari
photo, etc.). Ces options peuvent être gratuites pour un voyage ; elles sont alors incluses dans le tarif.

Nous considérons qu'il n'y a pas deux personnes homonymes ayant le même prénom et le même nom.
:::

## MCD

Voici le MCD correspondant (voir `figure~\ref{fig:mcd}`{=latex}) :

![Modèle conceptuel des données (MCD)](figures/mcd.pdf){#fig:mcd width=85%}

## Schéma relationnel

Les clefs primaires sont [soulignées]{.underline} et les clefs étrangères en *italique suivies d'un #*.

Le schéma relationnel de la base de données exemple est présenté ci-après :

:::: schema-relationnel
`Voyage` ([idV]{.pk}, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree)

`Planning` ([*idV#*]{.pkfk}, [dateDep]{.pk}, tarif)

`Client` ([numCl]{.pk}, nom, prenom, adresse, cp, ville, categorie)

`Reservation` ([*numCl#*]{.pkfk}, [*idV#*]{.pkfk}, [*dateDep#*]{.pkfk}, nbPers, dateRes)

`OptionV` ([code]{.pk}, libelle)

`Carac` ([*idV#*]{.pkfk}, [*code#*]{.pkfk}, prix)
::::

::: remarques
La clef étrangère composite (`idV`, `dateDep`) dans `Reservation` fait référence à la clef primaire
composite de `Planning`.
:::

# Requêtes avec SQL

Formulez, en SQL, sur la base de données exemple, les requêtes d'interrogation suivantes.

## Rappel : expression des jointures

**Quand cela est possible, formulez les requêtes suivantes de trois manières différentes.**

Q1
: Donnez les dates de départ, villes d'arrivée et tarifs des voyages à destination du Maroc. [3 attributs, 29 tuples]{.expected}

Q2
: Donnez les dates de départ, villes d'arrivée et pays d'arrivée des voyages réservés des clients ne résidant ni à Paris ni à Marseille. [3 attributs, 2 tuples]{.expected}

Q3
: Quels sont les libellés des options gratuites proposées pour les voyages réservés par le client Nicolas Barbier ? [1 attribut, 3 tuples]{.expected}

Q4
: Quels sont les noms, prénoms et villes de résidence des clients ayant réservé un voyage à destination d'Istanbul partant de leur ville de résidence ? [3 attributs, 5 tuples]{.expected}

## Utilisation des opérateurs ensemblistes et équivalences

**Formulez les requêtes suivantes en faisant appel aux opérateurs ensemblistes.**

Q5
: Quelles sont les villes de départ d'un voyage dans lesquelles résident des clients ? [1 attribut, 4 tuples]{.expected}

Q6
: Quels sont les libellés des options communes aux voyages d'identifiants 354 et 952 ? [1 attribut, 3 tuples]{.expected}

Q7
: Donnez les identifiants, villes d'arrivée et pays d'arrivée des voyages pour lesquels il n'y a aucune réservation. [3 attributs, 14 tuples]{.expected}

Q8
: Quels sont les libellés des options gratuites pour le voyage d'identifiant 354 et ceux des options payantes pour le voyage d'identifiant 952 ? [1 attribut, 5 tuples]{.expected}

**Formulez les requêtes suivantes en ne faisant pas appel aux opérateurs ensemblistes.**

Q9
: Quels sont les identifiants, villes d'arrivée et pays d'arrivée des voyages offrant à la fois les options de visite guidée et de piscine ? [3 attributs, 1 tuple]{.expected}

Q10
: Donnez les noms et prénoms des clients qui n'ont aucune réservation. [2 attributs, 11 tuples]{.expected}

## Création et modification d'attributs

**Formulez les requêtes suivantes en pensant générer, avec la commande `DESCRIBE`, un affichage
permettant de vérifier la validité des réponses et, à la fin de la séance, penser à annuler les
modifications faites pour laisser la base de données dans l'état initial.**

Q11
: Ajoutez les attributs correspondant au tarif enfant et au nombre d'enfants.

Q12
: Doublez la taille possible du libellé d'une option.

Q13
: En se basant sur les données actuelles, définissez une contrainte de domaine pour les catégories. Vérifiez en essayant d'ajouter un client ne respectant pas cette contrainte.

Q14
: En se basant sur les données actuelles, définissez une contrainte de domaine pour les nombres d'étoiles. Vérifiez en essayant d'ajouter un voyage ne respectant pas cette contrainte.

Q15
: Créez une nouvelle relation `Capacite` permettant de connaître par hôtel et type de chambre `typeC`, pouvant être `SIMPLE`, `DOUBLE`, `DOUBLE LUXE`, `SUITE`, `SUITE JUNIOR` et `SUITE PRESTIGE`, le nombre de chambres `nbCh`.

## Mises à jour des données

**Formulez les requêtes suivantes en pensant générer, avec la commande `SELECT` ou `DESCRIBE`,
un affichage permettant de vérifier la validité des réponses et, à la fin de la séance, penser à
annuler les modifications faites pour laisser la base de données dans l'état initial.**

Q16
: Le client numéro 2103 réserve toujours avec ses deux enfants et le client Thomas Jarolim avec son enfant unique. [4 tuples]{.expected}

Q17
: Un tarif enfant est moitié prix du tarif correspondant. [80 tuples]{.expected}

Q18
: Insérez les données suivantes. [12 tuples]{.expected}

: Extension de la relation `Capacite` de la base de données Voyage

| `hotel` | `typeC` | `nbCh` |
|---|---|---|
| ANTIQUE | SIMPLE | 10 |
| ANTIQUE | DOUBLE | 75 |
| ANTIQUE | DOUBLE LUXE | 12 |
| ANTIQUE | SUITE | 5 |
| ELIAS BEACH | DOUBLE | 83 |
| ELIAS BEACH | SUITE | 27 |
| OLD BRIDGE | SIMPLE | 25 |
| OLD BRIDGE | DOUBLE | 75 |
| SAFARI JAMBO | SIMPLE | 32 |
| SAFARI JAMBO | DOUBLE | 100 |
| TRANSATLANTIQUE | DOUBLE | 200 |
| BAMBURI | DOUBLE | 150 |

## Archivage d'information et gestion de transactions

Le mécanisme des transactions est ici illustré à travers un exemple d'archivage d'information.

Dans un souci d'archivage des données, on désire régulièrement purger la relation `Reservation`,
sans pour autant perdre les informations existantes.

Q19
: Créez une nouvelle relation `AncienneReservation` permettant d'archiver toutes les réservations programmées passées, la date de réservation étant remplacée par la date d'archivage.

Q20
: À l'aide d'une transaction, archivez les réservations antérieures à 2004. [`AncienneReservation` : 14 tuples]{.expected}, [`Reservation` : 18 tuples]{.expected}
