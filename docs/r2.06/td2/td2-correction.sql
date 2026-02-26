-- V1.0.2

-- @title Requêtes avec SQL
-- @intro Vérifiez que lors du TD précédent, vous avez laissé la base de données dans l'état
-- @+ initial ou réinitialisez-là. Formulez, en SQL, sur la base de données exemple, les requêtes
-- @+ d'interrogation suivantes.

-- @section Jointures externes

-- Q1 - c:4, t:34
-- Donnez les numéros et noms des clients ainsi que leurs éventuels identifiants des voyages et dates de réservation datant d'avant le 10/11/2003.
PROMPT "Q1";

SELECT C.numCl, nom, idV, dateRes
FROM Client C
    LEFT OUTER JOIN Reservation R
        ON
            C.numCl = R.numCl
            AND dateRes < TO_DATE('2003-11-10', 'YYYY-MM-DD');

-- Q2 - c:4, t:24
-- En s'inspirant de la requête précédente, donnez les numéros et noms des clients ainsi que leurs éventuels identifiants des voyages et dates de réservation qui n'ont jamais réservé avant le 10/11/2003.
PROMPT "Q2";

SELECT C.numCl, nom, idV, dateRes
FROM Client C
    LEFT JOIN Reservation R
        ON
            C.numCl = R.numCl
            AND dateRes < TO_DATE('2003-11-10', 'YYYY-MM-DD')
WHERE C.numCl IS NULL OR idV IS NULL;

-- Q3
-- Formulez les variations de requêtes suivantes de deux manières différentes :

-- Q3a - c:5, t:215
-- Donnez les numéros et ville de résidence des clients ainsi que les identifiants, villes de départ et pays d'arrivée d'éventuels voyages partant de leur ville de résidence.
PROMPT "Q3a - V1";

SELECT numCl, ville, idV, villeDep, paysArr
FROM Client
    LEFT OUTER JOIN Voyage ON ville = villeDep;

PROMPT "Q3a - V2";

SELECT numCl, ville, idV, villeDep, paysArr
FROM Voyage
    RIGHT OUTER JOIN Client ON ville = villeDep;

-- Q3b - c:5, t:215
-- Donnez les identifiants, villes de départ et pays d'arrivée des voyages ainsi que les éventuels numéros et ville de résidence des clients résidant dans les villes de départ des voyages.
PROMPT "Q3b - V1";

SELECT idV, villeDep, paysArr, numCl, ville
FROM Client
    RIGHT OUTER JOIN Voyage ON ville = villeDep;

-- Version alternative.
PROMPT "Q3b - V2";

SELECT idV, villeDep, paysArr, numCl, ville
FROM Voyage
    LEFT OUTER JOIN Client ON villeDep = ville;

-- Q4
-- Formulez les variations de requêtes suivantes à la manière de votre choix :

-- Q4a - c:5, t:46
-- Donnez les numéros et ville de résidence des clients ainsi que les identifiants, villes de départ et pays d'arrivée d'éventuels voyages à destination du Kenya partant de la ville de résidence des clients.
PROMPT "Q4a";

SELECT numCl, ville, idV, villeDep, paysArr
FROM Client
    LEFT OUTER JOIN Voyage
        ON
            ville = villeDep
            AND paysArr = 'KENYA';

-- Q4b - c:5, t:39
-- Donnez les identifiants, villes de départ et pays d'arrivée des voyages à destination du Kenya ainsi que les éventuels numéros et ville de résidence des clients résidant dans les villes de départ des voyages.
PROMPT "Q4b";

SELECT idV, villeDep, paysArr, numCl, ville
FROM Voyage
    LEFT OUTER JOIN Client ON villeDep = ville
WHERE paysArr = 'KENYA';

-- Q4c - c:5, t:30
-- Donnez les numéros et ville de résidence des clients de numéro supérieur à 2200 ainsi que les identifiants, villes de départ et pays d'arrivée d'éventuels voyages partant de la ville de résidence des clients.
PROMPT "Q4c";

SELECT numCl, ville, idV, villeDep, paysArr
FROM Client
    LEFT OUTER JOIN Voyage ON ville = villeDep
