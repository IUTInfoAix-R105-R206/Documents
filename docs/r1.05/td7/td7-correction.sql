-- V1.0.0

-- Q1 - c:1, t:5
-- Quelles sont les villes d'arrivée des voyages à destination du Maroc ?
PROMPT "Q1";

SELECT DISTINCT villeArr
FROM Voyage
WHERE paysArr = 'MAROC';

-- Q2 - c:2, t:2
-- Donnez les codes et libellés des options avec un libellé comportant le mot « Visite ».
PROMPT "Q2";

SELECT *
FROM OptionV
WHERE Libelle LIKE '%VISITE%';

-- Q3 - c:1, t:4
-- Donnez, triées par ordre chronologique, les dates de départ proposées pour le voyage d'identifiant 927 entre le 1er juin 2004 et le 30 juillet 2004.
PROMPT "Q3 - V1";

SELECT dateDep
FROM Planning 
WHERE idV = 927
 AND dateDep BETWEEN TO_DATE('2004-06-01', 'YYYY-MM-DD')
                 AND TO_DATE('2004-07-30', 'YYYY-MM-DD')
ORDER BY dateDep ASC;

-- Version alternative.
PROMPT "Q3 - V2";

SELECT dateDep FROM Planning 
WHERE idV = 927
  AND dateDep >= TO_DATE('2004-06-01', 'YYYY-MM-DD')
  AND dateDep <= TO_DATE('2004-07-30', 'YYYY-MM-DD')
ORDER BY dateDep ASC; 

-- Q4 - c:5, t:8
-- Donnez, triés par ordre décroissant du numéro de client, les numéros, noms, prénoms, code postaux et villes des clients n'habitant ni Paris ni Marseille.
PROMPT "Q4 - V1";

SELECT numCl, nom, prenom, cp, ville FROM Client
WHERE ville NOT IN ('PARIS', 'MARSEILLE')
ORDER BY numCl DESC;

-- Version alternative.
PROMPT "Q4 - V2";

SELECT numCl, nom, prenom, cp, ville FROM Client
WHERE ville <> 'PARIS'
  AND ville <> 'MARSEILLE' 
ORDER BY numCl DESC;

-- Q5 - c:2, t:7
-- Quels sont les identifiants et noms des clients qui n’ont pas d’adresse enregistrée ?
PROMPT "Q5";

SELECT numCl, nom
FROM Client
WHERE adresse IS NULL;

-- Q6 - c:1, t:2
-- Donnez les identifiants des voyages pour lesquels le client Hubert Marin a fait une réservation.
-- Version algébrique.
PROMPT "Q6 - Version algébrique";

SELECT idV 
FROM Reservation R
INNER JOIN Client C ON R.numCl = C.numCl
WHERE nom = 'MARIN'
  AND prenom = 'HUBERT';

-- Version imbriquée.
PROMPT "Q6 - Version imbriquée";

SELECT idV
FROM Reservation
WHERE numCl IN (SELECT numCl 
                FROM Client
                WHERE nom = 'MARIN'
 				  AND prenom = 'HUBERT');

-- Version prédicative.
PROMPT "Q6 - Version prédicative";

SELECT idV
FROM Reservation R, Client C
WHERE R.numCl = C.numCl
  AND nom = 'MARIN'
  AND prenom = 'HUBERT';

-- Q7 - c:3, t:15
-- Donnez les numéros des clients ainsi que les dates de réservation et villes d'arrivée des voyages réservés par des clients habitant Marseille.
-- Version algébrique.
PROMPT "Q7 - Version algébrique";

SELECT DISTINCT C.numCl, dateRes, villeArr 	 
FROM Voyage V
INNER JOIN Reservation R ON V.idV = R.idV	 
INNER JOIN Client C ON R.numCl = C.numCl	 
WHERE ville = 'MARSEILLE';

-- Version imbriquée.
PROMPT "Q7 - Version imbriquée";

SELECT DISTINCT numCl, dateRes, villeArr
FROM Voyage, Reservation
WHERE Voyage.idV = RESERVATION.idV
AND numCl IN
	(SELECT numCl
	 FROM Client
	 WHERE ville = 'MARSEILLE'); 
	 
-- Remarque : il n'est pas possible de faire une version totalement imbriquée pour cette question car les attributs présents dans la projection finale sont issus de relations différentes.

-- Version prédicative.
PROMPT "Q7 - Version prédicative";

SELECT DISTINCT C.numCl, dateRes, villeArr 	 
FROM Voyage V, Reservation R, Client C
WHERE V.idV = R.idV
  AND R.numCl = C.numCl
  AND ville = 'MARSEILLE';

-- Q8 - c:1, t:2
-- Quelles sont les libellés des options proposées pour le voyage d'identifiant 862 ?
-- Version algébrique.
PROMPT "Q8 - Version algébrique";

SELECT libelle
FROM OptionV O 
INNER JOIN Carac Ca ON O.code = Ca.code
WHERE idV = 862;

-- Version imbriquée.
PROMPT "Q8 - Version imbriquée";

