-- V1.0.0

-- @title Requêtes avec SQL
-- @intro Formulez, en SQL, sur la base de données exemple, les requêtes d'interrogation suivantes.

-- @section Expression des partitionnements

-- Q1 - c:4, t:12
-- Quel est, pour chacun des numéros et noms des professeurs, et pour chacune des années, le nombre d'étudiants auxquels il a enseigné ?
-- @difficulty 2
-- @tags jointure, groupement, calcul-vertical, distinct
PROMPT "Q1";

SELECT P.numProf, nomProf, anneeEt, COUNT(DISTINCT Et.numEt) AS nbEtudiants
FROM Enseigne E
    INNER JOIN Professeur P ON E.numProf = P.numProf
    INNER JOIN Etudiant Et ON E.numEt = Et.numEt
GROUP BY P.numProf, nomProf, anneeEt;

-- Q2 - c:3, t:5
-- Quel est, pour chacun des numéros et noms des professeurs responsable d'un module, le nombre de modules dans lesquels il fait cours ? Formulez les requêtes suivantes en utilisant, si possible, les trois formes de jointure.
-- @difficulty 2
-- @tags jointure, imbrication, semi-jointure, groupement, calcul-vertical, distinct

-- Version algébrique.
PROMPT "Q2 - Version algébrique";

SELECT P.numProf, nomProf, COUNT(DISTINCT E.code) AS nbModules
FROM Enseigne E
    INNER JOIN Professeur P ON E.numProf = P.numProf
    INNER JOIN MODULE M ON P.numProf = M.resp
GROUP BY P.numProf, nomProf;

-- Version imbriquée.
PROMPT "Q2 - Version imbriquée";

SELECT P.numProf, nomProf, COUNT(DISTINCT code) AS nbModules
FROM Enseigne E
    INNER JOIN Professeur P ON E.numProf = P.numProf
WHERE
    P.numProf IN (
        SELECT resp
        FROM MODULE
    )
GROUP BY P.numProf, nomProf;

-- Version prédicative.
PROMPT "Q2 - Version prédicative";

SELECT P.numProf, nomProf, COUNT(DISTINCT E.code) AS nbModules
FROM Enseigne E, Professeur P, MODULE M
WHERE
    E.numProf = P.numProf
    AND P.numProf = M.resp
GROUP BY P.numProf, nomProf;

-- Q3 - c:2, t:5
-- Donnez la moyenne des moyennes de test par groupe d'étudiants de seconde année pour le module de libellé Conception de SI.
-- @difficulty 2
-- @tags jointure, groupement, calcul-vertical, sélection
PROMPT "Q3";

SELECT groupeEt, AVG(moyTest) AS moyMoyTest
FROM Note N
    INNER JOIN Etudiant Et ON N.numEt = Et.numEt
    INNER JOIN MODULE M ON N.code = M.code
WHERE
    libelle = 'CONCEPTION DE SI'
    AND anneeEt = 2
GROUP BY groupeEt;

-- @section Calculs complexes

-- Q4 - c:3, t:4
-- Quels sont les numéros, noms et prénoms des enseignants ayant autant de modules que Bernard Faure ?
-- @difficulty 3
-- @tags jointure, groupement, calcul-vertical, imbrication, sous-requête, cte
PROMPT "Q4 - V1";

WITH
    NbModuleParProf (numProf, nomProf, prenomProf, nbCode) AS (
        SELECT E.numProf, nomProf, prenomProf, COUNT(DISTINCT code)
        FROM Enseigne E
            INNER JOIN Professeur P ON E.numProf = P.numProf
        GROUP BY E.numProf, nomProf, prenomProf
    )

SELECT DISTINCT numProf, nomProf, prenomProf
FROM NbModuleParProf
WHERE
    (nomProf <> 'FAURE' OR prenomProf <> 'BERNARD')
    AND nbCode IN (
        SELECT nbCode
        FROM NbModuleParProf
        WHERE
            nomProf = 'FAURE'
            AND prenomProf = 'BERNARD'
    );

-- Version alternative.
PROMPT "Q4 - V2";

