-- V1.1.0

-- @section Expression des jointures
-- @instruction Quand cela possible, formulez les requêtes suivantes de trois manières différentes.

-- Q1 - c:2, t:9
-- Donnez, pour l'étudiant Stéphane Rocchi, les moyennes de test obtenues par ordre décroissant avec le code du module associé. 
-- @difficulty 2
-- @tags jointure, imbrication, sélection, tri
-- Version algébrique.
PROMPT "Q1 - Version algébrique";

SELECT code, moyTest
FROM Etudiant Et
    INNER JOIN Note N ON Et.numEt = N.numEt
WHERE
    nomEt = 'ROCCHI'
    AND prenomEt = 'STEPHANE'
ORDER BY moyTest DESC;

-- Version imbriquée.
PROMPT "Q1 - Version imbriquée";

SELECT code, moyTest
FROM Note
WHERE
    numEt IN (
        SELECT numEt
        FROM Etudiant
        WHERE
            nomEt = 'ROCCHI'
            AND prenomEt = 'STEPHANE'
    )
ORDER BY moyTest DESC;

-- Version prédicative.
PROMPT "Q1 - Version prédicative";

SELECT code, moyTest
FROM Etudiant Et
    INNER JOIN Note N ON Et.numEt = N.numEt
WHERE
    nomEt = 'ROCCHI'
    AND prenomEt = 'STEPHANE'
ORDER BY moyTest DESC;

-- Q2 - c:2, t:2
-- Donnez les codes et libellés des modules enseignés par Didier Boitard.
-- @difficulty 2
-- @tags jointure, imbrication, distinct
-- Version algébrique.
PROMPT "Q2 - Version algébrique";

SELECT DISTINCT M.code, libelle
FROM Module M
    INNER JOIN Enseigne E ON M.code = E.code
    INNER JOIN Professeur P ON E.numProf = P.numProf
WHERE
    nomProf = 'BOITARD'
    AND prenomProf = 'DIDIER';

-- Version imbriquée.
PROMPT "Q2 - Version imbriquée";

SELECT code, libelle
FROM Module
WHERE code IN (
    SELECT code
    FROM Enseigne
    WHERE numProf IN (
        SELECT numProf
        FROM Professeur
        WHERE
            nomProf = 'BOITARD'
            AND prenomProf = 'DIDIER'
    )
);

-- Version prédicative.
PROMPT "Q2 - Version prédicative";

SELECT DISTINCT M.code, libelle
FROM Module M, Professeur P, Enseigne E
WHERE
    M.code = E.code
    AND E.numProf = P.numProf
    AND nomProf = 'BOITARD'
    AND prenomProf = 'DIDIER';

-- @remark Dans la version algébrique et prédicative, il y a autant de tuples résultats que d’étudiants ayant un enseignement de Didier Boitard. Il faut donc utiliser DISTINCT pour éliminer les modules dupliqués. Dans la version imbriquée, le premier bloc n’opère que sur la relation module dont code est la clef primaire. Il ne peut donc pas y avoir de duplicats et DISTINCT n’a donc pas besoin d’être utilisé.
-- @remark_teacher Erreur fréquente : les étudiants oublient DISTINCT dans la version algébrique. Leur faire remarquer que la version imbriquée ne nécessite pas DISTINCT car la projection porte sur la clef primaire de Module.

-- Q3 - c:1, t:2
-- Quels sont les groupes de seconde année pour lesquels Marc Laporte a effectué un enseignement ?
-- @difficulty 2
-- @tags jointure, imbrication, sélection, distinct
-- Version algébrique.
PROMPT "Q3 - Version algébrique";

SELECT DISTINCT groupeEt
FROM Etudiant Et
    INNER JOIN Enseigne E ON Et.numEt = E.numEt
    INNER JOIN Professeur P ON E.numProf = P.numProf
WHERE
    anneeEt = 2
    AND nomProf = 'LAPORTE'
    AND prenomProf = 'MARC';

