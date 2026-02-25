-- V1.0.0

-- @title Requêtes avec SQL
-- @intro Formulez, en SQL, sur la base de données exemple, les requêtes d'interrogation suivantes.

-- @section Création et manipulation de vues
-- @instruction Répondez aux questions suivantes sous forme de requêtes de création de vues, avant de consulter chaque vue par une requête d'interrogation ou des tentatives d'insertion, une valide et une invalide, pour les vues de mise à jour. Les vues à créer ont pour objectifs de créer de nouvelles relations logiques répondants à des besoins fréquents, d'assurer la prise en compte des contraintes d'intégrité de la base ou de limiter la consultation des données pour certains utilisateurs.

PROMPT "Suppression de toutes les vues";

DROP VIEW IF EXISTS Q1;
DROP VIEW IF EXISTS Q2;
DROP VIEW IF EXISTS Q3;
DROP VIEW IF EXISTS Q4;
DROP VIEW IF EXISTS Q51;
DROP VIEW IF EXISTS Q52;
DROP VIEW IF EXISTS Q6;
DROP VIEW IF EXISTS Q7;
DROP VIEW IF EXISTS Q8;

PROMPT "Suppression de toutes les autres éventuelles vues";

BEGIN
   FOR v IN (SELECT view_name FROM user_views) 
   LOOP
      EXECUTE IMMEDIATE 'DROP VIEW "' || v.view_name || '"';
   END LOOP;
END;
/

-- Q1 - c:3, t:9
-- Quels sont les numéros, noms et prénoms des professeurs de seconde année ?
PROMPT "Q1";

CREATE OR REPLACE VIEW Q1 (numProf, nomProf, prenomProf) AS
SELECT DISTINCT P.numProf, nomProf, prenomProf
FROM Professeur P
INNER JOIN Enseigne E ON P.numProf = E.numProf 
INNER JOIN Etudiant Et ON E.numEt = Et.numEt
WHERE anneeEt = 2;

SELECT *
FROM Q1;

-- @instruction Créez des vues supprimant les calculs complexes des questions correspondantes du TD5 : Interrogations avancées en SQL.

-- Q2 - c:1, t:1 (9)
-- À partir du nombre d'étudiants de chaque groupe d'étudiants de seconde année, donnez le nombre moyen d'étudiants.
PROMPT "Q2";

CREATE OR REPLACE VIEW Q2 (groupeEt, nbEtudiants) AS
SELECT groupeEt, COUNT(*)
FROM Etudiant
WHERE anneeEt = 2
GROUP BY groupeEt;

SELECT AVG(nbEtudiants)
FROM Q2;

-- Q3 - c:1, t:1 (45)
-- À partir du nombre d'étudiants à qui chaque professeur enseigne, quel est le plus grand nombre d'étudiants ?
PROMPT "Q3";

CREATE OR REPLACE VIEW Q3 (numProf, nbEtudiants) AS
SELECT numProf, COUNT(DISTINCT numEt)
FROM Enseigne
GROUP BY numProf;

SELECT MAX(nbEtudiants)
FROM Q3;

-- Q4 - c:3, t:9
-- À partir de la somme d'heures de cours pour chaque discipline, donnez les codes et libellés des modules ainsi que le pourcentage de ces sommes d'heures par rapport au total des heures de cours dans la discipline correspondante.
PROMPT "Q4";

CREATE OR REPLACE VIEW Q4 (discipline, total) AS
SELECT discipline, SUM(heureCMPrev)
FROM Module
GROUP BY discipline;

SELECT code, libelle, heureCMPrev / total pourcentagediscipline
FROM Module M
INNER JOIN Q4 ON M.discipline = Q4.discipline
WHERE heureCMPrev IS NOT NULL;

-- Q5 - c:3, t:6
-- À partir, du nombre de professeurs qui enseignent chaque module d'une part, et de la moyenne de test maximale de ces modules d'autre part, donnez les codes des modules, le nombre de professeurs qui les enseignent et la moyenne de test maximale de ces Modules.
PROMPT "Q5";

CREATE OR REPLACE VIEW Q51 (code, nbProfs) AS
SELECT code, COUNT(DISTINCT numProf)
FROM Enseigne
GROUP BY code;