WITH
    EnseignementParProf (numProf, nomProf, prenomProf, code) AS (
        SELECT E.numProf, nomProf, prenomProf, code
        FROM Enseigne E
            INNER JOIN Professeur P ON E.numProf = P.numProf
    )

SELECT numProf, nomProf, prenomProf
FROM EnseignementParProf
WHERE
    nomProf <> 'FAURE'
    OR prenomProf <> 'BERNARD'
GROUP BY numProf, nomProf, prenomProf
HAVING COUNT(DISTINCT code) = (
    SELECT COUNT(DISTINCT code)
    FROM EnseignementParProf
    WHERE
        nomProf = 'FAURE'
        AND prenomProf = 'BERNARD'
);

-- Q5 - c:1, t:1 (9)
-- Donnez le nombre moyen d'étudiants des groupes de seconde année.
-- @difficulty 2
-- @tags groupement, calcul-vertical, sélection, sous-requête, cte
PROMPT "Q5 - V1";

WITH
    EffectifParGroupe (groupeEt, nbEtudiant) AS (
        SELECT groupeEt, COUNT(*)
        FROM Etudiant
        WHERE anneeEt = 2
        GROUP BY groupeEt
    )

SELECT AVG(nbEtudiant)
FROM EffectifParGroupe;

-- Version alternative (sous-requête dans le FROM).
PROMPT "Q5 - V2";

SELECT AVG(nbEtudiant)
FROM (
    SELECT groupeEt, COUNT(*) AS nbEtudiant
    FROM Etudiant
    WHERE anneeEt = 2
    GROUP BY groupeEt
);

PROMPT "Q5 - V3";

SELECT COUNT(numEt) / COUNT(DISTINCT groupeEt)
FROM Etudiant
WHERE anneeEt = 2;

-- Q6 - c:1, t:1 (45)
-- Quel est le plus grand nombre d'étudiants à qui un professeur enseigne ?
-- @difficulty 2
-- @tags groupement, calcul-vertical, sous-requête, distinct, cte
PROMPT "Q6 - V1";

WITH
    NbEtudiantParProf (numProf, nbEtudiant) AS (
        SELECT numProf, COUNT(DISTINCT numEt)
        FROM Enseigne
        GROUP BY numProf
    )

SELECT MAX(nbEtudiant)
FROM NbEtudiantParProf;

-- Version alternative (sous-requête dans le FROM).
PROMPT "Q6 - V2";

SELECT MAX(nbEtudiant)
FROM (
    SELECT numProf, COUNT(DISTINCT numEt) AS nbEtudiant
    FROM Enseigne
    GROUP BY numProf
);

-- Q7 - c:3, t:9
-- Donnez les codes et libellés des modules, et lorsqu'il existe, le pourcentage de la somme d'heures de cours par rapport au total des heures de cours dans la discipline correspondante.
-- @difficulty 3
-- @tags jointure, groupement, calcul-vertical, sous-requête, null, cte
PROMPT "Q7 - V1";

WITH
    TotalHParDiscipline (total, discipline) AS (
        SELECT SUM(heureCMPrev), discipline
        FROM MODULE
        GROUP BY discipline
    )

SELECT code, libelle, heureCMPrev / total AS pourcentageDiscipline
FROM MODULE
    INNER JOIN TotalHParDiscipline ON MODULE.discipline = TotalHParDiscipline.discipline
WHERE
    heureCMPrev IS NOT NULL
    AND total IS NOT NULL;

-- Version alternative (sous-requête dans le FROM).
PROMPT "Q7 - V2";

SELECT code, libelle, heureCMPrev / total AS pourcentageDiscipline
FROM MODULE
    INNER JOIN (
        SELECT SUM(heureCMPrev) AS total, discipline
        FROM MODULE
        GROUP BY discipline
    ) NbH
        ON MODULE.discipline = NbH.discipline
WHERE
    heureCMPrev IS NOT NULL
    AND total IS NOT NULL;

-- @section Expression des recherches récursives

