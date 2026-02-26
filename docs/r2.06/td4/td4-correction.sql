-- V1.1.0

-- @title Requêtes avec SQL
-- @intro Formulez, en SQL, sur la base de données exemple, les requêtes d'interrogation suivantes.

-- @section Expression des recherches récursives

-- Q1 - c:2, t:2
-- Donnez les identifiants et libellés des racines des hiérarchies des thèmes.
PROMPT "Q1";

SELECT idT, libelle
FROM Theme
WHERE idTPere IS NULL;

-- Q2 - c:2, t:16
-- Donnez les identifiants et libellés des feuilles de la hiérarchie des thèmes.
PROMPT "Q2";

SELECT idT, libelle
FROM Theme
WHERE idT NOT IN (
    SELECT idTPere
    FROM Theme
    WHERE idTPere IS NOT NULL
);

-- Q3 - c:2, t:17
-- Donnez les identifiants et libellés de la hiérarchie des fils du thème Langage de requêtes.
PROMPT "Q3";

SELECT idT, libelle
FROM Theme
START WITH libelle = 'LANGAGE DE REQUETES'
CONNECT BY idTPere = PRIOR idT;

-- Q4 - c:2, t:5
-- Donnez les identifiants et libellés des thèmes subordonnés directement ou pas (l' ensemble des themes plus spécifiques) au thème Jointure à l’exception du sous-thème Jointure imbriquée. 
PROMPT "Q4";

SELECT idT, libelle
FROM Theme
WHERE libelle <> 'JOINTURE IMBRIQUEE'
START WITH libelle = 'JOINTURE'
CONNECT BY idTPere = PRIOR idT;

-- Q5 - c:2, t:4
-- Donnez les identifiants et libellés des thèmes subordonnés directement ou pas au thème Jointure à l'exception du thème Jointure imbriquée et de ses sous-thèmes.
PROMPT "Q5";

SELECT idT, libelle
FROM Theme
START WITH libelle = 'JOINTURE'
CONNECT BY
    idTPere = PRIOR idT
    AND libelle <> 'JOINTURE IMBRIQUEE';

-- Q6 - c:2, t:4
-- Donnez les identifiants et libellés généralisant strictement le thème Jointure externe en triant du thème le plus général au thème le plus spécifique.
PROMPT "Q6";

SELECT idT, libelle
FROM Theme
WHERE libelle <> 'JOINTURE EXTERNE'
START WITH libelle = 'JOINTURE EXTERNE'
CONNECT BY idT = PRIOR idTPere
ORDER BY LEVEL DESC;

-- Q7 - c:2, t:28
-- Quels sont les identifiants des questions et numéros de TP se rapportant à un thème subordonné directement ou indirectement au thème Jointure ?
PROMPT "Q7 - V1";

SELECT DISTINCT Q.idQ, Q.numTP
FROM Question Q
    INNER JOIN Traite TQ
        ON
            Q.idQ = TQ.idQ
            AND idT IN (
                SELECT idT
                FROM Theme
                START WITH libelle = 'JOINTURE'
                CONNECT BY idTPere = PRIOR idT
            );

-- Version alternative.
PROMPT "Q7 - V2";

SELECT idQ, numTP
FROM Question
WHERE idQ IN (
    SELECT idQ
    FROM Traite
    WHERE idT IN (
        SELECT idT
        FROM Theme
        START WITH libelle = 'JOINTURE'
        CONNECT BY idTPere = PRIOR idT
    )
);

-- Q8 - c:2, t:5
-- Quels sont les identifiants et libellés des thèmes généralisant les thèmes Jointure ou Sélection simple ?
PROMPT "Q8 - V1";

SELECT DISTINCT idT, libelle
FROM Theme
START WITH libelle IN ('JOINTURE', 'SELECTION SIMPLE')
CONNECT BY idT = PRIOR idTPere;

-- Version alternative.
PROMPT "Q8 - V2";

SELECT idT, libelle
FROM Theme
START WITH libelle IN ('JOINTURE')
CONNECT BY idT = PRIOR idTPere
UNION
SELECT idT, libelle
FROM Theme
START WITH libelle IN ('SELECTION SIMPLE')
CONNECT BY idT = PRIOR idTPere;

-- Q9 - c:2, t:3
-- Quels sont les identifiants et libellés des thèmes généralisant les thèmes Jointure et Sélection simple ?
PROMPT "Q9 - V1";

SELECT idT, libelle
FROM Theme
START WITH libelle = 'JOINTURE'
CONNECT BY idT = PRIOR idTPere
INTERSECT
SELECT idT, libelle
FROM Theme
START WITH libelle = 'SELECTION SIMPLE'
CONNECT BY idT = PRIOR idTPere;

-- Version alternative.
PROMPT "Q9 - V2";

SELECT idT, libelle
FROM Theme
WHERE idT IN (
    SELECT idT
    FROM Theme
    START WITH libelle = 'SELECTION SIMPLE'
    CONNECT BY idT = PRIOR idTPere
)
START WITH libelle = 'JOINTURE'
CONNECT BY idT = PRIOR idTPere;

-- Q10 - c:2, t:3
-- Quels sont les identifiants et libellés des thèmes subordonnés directement ou indirectement au thème SQL LDD et qui ne sont utilisés par aucune question ?
PROMPT "Q10 - V1";

SELECT idT, libelle
FROM Theme
WHERE idT NOT IN (
    SELECT idT 
    FROM Traite
)
START WITH libelle = 'SQL LDD'
CONNECT BY PRIOR idT = idTPere;

PROMPT "Q10 - V2";

SELECT idT, libelle
FROM Theme
START WITH libelle = 'SQL LDD'
CONNECT BY PRIOR idT = idTPere
EXCEPT
SELECT T.idT, libelle
FROM Theme T
    INNER JOIN Traite TQ 
        ON T.idT = TQ.idT;

PROMPT "Q10 - V3";

SELECT idT, libelle
FROM Theme
WHERE idT IN (
    SELECT idT
    FROM Theme
    START WITH libelle = 'SQL LDD'
    CONNECT BY PRIOR idT = idTPere
    EXCEPT
    SELECT idT
    FROM Traite
);

-- Q11 - c:2, t:10
-- Quels sont les identifiants et libellés des thèmes feuilles de la hiérarchie des thèmes qui sont subordonnés directement ou indirectement à la même racine que celle du thème Jointure.
PROMPT "Q11";

SELECT idT, libelle
FROM Theme
WHERE idT NOT IN (
    SELECT idTPere 
    FROM Theme 
    WHERE idTPere IS NOT NULL
)
START WITH idT = (
    SELECT idT
    FROM Theme
    WHERE idTPere IS NULL 
    CONNECT BY idT = PRIOR idTPere
    START WITH libelle = 'JOINTURE'
)
CONNECT BY PRIOR idT = idTPere;

-- Q12 - c:2, t:9
-- Quels sont les identifiants et libellés des thèmes se situant dans la branche, au-dessus ou en dessous, du thème Jointure ?
PROMPT "Q12";

SELECT idT, libelle
FROM Theme
START WITH libelle = 'JOINTURE'
CONNECT BY idT = PRIOR idTPere
UNION
SELECT idT, libelle
FROM Theme
START WITH libelle = 'JOINTURE'
CONNECT BY PRIOR idT = idTPere;

-- @section Expression des divisions

-- Q13 - c:3, t:4
-- Donnez les numéros, noms et prénoms des étudiants ayant fait toutes les questions du TP numéro 1. Proposer deux formulations différentes, avec double NOT EXISTS et HAVING, de cette requête.
PROMPT "Q13 - Version double NOT EXISTS";

SELECT numEt, nom, prenom
FROM Etudiant Et
WHERE NOT EXISTS (
    SELECT *
    FROM Question Q
    WHERE 
        numTP = 1
        AND NOT EXISTS (
            SELECT *
            FROM Evalue E
            WHERE
                Et.numEt = E.numEt
                AND Q.idQ = E.idQ
        )
);

-- Remarque : cette requête correspond au paraphrasage "Quels sont les numéros, noms et prénoms des étudiants ayant fait autant de questions du TP numéro 1 qu’il en existe ?"

PROMPT "Q13 - Version HAVING";

SELECT Et.numEt, nom, prenom
FROM Etudiant Et
    INNER JOIN Evalue E 
        ON Et.numEt = E.numEt
    INNER JOIN Question Q 
        ON E.idQ = Q.idQ
WHERE numTP = 1
GROUP BY Et.numEt, nom, prenom
HAVING COUNT(*) = (
    SELECT COUNT(*)
    FROM Question
    WHERE numTP = 1
);

-- Remarque : cette requête correspond au paraphrasage "Quels sont les numéros, noms et prénoms des étudiants tels qu’il n’existe aucune question du TP numéro 1 qu’ils n’aient pas faite ?"

-- Q14 - c:1, t:3
-- Quels sont les groupes d'étudiants dans lesquels tous les types de BAC sont représentés ? Proposer deux formulations différentes, avec double NOT EXISTS et HAVING, de cette requête. 
PROMPT "Q14 - Version double NOT EXISTS";

SELECT DISTINCT groupe
FROM Etudiant Et
WHERE NOT EXISTS (
    SELECT *
    FROM Etudiant Et2
    WHERE NOT EXISTS (
        SELECT *
        FROM Etudiant Et3
        WHERE 
            Et.groupe = Et3.groupe
            AND Et2.typeBAC = Et3.typeBAC
    )
);

-- Remarque : cette requête correspond au paraphrasage "Quels sont les groupes d'étudiants pour lesquels il n’existe pas de type de BAC qui ne soit pas représenté ?

PROMPT "Q14 - Version HAVING";

SELECT groupe
FROM Etudiant
GROUP BY groupe
HAVING COUNT(DISTINCT typeBAC) = (
    SELECT COUNT(DISTINCT typeBAC)
    FROM Etudiant
);

-- Remarque : cette requête correspond au paraphrasage "Quels sont les groupes d'étudiants ayant autant de Types de BAC qu’il en existe ?"

-- Q15 - c:1, t:2
-- Quels sont les groupes d'étudiants pour lesquels au moins un étudiant a été évalué pour chaque TP ?
PROMPT "Q15 - Version double NOT EXISTS";

SELECT DISTINCT groupe
FROM Etudiant Et
WHERE NOT EXISTS (
    SELECT *
    FROM Question Q
    WHERE NOT EXISTS (
        SELECT *
        FROM Evalue E
            INNER JOIN Etudiant Et2
                ON E.numEt = Et2.numEt
            INNER JOIN Question Q2
                ON E.idQ = Q2.idQ
        WHERE 
            Et.groupe = Et2.groupe
            AND Q.numTP = Q2.numTP
    )
);

-- Remarque : cette requête correspond au paraphrasage "Quels sont les groupes pour lesquels il y a autant de TP évalués qu’il en existe ?"

PROMPT "Q15 - Version HAVING";

SELECT groupe
FROM Etudiant Et
    INNER JOIN Evalue E 
        ON Et.numEt = E.numEt
    INNER JOIN Question Q 
        ON E.idQ = Q.idQ
GROUP BY groupe
HAVING COUNT(DISTINCT numTP) = (
    SELECT COUNT(DISTINCT numTP)
    FROM Question
);

-- Remarque : cette requête correspond au paraphrasage "Quels sont les groupes tels qu’il n’existe aucun TP pour lequel ils n’aient pas été évalué ?"

-- @section Requêtes complexes

-- Q16 - c:3, t:1
-- Donnez les numéros, noms et prénoms des étudiants ayant eu au moins un résultat faux au TP numéro 2 et au TP numéro 3. Proposer trois formulations différentes.
PROMPT "Q16 - V1";

SELECT DISTINCT Et.numEt, nom, prenom
FROM Etudiant Et
    INNER JOIN Evalue E 
        ON Et.numEt = E.numEt
    INNER JOIN Question Q 
        ON E.idQ = Q.idQ
    INNER JOIN Evalue E2 
        ON Et.numEt = E2.numEt
    INNER JOIN Question Q2 
        ON E2.idQ = Q2.idQ
WHERE 
    E.resultat = 'FAUX' 
    AND Q.numTP = 2 
    AND E2.resultat = 'FAUX' 
    AND Q2.numTP = 3;

-- Version alternative.
PROMPT "Q16 - V2";

SELECT DISTINCT Et.numEt, nom, prenom
FROM Etudiant Et
    INNER JOIN Evalue E 
        ON Et.numEt = E.numEt
    INNER JOIN Question Q
        ON E.idQ = Q.idQ
WHERE 
    resultat = 'FAUX'
    AND numTP = 2
    AND Et.numEt IN (
        SELECT Et.numEt
        FROM Etudiant Et
        INNER JOIN Evalue E 
            ON Et.numEt = E.numEt
        INNER JOIN Question Q 
            ON 
                E.idQ = Q.idQ
                AND E.idQ = Q.idQ
                AND resultat = 'FAUX'
                AND numTP = 3
);

-- Version alternative.
PROMPT "Q16 - V3";

SELECT numEt, nom, prenom
FROM Etudiant
WHERE numEt IN (
    SELECT numEt
    FROM Evalue E
        INNER JOIN Question Q 
            ON E.idQ = Q.idQ
    WHERE 
        resultat = 'FAUX'
        AND numTP = 2
    INTERSECT
    SELECT numEt
    FROM Evalue E
        INNER JOIN Question Q 
            ON E.idQ = Q.idQ
    WHERE 
        resultat = 'FAUX'
        AND numTP = 3
);

-- Version alternative.
PROMPT "Q16 - V4";

SELECT numEt, nom, prenom
FROM Etudiant
WHERE numEt IN (
    SELECT numEt
    FROM Evalue E
        INNER JOIN Question Q 
            ON E.idQ = Q.idQ
    WHERE 
        resultat = 'FAUX'
        AND numTP = 2
        AND numEt IN (
            SELECT numEt
            FROM Evalue E
                INNER JOIN Question Q
                    ON E.idQ = Q.idQ
            WHERE 
                resultat = 'FAUX'
                AND numTP = 3
        )
);

-- Q17 - c:1, t:1 (4)
-- Donnez les numéros des groupes d'étudiants dont aucun étudiant n'a obtenu un résultat faux au TP numéro 1. 
PROMPT "Q17";

SELECT DISTINCT groupe
FROM Etudiant
WHERE groupe NOT IN (
    SELECT groupe
    FROM Etudiant Et
        INNER JOIN Evalue E 
            ON Et.numEt = E.numEt
        INNER JOIN Question Q 
            ON E.idQ = Q.idQ
    WHERE 
        resultat = 'FAUX'
        AND numTP = 1
);

-- Q18 - c:3, t:7
-- Donnez les numéros, noms et prénoms des étudiants dans le même groupe et ayant le même type de Bac que l'étudiante Marie Dujardin.
PROMPT "Q18 - V1";

SELECT Et.numEt, Et.nom, Et.prenom
FROM Etudiant Et
    INNER JOIN Etudiant EtMD
        ON 
            Et.groupe = EtMD.groupe 
            AND Et.typeBAC = EtMD.typeBAC
WHERE 
    EtMD.nom = 'DUJARDIN'
    AND EtMD.prenom = 'MARIE';

-- Version alternative.
PROMPT "Q18 - V2";

SELECT numEt, nom, prenom
FROM Etudiant
WHERE (groupe, typeBAC) IN (
    SELECT groupe, typeBAC
    FROM Etudiant
    WHERE nom = 'DUJARDIN'
    AND prenom = 'MARIE'
);

-- Q19 - c:3, t:19
-- Donnez les numéros, noms et prénoms des étudiants ayant réalisés le nombre de variantes demandées pour au moins une Question du TP numéro 2.
PROMPT "Q19 - V1";

SELECT DISTINCT Et.numEt, Et.nom, Et.prenom
FROM Etudiant Et
    INNER JOIN Evalue Ev 
        ON Et.numEt = Ev.numEt 
    INNER JOIN Question Q 
        ON 
            Ev.idQ = Q.idQ 
            AND Ev.nbVariantes = Q.nbVariantes
WHERE numTP = 2;

-- Version alternative.
PROMPT "Q19 - V2";

SELECT DISTINCT Et.numEt, Et.nom, Et.prenom
FROM Etudiant Et
    INNER JOIN Evalue E ON Et.numEt = E.numEt
WHERE (idQ, nbVariantes) IN (
    SELECT idQ, nbVariantes
    FROM Question
    WHERE numTP = 2
);

-- Q20 - c:2, t:2
-- Donnez l'identifiant des questions et les numéros de TP portant à la fois sur le thème Jointure imbriquée et sur le thème Fonction agrégative ou statistique.
PROMPT "Q20 - V1";

SELECT Q.idQ, Q.numTP
FROM Question Q
    INNER JOIN Traite TQ 
        ON Q.idQ = TQ.idQ
    INNER JOIN Theme T 
        ON TQ.idT = T.idT
WHERE 
    T.libelle = 'JOINTURE IMBRIQUEE'
    AND Q.idQ IN (
        SELECT Q.idQ
        FROM Question Q
            INNER JOIN Traite TQ 
                ON Q.idQ = TQ.idQ
            INNER JOIN Theme T 
                ON TQ.idT = T.idT
        WHERE libelle = 'FONCTION AGREGATIVE OU STATISTIQUE'
    );

-- Version alternative.
PROMPT "Q20 - V2";

SELECT Q.idQ, Q.numTP
FROM Question Q
    INNER JOIN Traite TQ 
        ON Q.idQ = TQ.idQ
    INNER JOIN Theme T 
        ON TQ.idT = T.idT
WHERE T.libelle = 'JOINTURE IMBRIQUEE'
INTERSECT
SELECT Q.idQ, Q.numTP
FROM Question Q
    INNER JOIN Traite TQ 
        ON Q.idQ = TQ.idQ
    INNER JOIN Theme T 
        ON TQ.idT = T.idT
WHERE T.libelle = 'FONCTION AGREGATIVE OU STATISTIQUE';

-- Q21 - c:2, t:4
-- Donnez, pour chaque TP, le nombre de points obtenu par l'étudiante Marie Dujardin.
PROMPT "Q21";

SELECT numTP, SUM(E.NbPoints) AS totalPoints
FROM Etudiant Et
    INNER JOIN Evalue E 
        ON Et.numEt = E.numEt
    INNER JOIN Question Q 
        ON E.idQ = Q.idQ
WHERE 
    nom = 'DUJARDIN'
    AND prenom = 'MARIE'
GROUP BY numTP;

-- Q22 - c:2, t:3
-- Donnez les numéros et noms des étudiants ayant eu au moins trois résultats justes à des questions complexes.
PROMPT "Q22";

SELECT Et.numEt, Et.nom
FROM Etudiant Et
    INNER JOIN Evalue Ev 
        ON Et.numEt = Ev.numEt
    INNER JOIN Question Q 
        ON Ev.idQ = Q.idQ
WHERE 
    Niveau = 'COMPLEXE'
    AND resultat = 'JUSTE'
GROUP BY Et.numEt, nom
HAVING COUNT(*) >= 3;

-- Q23 - c:3, t:12
-- Donnez, pour chaque étudiant ayant au moins une réponse juste au TP numéro 3, le nombre de réponses effectivement justes à ce TP.
PROMPT "Q23";

SELECT Et.numEt, Et.nom, COUNT(*) AS nbJustes
FROM Etudiant Et
    INNER JOIN Evalue E 
        ON Et.numEt = E.numEt
WHERE (Et.numEt, idQ) IN (
    SELECT numEt, E.idQ
    FROM Evalue E
        INNER JOIN Question Q
            ON
                E.idQ = Q.idQ
                AND E.idQ = Q.idQ
    WHERE
        resultat = 'JUSTE'
        AND numTP = 3
)
GROUP BY Et.numEt, nom;