SELECT libelle
FROM OptionV
WHERE code IN (SELECT code
               FROM Carac
			   WHERE idV = 862);

-- Version prédicative.
PROMPT "Q8 - Version prédicative";

SELECT libelle
FROM OptionV O, Carac Ca
WHERE O.code = Ca.code
  AND idV = 862;

-- Q9 - c:1, t:6
-- Quels sont les libellés d’option proposées pour les voyages réservés par le client Thomas Jarolim ?
-- Version algébrique.
PROMPT "Q9 - Version algébrique";

SELECT DISTINCT libelle 
FROM OptionV O
INNER JOIN Carac Ca ON O.code = Ca.code
INNER JOIN Reservation R ON Ca.idV = R.idV
INNER JOIN Client C ON R.numCl = C.numCl
WHERE nom = 'JAROLIM'
  AND prenom = 'THOMAS';

-- Version imbriquée.
PROMPT "Q9 - Version imbriquée";

SELECT libelle
FROM OptionV
WHERE code IN (SELECT code
               FROM Carac 
			   WHERE idV IN (SELECT idV
			                 FROM Reservation
							 WHERE numCl IN (SELECT numCl
							                 FROM Client
											 WHERE nom = 'JAROLIM' 
                                               AND prenom = 'THOMAS')));

-- Version prédicative.
PROMPT "Q9 - Version prédicative";

SELECT DISTINCT libelle   
FROM OptionV O, Carac Ca, Reservation R, Client C
WHERE O.code = Ca.code
  AND Ca.idV = R.idV
  AND R.numCl = C.numCl
  AND nom = 'JAROLIM'
  AND prenom = 'THOMAS';

-- Q10 - c:3, t:16
-- Quels sont les noms, prénoms et villes des clients ayant réservé au moins un voyage partant de leur ville de résidence ?
-- Version algébrique.
PROMPT "Q10 - Version algébrique";

SELECT DISTINCT nom, prenom, ville   
FROM Client C 
INNER JOIN Reservation R ON C.numCl = R.numCl
INNER JOIN Voyage V ON R.idV = V.idV AND ville = villeDep;

-- Version imbriquée.
PROMPT "Q10 - Version imbriquée";

SELECT DISTINCT nom, prenom, ville   
FROM Client C
INNER JOIN Reservation R ON C.numCl = R.numCl 
WHERE (ville, idV) IN (SELECT villeDep, idV FROM Voyage);

-- Remarque : la jointure imbriquée doit se faire simultanément sur les attributs ville de la relation Client et idV de la relation Reservation, ces deux relations doivent être spécifiées dans la requête englobante.

-- Version prédicative.
PROMPT "Q10 - Version prédicative";

SELECT DISTINCT nom, prenom, ville   
FROM Client C, Reservation R, Voyage V
WHERE C.numCl = R.numCl
  AND R.idV = V.idV
  AND ville = villeDep;

-- Q11 - c:1, t:1 (32)
-- Combien y a-t-il de réservations ?
PROMPT "Q11";

SELECT COUNT(*)
FROM Reservation;  

-- Q12 - c:1, t:1 (6.25)
-- Quelle est la durée moyenne des séjours au Kenya ?
PROMPT "Q12";

SELECT AVG(duree)
FROM Voyage
WHERE paysArr = 'KENYA';

-- Q13 - c:1, t:1 (9)
-- Combien y a-t-il de places réservées pour les voyages réservés d’identifiant 122 ?
PROMPT "Q13";

SELECT SUM(nbPers)
FROM Reservation
WHERE idV = 122; 

-- Q14 - c:1, t:1 (179)
-- Quel est le tarif de voyage le moins cher ?
PROMPT "Q14";

SELECT MIN(tarif)
FROM Planning;

-- Q15 - c:2, t:10
-- Donnez les dates de départ et les dates de retour pour les voyages réservés d’identifiant 122.
PROMPT "Q15";

SELECT dateDep, dateDep + duree AS dateRetour
FROM Planning P
INNER JOIN Voyage V ON P.idV = V.idV
WHERE V.idV = 122;

-- Remarque : il est inutile d'utiliser COALESCE(dateDep, 0) car l'attribut dateDep faisant partie de la clef primaire de la relation Planning, les valeurs nulles ne sont pas acceptées. De même, il est inutile d'utiliser COALESCE(duree, 0)  car l'attribut est non null.

-- Q16 - c:5, t:1
-- Quels sont les identifiants, pays d’arrivée, villes d’arrivée et hôtels ainsi que leurs nombres d’étoiles des voyages pour lesquels le tarif est le plus faible ? Donnez deux formulations.
PROMPT "Q16 - V1";

SELECT DISTINCT V.idV, paysArr, villeArr, hotel, nbEtoiles
FROM Voyage V
INNER JOIN Planning P ON V.idV = P.idV 
WHERE tarif = (SELECT MIN(tarif)
               FROM Planning);

-- Version alternative.
PROMPT "Q16 - V2";