-- Q8 - c:3, t:6
-- Donnez, pour chaque code de module, le nombre de professeurs qui les enseignent et la moyenne de test maximale.
-- @difficulty 2
-- @tags jointure, groupement, calcul-vertical, sous-requête, distinct, cte
PROMPT "Q8 - V1";

WITH
    NbProfParModule (code, nbProf) AS (
        SELECT code, COUNT(DISTINCT numProf)
        FROM Enseigne
        GROUP BY code
    )

    , MoyMaxParModule (code, moyMax) AS (
        SELECT code, MAX(moyTest)
        FROM Note
        GROUP BY code
    )

SELECT NbProfParModule.code, nbProf, moyMax
FROM NbProfParModule
    INNER JOIN MoyMaxParModule ON NbProfParModule.code = MoyMaxParModule.code;

-- Version alternative (sous-requêtes dans le FROM).
PROMPT "Q8 - V2";

SELECT E.code, NB_Prof, moy_max
FROM (
    SELECT code, COUNT(DISTINCT numProf) AS NB_Prof
    FROM Enseigne
    GROUP BY code
) E
    INNER JOIN (
        SELECT code, MAX(moyTest) AS moy_max
        FROM Note
        GROUP BY code
    ) N
        ON E.code = N.code;

PROMPT "Q8 - V3";

SELECT E.code, COUNT(DISTINCT numProf) AS nbProfs, MAX(moyTest) AS maxMoyTest
FROM Enseigne E
    INNER JOIN Note N ON E.code = N.code
GROUP BY E.code;

-- Q9 - c:2, t:1
-- Quels sont les codes et libellés des racines des hiérarchies des modules ?
-- @difficulty 1
-- @tags sélection, null, récursion
PROMPT "Q9";

SELECT code, libelle
FROM MODULE
WHERE codePere IS NULL;

-- Q10 - c:1, t:16
-- Présenter, de manière hiérarchique, les libellés de tous les sous-modules du module Informatique 2de année.
-- @difficulty 2
-- @tags récursion
PROMPT "Q10";

SELECT LPAD('-', 2 * LEVEL, '-') || libelle
FROM MODULE
WHERE libelle <> 'INFORMATIQUE 2DE ANNEE'
START WITH libelle = 'INFORMATIQUE 2DE ANNEE'
CONNECT BY codePere = PRIOR code;

-- Version CTE récursive.
PROMPT "Q10 - Version CTE récursive";

WITH RECURSIVE
    DescModule (code, libelle, lvl) AS (
        SELECT code, libelle, 1
        FROM MODULE
        WHERE libelle = 'INFORMATIQUE 2DE ANNEE'
        UNION ALL
        SELECT M.code, M.libelle, D.lvl + 1
        FROM MODULE M
            INNER JOIN DescModule D ON M.codePere = D.code
    )

SELECT LPAD('-', 2 * lvl, '-') || libelle
FROM DescModule
WHERE libelle <> 'INFORMATIQUE 2DE ANNEE';

-- Q11 - c:1, t:7
-- Présenter, de manière hiérarchique, les libellés du module Outils modèles génie logiciel et de tous ses sous-modules.
-- @difficulty 2
-- @tags récursion
PROMPT "Q11";

SELECT LPAD('-', 2 * LEVEL, '-') || libelle
FROM MODULE
START WITH libelle = 'OUTILS MODELES GENIE LOGICIEL'
CONNECT BY codePere = PRIOR code;

-- Version CTE récursive.
PROMPT "Q11 - Version CTE récursive";

WITH RECURSIVE
    DescModule (code, libelle, lvl) AS (
        SELECT code, libelle, 1
        FROM MODULE
        WHERE libelle = 'OUTILS MODELES GENIE LOGICIEL'
        UNION ALL
        SELECT M.code, M.libelle, D.lvl + 1
        FROM MODULE M
            INNER JOIN DescModule D ON M.codePere = D.code
    )

SELECT LPAD('-', 2 * lvl, '-') || libelle
FROM DescModule;

-- Q12 - c:1, t:5
-- Présenter, de manière hiérarchique, les libellés de tous les modules d'où est issu le module Bases de données.
-- @difficulty 2
-- @tags récursion, tri
PROMPT "Q12";