-- Version imbriquée.
PROMPT "Q3 - Version imbriquée";

SELECT DISTINCT groupeEt
FROM Etudiant
WHERE
    anneeEt = 2
    AND numEt IN
    (
        SELECT numEt
        FROM Enseigne
        WHERE
            numProf IN
            (
                SELECT numProf
                FROM Professeur
                WHERE
                    nomProf = 'LAPORTE'
                    AND prenomProf = 'MARC'
            )
    );

-- Version prédicative.
PROMPT "Q3 - Version prédicative";

SELECT DISTINCT groupeEt
FROM Etudiant Et, Enseigne E, Professeur P
WHERE
    Et.numEt = E.numEt
    AND E.numProf = P.numProf
    AND anneeEt = 2
    AND nomProf = 'LAPORTE'
    AND prenomProf = 'MARC';

-- @remark Quelle que soit la version de la requête, il y a autant de valeurs résultats que d’étudiants ayant un enseignement de Marc Laporte. Il faut donc toujours utiliser DISTINCT pour éliminer les numéros de groupeEt dupliqués.

-- Q4 - c:2, t:18
-- Donnez les numéros et, par ordre alphabétique, les noms des étudiants ayant suivi un enseignement effectué par un professeur, par ailleurs responsable d'un module quelconque.
-- @difficulty 2
-- @tags jointure, imbrication, tri, distinct
-- Version algébrique.
PROMPT "Q4 - Version algébrique";

SELECT DISTINCT Et.numEt, nomEt
FROM Etudiant Et
    INNER JOIN Enseigne E ON Et.numEt = E.numEt
    INNER JOIN Module M ON E.numProf = resp
ORDER BY nomEt ASC;

-- Version imbriquée.
PROMPT "Q4 - Version imbriquée";

SELECT numEt, nomEt
FROM Etudiant
WHERE
    numEt IN
    (
        SELECT numEt
        FROM Enseigne
        WHERE numProf IN (
            SELECT resp
            FROM Module
        )
    )
ORDER BY nomEt ASC;

-- Version prédicative.
PROMPT "Q4 - Version prédicative";

SELECT DISTINCT Et.numEt, nomEt
FROM Etudiant Et, Enseigne E, Module M
WHERE
    Et.numEt = E.numEt
    AND E.numProf = resp
ORDER BY nomEt ASC;

-- @remark Un étudiant pouvant avoir plusieurs fois le même professeur pour des enseignements différents, le mot-clef DISTINCT est nécessaire pour éliminer les duplicats, cependant pour conserver les homonymes dans le résultat, il convient d'effectuer la projection de l'attribut clef primaire numEt.

-- Q5 - c:2, t:12
-- Donnez les numéros et, par ordre alphabétique, les noms des étudiants ayant suivi un enseignement effectué par le professeur responsable de ce module.
-- @difficulty 3
-- @tags jointure, imbrication, tri, distinct
-- Version algébrique.
PROMPT "Q5 - Version algébrique";

SELECT DISTINCT Et.numEt, nomEt
FROM Etudiant Et
    INNER JOIN Enseigne E ON Et.numEt = E.numEt
    INNER JOIN Module M
        ON
            E.code = M.code
            AND numProf = resp
ORDER BY nomEt ASC;

-- Version imbriquée.
PROMPT "Q5 - Version imbriquée";

SELECT numEt, nomEt
FROM Etudiant
WHERE
    numEt IN (
        SELECT numEt
        FROM Enseigne
        WHERE (numProf, code) IN (
            SELECT resp, code FROM Module
        )
    )
ORDER BY nomEt ASC;

-- Version prédicative.
PROMPT "Q5 - Version prédicative";

SELECT DISTINCT Et.numEt, nomEt
FROM Etudiant Et, Enseigne E, Module M
WHERE
    Et.numEt = E.numEt
    AND E.code = M.code
    AND numProf = resp
ORDER BY nomEt ASC;

-- @section Formulation de calculs verticaux et horizontaux
-- @instruction Formulez les requêtes suivantes, en veillant particulièrement à l'évaluation des valeurs nulles pour les calculs horizontaux.

