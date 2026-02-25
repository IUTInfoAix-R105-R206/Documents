---
title: "TD7 : Interrogation en SQL interprété"
course: "Introduction aux bases de données et SQL"
authors:
  - "Mickaël Martin Nevot"
license: "CC BY-NC-SA"
license-holder: "Mickaël Martin Nevot"
website: "www.mickael-martin-nevot.com"
---

# Prise en main d'un éditeur Oracle

Utilisez une des deux solutions ci-dessous.

## Oracle Live SQL

Vous pouvez utiliser directement, sans installation ou configuration, l'interpréteur en ligne :
[https://livesql.oracle.com](https://livesql.oracle.com).

## Oracle Cloud Free Tier

Mettez en place une solution d'hébergement en ligne d'un SGBD Oracle. Vous pouvez pour cela
consulter le document `Vade-Mecum mise en place d'un hébergement Oracle Cloud Free Tier`.

Ajouter ensuite une base de données nommée `zenetude-bd`.

# Tutoriel SQL

Répondez au tutoriel SQL, jusqu'à la question 16 incluse :

[https://eric.univ-lyon2.fr/jdarmont/tutoriel-sql/](https://eric.univ-lyon2.fr/jdarmont/tutoriel-sql/).

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

# Base de données exemple

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

Le MCD (voir `figure~\ref{fig:mcd}`{=latex}) modélise quatre entités : **Voyage** (les séjours
proposés par le réseau d'agences), **Client**, **OptionV** (les options proposées pour les voyages)
et **Planning** (les départs planifiés). L'association identifiante **A** relie un voyage à ses
plannings : chaque planning est identifié par sa date de départ au sein d'un voyage donné et porte
le tarif unitaire. L'association **Réservation** relie un planning à un client et porte le nombre de
personnes ainsi que la date de réservation. Enfin, l'association **Carac** relie un voyage à une
option et porte le prix de cette option pour ce voyage.

\begin{figure}[ht]
\centering
\includegraphics[width=\linewidth]{figures/mcd.pdf}
\caption{Modèle conceptuel des données (MCD)}
\label{fig:mcd}
\end{figure}

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

::: questions
:::
