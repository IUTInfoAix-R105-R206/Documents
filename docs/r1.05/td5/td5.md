---
title: "TD5 : Conception avec le modèle Entité/Association"
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

# Exercice n° 1 : vente par correspondance

Une entreprise commerciale de vente par correspondance (ou de vente en ligne) dispose d'un catalogue
de produits. Ces produits sont identifiés par une référence, ils ont une désignation, un prix unitaire,
une catégorie (par exemple : Textile, Ameublement, Electro-ménager...) et éventuellement une couleur
et une taille.

Les clients de l'entreprise se voient attribuer un numéro de client. Il faut connaître leur nom, prénom,
adresse, ville et code postal. Les clients passent commande des produits qui les intéressent en indiquant
la quantité voulue (nombre d'unités). Chaque commande a un numéro unique et est caractérisée par une
date. Régulièrement (i.e. chaque année), les anciennes commandes traitées sont éliminées de la base. En
revanche, on conserve tous les clients y compris ceux qui n'ont pas effectué de commandes depuis
longtemps. On suppose que le « traitement » d'une commande est effectué manuellement : c'est un
manutentionnaire qui sélectionne puis conditionne les produits commandés.

Q1
: Définissez précisément les objectifs de l'application.

Q2
: Etablissez le dictionnaire de données.

Q3
: Proposez le schéma conceptuel de l'application.

Q4
: Traduisez le schéma Entité/association en schéma relationnel.

Q5
: Vérifiez, qu'avec votre schéma relationnel, les objectifs de l'application peuvent être atteints. En
d'autres termes, pouvez-vous écrire les requêtes permettant de retrouver tout ce qui est nécessaire au
fonctionnement de l'application ?

Q6
: Afin de cibler les clients susceptibles d'être intéressés par des campagnes promotionnelles, on
souhaite, avant d'éliminer les anciennes commandes, calculer le montant des achats de chaque client
pour chaque catégorie de produit. Ces différents montants devront être stockés afin de conserver un
profil historique des clients. Ainsi, on pourra adresser un mailing publicitaire aux clients qui ont,
par le passé, acheté de l'électro-ménager ou faire une campagne ciblée sur les acheteurs réguliers
(par exemple une année sur deux) de textile lors des soldes d'été ou d'hiver.

    Modifiez le schéma conceptuel pour tenir compte de ce nouvel objectif. Répercutez ces modifications
sur le schéma relationnel. Vérifiez que l'objectif est atteint.

# Exercice n° 2 : agence immobilière

Une agence immobilière assure la gestion et la location de biens que lui confient des propriétaires. Elle
doit gérer essentiellement des informations sur les propriétaires, les locataires, les appartements et
opérer l'encaissement des loyers.

Une tâche importante est de pouvoir, lorsqu'un client se présente, lui proposer l'ensemble des
appartements vacants répondant à ses critères de choix (e. g. type, localisation, loyer...). De plus à
chaque date d'échéance, il faut envoyer un courrier de demande de règlement du loyer à chaque
locataire et pouvoir le relancer si le loyer n'est pas réglé.

Toute personne, qu'elle soit propriétaire et/ou locataire se voit attribuer un identifiant unique. On
conservera de plus leur nom, prénom et numéro de téléphone.

Concernant les logements, il faut connaître leur numéro, catégorie (appartement, maison de ville,
villa...), leur type (Studio, F2, F3...), leur adresse, leur ville, leur surface, leur loyer. Il faut également
pouvoir retrouver le montant des charges. En fait, ce montant est calculé en appliquant un certain
coefficient (COEF) au loyer et ce coefficient est défini en fonction uniquement de la ville et de la surface
de l'appartement.

Q7
: Définissez précisément les objectifs de l'application.

Q8
: Etablissez le dictionnaire de données.

Q9
: Proposez le schéma conceptuel correspondant.

Q10
: Dérivez du schéma conceptuel le schéma relationnel.

Q11
: Vérifiez, qu'avec votre schéma, les objectifs de l'application peuvent être atteints.

# Exercice n° 3 : association sportive de course de fond

Une association sportive de course de fonds souhaite informatiser sa gestion réalisée manuellement. Le
travail du secrétaire de l'association est d'enregistrer les nouveaux adhérents. Pour cela, il établit une
fiche sur laquelle sont notés les numéro, nom, prénom, date de naissance, adresse précise (bâtiment, n°
et rue, ville, code postal), n° de téléphone de l'adhérent et sa catégorie ainsi que la date d'inscription et
le montant de la cotisation. Lorsqu'un adhérent renouvelle son inscription (normalement chaque année),
le secrétaire ajoute simplement sur sa fiche la date du renouvellement et le montant de cotisation
acquitté. Le tarif de cotisation dépend simplement de la catégorie de l'adhérent. Si un adhérent ne
renouvelle pas son inscription, on conserve toutes les données le concernant (et on les utilise par
exemple pour faire appel aux bénévoles lors de l'organisation de courses ou d'entraînement).

La liste des courses auxquelles l'association participe est connue. Elle est simplement réactualisée chaque
année en notant, pour cette nouvelle édition (année) le nombre total d'inscrits dès que les organisateurs
le communiquent. Chaque course a une distance précise, un lieu de départ, un lieu d'arrivée. Par
exemple, pour la course « Marseille-Cassis », le point de départ est « le stade Vélodrome », le lieu
d'arrivée est « l'Oustaou Calendal » et la distance est de 20,3 kms. Pour l'édition 2007 du « Marseille-Cassis »,
il y a eu 12 240 participants. Le système d'information que l'on souhaite mettre en place devra
permettre le stockage des données concernant les adhérents, leurs inscriptions à l'association et les
courses. Il devra permettre de faciliter les renouvellements d'adhésion (envoi d'un courrier aux
adhérents de l'année précédente) et de relancer par courrier les retardataires. Il faudra également
enregistrer les participations des adhérents aux courses et les résultats obtenus (temps et classement). En
fait, on voudrait pouvoir éditer le palmarès de l'association ou des palmarès individuels reprenant tout
l'historique ou bien les résultats annuels. Ils pourraient se présenter comme suit :

\begin{table}[ht]
\centering
\caption*{Palmarès de l'association}
\begin{tabular}{llllll}
\toprule
Nom Course & Année & Nom Premier & Temps & Place & NbCoureurs \\
\midrule
Marseille-Cassis & 2004 & Fauvel & 1h 20' 08'' & 28 & 10580 \\
Marseille-Cassis & 2005 & Lefevre & 1h 18' 30'' & 25 & 11256 \\
Balcons de Cézanne & 2005 & Dumont & 0h 31' 23'' & 12 & 320 \\
\ldots \\
\bottomrule
\end{tabular}
\end{table}

\begin{table}[ht]
\centering
\caption*{Palmarès individuel (historique)}
\begin{tabular}{lllll}
\toprule
Adhérent : & Nom Course & Année & Temps & Place \\
\midrule
Pierre Dumont & Marseille-Cassis & 2005 & 1h 40' 08'' & 120 \\
 & Marseille-Cassis & 2006 & 1h 32' 30'' & 85 \\
 & Les bacons de Cézanne & 2005 & 0h 31' 23'' & 12 \\
\bottomrule
\end{tabular}
\end{table}

Q12
: Définissez précisément les objectifs de l'application.

Q13
: Etablissez le dictionnaire de données.

Q14
: Proposez le schéma conceptuel de l'application.

Q15
: Traduisez le schéma Entité/association en schéma relationnel.

Q16
: Vérifiez, qu'avec votre schéma relationnel, les objectifs de l'application peuvent être atteints. En
d'autres termes, pouvez-vous écrire les requêtes permettant de retrouver tout ce qui est nécessaire au
fonctionnement de l'application ?

# Exercice n° 4 : palais des congrès

Une association gère les locations des salles d'un palais des congrès. Celui-ci dispose d'une capacité
totale de 3300 places réparties en 20 salles de différentes dimensions. Ces locations se géraient jusqu'à
présent manuellement. Devant les difficultés croissantes, il a été décidé d'informatiser cette gestion.
Le principal objectif du projet est de pouvoir fournir à tout moment des informations, soit pour répondre
à des demandes précises d'organismes, soit pour formuler des propositions de location, soit pour aider
des clients dans leur choix.

Les règles suivantes doivent être respectées :

- les locations peuvent se faire sur place ou par téléphone,
- une réservation peut être provisoire ou définitive. Elle est provisoire tant que des arrhes n'ont
  pas été versées. Ce versement doit avoir lieu dans un délai de huit jours à compter de la date de
  la demande. Dans ce cas, la réservation devient définitive. Passé ce délai et si la salle est
  réclamée (il n'y en a pas, de taille équivalente, qui soit libre), elle sera attribuée au nouveau
  demandeur.
- Les arrhes s'élèvent à 20% du montant estimé de la location. Le client doit indiquer le nombre
  approximatif de participants et un montant est établi sur cette base.
- Les salles peuvent être louées n'importe quel jour pour une durée minimale de 2 heures.
  L'heure de début doit être une heure ronde. La durée maximale de location est de 15 heures
  (entre 9 heures et minuit).
- Le nettoyage peut se faire entre 8 heures et 20 heures.
- Il faut une heure pour remettre une salle en ordre après une manifestation. Donc une salle n'est
  pas utilisable dans l'heure qui suit la fin d'une manifestation.
- La facturation au client s'effectue sur la base de trois éléments :
    - le nombre d'heures de location, avec application d'un coefficient de 1,5 pour les heures à
      partir de 19 heures,
    - la capacité de la salle,
    - le nombre de participants effectifs.

    Exemple : prix de location pour une salle pour la journée du 26/10/07 de 13 heures à minuit
    avec 400 participants.

    - Location : taux horaire \* nombre d'heures, soit (t1 \* 6) + (t1 \* 1,5 \* 5)
    - Vestiaire-Accueil-Sécurité : taux de base \* capacité, soit t2 \* capacité
    - Nettoyage : taux de base \* nombre de participants, soit t3 \* 400.

    où t1, t2 et t3 sont des taux unitaires de prestation propres à chaque salle.

- L'attribution des salles se fait en fonction du nombre N de participants attendus suivant la
  règle : N < capacité <= N \* 1,5.

Exemple de demande de location :

\begin{center}
\fbox{\begin{minipage}{0.85\textwidth}
\centering
\textbf{FICHE DE DEMANDE DE LOCATION}

\rule{\textwidth}{0.4pt}

\begin{flushleft}
Date de la demande :\\
Nom du client : \hfill Code du client :\\
Adresse :\\
Téléphone :

\rule{\textwidth}{0.4pt}

Nom de la manifestation : \hfill Date de la manifestation :\\
Heure début : \hfill Heure Fin :\\
Nombre de participants attendus : \hfill Nom de la salle attribuée :\\
\ldots\ldots\ldots\ldots
\end{flushleft}
\end{minipage}}
\end{center}

Liste des salles :

\begin{table}[ht]
\centering
\shorthandoff{:}
\begin{tabular}{lrrrr}
\toprule
 & & \multicolumn{3}{c}{Taux} \\
\cmidrule(lr){3-5}
Nom & Capacité & Location (t1) & V-A-S (t2) & Nettoyage (t3) \\
\midrule
Matisse & 300 & 800 & 70 & 40 \\
Renoir & 50 & 150 & 20 & 40 \\
Millet & 200 & 300 & 35 & 20 \\
Cézanne & 1000 & 1800 & 100 & 60 \\
Braque & 300 & 600 & 60 & 30 \\
\ldots \\
\bottomrule
\end{tabular}
\end{table}

Q17
: Définissez précisément les objectifs de l'application.

Q18
: Etablissez le dictionnaire de données.

Q19
: Proposez le schéma conceptuel correspondant.

Q20
: Dérivez du schéma conceptuel le schéma relationnel.

Q21
: Modifiez le schéma conceptuel en tenant compte des hypothèses suivantes :

    - Une manifestation peut se dérouler sur plusieurs jours et dans plusieurs salles, mais toujours au
      même horaire (quels que soient le jour et la salle).
    - Une manifestation peut se dérouler sur plusieurs jours et dans plusieurs salles, avec un horaire
      variable selon les jours (quelle que soit la salle).
    - Une manifestation peut se dérouler sur plusieurs jours et dans plusieurs salles, avec un horaire
      variable selon les jours et selon les salles.
    - Une manifestation peut se dérouler sur plusieurs jours et dans plusieurs salles, avec un horaire
      variable selon les jours et selon les salles. De plus, on peut louer plusieurs fois la même salle dans
      la même journée pour différents créneaux horaires.

# Exercice n° 5 : location d'outils

La société Outils Services loue des outils à ses clients. Actuellement le système d'information
fonctionne à partir de fiches ; ainsi, on trouve la fiche client contenant un n° de client, son nom,
son adresse et son n° de téléphone ; les fiches emprunts numérotés par ordre croissant comporte
la date de l'emprunt, la date de retour, le n° du client, et la liste des outils empruntés (eux aussi
repérés par un n°).

Les utilisateurs désirent que les clients soient maintenus dans la BD le plus longtemps possible
et que l'application gère aussi l'entretien des outils qui doivent être en parfait état de
fonctionnement. Les différents entretiens possibles sont connus (par ex. réglage moteur,
nettoyage général, changement allumage etc.…).

Afin d'évaluer la qualité des différentes marques on devra connaître tous les entretiens subis
par un outil, leur durée ainsi que les intervalles de temps entre deux entretiens identiques du
même appareil.

Lorsqu'un outil a dépassé une certaine durée de service (variable selon les outils) il est retiré et
les données qui le concernent sont archivées. Si tous les outils d'un emprunt sont archivés
l'emprunt lui-même le sera aussi.

Un entretien n'est défini que dans la mesure où un outil répertorié doit le subir, les entretiens
ont tous un libellé différent. Certains outils sont achetés neufs et sont immédiatement proposés.

Q22
: Etablir le schéma entité association de cette application.