-- Q6 - c:1, t:1 (17)
-- Combien y-a-t-il de professeurs ?
-- @difficulty 1
-- @tags agrégation
PROMPT "Q6";

SELECT COUNT(*)
FROM Professeur;

-- Q7 - c:1, t:1 (9.7)
-- Quelle est la moyenne générale des notes de contrôle continu pour le module de code PRL ?
-- @difficulty 1
-- @tags agrégation, sélection
PROMPT "Q7";

SELECT AVG(moyCC)
FROM Note
WHERE code = 'PRL';

-- Q8 - c:1, t:1 (7)
-- Combien de professeurs ont donné un enseignement à l'étudiant Philippe Lyon ?
-- @difficulty 2
-- @tags jointure, agrégation, distinct
PROMPT "Q8";

SELECT COUNT(DISTINCT numProf)
FROM Enseigne E
    INNER JOIN Etudiant Et ON E.numEt = Et.numEt
WHERE
    nomEt = 'LYON'
    AND prenomEt = 'PHILIPPE';

-- @remark Sans l’utilisation de DISTINCT, la requête ne retourne pas le résultat voulu mais le nombre d’enseignements reçus par l’étudiant Philippe Lyon. S’il se trouve que cet étudiant n’a pas plusieurs fois le même professeur, la requête sans DISTINCT donnera un résultat juste mais elle est néanmoins logiquement fausse.

-- Q9 - c:1, t:1 (10.66)
-- Donnez, pour le module Prolog, la note moyenne obtenue par les étudiants en tenant compte des coefficients de contrôle continu et de test.
-- @difficulty 3
-- @tags jointure, agrégation, null
PROMPT "Q9";

SELECT AVG((COALESCE(moyCC, 0) * coefCC + COALESCE(moyTest, 0) * coefTest) / (coefCC + coefTest)) AS moyenne
FROM Note N
    INNER JOIN Module M ON N.code = M.code
WHERE libelle = 'PROLOG';

-- @remark L’alias moyenne spécifié après l’expression de calcul horizontal est introduit pour, notamment, éviter l’affichage de l’expression.

-- Q10 - c:1, t:1 (0)
-- Quel est le coefficient de test le plus faible ?
-- @difficulty 1
-- @tags agrégation
PROMPT "Q10";

SELECT MIN(coefTest)
FROM Module;

-- Q11 - c:1, t:1 (ETUDE DE CAS 1)
-- Quels sont les libellés des modules dont le coefficient de test est le plus faible ? Proposer deux formulations différentes de cette requête.
-- @difficulty 2
-- @tags imbrication, agrégation
PROMPT "Q11 - V1";

SELECT DISTINCT libelle
FROM Module
WHERE coefTest = (
    SELECT MIN(coefTest)
    FROM Module
);

-- Version alternative.
PROMPT "Q11 - V2";

SELECT DISTINCT libelle
FROM Module
WHERE coefTest <= ALL(
    SELECT coefTest
    FROM Module
    WHERE coefTest IS NOT NULL
);

-- @remark Dans la seconde requête, la condition coefTest IS NOT NULL doit être spécifiée. En effet si l’attribut concerné comprend des valeurs nulles, le résultat de la sous-requête est évalué à « inconnu » et la requête principale ne rend aucun tuple.

-- Q12 - c:1, t:1 (11.13)
-- En supposant que tous les modules sont de même importance, donnez la moyenne générale de l'étudiante Sandrine Levy.
-- @difficulty 3
-- @tags jointure, agrégation, null
PROMPT "Q12";

SELECT AVG(((COALESCE(moyCC, 0) * coefCC) + (COALESCE(moyTest, 0) * coefTest)) / (coefCC + coefTest)) AS moyenne
FROM Module M
    INNER JOIN Note N ON M.code = N.code
    INNER JOIN Etudiant
        Et ON N.numEt = Et.numEt
    AND nomEt = 'LEVY'
    AND prenomEt = 'SANDRINE';

