-- @title Requêtes avec SQL
-- @intro Formulez, en SQL, sur la base de données exemple, les requêtes d'interrogation suivantes.

-- @section Rappel : expression des jointures
-- @instruction Quand cela est possible, formulez les requêtes suivantes de trois manières différentes.

-- Q1 - c:3, t:29
-- Donnez les dates de départ, villes d'arrivée et tarifs des voyages à destination du Maroc.
-- @difficulty 2
-- @tags jointure, imbrication
-- Version algébrique.
PROMPT "Q1 - Version algébrique";

SELECT DISTINCT dateDep, villeArr, tarif
FROM Voyage V
    INNER JOIN Planning P
        ON V.idV = P.idV
WHERE paysArr = 'MAROC';

-- Version imbriquée.
-- @remark La version imbriquée ne peut pas être effectuée utilement car dateDep et tarif sont des attributs de Planning et villeArr est un attribut de Voyage.

-- Version prédicative.
PROMPT "Q1 - Version prédicative";

SELECT DISTINCT dateDep, tarif, villeArr
FROM Voyage V, Planning P
WHERE
    V.idV = P.idV
    AND paysArr = 'MAROC';

-- Q2 - c:3, t:2
-- Donnez les dates de départ, villes d'arrivée et pays d'arrivée des voyages réservés des clients ne résidant ni à Paris ni à Marseille.
-- @difficulty 2
-- @tags jointure, imbrication
-- Version algébrique.
PROMPT "Q2 - Version algébrique";

SELECT DISTINCT dateDep, villeArr, paysArr
FROM Voyage V
    INNER JOIN Reservation R
        ON V.idV = R.idV
    INNER JOIN Client C
        ON R.numCl = C.numCl
WHERE ville NOT IN ('PARIS', 'MARSEILLE');

-- Version imbriquée.
PROMPT "Q2 - Version imbriquée";

SELECT DISTINCT dateDep, villeArr, paysArr
FROM Voyage V
    INNER JOIN Reservation R
        ON
            V.idV = R.idV
            AND numCl IN (
                SELECT numCl
                FROM Client
                WHERE ville NOT IN ('PARIS', 'MARSEILLE')
            );

-- @remark La version imbriquée ne peut pas être effectuée parfaitement car dateDep est un attribut de Reservation et dateDep et tarif sont des attributs de Voyage.

-- Version prédicative.
PROMPT "Q2 - Version prédicative";

SELECT DISTINCT dateDep, villeArr, paysArr
FROM Voyage V, Reservation R, Client C
WHERE
    V.idV = R.idV
    AND R.numCl = C.numCl
    AND ville NOT IN ('PARIS', 'MARSEILLE');

-- Q3 - c:1, t:3
-- Quels sont les libellés des options gratuites proposées pour les voyages réservés par le client Nicolas Barbier ?
-- @difficulty 3
-- @tags jointure, imbrication, null
-- Version algébrique.
PROMPT "Q3 - Version algébrique";

SELECT DISTINCT libelle
FROM OptionV O
    INNER JOIN Carac Ca
        ON O.code = Ca.code
    INNER JOIN Reservation R
        ON Ca.idV = R.idV
    INNER JOIN Client C
        ON R.numCl = C.numCl
WHERE
    prix IS NULL
    AND prenom = 'NICOLAS'
    AND nom = 'BARBIER';

-- Version imbriquée.
PROMPT "Q3 - Version imbriquée";

SELECT libelle
FROM OptionV
WHERE code IN (
    SELECT code
    FROM Carac
    WHERE
        (prix = 0 OR prix IS NULL)
        AND idV IN (
            SELECT idV
            FROM Reservation
            WHERE numCl IN (
                SELECT numCl
                FROM Client
                WHERE
                    prenom = 'NICOLAS'
                    AND nom = 'BARBIER'
            )
        )
);

-- Version prédicative.
PROMPT "Q3 - Version prédicative";

SELECT DISTINCT libelle
FROM OptionV O, Carac Ca, Reservation R, Client C
WHERE
    O.code = Ca.code
    AND Ca.idV = R.idV
    AND R.numCl = C.numCl
    AND nom = 'BARBIER'
    AND prenom = 'NICOLAS'
    AND prix IS NULL;