CREATE OR REPLACE VIEW Q52 (code, moyMax) AS
SELECT code, MAX(moyTest)
FROM Note
GROUP BY code;

SELECT Q51.code, nbProfs, moyMax
FROM Q51
INNER JOIN Q52 ON Q51.code= Q52.code;

-- Q6 - c:3, t:29
-- À partir de la moins bonne et de la meilleure moyenne de test du module ACSI, donnez les numéros des étudiants et les écarts respectifs entre les éventuelles moyennes de test des étudiants et ces moyennes extrêmes.
PROMPT "Q6";

CREATE OR REPLACE VIEW Q6 (moyMin, moyMax) AS
SELECT MIN(moyTest), MAX(moyTest)
FROM Note
WHERE code ='ACSI';

SELECT numEt, moyTest - moyMin, moyTest - moyMax
FROM Note, Q6
WHERE code = 'ACSI';

-- Q7
-- Créer une vue de mise à jour permettant d'assurer que les discipline insérées ou modifiées ne peuvent être que Gestion, Informatique ou Maths.
PROMPT "Q7";

CREATE OR REPLACE VIEW Q7 AS
SELECT *
FROM Module
WHERE discipline IN ('INFORMATIQUE', 'GESTION', 'MATHS')
WITH CHECK OPTION;

INSERT INTO Q7 (code, libelle, heureCMPrev, heureCMReal, heureTPPrev, heureTPReal, discipline, coefTest, coefCC, resp, codePere) VALUES ('DRO', 'DROIT', 30, NULL, 10, NULL, 'GESTION', 80, 20, 3, 'EGO');

-- Insertion invalide.
PROMPT "Q7 - Insertion invalide";

INSERT INTO Q7 (code, libelle, heureCMPrev, heureCMReal, heureTPPrev, heureTPReal, discipline, coefTest, coefCC, resp, codePere) VALUES ('COM', 'COMMUNICATION ECRITE', 20, NULL, 40, NULL, 'COMMUNICATION', 70, 30, 3, 'EGO');

-- Remarque : cette insertion provoque une erreur.

-- Q8
-- Créer une vue de mise à jour permettant d'assurer que les responsables d'un Module inséré ou modifié doivent enseigner ce Module.
PROMPT "Q8 - V1";

CREATE OR REPLACE VIEW Q8 AS
SELECT *
FROM Module M
WHERE RESP IN (SELECT numProf
			   FROM Enseigne E
			   WHERE M.code = E.code)
WITH CHECK OPTION;

PROMPT "Q8 - V2";

CREATE OR REPLACE VIEW Q8 AS
SELECT *
FROM Module M
WHERE (code, RESP) IN (SELECT code, numProf
					   FROM Enseigne)
WITH CHECK OPTION;

ALTER TABLE Enseigne DROP CONSTRAINT fk_Enseignt_code;

ALTER TABLE Enseigne ADD 
CONSTRAINT fk_Enseignt_code FOREIGN KEY (code) REFERENCES Module(code) DEFERRABLE INITIALLY DEFERRED;

BEGIN
	INSERT INTO Enseigne (code, numProf, numEt) VALUES ('FDD', 3, 2317);

	INSERT INTO Q8 (code, libelle, heureCMPrev, heureCMReal, heureTPPrev, heureTPReal, discipline, coefTest, coefCC, resp, codePere) VALUES ('FDD', 'FOUILLE DE DONNEES', 20, NULL, 40, NULL, 'INFORMATIQUE', 40, 60, 3, 'OMGL2');
END;
/

-- Remarque : il est nécessaire de faire l'insertion de l'enseignement avant l'intertion du module avec le responsable devant enseigner ce Module, et cela n'est possible qu'en faisant une transaction et en modifiant la contrainte de clef étrangère afin qu'elle ne soit vérifiée qu'à la fin de la transaction.

-- Insertion invalide.
PROMPT "Q8 - Insertion invalide";

INSERT INTO Q8 (code, libelle, heureCMPrev, heureCMReal, heureTPPrev, heureTPReal, discipline, coefTest, coefCC, resp, codePere) VALUES ('EDD', 'ENTREPOTS DE DONNEES', 20, NULL, 40, NULL, 'INFORMATIQUE', 40, 60, 666, 'OMGL2');