-- Q13 - c:1, t:2
-- Quels sont les codes des modules pour lesquels la meilleure note de test a été obtenue ?
-- @difficulty 2
-- @tags imbrication, agrégation
PROMPT "Q13";

SELECT DISTINCT code
FROM Note
WHERE moyTest = (
    SELECT MAX(moyTest)
    FROM Note
);

-- Q14 - c:2, t:2
-- Quels sont les numéros et noms des étudiants qui ont obtenu, tous modules confondus, la meilleure note de test ? Proposer deux formulations différentes de cette requête.
-- @difficulty 2
-- @tags jointure, imbrication, agrégation, null
PROMPT "Q14 - V1";

SELECT DISTINCT Et.numEt, nomEt
FROM Etudiant Et
    INNER JOIN Note N ON Et.numEt = N.numEt
WHERE moyTest = (
    SELECT MAX(moyTest)
    FROM Note
);

-- @remark Il faut procéder à l'élimination des duplicats (par DISTINCT) car le même étudiant peut avoir obtenu la note maximale dans plusieurs modules différents.

-- Version alternative.
PROMPT "Q14 - V2";

SELECT DISTINCT Et.numEt, nomEt
FROM Etudiant Et
    INNER JOIN Note N ON Et.numEt = N.numEt
WHERE moyTest >= ALL(
    SELECT moyTest
    FROM Note
    WHERE moyTest IS NOT NULL
);

-- @remark La condition de sélection moyTest IS NOT NULL, dans la requête imbriquée, est nécessaire car il suffit d’une note de test inconnue pour que la requête ne rende aucun résultat.

-- Version alternative.
PROMPT "Q14 - V3";

SELECT numEt, nomEt
FROM Etudiant
WHERE numEt IN (
    SELECT numEt
    FROM Note
    WHERE moyTest IN (
        SELECT MAX(moyTest)
        FROM Note
    )
);

-- @section Utilisation des opérateurs ensemblistes

-- Q15 - c:1, t:6
-- Donnez les villes de résidence des étudiants et des professeurs.
-- @difficulty 1
-- @tags union, null
PROMPT "Q15";

SELECT villeEt
FROM Etudiant
WHERE villeEt IS NOT NULL
UNION
SELECT villeProf
FROM Professeur
WHERE villeProf IS NOT NULL;

-- Q16 - c:2, t:4
-- Quels sont les numéros des professeurs responsables d'un module qu'ils enseignent ainsi que le code du module correspondant ?
-- @difficulty 2
-- @tags intersection
PROMPT "Q16";

SELECT resp, code
FROM Module
INTERSECT
SELECT numProf, code
FROM Enseigne;

-- Q17 - c:1, t:23
-- Donnez les libellés des modules ne correspondant à la spécialité d'aucun professeur.
-- @difficulty 2
-- @tags différence, imbrication
PROMPT "Q17";

SELECT DISTINCT libelle
FROM Module
WHERE code IN (
    SELECT code
    FROM Module
    EXCEPT
    SELECT specProf
    FROM Professeur
);

-- @section Équivalent des opérateurs ensemblistes
-- @instruction Proposez une nouvelle formulation des requêtes de la section précédente sans faire appel aux opérateurs ensemblistes.

-- Q18 - c:2, t:4 [= Q16]
-- Quels sont les numéros des professeurs responsables d'un module qu'ils enseignent ainsi que le code du module correspondant ?
-- @difficulty 2
-- @tags jointure, imbrication, distinct
PROMPT "Q18 - V1";

SELECT DISTINCT resp, M.code
FROM Module M
    INNER JOIN Enseigne E
        ON
            M.resp = E.numProf
            AND M.code = E.code;

-- @remark Le mot clef DISTINCT est obligatoire car un même responsable peut enseigner le même module à des étudiants différents.

-- Version alternative.
PROMPT "Q18 - V2";