-- Q4 - c:3, t:5
-- Quels sont les noms, prénoms et villes de résidence des clients ayant réservé un voyage à destination d'Istanbul partant de leur ville de résidence ?
-- @difficulty 3
-- @tags jointure, imbrication
-- Version algébrique.
PROMPT "Q4 - Version algébrique";

SELECT DISTINCT nom, prenom, ville
FROM Client C
    INNER JOIN Reservation R
        ON C.numCl = R.numCl
    INNER JOIN Voyage V
        ON
            R.idV = V.idV
            AND villeDep = ville
WHERE villeArr = 'ISTANBUL';

-- Version imbriquée.
PROMPT "Q4 - Version imbriquée";

SELECT nom, prenom, ville
FROM Client
WHERE (numCl, ville) IN (
    SELECT numCl, villeDep
    FROM Reservation R
        INNER JOIN Voyage V
            ON
                R.idV = V.idV
                AND villeArr = 'ISTANBUL'
);

-- @remark La version imbriquée ne peut pas être effectuée parfaitement car numCl est un attribut de Reservation et villeDep un attribut de Voyage.

-- Version prédicative.
PROMPT "Q4 - Version prédicative";

SELECT DISTINCT nom, prenom, ville
FROM Voyage V, Reservation R, Client C
WHERE
    V.idV = R.idV
    AND R.numCl = C.numCl
    AND villeDep = ville
    AND villeArr = 'ISTANBUL';

-- @section Utilisation des opérateurs ensemblistes et équivalences
-- @instruction Formulez les requêtes suivantes en faisant appel aux opérateurs ensemblistes.

-- Q5 - c:1, t:4
-- Quelles sont les villes de départ d'un voyage dans lesquelles résident des clients ?
-- @difficulty 2
-- @tags intersection
PROMPT "Q5";

SELECT villeDep
FROM Voyage
INTERSECT
SELECT ville
FROM Client;

-- Q6 - c:1, t:3
-- Quels sont les libellés des options communes aux voyages d'identifiants 354 et 952 ?
-- @difficulty 2
-- @tags intersection, imbrication
PROMPT "Q6";

SELECT libelle
FROM OptionV
WHERE code IN (
    SELECT code
    FROM Carac
    WHERE idV = 354
    INTERSECT
    SELECT code
    FROM Carac
    WHERE idV = 952
);

-- Q7 - c:3, t:14
-- Donnez les identifiants, villes d'arrivée et pays d'arrivée des voyages pour lesquels il n'y a aucune réservation.
-- @difficulty 2
-- @tags différence, imbrication
PROMPT "Q7";

SELECT idV, villeArr, paysArr
FROM Voyage
WHERE idV IN (
    SELECT idV
    FROM Voyage
    EXCEPT
    SELECT idV
    FROM Reservation
);

-- Q8 - c:1, t:5
-- Quels sont les libellés des options gratuites pour le voyage d'identifiant 354 et ceux des options payantes pour le voyage d'identifiant 952 ?
-- @difficulty 2
-- @tags union, imbrication, null
PROMPT "Q8";

SELECT libelle
FROM OptionV
WHERE code IN (
    SELECT code
    FROM Carac
    WHERE
        (prix = 0 OR prix IS NULL)
        AND idV = 354
    UNION
    SELECT code
    FROM Carac
    WHERE
        (prix <> 0 OR prix IS NOT NULL)
        AND idV = 952
);

-- @instruction Formulez les requêtes suivantes en ne faisant pas appel aux opérateurs ensemblistes.

-- Q9 - c:3, t:1
-- Quels sont les identifiants, villes d'arrivée et pays d'arrivée des voyages offrant à la fois les options de visite guidée et de piscine ?
-- @difficulty 3
-- @tags jointure, imbrication
-- Version algébrique.
PROMPT "Q9 - Version algébrique";

SELECT DISTINCT V.idV, villeArr, paysArr
FROM Voyage V
    INNER JOIN Carac C1
        ON V.idV = C1.idV
    INNER JOIN OptionV O1
        ON C1.code = O1.code
    INNER JOIN Carac C2
        ON V.idV = C2.idV
    INNER JOIN OptionV O2
        ON C2.code = O2.code
WHERE
    O1.libelle = 'VISITE GUIDEE'
    AND O2.libelle = 'PISCINE';

-- Version imbriquée.
PROMPT "Q9 - Version imbriquée";