-- Remarque : cette insertion provoque une erreur.

-- @section Requêtes complexes

-- Q9 - c:3, t:19
-- Quels sont les numéros, noms et prénoms des étudiants ayant eu une note dans le module Principes des BD ou dans un de ses sous-modules direct ou pas ?
PROMPT "Q9";

SELECT DISTINCT Et.numEt, nomEt, prenomEt
FROM Etudiant Et
INNER JOIN Note N ON Et.numEt = N.numEt
AND code IN (SELECT code
			 FROM Module
			 START WITH libelle = 'PRINCIPES DES BD'
			 CONNECT BY codePere = PRIOR code);

-- Q10 - c:2, t:32
-- Donnez les libellés des modules et les libellés des modules d'où ils sont directement issus.
PROMPT "Q10";

SELECT M.libelle, MPere.libelle AS libellePere
FROM Module M, Module MPere
WHERE MPere.code = M.codePere;

-- Q11 - c:1, t:1 (4)
-- Quels sont les groupes de seconde année, dans lesquels un étudiant a obtenu, pour le module Conception de SI, une meilleure note de test que le meilleur étudiant du groupe d'étudiants 3 dans le même Module ?
PROMPT "Q11 - V1";

WITH T (anneeEt, groupeEt, moyTest, libelle) AS (
	SELECT anneeEt, groupeEt, moyTest, libelle 
	FROM Etudiant Et
	INNER JOIN Note N ON Et.numEt = N.numEt 
	INNER JOIN Module M ON N.code = M.code
	WHERE libelle = 'CONCEPTION DE SI'
)
SELECT groupeEt
FROM Etudiant
WHERE anneeEt = 2
  AND groupeEt IN (SELECT groupeEt
				 FROM T
				 WHERE moyTest > (SELECT MAX(moyTest)
								   FROM T
								   WHERE anneeEt = 2
								     AND groupeEt = 3))
GROUP BY groupeEt;

PROMPT "Q11 - V2";

WITH T (anneeEt, groupeEt, moyTest, libelle) AS (
	SELECT anneeEt, groupeEt, moyTest, libelle 
	FROM Etudiant Et
	INNER JOIN Note N ON Et.numEt = N.numEt 
	INNER JOIN Module M ON N.code = M.code
	WHERE libelle = 'CONCEPTION DE SI'
)
SELECT groupeEt
FROM Etudiant
WHERE anneeEt = 2
  AND groupeEt IN (SELECT groupeEt
				 FROM T
				 GROUP BY groupeEt
				 HAVING MAX(moyTest) > (SELECT MAX(moyTest)
										 FROM T
										 WHERE anneeEt = 2
										   AND groupeEt = 3))
GROUP BY groupeEt;

-- @section Consultation des tables systèmes
-- @text En lieu et place du schéma relationnel de la base de données exemple, focalisons-nous plutôt à présent sur les vues système suivantes issues du dictionnaire de données Oracle dont un extrait est présenté ci-après :
-- @text :::: schema-relationnel
-- @+
-- @+ `User_Tables` (table\_Name, tablespace\_Name, ...)
-- @+
-- @+ `User_Tab_Columns` (table\_Name, column\_Name, data\_Type, ..., data\_Length, ...)
-- @+
-- @+ `User_Cons_Columns` (..., constraint\_Name, table\_Name, column\_Name, ...)
-- @+
-- @+ `User_Constraints` (..., constraint\_Name, constraint\_Type, table\_Name, ...)
-- @+
-- @+ `User_Objects` (object\_Name, ..., object\_Type, ...)
-- @+
-- @+ ::::
-- @text ::: remarques
-- @+
-- @+ Les valeurs de l'attribut `data_Type` correspondent aux types de données Oracle : `VARCHAR2`, `NUMBER`, `DATE`, etc.
-- @+
-- @+ La valeur de l'attribut `constraint_Type` peut être `P`, pour `PRIMAY KEY`, `R`, pour `REFERENCES`, `C` pour `CHECK`, etc.
-- @+
-- @+ La valeur de l'attribut `object_Type` peut être `TABLE`, `VIEW`, `FUNCTION`, `PROCEDURE`, `TRIGGER`, `INDEX`, etc.
-- @+
-- @+ :::
-- @text Effectuez les requêtes sur les relations actuelles, pas celles éventuellement dans la corbeille. N'exécutez qu'une seule requête à la fois.
-- @instruction En cas de doute ou de curiosité, n'oubliez pas d'utiliser la commande `DESCRIBE`.

