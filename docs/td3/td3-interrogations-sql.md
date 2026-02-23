---
title: "TD3 : Interrogations en SQL"
version: "V2.0.4"
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

# Base de données exemple

La base de données exemple, Gestion pédagogique, utilisée dans les documents de travaux dirigés
de cet enseignement, permet de gérer une formation en informatique, avec ses professeurs, ses
étudiants, ses modules ainsi que leurs enseignements et notations.

## Dictionnaire de données

La base de données Gestion pédagogique a été élaborée à partir du dictionnaire des données
suivant :

: Dictionnaire des données de la base de données exemple {#tbl:dictionnaire}

| Attribut | Description | Domaine[^2] | Remarques |
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
*Remarques*

Les modules forment une hiérarchie entre eux. Quel que soit leur niveau dans la hiérarchie, tous les
modules possèdent les mêmes attributs. La racine de l'arbre ainsi formé par cette hiérarchie est le
programme pédagogique national de formation en informatique. Il se décompose en véritables
modules, eux-mêmes se décomposant en sous-modules et ainsi de suite jusqu'aux feuilles qui
correspondent aux matières. Les matières sont les seuls modules pouvant être enseignés et
susceptibles de recevoir des notes. Certains modules sont associés à une discipline.
:::

Voici la hiérarchie des modules de l'extension de la base de données exemple représentée sous
forme d'arborescence des codes :

![Hiérarchie des modules](figures/hierarchie-modules.pdf){#fig:hierarchie width=100%}

Les coefficients de contrôle continue et de test d'un module sont des pourcentages. Ils peuvent ne
pas être renseignés. Si un des deux coefficients n'est pas renseigné, l'autre ne doit pas l'être non
plus. Leur somme pour un même module est donc soit de 0, soit de 100.

Nous considérons qu'il n'y a pas deux personnes homonymes ayant le même prénom et le même
nom.

## MCD

Voici le MCD correspondant :

![Modèle conceptuel des données (MCD)](figures/mcd.pdf){#fig:mcd width=85%}

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
*Remarques*

La clef étrangère `resp` dans `Module` représente le numéro d'un professeur responsable d'un module[^3]
et fait référence à la clef primaire `numProf`.

La clef étrangère `specProf` dans `Professeur` représente le code d'une matière dont un professeur
est spécialiste et fait référence à la clef primaire `code`.

La clef étrangère `codePere` dans la relation `Module` fait référence à la clef primaire `code`.
:::

[^3]: Idéalement, il ne devrait être possible d'y avoir qu'un responsable d'une matière, pas de n'importe quel module. Par souci de simplification, cette contrainte n'a pas été prise en compte dans l'intension de la base de données exemple.

Les autres clefs étrangères font référence aux clefs primaires de même nom.

# Requêtes avec SQL

Formulez, en SQL, sur la base de données exemple, les requêtes d'interrogation suivantes.

## Expression des jointures

**Quand cela possible, formulez les requêtes suivantes de trois manières différentes.**

Q1
: Donnez, pour l'étudiant Stéphane Rocchi, les moyennes de test obtenues par ordre
décroissant avec le code du module associé. [2 attributs, 9 tuples]{.expected}

Q2
: Donnez les codes et libellés des modules enseignés par Didier Boitard. [2 attributs, 2 tuples]{.expected}

Q3
: Quels sont les groupes de seconde année pour lesquels Marc Laporte a effectué un
enseignement ? [1 attribut, 2 tuples]{.expected}

Q4
: Donnez les numéros et, par ordre alphabétique, les noms des étudiants ayant suivi un
enseignement effectué par un professeur, par ailleurs responsable d'un module quelconque. [2 attributs, 18 tuples]{.expected}

Q5
: Donnez les numéros et, par ordre alphabétique, les noms des étudiants ayant suivi un
enseignement effectué par le professeur responsable de ce module. [2 attributs, 12 tuples]{.expected}

## Formulation de calculs verticaux et horizontaux

**Formulez les requêtes suivantes, en veillant particulièrement à l'évaluation des valeurs nulles
pour les calculs horizontaux.**

Q6
: Combien y-a-t-il de professeurs ? [1 attribut, 1 tuple (17)]{.expected}

Q7
: Quelle est la moyenne générale des notes de contrôle continu pour le module de code PRL ?
[1 attribut, 1 tuple (9.7)]{.expected}

Q8
: Combien de professeurs ont donné un enseignement à l'étudiant Philippe Lyon ? [1 attribut, 1 tuple (7)]{.expected}

Q9
: Donnez, pour le module Prolog, la note moyenne obtenue par les étudiants en tenant compte
des coefficients de contrôle continu et de test. [1 attribut, 1 tuple (10.66)]{.expected}

Q10
: Quel est le coefficient de test le plus faible ? [1 attribut, 1 tuple (0)]{.expected}

Q11
: Quels sont les libellés des modules dont le coefficient de test est le plus faible ? Proposer
deux formulations différentes de cette requête. [1 attribut, 1 tuple (ETUDE DE CAS 1)]{.expected}

Q12
: En supposant que tous les modules sont de même importance, donnez la moyenne générale
de l'étudiante Sandrine Levy. [1 attribut, 1 tuple (11.13)]{.expected}

Q13
: Quels sont les codes des modules pour lesquels la meilleure note de test a été obtenue ? [1 attribut, 2 tuples]{.expected}

Q14
: Quels sont les numéros et noms des étudiants qui ont obtenu, tous modules confondus, la
meilleure note de test ? Proposer deux formulations différentes de cette requête. [2 attributs, 2 tuples]{.expected}

## Utilisation des opérateurs ensemblistes

Q15
: Donnez les villes de résidence des étudiants et des professeurs. [1 attribut, 6 tuples]{.expected}

Q16
: Quels sont les numéros des professeurs responsables d'un module qu'ils enseignent ainsi que
le code du module correspondant ? [2 attributs, 4 tuples]{.expected}

Q17
: Donnez les libellés des modules ne correspondant à la spécialité d'aucun professeur. [1 attribut, 23 tuples]{.expected}

## Équivalent des opérateurs ensemblistes

**Proposez une nouvelle formulation des requêtes de la section précédente sans faire appel aux
opérateurs ensemblistes.**

Q18
: Quels sont les numéros des professeurs responsables d'un module qu'ils enseignent ainsi que
le code du module correspondant ? [Q16, 2 attributs, 4 tuples]{.expected}

Q19
: Donnez les libellés des modules ne correspondant à la spécialité d'aucun professeur. [Q17, 1 attribut, 23 tuples]{.expected}

## Test d'absence de données

**Formulez les requêtes suivantes de trois manières différentes, sans utiliser d'opérateur
ensembliste.**

Q20
: Donnez les numéros, noms et prénoms des étudiants n'ayant aucune note. [3 attributs, 27 tuples]{.expected}

Q21
: Quels sont les noms et prénoms des étudiants n'ayant eu aucun enseignement de Marc
Laporte ? [2 attributs, 41 tuples]{.expected}

Q22
: Quels sont les noms et prénoms des professeurs n'étant pas responsables de modules ? [2 attributs, 8 tuples]{.expected}

## Expression des partitionnements

Q23
: Donnez, par groupe de seconde année, le nombre d'étudiants. [2 attributs, 5 tuples]{.expected}

Q24
: Donnez, pour chaque numéro d'étudiant, la meilleure note de test. [2 attributs, 29 tuples]{.expected}

Q25
: Donnez, pour chaque numéro et nom des étudiants de seconde année ainsi que pour chaque
code de module, le nombre de professeurs. [4 attributs, 71 tuples]{.expected}

Q26
: Donnez, pour chaque ville de plus de cinq professeurs, le nombre de professeurs y résidant.
[2 attributs, 2 tuples]{.expected}