SELECT resp, code
FROM Module
WHERE (
    resp, code) IN (
    SELECT numProf, code
    FROM Enseigne
);

-- @remark Il est inutile de contrôler que la sous-requête puisse retourner des valeurs nulles. En effet, ce cas est impossible : numProf et code font partie de la clef primaire de Enseigne.

-- Q19 - c:1, t:23 [= Q17]
-- Donnez les libellés des modules ne correspondant à la spécialité d'aucun professeur.
-- @difficulty 2
-- @tags différence, imbrication, not-exists, jointure-externe, null
PROMPT "Q19 - V1";

SELECT DISTINCT libelle
FROM Module
WHERE code NOT IN (
    SELECT specProf
    FROM Professeur
    WHERE specProf IS NOT NULL
);

-- @remark Il faut spécifier la condition NOT NULL, car le prédicat « NOT IN » est évalué à « inconnu » quand l'ensemble retourné par la sous-requête comporte une valeur nulle.

-- Version alternative.
PROMPT "Q19 - V2";

SELECT DISTINCT libelle
FROM Module M
WHERE NOT EXISTS (
    SELECT *
    FROM Professeur
    WHERE specProf = M.code -- noqa: RF03
);

-- Version alternative.
PROMPT "Q19 - V3";

SELECT DISTINCT libelle
FROM Module
    LEFT OUTER JOIN Professeur ON code = specProf
WHERE specProf IS NULL;

-- @section Test d'absence de données
-- @instruction Formulez les requêtes suivantes de trois manières différentes, sans utiliser d'opérateur ensembliste.

-- Q20 - c:3, t:27
-- Donnez les numéros, noms et prénoms des étudiants n'ayant aucune note.
-- @difficulty 2
-- @tags différence, imbrication, not-exists, jointure-externe
PROMPT "Q20 - V1";

SELECT numEt, nomEt, prenomEt
FROM Etudiant
WHERE numEt NOT IN (
    SELECT numEt
    FROM Note
);

-- Version alternative.
PROMPT "Q20 - V2";

SELECT numEt, nomEt, prenomEt
FROM Etudiant
WHERE numEt <> ALL(
    SELECT numEt
    FROM Note
);

-- Version alternative.
PROMPT "Q20 - V3";

SELECT numEt, nomEt, prenomEt
FROM Etudiant E
WHERE NOT EXISTS (
    SELECT *
    FROM Note N
    WHERE N.numEt = E.numEt -- noqa: RF03
);

-- Version alternative.
PROMPT "Q20 - V4";

SELECT Et.numEt, nomEt, prenomEt
FROM Etudiant Et
    LEFT OUTER JOIN Note N ON Et.numEt = N.numEt
WHERE N.numEt IS NULL;

-- Q21 - c:2, t:41
-- Quels sont les noms et prénoms des étudiants n'ayant eu aucun enseignement de Marc Laporte ?
-- @difficulty 3
-- @tags jointure, différence, imbrication, not-exists, jointure-externe
PROMPT "Q21 - V1";

SELECT nomEt, prenomEt
FROM Etudiant
WHERE numEt NOT IN (
    SELECT numEt
    FROM Enseigne E
        INNER JOIN Professeur P ON E.numProf = P.numProf
    WHERE
        nomProf = 'LAPORTE'
        AND prenomProf = 'MARC'
);

-- Version alternative.
PROMPT "Q21 - V2";

SELECT nomEt, prenomEt
FROM Etudiant
WHERE numEt <> ALL(
    SELECT numEt
    FROM Enseigne E
        INNER JOIN Professeur P ON E.numProf = P.numProf
    WHERE
        nomProf = 'LAPORTE'
        AND prenomProf = 'MARC'
);

-- Version alternative.
PROMPT "Q21 - V3";

SELECT nomEt, prenomEt
FROM Etudiant Et
WHERE NOT EXISTS (
    SELECT *
    FROM Enseigne E
        INNER JOIN Professeur P ON E.numProf = P.numProf
    WHERE
        E.numEt = Et.numEt
        AND nomProf = 'LAPORTE'
        AND prenomProf = 'MARC'
);

