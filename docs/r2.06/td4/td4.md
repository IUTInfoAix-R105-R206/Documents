---
title: "TD4 : Recherche récursive, division et requêtes complexes"
course: "Exploitation d'une base de données"
authors:
  - "Rosine Cicchetti"
  - "Lotfi Lakhal"
  - "Mickaël Martin Nevot"
license: "CC BY-NC-SA"
license-holder: "Rosine Cicchetti"
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

# Base de données exemple

La base de données exemple, Questionnaire, utilisée dans les documents de travaux dirigés de cet
enseignement, permet à un enseignant de base de données d'effectuer le suivi des étudiants lors des
travaux pratiques de sa matière, en gérant les étudiants, les thèmes abordés, les questions et les
évaluations.

## Dictionnaire de données

La base de données Questionnaire a été élaborée à partir du dictionnaire des données suivant[^2] :

[^2]: Les types syntaxiques, utilisés pour la description des domaines, sont disponibles dans Oracle.

: Dictionnaire des données de la base de données exemple

| Attribut | Description | Domaine | Remarques |
|---|---|---|---|
| `numEt` | Numéro d'un étudiant | `D_NUMET : NUMBER(6,0)` | Valeurs uniques |
| `nom` | Nom d'un étudiant | `D_NOM : VARCHAR2(20)` | |
| `prenom` | Prénom d'un étudiant | `D_PRENOM : VARCHAR2(15)` | |
| `typeBac` | Type du Bac d'un étudiant | `D_TYPEBAC : VARCHAR2(15)` | {GENERAL, ..., INTERNATIONAL} |
| `groupe` | Numéro de groupe d'un étudiant | `D_GROUPE : NUMBER(1,0)` | {1, 2, 3, 4} |
| `idQ` | Identifiant d'une question | `D_IDQ : NUMBER(6,0)` | Valeurs uniques |
| `numTP` | Numéro d'un TP | `D_NUMTP : NUMBER(1,0)` | {1, 2, 3, 4} |
| `niveau` | Niveau de difficulté d'une question | `D_NIVEAU : VARCHAR2(15)` | {FACILE, ..., COMPLEXE} |
| `temps` (Question) | Temps estimé pour répondre à une question | `D_TEMPS : NUMBER(2,0)` | |
| `nbVariantes` | Nombre de variantes demandées | `D_NBVARIANTE : NUMBER(1,0)` | {1, 2, 3} |
| `nbPoints` (Question) | Nombres de points attribués à la question | `D_NBPOINT : NUMBER(2,0)` | {1, 2, 3, 4, 5} |
| `idT` | Identifiant d'un thème | `D_IDT : NUMBER(6,0)` | Valeurs uniques |
| `libelle` | Libellé d'un thème | `D_LIBELLE : VARCHAR2(40)` | Valeurs uniques |
| `idTPere` | Identifiant du thème père d'un thème | `D_IDT : NUMBER(6,0)` | |
| `resultat` | Résultat d'une évaluation | `D_RESULTAT : VARCHAR2(30)` | {FAUX, ..., JUSTE} |
| `temps` (Evalue) | Temps mis par un étudiant pour répondre | `D_TEMPS : NUMBER(2,0)` | |
| `nbVariantes` | Nombre de variantes réalisées | `D_NBVARIANTE : NUMBER(1,0)` | |
| `nbPoints` (Evalue) | Nombre de points obtenus | `D_POINT : NUMBER(4,2)` | |

::: remarques
Les thèmes sont organisés de manière hiérarchique. Quel que soit leur niveau dans la hiérarchie,
tous les thèmes possèdent les mêmes attributs.

Voici la hiérarchie des thèmes de l'extension de la base de données exemple représentée sous forme
d'arborescences des libellés :
:::

\begin{sidewaysfigure}
\centering
\includegraphics{figures/hierarchie-themes.pdf}
\caption{Hiérarchie des thèmes}
\label{fig:hierarchie-themes}
\end{sidewaysfigure}

::: remarques
Nous considérons qu'il n'y a pas deux étudiants homonymes ayant le même prénom et le même nom.
:::

## MCD

Le MCD (voir `figure~\ref{fig:mcd}`{=latex}) modélise trois entités :

- **Etudiant** : les étudiants suivis lors des travaux pratiques
- **Question** : les questions posées dans les TP
- **Theme** : les thèmes abordés, organisés hiérarchiquement (association réflexive **A pour père**)

L'association **Traite** relie une question à un ou plusieurs thèmes. L'association **Evalue** relie
un étudiant à une question et porte le résultat, le temps de réponse, le nombre de variantes
réalisées et le nombre de points obtenus.

\begin{figure}[ht]
\centering
\includegraphics{figures/mcd.pdf}
\caption{Modèle conceptuel des données (MCD)}
\label{fig:mcd}
\end{figure}

## Schéma relationnel

Les clefs primaires sont [soulignées]{.underline} et les clefs étrangères en *italique suivies d'un #*.

Le schéma relationnel de la base de données exemple est présenté ci-après :

:::: schema-relationnel
`Etudiant` ([numEt]{.pk}, nom, prenom, typeBac, groupe)

`Question` ([idQ]{.pk}, numTP, niveau, temps, nbVariantes, nbPoints)

`Theme` ([idT]{.pk}, libelle, [*idTPere#*]{.fk})

`Traite` ([*idQ#*]{.pkfk}, [*idT#*]{.pkfk})

`Evalue` ([*numEt#*]{.pkfk}, [*idQ#*]{.pkfk}, resultat, temps, nbVariantes, nbPoints)
::::

::: remarques
La clef étrangère `idTPere` dans la relation `Theme` fait référence à la clef primaire `idT`.

Les autres clefs étrangères font référence aux clefs primaires de même nom.
:::

::: questions
:::