SELECT idV, villeArr, paysArr
FROM Voyage
WHERE
    idV IN (
        SELECT idV
        FROM Carac
        WHERE code IN (
            SELECT code
            FROM OptionV
            WHERE libelle = 'PISCINE'
        )
    )
    AND idV IN (
        SELECT idV
        FROM Carac
        WHERE code IN (
            SELECT code
            FROM OptionV
            WHERE libelle = 'VISITE GUIDEE'
        )
    );

-- Version prédicative.
PROMPT "Q9 - Version prédicative";

SELECT DISTINCT V.idV, villeArr, paysArr
FROM Voyage V, Carac C1, OptionV O1, Carac C2, OptionV O2
WHERE
    V.idV = C1.idV
    AND C1.code = O1.code
    AND V.idV = C2.idV
    AND C2.code = O2.code
    AND O1.libelle = 'VISITE GUIDEE'
    AND O2.libelle = 'PISCINE';

-- Q10 - c:2, t:11
-- Donnez les noms et prénoms des clients qui n'ont aucune réservation.
-- @difficulty 2
-- @tags imbrication, différence, not-exists
PROMPT "Q10 - V1";

SELECT nom, prenom
FROM Client
WHERE numCl NOT IN (
    SELECT numCl
    FROM Reservation
);

-- Version alternative.
PROMPT "Q10 - V2";

SELECT nom, prenom
FROM Client
WHERE numCl <> ALL (  -- noqa: LT01, LT06
    SELECT numCl
    FROM Reservation
);

-- Version alternative.
PROMPT "Q10 - V3";

SELECT C.nom, C.prenom
FROM Client C
WHERE NOT EXISTS (
    SELECT *
    FROM Reservation R
    WHERE R.numCl = C.numCl  -- noqa: RF03
);

-- @section Création et modification d'attributs
-- @instruction Formulez les requêtes suivantes en pensant générer, avec la commande `DESCRIBE`, un affichage
-- @+ permettant de vérifier la validité des réponses et, à la fin de la séance, penser à annuler les
-- @+ modifications faites pour laisser la base de données dans l'état initial.

-- noqa: disable=all

-- Q11
-- Ajoutez les attributs correspondant au tarif enfant et au nombre d'enfants.
-- @difficulty 1
-- @tags ddl
PROMPT "Q11";

ALTER TABLE Planning ADD (tarifEnf NUMBER(6, 2));
ALTER TABLE Reservation ADD (nbEnf NUMBER(2, 0));

DESCRIBE Planning;

DESCRIBE Reservation;
-- Q12
-- Doublez la taille possible du libellé d'une option.
-- @difficulty 1
-- @tags ddl
PROMPT "Q12";

ALTER TABLE OptionV MODIFY (libelle VARCHAR2(40));

DESCRIBE OptionV;

-- Q13
-- En se basant sur les données actuelles, définissez une contrainte de domaine pour les catégories. Vérifiez en essayant d'ajouter un client ne respectant pas cette contrainte.
-- @difficulty 2
-- @tags ddl
PROMPT "Q13";

ALTER TABLE Client ADD (CONSTRAINT ck_Client_categorie CHECK (categorie IN ('PRIVILEGIE', 'BON')));

DESCRIBE Client;

-- Insertion invalide.
PROMPT "Q13 - Insertion invalide";

INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (666, 'MARTIN NEVOT', 'MICKAEL', '1 IMPASSE DES DRAGONS', '13600', 'CEYRESTE', 'MAUVAIS');

-- @remark Cette insertion provoque une erreur.

-- Q14
-- En se basant sur les données actuelles, définissez une contrainte de domaine pour les nombres d'étoiles. Vérifiez en essayant d'ajouter un voyage ne respectant pas cette contrainte.
-- @difficulty 2
-- @tags ddl
PROMPT "Q14";

ALTER TABLE Voyage ADD (CONSTRAINT ck_Voyage_nbEtoiles CHECK (nbEtoiles BETWEEN 3 AND 5));

DESCRIBE Voyage;

-- Insertion invalide.
PROMPT "Q14 - Insertion invalide";

INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (666, 'DUBLIN', 'IRELAND', 'MARSEILLE', 'TEMPLE BAR HOTEL', '2', '6');

-- @remark Cette insertion provoque une erreur.

-- Q15
-- Créez une nouvelle relation `Capacite` permettant de connaître par hôtel et type de chambre `typeC`, pouvant être `SIMPLE`, `DOUBLE`, `DOUBLE LUXE`, `SUITE`, `SUITE JUNIOR` et `SUITE PRESTIGE`, le nombre de chambres `nbCh`.
-- @difficulty 2
-- @tags ddl
PROMPT "Q15";