-- Version alternative.
PROMPT "Q21 - V4";

SELECT nomEt, prenomEt
FROM Etudiant Et
    LEFT OUTER JOIN (
        SELECT numEt
        FROM Enseigne E
            INNER JOIN Professeur P ON E.numProf = P.numProf
        WHERE
            nomProf = 'LAPORTE'
            AND prenomProf = 'MARC'
    ) T
        ON Et.numEt = T.numEt
WHERE T.numEt IS NULL;

-- Q22 - c:2, t:8
-- Quels sont les noms et prénoms des professeurs n'étant pas responsables de modules ?
-- @difficulty 2
-- @tags différence, imbrication, not-exists, jointure-externe, null
PROMPT "Q22 - V1";

SELECT nomProf, prenomProf
FROM Professeur
WHERE numProf NOT IN (
    SELECT resp
    FROM Module
    WHERE resp IS NOT NULL
);

-- Version alternative.
PROMPT "Q22 - V2";

SELECT nomProf, prenomProf
FROM Professeur
WHERE numProf <> ALL(
    SELECT resp
    FROM Module
    WHERE resp IS NOT NULL
);

-- @remark Dans les deux versions précédente de la requête, la condition de sélection « resp IS NOT NULL » est nécessaire. Sans elle, l’attribut resp ayant des valeurs nulles, le résultat de la sous-requête est évalué à « inconnu » et la requête ne rend aucun tuple.

-- Version alternative.
PROMPT "Q22 - V3";

SELECT nomProf, prenomProf
FROM Professeur P
WHERE NOT EXISTS (
    SELECT *
    FROM Module M
    WHERE M.resp = P.numProf -- noqa: RF03
);

-- Version alternative.
PROMPT "Q22 - V4";

SELECT nomProf, prenomProf
FROM Professeur
    LEFT OUTER JOIN Module ON numProf = resp
WHERE resp IS NULL;

-- @section Expression des partitionnements

-- Q23 - c:2, t:5
-- Donnez, par groupe de seconde année, le nombre d'étudiants.
-- @difficulty 1
-- @tags groupement, agrégation, sélection
PROMPT "Q23";

SELECT groupeEt, COUNT(*) AS nbEtudiants
FROM Etudiant
WHERE anneeEt = 2
GROUP BY groupeEt;

-- Q24 - c:2, t:29
-- Donnez, pour chaque numéro d'étudiant, la meilleure note de test.
-- @difficulty 1
-- @tags groupement, agrégation
PROMPT "Q24";

SELECT numEt, MAX(moyTest) AS maxMoyTest
FROM Note
GROUP BY numEt;

-- Q25 - c:4, t:71
-- Donnez, pour chaque numéro et nom des étudiants de seconde année ainsi que pour chaque code de module, le nombre de professeurs.
-- @difficulty 2
-- @tags jointure, groupement, agrégation, sélection
PROMPT "Q25";

SELECT Et.numEt, nomEt, code, COUNT(numProf) AS nbProfs
FROM Etudiant Et
    INNER JOIN Enseigne E ON Et.numEt = E.numEt
WHERE anneeEt = 2
GROUP BY Et.numEt, nomEt, code;

-- @remark La projection de l'attribut clef primaire numEt assure que des fragments différents sont créées par le partitionnement même en cas d'homonymie des étudiants. il est aussi inutile de préciser DISTINCT avant l'argument de la fonction COUNT. En effet, par définition de la relation Enseigne, pour une matière et un étudiant donnés, un numéro de professeur n'apparaît qu'une seule fois.

-- Q26 - c:2, t:2
-- Donnez, pour chaque ville de plus de cinq professeurs, le nombre de professeurs y résidant.
-- @difficulty 2
-- @tags groupement, agrégation
PROMPT "Q26";

SELECT villeProf, COUNT(*) AS nbProfs
FROM Professeur
GROUP BY villeProf
HAVING COUNT(*) > 5;
