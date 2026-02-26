-- V1.0.2

-- @title Requêtes avec SQL
-- @intro Formulez, en SQL, sur la base de données exemple, les requêtes d'interrogation suivantes.

-- @section Requêtes simples

-- Q1 - c:4, t:3
-- Donnez la liste des avions dont la capacité est strictement supérieure à 350 passagers.
PROMPT "Q1";

SELECT *
FROM Avion
WHERE capacite > 350;

-- Q2 - c:2, t:2
-- Quels sont les numéros et noms des avions localisés à Nice ?
PROMPT "Q2";

SELECT numAv, nomAv
FROM Avion
WHERE localisation = 'NICE';

-- Q3 - c:2, t:10
-- Quels sont les numéros des pilotes en service et les villes de départ de leurs vols ?
PROMPT "Q3";

SELECT DISTINCT numPil, villeDep
FROM Vol;

-- Q4 - c:1, t:2
-- Quel sont les noms des pilotes domiciliés à Paris ayant un salaire d'au moins 5000 ?
PROMPT "Q4";

SELECT DISTINCT nomPil
FROM Pilote
WHERE
    adresse = 'PARIS'
    AND salaire > 5000;

-- Q5 - c:2, t:3
-- Quels sont les numéros et noms d'avions localisés à Nice ou dont la capacité est strictement inférieure à 350 passagers ?
PROMPT "Q5 - V1";

SELECT numAv, nomAv
FROM Avion
WHERE
    localisation = 'NICE'
    OR capacite < 350;

-- Version alternative (pas au programme mais plus fidèle la à requête correspondante en algèbre relationnelle).
PROMPT "Q5 - V2";

SELECT numAv, nomAv
FROM Avion
WHERE localisation = 'NICE'
UNION
SELECT numAv, nomAv
FROM Avion
WHERE capacite < 350;

-- Q6 - c:7, t:2
-- Donnez la liste des vols au départ de Nice allant à Paris à partir de 18 heures.
PROMPT "Q6 - V1";

SELECT *
FROM Vol
WHERE
    villeDep = 'NICE'
    AND villeArr = 'PARIS'
    AND heureDep > '18:00';
--  AND heureDep > TO_DATE('18', 'HH24');

-- Version alternative (pas au programme mais plus fidèle à la requête correspondante en algèbre relationnelle).
PROMPT "Q6 - V2";

SELECT *
FROM Vol
WHERE villeDep = 'NICE'
INTERSECT
SELECT *
FROM Vol
WHERE villeArr = 'PARIS'
INTERSECT
SELECT *
FROM Vol
WHERE heureDep > '18:00';
-- WHERE heureDep > TO_DATE('18', 'HH24');

-- Q7 - c:2, t:5
-- Quels sont les numéros et villes de départ des vols effectués par les pilotes de numéro 100 ou 204 ?
PROMPT "Q7 - V1";

SELECT numVol, villeDep
FROM Vol
WHERE
    numPil = 100
    OR numPil = 204;

-- Version alternative.
PROMPT "Q7 - V2";

SELECT numVol, villeDep
FROM Vol
WHERE numPil IN (100, 204);

-- Remarque : `= ANY` est synonyme de `IN` sous Oracle même pour les ensembles de valeurs mais ce n'est pas portable dans d'autres systèmes de gestion de base de données. L'alternative n'est donc pas intéréssantes ici.

-- Version alternative (pas au programme mais plus fidèle à la requête correspondante en algèbre relationnelle).
PROMPT "Q7 - V3";

SELECT numVol, villeDep
FROM Vol
WHERE numPil = 100
UNION
SELECT numVol, villeDep
FROM Vol
WHERE numPil = 204;

-- Q8 - c:1, t:1
-- Combien y a-t-il de vols desservant Paris ?
PROMPT "Q8";

SELECT COUNT(*)
FROM Vol
WHERE villeArr = 'PARIS';

-- Q9 - c:1, t:1
-- Donnez le nombre de pilotes effectuant un vol au départ de Paris.
PROMPT "Q9";

SELECT COUNT(DISTINCT numPil)
FROM Vol
WHERE villeDep = 'PARIS';

-- Q10 - c:1, t:1
-- Quel est le salaire moyen des pilotes marseillais ?
PROMPT "Q10";