DROP TABLE IF EXISTS Capacite PURGE;

CREATE TABLE Capacite (
    hotel VARCHAR2(20),
    typeC VARCHAR2(15),
    nbCh NUMBER(3, 0),
    CONSTRAINT pk_Capacite PRIMARY KEY(hotel, typeC),
    CONSTRAINT ck_Capacite_typeC CHECK(typeC IN ('SIMPLE', 'DOUBLE', 'DOUBLE LUXE', 'SUITE', 'SUITE JUNIOR', 'SUITE PRESTIGE'))
);

DESCRIBE Capacite;


-- @section Mises à jour des données
-- @instruction Formulez les requêtes suivantes en pensant générer, avec la commande `SELECT` ou `DESCRIBE`,
-- @+ un affichage permettant de vérifier la validité des réponses et, à la fin de la séance, penser à
-- @+ annuler les modifications faites pour laisser la base de données dans l'état initial.

-- Q16 - t:4
-- Le client numéro 2103 réserve toujours avec ses deux enfants et le client Thomas Jarolim avec son enfant unique.
-- @difficulty 2
-- @tags dml, imbrication
PROMPT "Q16";

ALTER TABLE Planning ADD (tarifEnf NUMBER(6, 2));
ALTER TABLE Reservation ADD (nbEnf NUMBER(2, 0));

-- @remark Les commandes précédentes sont nécessaires si les altérations de table n'ont pas été faites précédemment. Elles ne doivent pas être exécutées dans le cas contraire.

UPDATE Reservation
SET nbEnf = 2
WHERE numCl = 2103;

UPDATE Reservation
SET nbEnf = 1
WHERE numCl IN (
    SELECT numCl
    FROM Client
    WHERE nom = 'JAROLIM'
        AND prenom = 'THOMAS'
);

SELECT C.numCl, nom, prenom, idV, dateDep, nbEnf
FROM Client C
    INNER JOIN Reservation R
        ON C.numCl = R.numCl
WHERE
    C.numCl = 2103
    OR (nom = 'JAROLIM' AND prenom = 'THOMAS');

-- Q17 - t:80
-- Un tarif enfant est moitié prix du tarif correspondant.
-- @difficulty 1
-- @tags dml
PROMPT "Q17";

ALTER TABLE Planning ADD (tarifEnf NUMBER(6, 2));

-- @remark La commande précédente est nécessaire si l'altération de table n'a pas été faite précédemment. Elle ne doit pas être exécutée dans le cas contraire.

UPDATE Planning SET tarifEnf = tarif / 2;

SELECT *
FROM Planning;

-- Q18 - t:12
-- Insérez les données suivantes.
-- @difficulty 1
-- @tags dml
--
-- : Extension de la relation `Capacite` de la base de données Voyage
--
-- | `hotel` | `typeC` | `nbCh` |
-- |---|---|---|
-- | ANTIQUE | SIMPLE | 10 |
-- | ANTIQUE | DOUBLE | 75 |
-- | ANTIQUE | DOUBLE LUXE | 12 |
-- | ANTIQUE | SUITE | 5 |
-- | ELIAS BEACH | DOUBLE | 83 |
-- | ELIAS BEACH | SUITE | 27 |
-- | OLD BRIDGE | SIMPLE | 25 |
-- | OLD BRIDGE | DOUBLE | 75 |
-- | SAFARI JAMBO | SIMPLE | 32 |
-- | SAFARI JAMBO | DOUBLE | 100 |
-- | TRANSATLANTIQUE | DOUBLE | 200 |
-- | BAMBURI | DOUBLE | 150 |
PROMPT "Q18";

DROP TABLE IF EXISTS Capacite PURGE;

CREATE TABLE Capacite (
    hotel VARCHAR2(20),
    typeC VARCHAR2(15),
    nbCh NUMBER(3, 0),
    CONSTRAINT pk_Capacite PRIMARY KEY(hotel, typeC),
    CONSTRAINT ck_Capacite_typeC CHECK(typeC IN ('SIMPLE', 'DOUBLE', 'DOUBLE LUXE', 'SUITE', 'SUITE JUNIOR', 'SUITE PRESTIGE'))
);