SELECT DISTINCT V.idV, paysArr, villeArr, hotel, nbEtoiles  
FROM Voyage V
INNER JOIN Planning P ON V.idV = P.idV 
WHERE tarif <= ALL (SELECT tarif
                    FROM Planning);

-- Q17 - c:4, t:1
-- Quels sont les pays d’arrivée et villes d’arrivée et hôtels ainsi que leurs nombres d’étoiles des voyages réservés les plus cher ? Donnez deux formulations.
PROMPT "Q17 - V1";

SELECT DISTINCT paysArr, villeArr, hotel, nbEtoiles 
FROM Voyage V
INNER JOIN Planning P ON V.idV = P.idV 
WHERE tarif = (SELECT MAX(tarif)
               FROM Planning);

PROMPT "Q17 - V2";

SELECT DISTINCT paysArr, villeArr, hotel, nbEtoiles 
FROM Voyage V
INNER JOIN Planning P ON V.idV = P.idV 
WHERE tarif >= ALL (SELECT tarif
                    FROM Planning);

-- Q18 - c:1, t:1 (1629)
-- Donnez, en tenant compte du nombre de personnes, le prix total des réservations du client Arnaud Peyroche.
PROMPT "Q18 - V1";

SELECT SUM(tarif * nbPers)
FROM Planning P 
INNER JOIN Reservation R ON P.idV = R.idV AND P.dateDep = R.dateDep
INNER JOIN Client C ON R.numCl = C.numCl
WHERE nom = 'PEYROCHE'  
  AND prenom = 'ARNAUD';

-- Remarque : si l'un des deux attributs a une valeur nulle, le calcul horizontal rend NULL et la fonction agrégative SUM n'en tient pas compte.

-- Version alternative.
PROMPT "Q18 - V2";

SELECT SUM(tarif * nbPers)
FROM Planning P 
INNER JOIN Reservation R ON P.idV = R.idV AND P.dateDep = R.dateDep
WHERE R.numCl IN (SELECT NUMCL 
                  FROM CLIENT
                  WHERE NOM = 'PEYROCHE'
                    AND PRENOM = 'ARNAUD');

-- Q19 - c:1, t:1 (35)
-- Donnez, le prix total des options proposées pour les voyages réservés par le client Nicolas Potier.
PROMPT "Q19";

SELECT SUM(prix) 
FROM Client C
INNER JOIN Reservation R ON C.numCl = R.numCl
INNER JOIN Carac Ca ON R.idV = Ca.idV
WHERE nom = 'POTIER'
  AND prenom = 'NICOLAS';

-- Q20 - c:2, t:11
-- Quels sont les noms et prénoms des clients qui n’ont aucune réservation ?
PROMPT "Q20 - V1";

SELECT DISTINCT nom, prenom
FROM Client
WHERE numCl NOT IN (SELECT numCl
                    FROM Reservation);

-- Version alternative.
PROMPT "Q20 - V2";

SELECT DISTINCT nom, prenom
FROM Client
WHERE numCl <> ALL (SELECT numCl
                    FROM Reservation);

-- Q21 - c:3, t:14
-- Quels sont les identifiants, pays d’arrivée et ville d’arrivée des voyages qui ne sont planifiés à aucune date ?
PROMPT "Q21 - V1";

SELECT idv, paysArr, villeArr 
FROM Voyage
WHERE idV NOT IN (SELECT idV
                  FROM Reservation);

-- Version alternative.
PROMPT "Q21 - V2";

SELECT idv, paysArr, villeArr 
FROM Voyage
WHERE idV <> ALL (SELECT idV
                  FROM Reservation);

-- Q22 - c:2, t:6
-- Quels sont les pays d’arrivée et villes d’arrivée qui ne sont pas proposés au départ de Marseille ?
PROMPT "Q22 - V1";

SELECT DISTINCT paysArr, villeArr 
FROM Voyage  
WHERE (paysArr, villeArr) NOT IN (SELECT paysArr, villeArr
                                  FROM Voyage
								  WHERE villeDep = 'MARSEILLE');

-- Version alternative.
PROMPT "Q22 - V2";

SELECT DISTINCT paysArr, villeArr 
FROM Voyage  
WHERE (paysArr, villeArr) <> ALL (SELECT paysArr, villeArr
                                  FROM Voyage
								  WHERE villeDep = 'MARSEILLE');

-- Q23 - c:2, t:10
-- Quels sont les codes et libellés des options qui ne sont pas proposés dans les voyages pour Chypre ?
PROMPT "Q23 - V1";

SELECT code, Libelle
FROM OptionV  
WHERE code NOT IN (SELECT code
                   FROM Carac Ca
				   INNER JOIN Voyage V ON Ca.idV = V.idV
                     AND paysArr = 'CHYPRE');

-- Version alternative.
PROMPT "Q23 - V2";

SELECT code, Libelle
FROM OptionV  
WHERE code <> ALL (SELECT code
				   FROM Carac Ca
                   INNER JOIN Voyage V ON Ca.idV = V.idV
                     AND paysArr = 'CHYPRE');