SELECT LPAD('-', 2 * (MAX(LEVEL) OVER () + 1 - LEVEL), '-') || libelle
FROM MODULE
START WITH libelle = 'BASES DE DONNEES'
CONNECT BY code = PRIOR codePere
ORDER BY LEVEL DESC;

-- Version CTE récursive.
PROMPT "Q12 - Version CTE récursive";

WITH RECURSIVE
    AncModule (code, libelle, codePere, lvl) AS (
        SELECT code, libelle, codePere, 1
        FROM MODULE
        WHERE libelle = 'BASES DE DONNEES'
        UNION ALL
        SELECT M.code, M.libelle, M.codePere, A.lvl + 1
        FROM MODULE M
            INNER JOIN AncModule A ON M.code = A.codePere
    )

SELECT LPAD('-', 2 * (MAX(lvl) OVER () + 1 - lvl), '-') || libelle
FROM AncModule
ORDER BY lvl DESC;

-- Q13 - c:1, t:13
-- Présenter, de manière hiérarchique, les libellés de tous les sous-modules de la discipline Informatique, subordonnés au module Informatique 2e année, à l'exception du module Bases de données.
-- @difficulty 3
-- @tags récursion, sélection
PROMPT "Q13";

SELECT LPAD('-', 2 * LEVEL, '-') || libelle
FROM MODULE
WHERE
    discipline = 'INFORMATIQUE'
    AND libelle NOT IN ('INFORMATIQUE 2DE ANNEE', 'BASES DE DONNEES')
START WITH libelle = 'INFORMATIQUE 2DE ANNEE'
CONNECT BY codePere = PRIOR code;

-- Version CTE récursive.
PROMPT "Q13 - Version CTE récursive";

WITH RECURSIVE
    DescModule (code, libelle, discipline, lvl) AS (
        SELECT code, libelle, discipline, 1
        FROM MODULE
        WHERE libelle = 'INFORMATIQUE 2DE ANNEE'
        UNION ALL
        SELECT M.code, M.libelle, M.discipline, D.lvl + 1
        FROM MODULE M
            INNER JOIN DescModule D ON M.codePere = D.code
    )

SELECT LPAD('-', 2 * lvl, '-') || libelle
FROM DescModule
WHERE
    discipline = 'INFORMATIQUE'
    AND libelle NOT IN ('INFORMATIQUE 2DE ANNEE', 'BASES DE DONNEES');

-- @section Expression des divisions

-- @instruction Quand cela possible, formulez les requêtes suivantes de deux manières différentes.

-- Q14 - c:2, t:1
-- Quels sont les noms et prénoms des professeurs ayant enseigné à tous les étudiants de seconde année ?
-- @difficulty 3
-- @tags division, not-exists, jointure, groupement, calcul-vertical
PROMPT "Q14 - Version double NOT EXISTS";

SELECT nomProf, prenomProf
FROM Professeur P
WHERE NOT EXISTS (
    SELECT *
    FROM Etudiant Et
    WHERE
        anneeEt = 2
        AND NOT EXISTS (
            SELECT *
            FROM Enseigne E
            WHERE
                P.numProf = E.numProf -- noqa: RF03
                AND Et.numEt = E.numEt
        )
);

-- @remark Cette requête correspond au paraphrasage "Quels sont les noms et prénoms des Professeurs tels qu'il n'existe aucun étudiant de seconde année auquel ces Professeurs n'aient pas enseigné ?"

PROMPT "Q14 - Version HAVING";

SELECT nomProf, prenomProf
FROM Professeur P
    INNER JOIN Enseigne E ON P.numProf = E.numProf
    INNER JOIN Etudiant Et ON E.numEt = Et.numEt
WHERE anneeEt = 2
GROUP BY nomProf, prenomProf
HAVING COUNT(DISTINCT Et.numEt) = (
    SELECT COUNT(*)
    FROM Etudiant
    WHERE anneeEt = 2
);