SELECT AVG(salaire)
FROM Pilote
WHERE adresse = 'MARSEILLE';

-- @section Requêtes complexes
-- @instruction Quand cela possible, formulez les requêtes suivantes de trois manières différentes.

-- Q11 - c:1, t:3
-- Donnez les numéros des vols effectués au départ de Nice par des pilotes parisiens.
-- Version algébrique.
PROMPT "Q11 - Version algébrique";

SELECT numVol
FROM Vol V
    INNER JOIN Pilote P ON V.numPil = P.numPil
WHERE
    villeDep = 'NICE'
    AND adresse = 'PARIS';

-- Version imbriquée.
PROMPT "Q11 - Version imbriquée";

SELECT numVol
FROM Vol
WHERE
    villeDep = 'NICE'
    AND numPil IN (
        SELECT numPil
        FROM Pilote
        WHERE adresse = 'PARIS'
    );

-- Version prédicative.
PROMPT "Q11 - Version prédicative";

SELECT numVol
FROM Vol V, Pilote P
WHERE
    V.numPil = P.numPil
    AND villeDep = 'NICE'
    AND adresse = 'PARIS';

-- Q12 - c:3, t:12
-- Quels sont les numéros, villes de départ, et villes d'arrivée des vols effectués par un avion qui n'est pas localisé à Nice ?
-- Version algébrique.
PROMPT "Q12 - Version algébrique";

SELECT numVol, villeDep, villeArr
FROM Vol V
    INNER JOIN Avion A ON V.numAv = A.numAv
WHERE localisation <> 'NICE';

-- Version imbriquée.
PROMPT "Q12 - Version imbriquée";

SELECT numVol, villeDep, villeArr
FROM Vol
WHERE numAv IN (
    SELECT numAv
    FROM Avion
    WHERE localisation <> 'NICE'
);

-- Version prédicative.
PROMPT "Q12 - Version prédicative";

SELECT numVol, villeDep, villeArr
FROM Vol V, Avion A
WHERE
    V.numAv = A.numAv
    AND localisation <> 'NICE';

-- Q13 - c:1, t:2
-- Quels sont les numéros des pilotes qui ne sont pas en service ?
PROMPT "Q13 - V1";

SELECT numPil
FROM Pilote
WHERE NumPil NOT IN (
    SELECT NumPil
    FROM Vol
);

-- Version alternative.
PROMPT "Q13 - V2";

SELECT numPil
FROM Pilote
WHERE NumPil <> ALL(
    SELECT NumPil
    FROM Vol
);

-- Version alternative (pas au programme mais plus fidèle à la requête correspondante en algèbre relationnelle).
PROMPT "Q13 - V3";

SELECT numPil
FROM Pilote
EXCEPT
SELECT numPil
FROM Vol;

-- Q14 - c:2, t:4
-- Quels sont les noms et adresses des pilotes assurant au moins un vol au départ de Nice avec des avions de capacité de plus de 300 places ?
-- Version algébrique.
PROMPT "Q14 - Version algébrique";

SELECT DISTINCT nomPil, adresse
FROM Pilote P
    INNER JOIN Vol V ON P.numPil = V.numPil
    INNER JOIN Avion A ON V.numAv = A.numAv
WHERE
    villeDep = 'NICE'
    AND capacite > 300;

-- Version imbriquée.
PROMPT "Q14 - Version imbriquée";

SELECT DISTINCT nomPil, adresse
FROM Pilote
WHERE numPil IN (
    SELECT numPil
    FROM Vol
    WHERE
        villeDep = 'NICE'
        AND numAv IN (
            SELECT numAv
            FROM Avion
            WHERE capacite > 300
        )
);

-- Version prédicative.
PROMPT "Q14 - Version prédicative";

SELECT DISTINCT nomPil, adresse
FROM Pilote P, Vol V, Avion A
WHERE
    P.numPil = V.numPil
    AND V.numAv = A.numAv
    AND villeDep = 'NICE'
    AND capacite > 300;

-- Q15 - c:1, t:1
-- Quels sont les noms des pilotes domiciliés à Paris assurant des vols au départ de Nice avec des A320 ?
-- Version algébrique.
PROMPT "Q15 - Version algébrique";