WHERE numCl > 2200;

-- Q4d - c:5, t:41
-- Donnez les identifiants, villes de départ et pays d'arrivée des voyages ainsi que les éventuels numéros et ville de résidence des clients de numéro supérieur à 2200 résidant dans les villes de départ des voyages.
PROMPT "Q4d";

SELECT idV, villeDep, paysArr, numCl, ville
FROM Voyage
    LEFT OUTER JOIN Client
        ON
            villeDep = ville
            AND numCl > 2200;

-- Q5 - c:5, t:8
-- Donnez les numéros et ville de résidence des clients ainsi que les identifiants, villes de départ et pays d'arrivée d'éventuels voyages de clients habitant une ville d'où ne part aucun voyage pour le Kenya.
PROMPT "Q5";

SELECT C.numCl, ville, idV, villeDep, paysArr
FROM Client C
    LEFT OUTER JOIN Voyage
        ON
            ville = villeDep
            AND paysArr = 'KENYA'
WHERE idV IS NULL;

-- Q6 - c:5, t:14
-- Donnez les identifiants, villes de départ et pays d'arrivée des voyages ainsi que les éventuels numéros et ville de résidence des clients pour les voyages ne comportant aucun client de numéro supérieur à 2200 résidant dans les villes de départ.
PROMPT "Q6";

SELECT idV, villeDep, paysArr, C.numCl, ville
FROM Voyage
    LEFT OUTER JOIN Client C
        ON
            villeDep = ville
            AND numCl > 2200
WHERE numCl IS NULL;

-- @section Opérations de partitionnement

-- Q7 - c:2, t:7
-- Donnez, par pays d'arrivée, le nombre de voyages.
PROMPT "Q7";

SELECT paysArr, COUNT(*)
FROM Voyage
GROUP BY paysArr;

-- Q8 - c:3, t:15
-- Donnez, par pays et ville d'arrivée, le nombre de voyages.
PROMPT "Q8";

SELECT paysArr, villeArr, COUNT(*)
FROM Voyage
GROUP BY paysArr, villeArr;

-- Q9 - c:2, t:7
-- Donnez, pour chaque pays d'arrivée, le nombre de villes.
PROMPT "Q9";

SELECT paysArr, COUNT(DISTINCT villeArr)
FROM Voyage
GROUP BY paysArr;

-- Q10 - c:3, t:15
-- Donnez, pour chaque identifiant et ville d'arrivée de voyage, le nombre de dates planifiées.
PROMPT "Q10";

SELECT V.idV, villeArr, COUNT(dateDep)
FROM Voyage V
    INNER JOIN Planning P ON V.idV = P.idV
GROUP BY V.idV, villeArr;

-- Q11 - c:3, t:11
-- Donnez, pour chaque identifiant et ville d'arrivée de voyage, le nombre d'options gratuites.
PROMPT "Q11";

SELECT V.idV, villeArr, COUNT(code)
FROM Voyage V
    INNER JOIN Carac Ca ON V.idV = Ca.idV
WHERE prix = 0 OR prix IS NULL
GROUP BY V.idV, villeArr;

-- Q12 - c:2, t:2
-- Donnez, par catégorie effective, le nombre de clients.
PROMPT "Q12";

SELECT categorie, COUNT(*)
FROM Client
WHERE categorie IS NOT NULL
GROUP BY categorie;

-- Q13 - c:4, t:9
-- Donnez, par identifiant de voyage et ville d'arrivée, le nombre de voyages réservés et le nombre total de personnes.
PROMPT "Q13";

SELECT V.idV, villeArr, COUNT(R.idV), SUM(COALESCE(nbPers, 0))
FROM Voyage V
    INNER JOIN Reservation R ON V.idV = R.idV
GROUP BY V.idV, villeArr;

-- Q14 - c:2, t:7
-- Donnez, par voyage, le prix moyen effectif des options.
PROMPT "Q14 - V1";

SELECT idV, AVG(prix)
FROM Carac
WHERE (prix <> 0 OR prix IS NOT NULL)
GROUP BY idV;

-- Version alternative.
PROMPT "Q14 - V2";