-- @remark Cette requête correspond au paraphrasage "Quels sont les noms et prénoms des Professeurs qui ont enseigné à autant d'étudiants de seconde année qu'il en existe ?"

-- Q15 - c:2, t:11
-- Quels sont les noms et prénoms des étudiants dont tous les professeurs ont aussi donné cours à l'étudiant numéro 1102 ?
-- @difficulty 3
-- @tags division, not-exists, jointure
PROMPT "Q15 - Version double NOT EXISTS";

SELECT nomEt, prenomEt
FROM Etudiant Et
WHERE NOT EXISTS (
    SELECT *
    FROM Enseigne E
    WHERE
        numEt = 1102
        AND NOT EXISTS (
            SELECT *
            FROM Enseigne E2
            WHERE
                Et.numEt = E2.numEt -- noqa: RF03
                AND E.numProf = E2.numProf
        )
);

-- @remark Cette requête correspond au paraphrasage "Quels sont les noms et prénoms des étudiants tels qu'il n'existe aucun Professeur ayant eu l'étudiant numéro 1102 qui ne les ait pas eu aussi ?"

-- @remark Il est impossible de répondre à cette requête avec la version HAVING car il ne suffit pas que les étudiants aient eu le même nombre de Professeurs que l'étudiant numéro 1102, il faut que ces Professeurs soient les mêmes.

-- Q16 - c:3, t:3
-- Quels sont les numéros, noms et prénoms des étudiants ayant eu, pour le module Conception de SI, tous les Professeurs enseignant ce module ?
-- @difficulty 3
-- @tags division, not-exists, jointure, groupement, calcul-vertical
PROMPT "Q16 - Version double NOT EXISTS";

SELECT numEt, nomEt, prenomEt
FROM Etudiant Et
WHERE NOT EXISTS (
    SELECT *
    FROM Enseigne E
        INNER JOIN MODULE M ON E.code = M.code
    WHERE
        libelle = 'CONCEPTION DE SI'
        AND NOT EXISTS (
            SELECT *
            FROM Enseigne E2
            WHERE
                Et.numEt = E2.numEt -- noqa: RF03
                AND E.code = E2.code
                AND E.numProf = E2.numProf
        )
);

-- @remark Cette requête correspond au paraphrasage "Quels sont les numéros, étudiants tels qu'il n'existe aucun Professeur enseignant le module Conception de SI qui ne leur ait pas enseigné ce module ?"

PROMPT "Q16 - Version HAVING";

WITH
    EnseignementParModule (numProf, numEt, libelle) AS (
        SELECT numProf, numEt, libelle
        FROM Enseigne E
            INNER JOIN MODULE M ON E.code = M.code
    )

SELECT Et.numEt, nomEt, prenomEt
FROM EnseignementParModule
    INNER JOIN Etudiant Et ON EnseignementParModule.numEt = Et.numEt
WHERE libelle = 'CONCEPTION DE SI'
GROUP BY Et.numEt, nomEt, prenomEt
HAVING COUNT(DISTINCT numProf) = (
    SELECT COUNT(DISTINCT numProf)
    FROM EnseignementParModule
    WHERE libelle = 'CONCEPTION DE SI'
);

-- @remark Cette requête correspond au paraphrasage "Quels sont les numéros, noms et prénoms des étudiants dont le nombre de Professeurs en Conception de SI est égal au nombre total de Professeurs enseignant ce module ?"

-- Q17 - c:2, t:1
-- Quels sont les codes et libellés des modules suivis par tous les étudiants du groupe d'étudiants 2 de seconde année ?
-- @difficulty 3
-- @tags division, not-exists, jointure, groupement, calcul-vertical
PROMPT "Q17 - Version double NOT EXISTS";

SELECT code, libelle
FROM MODULE M
WHERE NOT EXISTS (
    SELECT *
    FROM Etudiant Et
    WHERE
        anneeEt = 2
        AND groupeEt = 2
        AND NOT EXISTS (
            SELECT *
            FROM Enseigne E
            WHERE
                M.code = E.code -- noqa: RF03
                AND Et.numEt = E.numEt
        )
);