SELECT DISTINCT nomPil
FROM Pilote P
    INNER JOIN Vol V ON P.numPil = V.numPil
    INNER JOIN Avion A ON V.numAv = A.numAv
WHERE
    adresse = 'PARIS'
    AND villeDep = 'NICE'
    AND nomAv = 'A320';

-- Version imbriquée.
PROMPT "Q15 - Version imbriquée";

SELECT DISTINCT nomPil
FROM Pilote
WHERE
    adresse = 'PARIS'
    AND numPil IN (
        SELECT numPil
        FROM Vol
        WHERE
            villeDep = 'NICE'
            AND numAv IN (
                SELECT numAv
                FROM Avion
                WHERE nomAv = 'A320'
            )
    );

-- Version prédicative.
PROMPT "Q15 - Version prédicative";

SELECT DISTINCT nomPil
FROM Pilote P, Vol V, Avion A
WHERE
    P.numPil = V.numPil
    AND V.numAv = A.numAv
    AND adresse = 'PARIS'
    AND villeDep = 'NICE'
    AND nomAv = 'A320';

-- Q16 - c:1, t:1
-- Quels sont les numéros des vols effectués par des pilotes niçois au départ ou à l'arrivée de Nice avec des avions localisés à Paris ?
-- Version algébrique.
PROMPT "Q16 - Version algébrique";

SELECT numVol
FROM Vol V
    INNER JOIN Pilote P ON V.numPil = P.numPil
    INNER JOIN Avion A ON V.numAv = A.numAv
WHERE
    (villeDep = 'NICE' OR villeArr = 'NICE')
    AND adresse = 'NICE'
    AND localisation = 'PARIS';

-- Version imbriquée.
PROMPT "Q16 - Version imbriquée";

SELECT numVol
FROM Vol
WHERE
    (villeDep = 'NICE' OR villeArr = 'NICE')
    AND numPil IN (
        SELECT numPil
        FROM Pilote
        WHERE adresse = 'NICE'
    )
    AND numAv IN (
        SELECT numAv
        FROM Avion
        WHERE localisation = 'PARIS'
    );

-- Version prédicative.
PROMPT "Q16 - Version prédicative";

SELECT numVol
FROM Vol V, Pilote P, Avion A
WHERE
    V.numPil = P.numPil
    AND V.numAv = A.numAv
    AND (villeDep = 'NICE' OR villeArr = 'NICE')
    AND adresse = 'NICE'
    AND localisation = 'PARIS';

-- Q17 - c:1, t:5
-- Quels sont, à l'exception des pilotes nommés Durand, les noms de pilotes en service ?
-- Version algébrique.
PROMPT "Q17 - Version algébrique";

SELECT DISTINCT nomPil
FROM Pilote P
    INNER JOIN Vol V ON P.numPil = V.numPil
WHERE nomPil <> 'DURAND';

-- Version imbriquée.
PROMPT "Q17 - Version imbriquée";

SELECT DISTINCT nomPil
FROM Pilote P
WHERE
    nomPil <> 'DURAND'
    AND numPil IN (
        SELECT numPil
        FROM Vol
    );

-- Version prédicative.
PROMPT "Q17 - Version prédicative";

SELECT DISTINCT nomPil
FROM Pilote P, Vol V
WHERE
    P.numPil = V.numPil
    AND nomPil <> 'DURAND';

-- Q18 - c:1, t:3
-- Quels sont les horaires de départ des vols desservant les villes d'arrivée des vols au départ de Paris ?
-- Version algébrique.
PROMPT "Q18 - Version algébrique";

SELECT DISTINCT VolCor.heureDep
FROM Vol VolPar
    INNER JOIN Vol VolCor ON VolPar.villeDep = VolCor.villeArr
WHERE VolPar.villeDep = 'PARIS';

-- Version imbriquée.
-- Q18 - c:1, t:7
PROMPT "Q18 - Version imbriquée";

SELECT DISTINCT heureDep
FROM Vol
WHERE villeDep IN (
    SELECT villeArr
    FROM Vol
    WHERE villeDep = 'PARIS'
);


-- Version prédicative.
-- Q18 - c:1, t:3
PROMPT "Q18 - Version prédicative";

SELECT DISTINCT VolCor.heureDep
FROM Vol VolPar, Vol VolCor
WHERE
    VolPar.villeDep = VolCor.villeArr
    AND VolPar.villeDep = 'PARIS';