SELECT idV, AVG(prix)
FROM Carac
GROUP BY idV
HAVING AVG(prix) IS NOT NULL;

-- Q15 - c:4, t:6
-- Donnez, pour chaque identifiant de voyage et ville d'arrivée, le nombre d'options gratuites et le nombre d'options payantes.
PROMPT "Q15";

SELECT V.idV, villeArr, COUNT(DISTINCT CaG.code), COUNT(DISTINCT CaP.code)
FROM Voyage V
    INNER JOIN Carac CaG ON V.idV = CaG.idV
    INNER JOIN Carac CaP ON V.idV = CaP.idV
WHERE
    (CaG.prix = 0 OR CaG.prix IS NULL)
    AND (CaP.prix <> 0 OR CaP.prix IS NOT NULL)
GROUP BY V.idV, villeArr;

-- Q16 - c:2, t:2
-- Donnez, par ville de résidence, et lorsque son nombre est supérieur à cinq, le nombre de clients.
PROMPT "Q16";

SELECT ville, COUNT(*)
FROM Client
GROUP BY ville
HAVING COUNT(*) > 5;

-- Q17 - c:3, t:9
-- Quel est, pour chaque identifiant de voyage et pays d'arrivée, le montant total, tenant compte du nombre de personnes, réglé par les clients ?
PROMPT "Q17";

SELECT V.idV, paysArr, SUM(tarif * nbPers)
FROM Voyage V
    INNER JOIN Reservation R ON V.idV = R.idV
    INNER JOIN Planning P ON R.idV = P.idV
GROUP BY V.idV, paysArr;

-- Q18 - c:3, t:17
-- Quel est, pour chaque identifiant de voyage et date de départ planifiée, le montant total, tenant compte du nombre de personnes, réglé par les clients ?
PROMPT "Q18";

SELECT P.idV, P.dateDep, SUM(tarif * nbPers)
FROM Planning P
    INNER JOIN Reservation R
        ON
            P.idV = R.idV
            AND P.dateDep = R.dateDep
GROUP BY P.idV, P.dateDep;

-- Q19 - c:1, t:6
-- Quels sont les pays pour lesquels il y a plus de réservations que pour l'Espagne ?
PROMPT "Q19";

WITH
    T (paysArr) AS (
        SELECT paysArr
        FROM Voyage V
            INNER JOIN Reservation R ON V.idV = R.idV
    )

SELECT paysArr
FROM T
GROUP BY paysArr
HAVING COUNT(*) > (
    SELECT COUNT(*)
    FROM T
    WHERE paysArr = 'ESPAGNE'
);

-- Q20 - c:1, t:1 (PRIVILEGIE)
-- Quelles sont les catégories effectives comportant le plus de clients ?
PROMPT "Q20";

WITH
    T (categorie, nbClients) AS (
        SELECT categorie, COUNT(*)
        FROM Client
        WHERE categorie IS NOT NULL
        GROUP BY categorie
    )

SELECT categorie
FROM T
WHERE nbClients >= ALL(
    SELECT nbClients
    FROM T
);

-- Q21 - c:1, t:2
-- Quels sont les pays pour lesquels il y a le plus de réservations ?
PROMPT "Q21";

WITH
    T (paysArr, nbRes) AS (
        SELECT paysArr, COUNT(*)
        FROM Voyage V
            INNER JOIN Reservation R ON V.idV = R.idV
        GROUP BY paysArr
    )

SELECT paysArr
FROM T
WHERE nbRes >= ALL(
    SELECT nbRes
    FROM T
);

-- Q22 - c:3, t:6
-- Donnez, pour chaque numéro et nom de client ayant fait une réservation pour le Kenya, le nombre total de réservations.
PROMPT "Q22";

SELECT C.numCl, nom, COUNT(*)
FROM Client C
    INNER JOIN Reservation R ON C.numCl = R.numCl
WHERE
    R.numCl IN (
        SELECT numCl
        FROM Reservation R
            INNER JOIN Voyage V ON R.idV = V.idV
        WHERE paysArr = 'KENYA'
    )
GROUP BY C.numCl, nom;