-- @remark Cette requête correspond au paraphrasage "Quelles sont les modules tels qu'il n'existe aucun étudiant du groupeEt 2 de seconde année qui ne les suit pas ?"

PROMPT "Q17 - Version HAVING";

SELECT M.code, libelle
FROM Etudiant Et
    INNER JOIN Enseigne E ON Et.numEt = E.numEt
    INNER JOIN MODULE M ON E.code = M.code
WHERE
    anneeEt = 2
    AND groupeEt = 2
GROUP BY M.code, libelle
HAVING COUNT(DISTINCT Et.numEt) = (
    SELECT COUNT(numEt)
    FROM Etudiant
    WHERE
        anneeEt = 2
        AND groupeEt = 2
);

-- @remark Cette requête correspond au paraphrasage "Quelles sont les modules suivis par autant d'étudiants du groupeEt 2 de seconde année qu'il en existe ?"

-- @section Requêtes complexes

-- Q18 - c:1, t:13
-- Présenter, de manière hiérarchique, les libellés de tous les sous-modules de la discipline Informatique subordonnés au module Informatique 2de année à l'exception du module Codage et circuits et de tous ses éventuels sous-modules.
-- @difficulty 3
-- @tags récursion, sélection
PROMPT "Q18";

SELECT LPAD('-', 2 * LEVEL, '-') || libelle
FROM MODULE
WHERE discipline = 'INFORMATIQUE'
START WITH libelle = 'INFORMATIQUE 2DE ANNEE'
CONNECT BY codePere = PRIOR code
AND libelle <> 'CODAGE ET CIRCUITS';

-- Version CTE récursive.
PROMPT "Q18 - Version CTE récursive";

WITH RECURSIVE
    DescModule (code, libelle, discipline, lvl) AS (
        SELECT code, libelle, discipline, 1
        FROM MODULE
        WHERE libelle = 'INFORMATIQUE 2DE ANNEE'
        UNION ALL
        SELECT M.code, M.libelle, M.discipline, D.lvl + 1
        FROM MODULE M
            INNER JOIN DescModule D ON M.codePere = D.code
        WHERE M.libelle <> 'CODAGE ET CIRCUITS'
    )

SELECT LPAD('-', 2 * lvl, '-') || libelle
FROM DescModule
WHERE discipline = 'INFORMATIQUE';

-- Q19 - c:1, t:24
-- Présenter, de manière hiérarchique, les modules suivis par l'étudiant Jérôme Atlani ?
-- @difficulty 3
-- @tags récursion, jointure, imbrication, semi-jointure
PROMPT "Q19";

SELECT LPAD('-', 2 * (MAX(LEVEL) OVER () + 1 - LEVEL), '-') || libelle
FROM MODULE
START WITH code IN (
    SELECT code
    FROM Enseigne E
        INNER JOIN Etudiant Et ON E.numEt = Et.numEt
    WHERE
        nomEt = 'ATLANI'
        AND prenomEt = 'JEROME'
)
CONNECT BY code = PRIOR codePere;

-- Version CTE récursive.
PROMPT "Q19 - Version CTE récursive";

WITH RECURSIVE
    AncModule (code, libelle, codePere, lvl) AS (
        SELECT M.code, M.libelle, M.codePere, 1
        FROM MODULE M
        WHERE
            M.code IN (
                SELECT E.code
                FROM Enseigne E
                    INNER JOIN Etudiant Et ON E.numEt = Et.numEt
                WHERE
                    nomEt = 'ATLANI'
                    AND prenomEt = 'JEROME'
            )
        UNION ALL
        SELECT M.code, M.libelle, M.codePere, A.lvl + 1
        FROM MODULE M
            INNER JOIN AncModule A ON M.code = A.codePere
    )

SELECT LPAD('-', 2 * (MAX(lvl) OVER () + 1 - lvl), '-') || libelle
FROM AncModule;

-- @remark Il n'existe pas de manière simple pour présenter, de manière hiérarchique, chacune des arborescences. L'utilisation de la clause ORDER BY aurait pour effet de les mélanger, pas de les trier comme souhaité.