-- Q19 - c:2, t:3
-- Quels sont les numéros et noms des pilotes habitant dans les mêmes villes que les pilotes nommés Martin ?
PROMPT "Q19 - Version algébrique";

SELECT DISTINCT Px.numPil, Px.nomPil
FROM Pilote Px
    INNER JOIN Pilote PMar ON Px.adresse = PMar.adresse
WHERE
    Px.nomPil <> 'MARTIN'
    AND PMar.nomPil = 'MARTIN';

-- Version imbriquée.
PROMPT "Q19 - Version imbriquée";

SELECT DISTINCT numPil, nomPil
FROM Pilote
WHERE
    nomPil <> 'MARTIN'
    AND adresse IN (
        SELECT adresse
        FROM Pilote
        WHERE nomPil = 'MARTIN'
    );

-- Version prédicative.
PROMPT "Q19 - Version prédicative";

SELECT DISTINCT Px.numPil, Px.nomPil
FROM Pilote Px, Pilote PMar
WHERE
    Px.adresse = PMar.adresse
    AND Px.nomPil <> 'MARTIN'
    AND PMar.nomPil = 'MARTIN';

-- Q20 - c:1, t:1
-- Quels sont les numéros des avions localisés dans la même ville que l'avion numéro 100 ?
PROMPT "Q20 - Version algébrique";

SELECT Ax.numAv
FROM Avion Ax
    INNER JOIN Avion A100 ON Ax.localisation = A100.localisation
WHERE
    Ax.numAv <> 100
    AND A100.numAv = 100;

-- Version imbriquée.
PROMPT "Q20 - Version imbriquée";

SELECT numAv
FROM Avion
WHERE
    numAv <> 100
    AND localisation IN (
        SELECT localisation
        FROM Avion
        WHERE numAv = 100
    );

-- Version prédicative.
PROMPT "Q20 - Version prédicative";

SELECT Ax.numAv
FROM Avion Ax, Avion A100
WHERE
    Ax.localisation = A100.localisation
    AND Ax.numAv <> 100
    AND A100.numAv = 100;

-- Q21 - c:1, t:1
-- Quelles sont les villes de départ de vols dans lesquelles ne réside aucun pilote ?
PROMPT "Q21 - V1";

SELECT DISTINCT villeDep
FROM Vol
WHERE villeDep NOT IN (
    SELECT adresse
    FROM Pilote
);

-- Version alternative.
PROMPT "Q21 - V2";

SELECT DISTINCT villeDep
FROM Vol
WHERE villeDep <> ALL(
    SELECT adresse
    FROM Pilote
);

-- Version alternative (pas au programme mais plus fidèle à la requête correspondante en algèbre relationnelle).
PROMPT "Q21 - V3";

SELECT villeDep
FROM Vol
EXCEPT
SELECT adresse
FROM Pilote;

-- Q22 - c:1, t:6
-- Quels sont les noms des pilotes n'effectuant pas de vol au départ de Lyon ?
PROMPT "Q22 - V1";

SELECT DISTINCT nomPil
FROM Pilote
WHERE numPil NOT IN (
    SELECT numPil
    FROM Vol
    WHERE villeDep = 'LYON'
);

-- Version alternative.
PROMPT "Q22 - V2";

SELECT DISTINCT nomPil
FROM Pilote
WHERE numPil <> ALL(
    SELECT numPil
    FROM Vol
    WHERE villeDep = 'LYON'
);

-- Version alternative (pas au programme mais plus fidèle à la requête correspondante en algèbre relationnelle).
PROMPT "Q22 - V3";

SELECT nomPil
FROM Pilote
EXCEPT
SELECT nomPil
FROM Pilote P
    INNER JOIN Vol V ON P.numPil = V.numPil
WHERE villeDep = 'LYON';

-- Q23 - c:2, t:2
-- Donnez les numéros et noms des pilotes homonymes.
PROMPT "Q23 - Version algébrique";

SELECT P1.numPil, P1.nomPil
FROM Pilote P1
    INNER JOIN Pilote P2
        ON
            P1.nomPil = P2.nomPil
            AND P1.numPil <> P2.numPil;

