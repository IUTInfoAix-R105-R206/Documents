---
title: "TD6 : Vues, tables système et rappels SQL"
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

# Rappel : Base de données exemple

La base de données exemple, Gestion pédagogique, utilisée dans les documents de travaux dirigés
de cet enseignement, permet de gérer une formation en informatique, avec ses professeurs, ses
étudiants, ses modules ainsi que leurs enseignements et notations.

## Dictionnaire de données

La base de données Gestion pédagogique a été élaborée à partir du dictionnaire des données
suivant[^2] :

: Dictionnaire des données de la base de données exemple

| Attribut | Description | Domaine | Remarques |
|---|---|---|---|
| `numEt` | Numéro d'un étudiant | `D_NUMET : NUMBER(6,0)` | Valeurs uniques |
| `nomEt` | Nom d'un étudiant | `D_NOM : VARCHAR2(30)` | |
| `prenomEt` | Prénom d'un étudiant | `D_PRENOM : VARCHAR2(20)` | |
| `cpEt` | Code postal d'un étudiant | `D_CP : VARCHAR2(5)` | |
| `villeEt` | Ville d'un étudiant | `D_VILLE : VARCHAR2(20)` | |
| `anneeEt` | Année d'étude d'un étudiant | `D_ANNEE : NUMBER(2,0)` | \[1..2\] |
| `groupeEt` | Numéro de groupe d'un étudiant | `D_GROUPE : NUMBER(1,0)` | \[1..5\] |
| `numProf` | Numéro d'un professeur | `D_NUMPROF : NUMBER(3,0)` | Valeurs uniques |
| `nomProf` | Nom d'un professeur | `D_NOM : VARCHAR2(20)` | |
| `prenomProf` | Prénom d'un professeur | `D_PRENOM : VARCHAR2(20)` | |
| `adresseProf` | Adresse d'un professeur | `D_ADRESSE : VARCHAR2(40)` | |
| `cpProf` | Code postal d'un professeur | `D_CP : VARCHAR2(5)` | |
| `villeProf` | Ville d'un professeur | `D_VILLE : VARCHAR2(20)` | |
| `specProf` | Code d'une matière dont un professeur est spécialiste | `D_CODE : VARCHAR2(7)` | |
| `code` | Code d'un module | `D_CODE : VARCHAR2(7)` | Valeurs uniques |
| `libelle` | Libellé d'un module | `D_LIBELLE : VARCHAR2(30)` | |
| `heureCMPrev` | Nombre d'heures de CM prévues pour un module | `D_NBHEURE : NUMBER(3,0)` | |
| `heureCMReal` | Nombre d'heures de CM réalisées pour un module | `D_NBHEURE : NUMBER(3,0)` | |
| `heureTPPrev` | Nombre d'heures de TP prévues pour un module | `D_NBHEURE : NUMBER(3,0)` | |
| `heureTPReal` | Nombre d'heures de TP réalisées pour un module | `D_NBHEURE : NUMBER(3,0)` | |
| `discipline` | Discipline enseignée | `D_DISCIPLINE : VARCHAR2(15)` | {INFORMATIQUE, MATHS, GESTION} |
| `coefCC` | Coefficient du contrôle continu pour un module | `D_COEF : NUMBER(3,0)` | \[0..100\] |
| `coefTest` | Coefficient du test pour un module | `D_COEF : NUMBER(3,0)` | \[0..100\] |
| `resp` | Numéro d'un professeur responsable d'une matière | `D_NUMPROF : NUMBER(3,0)` | |
| `codePere` | Code du module père d'un module | `D_CODE : VARCHAR2(7)` | |
| `moyCC` | Moyenne de contrôle continu d'un étudiant dans un module | `D_NOTE : NUMBER(2,0)` | \[0..20\] |
| `moyTest` | Moyenne de test d'un étudiant dans un module | `D_NOTE : NUMBER(2,0)` | \[0..20\] |

[^2]: Les types syntaxiques, utilisés pour la description des domaines, sont disponibles dans Oracle.

::: remarques
Les modules forment une hiérarchie entre eux. Quel que soit leur niveau dans la hiérarchie, tous les
modules possèdent les mêmes attributs. La racine de l'arbre ainsi formé par cette hiérarchie est le
programme pédagogique national de formation en informatique. Il se décompose en véritables
modules, eux-mêmes se décomposant en sous-modules et ainsi de suite jusqu'aux feuilles qui
correspondent aux matières. Les matières sont les seuls modules pouvant être enseignés et
susceptibles de recevoir des notes. Certains modules sont associés à une discipline.
:::

La hiérarchie des modules de l'extension de la base de données exemple est représentée sous
forme d'arborescence des codes en `figure~\ref{fig:hierarchie}`{=latex}.

\begin{figure}[ht]
\centering
\includegraphics[width=\linewidth]{figures/hierarchie-modules.pdf}
\caption{Hiérarchie des modules}
\label{fig:hierarchie}
\end{figure}

Les coefficients de contrôle continue et de test d'un module sont des pourcentages. Ils peuvent ne
pas être renseignés. Si un des deux coefficients n'est pas renseigné, l'autre ne doit pas l'être non
plus. Leur somme pour un même module est donc soit de 0, soit de 100.

Nous considérons qu'il n'y a pas deux personnes homonymes ayant le même prénom et le même
nom.

## MCD

Le MCD (voir `figure~\ref{fig:mcd}`{=latex}) modélise trois entités : **Module** (les unités d'enseignement organisées en hiérarchie),
**Étudiant** et **Prof**. L'association **Notation** relie un étudiant à un module et porte ses
moyennes de contrôle continu et de test. L'association ternaire **Enseignement** lie un professeur,
un module et un étudiant. Un professeur peut être **Spécialiste** d'un module (sa discipline de
référence) et **Responsable** d'un module. Enfin, l'association réflexive **A pour père** matérialise
la hiérarchie entre modules (voir `figure~\ref{fig:hierarchie}`{=latex}).


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
`Etudiant` ([numEt]{.pk}, nomEt, prenomEt, cpEt, villeEt, anneeEt, groupeEt)

`Professeur` ([numProf]{.pk}, nomProf, prenomProf, adresseProf, cpProf, villeProf, [*specProf#*]{.fk})

`Module` ([code]{.pk}, libelle, heureCMPrev, heureCMReal, heureTDPrev, heureTDReal, discipline, coefCC, coefTest, [*resp#*]{.fk}, [*codePere#*]{.fk})

`Note` ([*numEt#*]{.pkfk}, [*code#*]{.pkfk}, moyCC, moyTest)

`Enseigne` ([*numEt#*]{.pkfk}, [*code#*]{.pkfk}, [*numProf#*]{.pkfk})
::::

::: remarques
La clef étrangère `resp` dans `Module` représente le numéro d'un professeur responsable d'un module[^3]
et fait référence à la clef primaire `numProf`.

La clef étrangère `specProf` dans `Professeur` représente le code d'une matière dont un professeur
est spécialiste et fait référence à la clef primaire `code`.

La clef étrangère `codePere` dans la relation `Module` fait référence à la clef primaire `code`.
:::

[^3]: Idéalement, il ne devrait être possible d'y avoir qu'un responsable d'une matière, pas de n'importe quel module. Par souci de simplification, cette contrainte n'a pas été prise en compte dans l'intension de la base de données exemple.

Les autres clefs étrangères font référence aux clefs primaires de même nom.

::: questions
:::
