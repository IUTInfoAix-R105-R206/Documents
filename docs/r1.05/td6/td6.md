---
title: "TD6 : Interrogation en SQL"
course: "Introduction aux bases de données et SQL"
authors:
  - "Rosine Cicchetti"
  - "Lotfi Lakhal"
  - "Mickaël Martin Nevot"
license: "CC BY-NC-SA"
license-holder: "Mickaël Martin Nevot"
website: "www.mickael-martin-nevot.com"
---

# Rappel : généralités

Voici la convention de nommage proposé dans cet enseignement :

- **mots clefs** : en lettre capitales (*upper case*) ;
- **relation** : première lettre de chaque mot en capitale (*pascal case*) ;
- **attributs** : premier mot en minuscule et première lettre de chaque mot suivant en capitale (*camel case*) ;
- **domaine** : en lettre capitales (*upper case*) au format `D_XXX`[^1].

[^1]: Les domaines identiques sont surlignés avec la même couleur.

Pour rappel, les valeurs saisies dans une base de données, comme les chaînes de caractères, sont
sensibles à la casse et, par convention, sont saisies **en lettres capitales** (*upper case*), sans
diacritique, dans le cadre de cet enseignement.

# Rappel : schéma relationnel

La base de données exemple, Airbase, utilisée dans les documents de travaux dirigés de cet
enseignement, propose la gestion très simplifiée d'une compagnie aérienne. Ses relations sont
présentées ci-après.

Les clefs primaires sont [soulignées]{.underline} et les clefs étrangères en *italique suivies d'un #*.
Les clefs étrangères font référence aux clefs primaires de même nom.

On considère qu'un vol, référencé par son numéro `numVol`, est effectué par un unique pilote, de
numéro `numPil`, sur un avion identifié par son numéro `numAv`. L'attribut `nomAv` correspond au modèle
de l'avion (voir 3 ci-dessous).

## Schéma relationnel sans domaine

:::: schema-relationnel
`Pilote` ([numPil]{.pk}, nomPil, adresse, salaire)

`Avion` ([numAv]{.pk}, nomAv, capacite, localisation)

`Vol` ([numVol]{.pk}, [*numPil#*]{.fk}, [*numAv#*]{.fk}, villeDep, villeArr, heureDep, heureArr)
::::

## Schéma relationnel avec domaine

:::: schema-relationnel
`Pilote` ([numPil]{.pk} : D_NUMPIL, nomPil : D_NOMPIL, adresse : D_VILLE, salaire : D_SAL)

`Avion` ([numAv]{.pk} : D_NUMAV, nomAv : D_NOMAV, capacite : D_CAP, localisation : D_VILLE)

`Vol` ([numVol]{.pk} : D_NUMVOL, [*numPil#*]{.fk} : D_NUMPIL, [*numAv#*]{.fk} : D_NUMAV, villeDep : D_VILLE, villeArr : D_VILLE, heureDep : D_HEURE, heureArr : D_HEURE)
::::

# Rappel : tuples

Voici des exemples de tuples de la base de données Airbase.

: Extrait de l'extension de la relation `Pilote` de la base de données Airbase

| `Pilote` | numPil | nomPil | adresse | salaire |
|---|---|---|---|---|
| | 100 | MARTIN | MARSEILLE | 5000 |
| | 101 | DUPRE | PARIS | 6000 |
| | 102 | DUBOIS | MARSEILLE | 7000 |
| | 103 | DUVAL | MARSEILLE | 5000 |
| | 104 | MARTIN | PARIS | 6000 |
| | ... | ... | ... | ... |
| | 204 | DURAND | BORDEAUX | 7000 |
| | ... | ... | ... | ... |

: Extrait de l'extension de la relation `Avion` de la base de données Airbase

| `Avion` | numAv | nomAv | capacite | localisation |
|---|---|---|---|---|
| | 100 | A320 | 350 | MARSEILLE |
| | 101 | B787 | 500 | PARIS |
| | ... | ... | ... | ... |

\begin{table}[ht]
\centering
\caption{Extrait de l'extension de la relation \texttt{Vol} de la base de données Airbase}
\footnotesize
\shorthandoff{:}
\begin{tabular}{llllllll}
\toprule
\texttt{Vol} & numVol & \textit{numPil\#} & \textit{numAv\#} & villeDep & villeArr & heureDep & heureArr \\
\midrule
 & 1 & 100 & 100 & MARSEILLE & PARIS & 12:00 & 13:20 \\
 & 2 & 100 & 101 & PARIS & BORDEAUX & 14:00 & 15:00 \\
 & 3 & 101 & 100 & PARIS & BORDEAUX & 16:00 & 17:30 \\
 & 4 & 204 & 105 & LYON & BREST & 06:30 & 08:00 \\
 & \ldots & \ldots & \ldots & \ldots & \ldots & \ldots & \ldots \\
\bottomrule
\end{tabular}
\end{table}

## MCD

Le MCD (voir `figure~\ref{fig:mcd}`{=latex}) modélise trois entités : **Pilote**, **Vol** et **Avion**.
L'association **A (n°1)** relie un pilote à ses vols : un pilote peut effectuer plusieurs vols (0,n)
et chaque vol est effectué par un unique pilote (1,1). L'association **A (n°2)** relie un vol à son
avion : chaque vol utilise un unique avion (1,1) et un avion peut être utilisé pour plusieurs
vols (0,n).

\begin{figure}[ht]
\centering
\includegraphics{figures/mcd.pdf}
\caption{Modèle conceptuel des données (MCD)}
\label{fig:mcd}
\end{figure}

::: questions
:::
