---
title: "TD3 : Dépendances fonctionnelles et normalisation"
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

Cette troisième séance de travaux dirigés est consacrée aux dépendances fonctionnelles et
à la normalisation des relations.

# Exercice n° 1 : clefs candidates

On considère la relation R contenant les attributs A, B, C, D et dont l'extension est donnée
ci-dessous :

| `R` | A  | B  | C  | D  |
|:---:|:--:|:--:|:--:|:--:|
|     | a1 | b1 | c1 | d1 |
|     | a1 | b2 | c1 | d2 |
|     | a2 | b2 | c2 | d3 |
|     | a3 | b1 | c1 | d2 |
|     | a4 | b4 | c3 | d2 |

Q1
: L'un des attributs A, B, C ou D peut-il jouer le rôle de clef primaire ?

Q2
: Quelles sont les combinaisons « minimales » d'attributs qui pourraient avoir un rôle
de clef primaire dans la relation (les clefs candidates minimales) telle qu'elle est
donnée ?

# Exercice n° 2 : dépendances fonctionnelles

Soit la relation `PIECES` dont le schéma ne comportant que des attributs mono-valués est
donné ci-dessous :

> `PIECES` (`NUM_PIECE`, `PRIX`, `TAUX_TVA`, `LIBELLE`, `CATEGORIE`)

avec l'ensemble F de dépendances fonctionnelles suivant :

> F = \{`NUM_PIECE` $\to$ `PRIX` ; `NUM_PIECE` $\to$ `LIBELLE` ; `CATEGORIE` $\to$ `TAUX_TVA` ;
> `LIBELLE` $\to$ `CATEGORIE`\}

Q3
: Donnez les dépendances fonctionnelles qui peuvent être déduites de l'ensemble F
en appliquant la propriété de transitivité.

Q4
: Donnez un exemple de dépendance déduite de F en utilisant la propriété d'union.

Q5
: Quelle est la clef primaire de la relation `PIECES` ?

# Exercice n° 3 : axiomes d'Armstrong

Considérons la relation R (B, O, I, S, Q, D) où les attributs sont atomiques, avec l'ensemble
de dépendances fonctionnelles suivant : \{S $\to$ D ; I $\to$ B ; I, S $\to$ Q ; B $\to$ O ; D $\to$ S\}

Q6
: Quelles sont les clefs candidates minimales. Justifiez votre réponse en utilisant les
Axiomes d'Armstrong.

Q7
: Choisir une clef primaire puis trouver une décomposition en 3NF de R. Sur le
schéma obtenu, préciser les clefs primaires et étrangères.

Q8
: Existe-t-il d'autre décomposition en 3NF de R ?

# Exercice n° 4 : notes et normalisation

Considérons l'extension suivante de la relation R, répertoriant les notes obtenues
(MOYENNE) par les étudiants dans les différentes matières :

| `R` | CODE\_MAT | NOM\_MAT | NUM\_ETUD | NOM\_ETUD | MOYENNE |
|:---:|:---------:|:--------:|:---------:|:---------:|:-------:|
|     | 1         | Math     | 100       | Dupont    | 10      |
|     | 1         | Math     | 200       | Durand    | 15      |
|     | 1         | Math     | 300       | Dupont    | 10      |
|     | 2         | BD       | 100       | Dupont    | 10      |
|     | 2         | BD       | 200       | Durand    | 10      |
|     | 2         | BD       | 300       | Dupont    | 12      |
|     | 3         | Anglais  | 100       | Dupont    | 16      |
|     | 3         | Anglais  | 300       | Dupont    | 10      |

Q9
: Quelles sont les dépendances fonctionnelles minimales existant dans R ?

Q10
: Quelles sont les clefs candidates minimales.

Q11
: Choisir la meilleure clef primaire en justifiant votre choix.

Q12
: On considère les projections de R suivantes :

    R1 = Projection(R / CODE\_MAT, NOM\_MAT, NOM\_ETUD)

    R2 = Projection(R / NUM\_ETUD, NOM\_ETUD, MOYENNE)

    Sur quel attribut peut être réalisée la jointure entre R1 et R2 ?
    Donnez le résultat d'une telle jointure (avec égalité entre les deux attributs) en
    indiquant l'ensemble des tuples engendrés. Que constatez-vous ?

Q13
: En quelle forme normale est R ? Justifiez votre réponse.

Q14
: Trouvez une décomposition 3NF de R.

# Exercice n° 5 : degré de normalité

Soient les deux relations R1, R2 suivantes dont les clefs respectives sont soulignées et dont
tous les attributs sont atomiques. Pour chacune d'entre elles, un ensemble de dépendances
fonctionnelles est donné.

::: remarques
Les dépendances fonctionnelles dont la source est la clef de la relation ne sont
pas indiquées dans ces ensembles.
:::

:::: schema-relationnel
`R1` ([A]{.pk}, [B]{.pk}, C, D, E, F) - \{B $\to$ C ; D $\to$ E ; D $\to$ F\}

`R2` ([G]{.pk}, [H]{.pk}, [I]{.pk}, [J]{.pk}, K, L, M, N) - \{M $\to$ N ; I, J $\to$ K\}
::::

Q15
: Quel est le degré de normalité des deux relations R1 et R2 ?

Q16
: On décompose la relation R1 en R11 et R12, et la relation R2 en R21 et R22 :

    `R11` ([A]{.pk}, [B]{.pk}, D, E, F) et `R12` ([B]{.pk}, C)

    `R21` ([G]{.pk}, [H]{.pk}, J, K, L) et `R22` ([I]{.pk}, [J]{.pk}, M, N)

    Quel est le degré de normalité de ces quatre relations ?

Q17
: Donner une décomposition en 3NF de R1 et R2.

# Exercice n° 6 : agence immobilière

Reprenons l'univers réel d'une agence de location immobilière (Cf. Exercice 2, TD séance
2). Pour éliminer les cas de redondances et les limites de représentation observée sur le
schéma initial, un nouveau schéma relationnel normalisé est proposé (les attributs `CODE`,
`CODEPROP` et `CODELOC` sont définis sur le même domaine) :

:::: schema-relationnel
`APPART` ([NUM]{.pk}, TYPE, ADR, VILLE, SURFACE, LOYER, [*CODEPROP#*]{.fk})

`PERSONNE` ([CODE]{.pk}, NOM, PRENOM)

`LOCATION` ([*CODELOC#*]{.pkfk}, [*NUM#*]{.pkfk})
::::

Q18
: On désire intégrer dans la relation `PERSONNE`, un attribut `CATEGORIE` dont le
domaine comprendrait les valeurs : \{PROPRIETAIRE, LOCATAIRE, AGENCE, …\}.
Quelle solution proposez-vous ? Justifiez votre réponse.

Q19
: On voudrait, pour les différents appartements, connaître non seulement le loyer
mensuel mais également le montant prévu des charges.
En fait, ce montant est calculé en appliquant un certain coefficient (`COEF`) au loyer et
ce coefficient est défini en fonction uniquement de la ville et de la surface de
l'appartement. Quelle solution proposez-vous ? Justifiez votre réponse.