-- Q20 - c:3, t:23
-- Quels sont les numéros, noms et prénoms des étudiants de seconde année dont toutes les moyennes de test sont supérieures ou égales à 10 ?
-- @difficulty 3
-- @tags jointure, groupement, calcul-vertical, sélection
PROMPT "Q20 - V1";

SELECT Et.numEt, nomEt, prenomEt
FROM Note N
    INNER JOIN Etudiant Et ON N.numEt = Et.numEt
WHERE
    anneeEt = 2
    AND moyTest >= 10
GROUP BY Et.numEt, nomEt, prenomEt
HAVING COUNT(moyTest) = (
    SELECT COUNT(moyTest) -- noqa: RF03
    FROM Note N2
    WHERE Et.numEt = N2.numEt -- noqa: RF03
);

-- Version alternative.
PROMPT "Q20 - V2";

SELECT Et.numEt, nomEt, prenomEt
FROM Note N
    INNER JOIN Etudiant Et ON N.numEt = Et.numEt
WHERE anneeEt = 2
GROUP BY Et.numEt, nomEt, prenomEt
HAVING MIN(moyTest) >= 10;

-- Q21 - c:3, t:19
-- Quels sont les numéros, noms et prénoms des étudiants ayant des moyennes dans un module subordonnés au module Principes des BD ?
-- @difficulty 2
-- @tags jointure, imbrication, semi-jointure, récursion, distinct
PROMPT "Q21";

SELECT DISTINCT Et.numEt, nomEt, prenomEt
FROM Etudiant Et
    INNER JOIN Note N ON Et.numEt = N.numEt
WHERE code IN (
    SELECT code
    FROM MODULE
    START WITH libelle = 'PRINCIPES DES BD'
    CONNECT BY codePere = PRIOR code
);

-- Version CTE récursive.
PROMPT "Q21 - Version CTE récursive";

WITH RECURSIVE
    DescModule (code) AS (
        SELECT code
        FROM MODULE
        WHERE libelle = 'PRINCIPES DES BD'
        UNION ALL
        SELECT M.code
        FROM MODULE M
            INNER JOIN DescModule D ON M.codePere = D.code
    )

SELECT DISTINCT Et.numEt, nomEt, prenomEt
FROM Etudiant Et
    INNER JOIN Note N ON Et.numEt = N.numEt
WHERE code IN (SELECT code FROM DescModule);

-- Q22 - c:3, t:29
-- Donnez les numéros des étudiants, les écarts entre leurs éventuelles moyennes de test et la moins bonne moyenne de test du module ACSI ainsi que les écarts entre leurs éventuelles moyennes de test et la meilleure moyenne de test du module ACSI.
-- @difficulty 3
-- @tags calcul-vertical, imbrication, sous-requête, sélection

PROMPT "Q22 - V1";

WITH
    ExtremumACSI (moyMin, moyMax) AS (
        SELECT MIN(moyTest), MAX(moyTest)
        FROM Note
        WHERE code = 'ACSI'
    )

    , NoteACSI (numEt, moyTest) AS (
        SELECT numEt, moyTest
        FROM Note
        WHERE code = 'ACSI'
    )

SELECT numEt, moyTest - moyMin AS ecartMin, moyTest - moyMax AS ecartMax
FROM ExtremumACSI, NoteACSI;

PROMPT "Q22 - V2";

SELECT numEt, moyTest - moyMin AS ecartMin, moyTest - moyMax AS ecartMax
FROM Note, (
    SELECT MIN(moyTest) AS moyMin, MAX(moyTest) AS moyMax
    FROM Note
    WHERE code = 'ACSI'
) T
WHERE code = 'ACSI';

-- Version alternative.
PROMPT "Q22 - V3";

SELECT
    numEt
    , moyTest - (
        SELECT MIN(moyTest)
        FROM Note
        WHERE code = 'ACSI'
    ) AS moyMin
    , moyTest - (
        SELECT MAX(moyTest)
        FROM Note
        WHERE code = 'ACSI'
    ) AS moyMax
FROM Note
WHERE code = 'ACSI';