-- Version imbriquée.
-- Remarque : la version imbriquée n'est pas possible quand nous utilisons l'opérateur <> comme critère d'une condition de jointure.

-- Version prédicative.
PROMPT "Q23 - Version prédicative";

SELECT P1.numPil, P1.nomPil
FROM Pilote P1, Pilote P2
WHERE
    P1.nomPil = P2.nomPil
    AND P1.numPil <> P2.numPil;

-- Q24 - c:1, t:4
-- Quelles sont les villes où habitent des pilotes et où sont localisés des avions ?
PROMPT "Q24 - V1";

SELECT DISTINCT adresse
FROM Pilote
WHERE adresse IN (
    SELECT localisation
    FROM Avion
);

-- Version alternative (pas au programme mais plus fidèle à la requête correspondante en algèbre relationnelle).
-- Q24 - c:1, t:4
PROMPT "Q24 - V2";

SELECT adresse
FROM Pilote
INTERSECT
SELECT localisation
FROM Avion;

-- Q25 - c:1, t:4
-- Quels sont les noms des pilotes qui effectuent des vols au départ de leur ville de résidence ?
PROMPT "Q25 - Version algébrique";

SELECT DISTINCT nomPil
FROM Pilote P
    INNER JOIN Vol V
        ON
            P.numPil = V.numPil
            AND adresse = villeDep;

-- Version imbriquée.
PROMPT "Q25 - Version imbriquée";

SELECT DISTINCT nomPil
FROM Pilote
WHERE (
    numPil, adresse) IN (
    SELECT numPil, villeDep
    FROM Vol
);

-- Version prédicative.
PROMPT "Q25 - Version prédicative";

SELECT DISTINCT nomPil
FROM Pilote P, Vol V
WHERE
    P.numPil = V.numPil
    AND adresse = villeDep;

-- Q26 - c:3, t:1
-- Quels sont les numéros, noms et salaires des pilotes domiciliés dans les mêmes villes que les pilotes nommés Martin tout en ayant un salaire supérieur à eux ?
PROMPT "Q26 - Version algébrique";

SELECT Px.numPil, Px.nomPil, Px.salaire
FROM Pilote Px
    INNER JOIN Pilote PMar
        ON
            Px.adresse = PMar.adresse
            AND Px.salaire > PMar.salaire
WHERE PMar.nomPil = 'MARTIN';

-- Version imbriquée.
-- Remarque : la version imbriquée n'est pas possible quand nous utilisons l'opérateur > comme critère d'une condition de jointure.

-- Version prédicative.
PROMPT "Q26 - Version prédicative";

SELECT Px.numPil, Px.nomPil, Px.salaire
FROM Pilote Px, Pilote PMar
WHERE
    Px.adresse = PMar.adresse
    AND Px.salaire > PMar.salaire
    AND PMar.nomPil = 'MARTIN';

-- Q27 - c:2, t:1
-- Quels sont les numéros et villes d'arrivée des vols dont l'horaire de départ est le plus tardif ?
PROMPT "Q27 - V1";

SELECT numVol, villeArr
FROM Vol
WHERE heureDep = (
    SELECT MAX(heureDep)
    FROM Vol
);

-- Version alternative.
PROMPT "Q27 - V2";

SELECT numVol, villeArr
FROM Vol
WHERE heureDep >= ALL(
    SELECT heureDep
    FROM Vol
);

-- Q28 - c:1, t:1
-- Donnez le nombre de vols effectués par les pilotes ayant les plus petits salaires.
PROMPT "Q28 - V1";

SELECT COUNT(*)
FROM Vol
WHERE numPil IN (
    SELECT numPil
    FROM Pilote
    WHERE salaire = (
        SELECT MIN(salaire)
        FROM Pilote
    )
);

-- Version alternative.
PROMPT "Q28 - V2";

SELECT COUNT(*)
FROM Vol V
    INNER JOIN Pilote P ON V.numPil = P.numPil
WHERE salaire = (
    SELECT MIN(salaire)
    FROM Pilote
);

-- Version alternative.
PROMPT "Q28 - V3";

SELECT COUNT(*)
FROM Vol V
    INNER JOIN Pilote P ON V.numPil = P.numPil
WHERE salaire <= ALL(
    SELECT salaire
    FROM Pilote
);