-- @remark Les commandes précédentes sont nécessaires si la création de table n'a pas été faite précédemment. Il est inutile de les exécuter dans le cas contraire.

INSERT INTO Capacite (hotel, typeC, nbCh) VALUES ('ANTIQUE', 'SIMPLE', 10);
INSERT INTO Capacite (hotel, typeC, nbCh) VALUES ('ANTIQUE', 'DOUBLE', 75);
INSERT INTO Capacite (hotel, typeC, nbCh) VALUES ('ANTIQUE', 'DOUBLE LUXE', 12);
INSERT INTO Capacite (hotel, typeC, nbCh) VALUES ('ANTIQUE', 'SUITE', 5);
INSERT INTO Capacite (hotel, typeC, nbCh) VALUES ('ELIAS BEACH', 'DOUBLE', 83);
INSERT INTO Capacite (hotel, typeC, nbCh) VALUES ('ELIAS BEACH', 'SUITE', 27);
INSERT INTO Capacite (hotel, typeC, nbCh) VALUES ('OLD BRIDGE', 'SIMPLE', 25);
INSERT INTO Capacite (hotel, typeC, nbCh) VALUES ('OLD BRIDGE', 'DOUBLE', 75);
INSERT INTO Capacite (hotel, typeC, nbCh) VALUES ('SAFARI JAMBO', 'SIMPLE', 32);
INSERT INTO Capacite (hotel, typeC, nbCh) VALUES ('SAFARI JAMBO', 'DOUBLE', 100);
INSERT INTO Capacite (hotel, typeC, nbCh) VALUES ('TRANSATLANTIQUE', 'DOUBLE', 200);
INSERT INTO Capacite (hotel, typeC, nbCh) VALUES ('BAMBURI', 'DOUBLE', 150);

SELECT *
FROM Capacite;

-- @section Archivage d'information et gestion de transactions
-- @text Le mécanisme des transactions est ici illustré à travers un exemple d'archivage d'information.
-- @text Dans un souci d'archivage des données, on désire régulièrement purger la relation `Reservation`,
-- @+ sans pour autant perdre les informations existantes.

-- Q19
-- Créez une nouvelle relation `AncienneReservation` permettant d'archiver toutes les réservations programmées passées, la date de réservation étant remplacée par la date d'archivage.
-- @difficulty 2
-- @tags ddl
PROMPT "Q19";

DROP TABLE IF EXISTS AncienneReservation PURGE;

CREATE TABLE AncienneReservation (
    numCl NUMBER(6, 0),
    idV NUMBER(6, 0),
    dateDep DATE,
    nbPers NUMBER(2, 0),
    dateArch DATE,
    nbEnf NUMBER(2, 0),
    CONSTRAINT pk_AncienneReservation PRIMARY KEY(numCl, idV, dateDep)
);

DESCRIBE AncienneReservation;

-- Q20 - [`AncienneReservation` : 14 tuples]{.expected}, [`Reservation` : 18 tuples]{.expected}
-- À l'aide d'une transaction, archivez les réservations antérieures à 2004.
-- @difficulty 3
-- @tags dml, transaction
PROMPT "Q20";

ALTER TABLE Reservation ADD (nbEnf NUMBER(2, 0));

DROP TABLE IF EXISTS AncienneReservation PURGE;

CREATE TABLE AncienneReservation (
    numCl NUMBER(6, 0),
    idV NUMBER(6, 0),
    dateDep DATE,
    nbPers NUMBER(2, 0),
    dateArch DATE,
    nbEnf NUMBER(2, 0),
    CONSTRAINT pk_AncienneReservation PRIMARY KEY(numCl, idV, dateDep)
);

-- @remark Les commandes précédentes sont nécessaires si l'alteration et la création de table n'ont pas été faites précédemment. L'altération ne doit pas être exécutée, et il est inutile d'exécuter la création dans le cas contraire.

BEGIN
    INSERT INTO AncienneReservation
    SELECT numCl, idV, dateDep, nbPers, SYSDATE, nbEnf
    FROM Reservation
    WHERE dateRes < TO_DATE('2004-01-01', 'YYYY-MM-DD');

    DELETE FROM Reservation
    WHERE dateRes < TO_DATE('2004-01-01', 'YYYY-MM-DD');
END;
/

SELECT *
FROM AncienneReservation;

SELECT *
FROM Reservation;
-- noqa: enable=all
