---
title: "TD4 : Modèle Entité/Association et traduction relationnelle"
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

L'objectif de ce TD est de manipuler les concepts du modèle Entité/Association, d'élaborer des
schémas conceptuels selon ce modèle et de les traduire selon le modèle relationnel.

# Exercice n° 1 : automobiles

Soit la relation « universelle » suivante :

> r(Num\_immat, Puissance, Marque, Pays, Agence, Chiffre\_Aff)

En supposant que :

- un numéro d'immatriculation correspond à un unique véhicule et pour décrire ce dernier,
  on doit connaître sa puissance et sa marque ;
- une marque est spécifique d'un pays. Par exemple Renault et Peugeot sont français,
  Volkswagen est allemand... ;
- le chiffre d'affaires est relatif à une agence pour une marque ;
- une agence peut représenter plusieurs marques mais une agence n'a jamais l'exclusivité
  d'une marque.

Q1
: Quelles DF pouvez-vous déduire de ces hypothèses ?

Q2
: Proposez le schéma conceptuel correspondant.

Q3
: Traduisez le schéma conceptuel en schéma relationnel.

# Exercice n° 2 : transport de marchandises

Cet exercice porte sur une entreprise de transport de marchandises dont le fonctionnement
simplifié est décrit ci-dessous. Les attributs mono-valués recensés sont les suivants :

| Attribut | Description |
|---|---|
| Num\_Produit | Numéro identifiant des produits livrés |
| Quantite | Nombre d'unités d'un même produit à livrer |
| Depot | Nom du hangar de stockage des produits |
| Ville\_Client | Nom de la ville dans laquelle est livré un client |
| Departement | Code (sur 2 chiffres) du département d'une ville |
| N°Camion | Numéro identifiant un camion de livraison |
| N°Client | Numéro identifiant un client |
| Poids\_Unit | Poids d'un produit |
| Volume\_Unit | Volume d'un produit |
| Date | Date de Livraison |

Les différentes hypothèses de fonctionnement sont les suivantes :

- A une date de livraison donnée, il ne peut y avoir qu'au plus une quantité d'un produit à
  livrer à un client. Par exemple on peut livrer 3 chaises et 1 table au client numéro 4785 le
  10/12/07 puis 5 chaises au même client le 20/12/07 mais on ne pourrait pas livrer ces deux
  lots de chaises le même jour. En revanche, rien n'interdit de livrer 3 chaises au client
  numéro 4785 et 5 chaises au client numéro 2326 le 10/12/07.
- De plus, ce sera forcément le même camion qui livrera ces produits à ce client ce jour là.
- Un produit a toujours le même poids et le même volume.
- Un client ne peut avoir des villes de livraison différentes.
- Il n'y a pas le choix du hangar de départ (dépôt) pour un produit donné.
- On suppose qu'il n'y a pas deux villes de nom identique dans des départements
  différents.

Q4
: Quelles DF pouvez-vous déduire de ces hypothèses ?

Q5
: Proposez le schéma conceptuel correspondant.

Q6
: Traduisez le schéma conceptuel pour obtenir le schéma relationnel.

\begin{figure}[ht]
\centering
\includegraphics{figures/gestion-artistique-1.pdf}
\caption{GESTION ARTISTIQUE 1}
\label{fig:ga1}
\end{figure}

\begin{figure}[ht]
\centering
\includegraphics{figures/gestion-artistique-2.pdf}
\caption{GESTION ARTISTIQUE 2}
\label{fig:ga2}
\end{figure}

# Exercice n° 3 : gestion artistique

Il s'agit, dans cet exercice, de comprendre et interpréter les deux schémas E/A donnés
ci-après (`figure~\ref{fig:ga1}`{=latex} et `figure~\ref{fig:ga2}`{=latex}).


Q7
: En vous appuyant sur le schéma « GESTION ARTISTIQUE 1 » (voir `figure~\ref{fig:ga1}`{=latex}),
répondez aux questions suivantes en justifiant vos réponses.

    - Combien de marques a un morceau de disque ?
    - Combien d'auteurs a un morceau de disque au plus et au moins ?
    - A combien de morceaux de disque une œuvre donne-t-elle lieu au plus et au moins ?
    - Un orchestre est-il nécessairement enregistré ?
    - Combien de rôles une personne peut-elle tenir au plus et au moins ?
    - Combien de rôles une personne peut-elle tenir au plus et au moins dans le même morceau ?
    - Combien de rôles une personne peut-elle tenir dans une œuvre donnée ?
    - Une personne peut-elle avoir des rôles différents avec le même orchestre ?