-- Q23 - c:2, t:3
-- Donnez, pour chaque pays ayant au moins un hôtel classé cinq étoiles, le nombre total d'hôtels, quel que soit leur nombre d'étoiles.
PROMPT "Q23";

SELECT paysArr, COUNT(DISTINCT Hotel)
FROM Voyage
WHERE
    paysArr IN (
        SELECT paysArr
        FROM Voyage
        WHERE nbEtoiles = 5
    )
GROUP BY paysArr;

-- @section Requêtes complexes

-- Q24 - c:1, t:3
-- Quelles sont les libellés des options gratuites incluses dans le voyage réservé par le Client Hubert Marin à destination d'Istanbul en date du 04/05/2004 ?
PROMPT "Q24";

SELECT DISTINCT libelle
FROM Client C
    INNER JOIN Reservation R ON C.numCl = R.numCl
    INNER JOIN Voyage V ON R.idV = V.idV
    INNER JOIN Carac Ca ON V.idV = Ca.idV
    INNER JOIN OptionV O ON Ca.code = O.code
WHERE
    nom = 'MARIN'
    AND prenom = 'HUBERT'
    AND villeArr = 'ISTANBUL'
    AND dateDep = TO_DATE('2004-05-04', 'YYYY-MM-DD')
    AND (prix = 0 OR prix IS NULL);

-- Q25 - c:1, t:2
-- Quelles sont les libellés des options gratuites pour au moins un voyage et payante pour au moins un autre ? Donner deux formulations différentes.
PROMPT "Q25 - V1";

SELECT DISTINCT libelle
FROM Carac C1
    INNER JOIN Carac C2 ON C1.code = C2.code
    INNER JOIN OptionV O ON C2.code = O.code
WHERE
    (C2.prix = 0 OR C2.prix IS NULL)
    AND (C1.prix <> 0 OR C1.prix IS NOT NULL);

-- Version alternative.
PROMPT "Q25 - V2";

WITH
    T (code, libelle, prix) AS (
        SELECT C.code, libelle, prix
        FROM Carac C
            INNER JOIN OptionV O ON C.code = O.code
    )

SELECT DISTINCT libelle
FROM T
WHERE
    (prix = 0 OR prix IS NULL)
    AND code IN (
        SELECT code
        FROM T
        WHERE (prix <> 0 OR prix IS NOT NULL)
    );

-- Q26 - c:1, t:5
-- Quelles sont les libellés des options toujours gratuites ? Proposer quatre formulations différentes.
PROMPT "Q26 - V1";

SELECT libelle
FROM OptionV
WHERE code NOT IN (
    SELECT code
    FROM Carac
    WHERE (prix <> 0 OR prix IS NOT NULL)
);

-- Version alternative.
PROMPT "Q26 - V2";

SELECT libelle
FROM OptionV
WHERE code <> ALL(
    SELECT code
    FROM Carac
    WHERE (prix <> 0 OR prix IS NOT NULL)
);

-- Version alternative.
PROMPT "Q26 - V3";

SELECT libelle
FROM OptionV O
WHERE NOT EXISTS (
    SELECT *
    FROM Carac Ca
    WHERE
        Ca.code = O.code
        AND (prix <> 0 OR prix IS NOT NULL)
);

-- Version alternative.
PROMPT "Q26 - V4";

SELECT DISTINCT libelle
FROM OptionV O
    LEFT OUTER JOIN Carac Ca
        ON
            O.code = Ca.code
            AND (prix <> 0 OR prix IS NOT NULL)
WHERE idV IS NULL;

-- Version alternative.
PROMPT "Q26 - V5";

SELECT libelle
FROM OptionV
WHERE code IN (
    SELECT code
    FROM Carac
    EXCEPT
    SELECT code
    FROM Carac
    WHERE (prix <> 0 OR prix IS NOT NULL)
);

-- Q27 - c:3, t:7
-- Quels sont les numéros, noms et prénoms des autres clients ayant réservé pour un des voyages réservé par Arnaud Peyroche ?
PROMPT "Q27";

WITH
    T (numCl, nom, prenom, idV) AS (
        SELECT C.numCl, nom, prenom, idV
        FROM Client C
            INNER JOIN Reservation R ON C.numCl = R.numCl
    )