-- Nettoyage : supprimer les vues et données créées par les questions précédentes
-- pour que les requêtes sur les tables systèmes retournent les résultats attendus.
PROMPT "Nettoyage avant consultation des tables systèmes";

BEGIN
   FOR v IN (SELECT view_name FROM user_views)
   LOOP
      EXECUTE IMMEDIATE 'DROP VIEW "' || v.view_name || '"';
   END LOOP;
END;
/

DELETE FROM Enseigne WHERE code = 'FDD';
DELETE FROM Module WHERE code IN ('DRO', 'FDD');

ALTER TABLE Enseigne DROP CONSTRAINT fk_Enseignt_code;
ALTER TABLE Enseigne ADD CONSTRAINT fk_Enseignt_code FOREIGN KEY (code) REFERENCES Module(code);

-- Q12 - c:1, t:7
-- Quels sont les noms des attributs de la relation Professeur ?
PROMPT "Q12";

SELECT column_Name
FROM User_Tab_Columns
WHERE table_Name = 'PROFESSEUR';

-- Q13 - c:1, t:5
-- Quelle sont les tables ?
PROMPT "Q13 - V1";

SELECT table_Name
FROM User_Tables;

PROMPT "Q13 - V2";

SELECT object_Name
FROM User_Objects
WHERE object_Type = 'TABLE';

-- Q14 - c:1, t:20
-- Quelles sont les noms des contraintes d'intégrité ?
PROMPT "Q14";

SELECT constraint_Name
FROM User_Constraints;

-- Q15 - c:1, t:13
-- Quelles sont les noms des contraintes d'intégrité définies sur des relations ayant au moins un attribut de type VARCHAR2 de 20 caractères ou plus ?
PROMPT "Q15";

SELECT constraint_Name
FROM User_Constraints
WHERE table_Name IN (SELECT table_Name
					 FROM User_Tab_Columns
					 WHERE data_Type = 'VARCHAR2'
					   AND data_Length >= 20);

-- Q16 - c:2, t:15
-- Quelles sont, pour les attributs de type NUMBER, les noms des contraintes et les noms des attributs sur lesquels elles portent ?
PROMPT "Q16";

SELECT DISTINCT UCC.constraint_Name, UCC.column_Name
FROM User_Cons_Columns UCC
INNER JOIN User_Tab_Columns UTC
ON UCC.column_Name = UTC.column_Name AND UCC.table_Name = UTC.table_Name 
WHERE data_Type = 'NUMBER';

-- Q17 - c:3, t:26
-- Quels sont les noms des contraintes, les noms attributs sur lesquels elles portent et le type de ces attributs, pour les relations ayant au moins un attribut de type NUMBER ?
PROMPT "Q17";

SELECT UCC.constraint_Name, UCC.column_Name, data_Type
FROM User_Cons_Columns UCC
INNER JOIN User_Tab_Columns UTC
ON UCC.column_Name = UTC.column_Name AND UCC.table_Name = UTC.table_Name
WHERE UCC.table_Name IN (SELECT table_Name
				         FROM User_Tab_Columns
						 WHERE data_Type = 'NUMBER');

-- Q18 - c:1, t:5
-- Quelles sont les noms des contraintes de clefs primaires ?
PROMPT "Q18";

SELECT constraint_Name
FROM User_Constraints
WHERE constraint_Type = 'P';

-- Q19 - c:3, t:7
-- Quels sont les noms des attributs, et leurs relations correspondantes, d'attributs portant le même nom dans des relations différentes ?
PROMPT "Q19";

SELECT UTC1.column_Name, UTC1.table_Name AS Relation1, UTC2.table_Name AS Relation2
FROM User_Tab_Columns UTC1
INNER JOIN User_Tab_Columns UTC2
ON UTC1.column_Name = UTC2.column_Name AND UTC1.table_Name < UTC2.table_Name;