Q8
: Effectuez la traduction de ce schéma en schéma relationnel.

Q9
: Faites la traduction relationnelle du schéma « GESTION ARTISTIQUE 2 » (voir `figure~\ref{fig:ga2}`{=latex}).

Q10
: En vous appuyant sur le schéma « GESTION ARTISTIQUE 2 » (voir `figure~\ref{fig:ga2}`{=latex}),
répondez aux questions suivantes en justifiant vos réponses.

    - Combien y a t-il d'interprétations (au plus et au moins) pour un N° d'enregistrement donné ?
    - Combien y a t-il de rôles (au plus et au moins) pour un N° d'enregistrement donné ?
    - Qu'est-ce qui correspond à un enregistrement donné par le TA interprétation ?
    - Combien y a t-il d'interprétations (au plus et au moins) pour enregistrement donné et
      un morceau de musique donné ?
    - Combien y a t-il d'interprétation (au plus et au moins) pour enregistrement donné, une
      personne donnée et un morceau de musique donné ?
    - Combien y a t-il d'enregistrements (au plus et au moins) pour une interprétation
      donnée ?

# Exercice n° 4 : gestion sportive

Les deux schémas (`figure~\ref{fig:gs1}`{=latex} et `figure~\ref{fig:gs2}`{=latex}),
donnés ci-après, sont différents mais établis à partir du même thème.

Q11
: Interprétez-les tous les deux puis mettez en évidence leurs différences.

Q12
: Effectuez leur traduction en relationnel. Sur chaque schéma, donnez la requête
permettant de retrouver les joueurs battus des différents matchs.

\begin{figure}[ht]
\centering
\includegraphics{figures/gestion-sportive-1.pdf}
\caption{GESTION SPORTIVE 1}
\label{fig:gs1}
\end{figure}

\begin{figure}[ht]
\centering
\includegraphics{figures/gestion-sportive-2.pdf}
\caption{GESTION SPORTIVE 2}
\label{fig:gs2}
\end{figure}

# Exercice n° 5 : botanique

Une base de données est utilisée pour donner diverses informations sur des plantes, leurs
familles et les différentes manières de les multiplier. Son schéma est le suivant :

:::: schema-relationnel
`Plante` ([IdP]{.pk}, NomCommun, NomScient, [*IdFamille*]{.fk}, Hauteur)

`Famille` ([IdF]{.pk}, NomCommun, NomScient)

`TypeMultip` ([IdM]{.pk}, NomM)

`SeMultiplie` ([*IdP#*]{.pkfk}, [*IdM*]{.pkfk}, Remarque)
::::

::: remarques
- Les clefs primaires sont soulignées. Les clefs étrangères sont en italique gras. Les attributs
  IDF et IDFamille sont compatibles.
- Chaque tuple de la relation TYPE\_MULTIP décrit une technique de multiplication de
  plante. L'attribut NomM est un énuméré : {Semis, Bouturage, Marcottage...}.
:::

En vous appuyant sur la structure relationnelle, répondez aux questions suivantes en justifiant
vos réponses :

Q13
: Est-il possible que, pour une plante, on n'ait pas de méthode de multiplication ?

Q14
: Peut-on avoir, pour une plante, plusieurs méthodes de multiplication ?

Q15
: A quelle étape de normalisation correspond la création de la relation SE\_MULTIPLIE ?

Q16
: Construisez le schéma Entité/Association correspondant au schéma relationnel.

Q17
: On souhaite intégrer dans la base des informations concernant les types de sol dont les
valeurs peuvent être : {Léger, Bien drainé, Argileux, Calcaire, Acide...}. D'autre part, on
souhaite associer à chacune des plantes les différents types de sol qu'elle apprécie.
Comment faire pour intégrer dans la base ces nouvelles informations ?