SELECT DISTINCT numCl, nom, prenom
FROM T
WHERE
    (nom <> 'PEYROCHE' OR prenom <> 'ARNAUD')
    AND idV IN (
        SELECT idV
        FROM T
        WHERE
            nom = 'PEYROCHE'
            AND prenom = 'ARNAUD'
    );

-- Q28 - c:2, t:1 (6, 10)
-- Donnez le nombre de réservations et le nombre total de personnes pour les clients de la catégorie privilégié.
PROMPT "Q28";

SELECT COUNT(*), SUM(COALESCE(nbPers, 0))
FROM Client C
    INNER JOIN Reservation R ON C.numCl = R.numCl
WHERE categorie = 'PRIVILEGIE';

-- Remarque : Il faut gérer les valeurs nulles dans le calcul horizontal, car si nbPers prend une valeur nulle, sa somme sera à NULL et la fonction agrégative SUM rendra un résultat faux.

-- Q29 - c:3, t:1
-- Quels sont les numéros, noms et prénoms des clients ayant fait une réservation avec un nombre total maximal de personnes ?
PROMPT "Q29";

WITH
    T (numCl, nom, prenom, nbPers) AS (
        SELECT C.numCl, nom, prenom, nbPers
        FROM Client C
            INNER JOIN Reservation R ON C.numCl = R.numCl
    )

SELECT numCl, nom, prenom
FROM T
WHERE COALESCE(nbPers, 0) = (
    SELECT MAX(COALESCE(nbPers, 0))
    FROM T
);

-- Q30 - c:1, t:1 (14484)
-- Quel est le montant total des réservations du Client numéro 2101 ?
PROMPT "Q30";

SELECT SUM(COALESCE(nbPers, 0) * COALESCE(tarif, 0))
FROM Reservation R
    INNER JOIN Planning P ON R.idV = P.idV
WHERE numCl = 2101;

-- Q31 - c:1, t:4
-- Quels sont les hôtels avec le plus d'étoiles ?
PROMPT "Q31";

SELECT DISTINCT Hotel
FROM Voyage
WHERE nbEtoiles = (
    SELECT MAX(nbEtoiles)
    FROM Voyage
);

-- Q32 - c:1, t:4
-- Quels sont les pays n'ayant pas d'hôtel avec le plus grand nombre d'étoiles ?
PROMPT "Q32";

SELECT DISTINCT paysArr
FROM Voyage
WHERE paysArr NOT IN (
    SELECT paysArr
    FROM Voyage
    WHERE nbEtoiles = (
        SELECT MAX(nbEtoiles)
        FROM Voyage
    )
);

-- Q33 - c:5, t:66
-- Donnez les numéros et ville de résidence des clients, y compris ceux sans voyage, ainsi que les identifiants, villes de départ et pays d'arrivée des voyages, y compris ceux sans client, à destination du Kenya partant de la ville de résidence des clients.
PROMPT "Q33";

SELECT numCl, ville, idV, villeDep, paysArr
FROM Client
    FULL OUTER JOIN Voyage
        ON
            ville = villeDep
            AND paysArr = 'KENYA';

-- Q34 - c:2, t:26
-- Quels sont les numéros et noms des clients qui n'ont fait aucune réservation pour un voyage au Maroc ? Donnez deux formulations : une avec jointure externe et une avec test de non-existence.
-- Version avec jointure externe.
PROMPT "Q34 - Version avec jointure externe";

SELECT C.numCl, nom
FROM Client C
    LEFT OUTER JOIN (
        SELECT *
        FROM Voyage V
            INNER JOIN Reservation R ON V.idV = R.idV
        WHERE paysArr = 'MAROC'
    ) T
        ON C.numCl = T.numCl
WHERE T.numCl IS NULL;

-- Version avec test de non existence.
PROMPT "Q34 - Version avec test de non existence";

SELECT C.numCl, C.nom
FROM Client C
WHERE NOT EXISTS (
    SELECT *
    FROM Voyage V
        INNER JOIN Reservation R ON V.idV = R.idV
    WHERE
        paysArr = 'MAROC'
        AND R.numCl = C.numCl
);
