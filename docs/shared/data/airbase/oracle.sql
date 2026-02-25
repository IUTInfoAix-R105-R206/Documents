-- V1.0.0

PROMPT "Création de la base de données Airbase";

-- **************************************************************************** Définition des données

PROMPT "Définition des données";

DROP TABLE IF EXISTS Vol CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS Avion CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS Pilote CASCADE CONSTRAINTS PURGE;

CREATE TABLE Pilote (
	numPil NUMBER(6, 0),
	nomPil VARCHAR2(25),
	adresse VARCHAR2(20),
	salaire NUMBER(8, 2),
	CONSTRAINT pk_Pilote PRIMARY KEY (numPil)
);

CREATE TABLE Avion (
	numAv NUMBER(6, 0),
	nomAv VARCHAR2(20),
	capacite NUMBER(4, 0),
	localisation VARCHAR2(20),
	CONSTRAINT pk_Avion PRIMARY KEY (numAv)
);

CREATE TABLE Vol (
	numVol NUMBER(6, 0),
	numPil NUMBER(6, 0),
	numAv NUMBER(6, 0),
	villeDep VARCHAR2(20),
	villeArr VARCHAR2(20),
	heureDep DATE,
	heureArr DATE,
	CONSTRAINT pk_Vol PRIMARY KEY (numVol),
	CONSTRAINT fk_Vol_Pilote FOREIGN KEY (numPil) REFERENCES Pilote(numPil),
	CONSTRAINT fk_Vol_Avion FOREIGN KEY (numAv) REFERENCES Avion(numAv)
);

-- **************************************************************************** Insertions des données

PROMPT "Insertions des données";

PROMPT "Insertions des données de la table Pilote";

INSERT INTO Pilote (numPil, nomPil, adresse, salaire) VALUES (100, 'MARTIN', 'MARSEILLE', 5000);
INSERT INTO Pilote (numPil, nomPil, adresse, salaire) VALUES (101, 'DUPRE', 'PARIS', 6000);
INSERT INTO Pilote (numPil, nomPil, adresse, salaire) VALUES (102, 'DUBOIS', 'MARSEILLE', 7000);
INSERT INTO Pilote (numPil, nomPil, adresse, salaire) VALUES (103, 'DUVAL', 'MARSEILLE', 5000);
INSERT INTO Pilote (numPil, nomPil, adresse, salaire) VALUES (104, 'MARTIN', 'PARIS', 6000);
INSERT INTO Pilote (numPil, nomPil, adresse, salaire) VALUES (105, 'LAMBERT', 'NICE', 4500);
INSERT INTO Pilote (numPil, nomPil, adresse, salaire) VALUES (106, 'LEROY', 'LYON', 5500);
INSERT INTO Pilote (numPil, nomPil, adresse, salaire) VALUES (204, 'DURAND', 'BORDEAUX', 7000);
INSERT INTO Pilote (numPil, nomPil, adresse, salaire) VALUES (300, 'RICHARD', 'TOULOUSE', 5000);

PROMPT "Insertions des données de la table Avion";

INSERT INTO Avion (numAv, nomAv, capacite, localisation) VALUES (100, 'A320', 350, 'MARSEILLE');
INSERT INTO Avion (numAv, nomAv, capacite, localisation) VALUES (101, 'B787', 500, 'PARIS');
INSERT INTO Avion (numAv, nomAv, capacite, localisation) VALUES (102, 'A340', 400, 'NICE');
INSERT INTO Avion (numAv, nomAv, capacite, localisation) VALUES (103, 'CONCORDE', 200, 'NICE');
INSERT INTO Avion (numAv, nomAv, capacite, localisation) VALUES (104, 'A380', 550, 'MARSEILLE');
INSERT INTO Avion (numAv, nomAv, capacite, localisation) VALUES (105, 'ATR42', 50, 'LYON');

PROMPT "Insertions des données de la table Vol";

INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (1, 100, 100, 'MARSEILLE', 'PARIS', TO_DATE('12:00', 'HH24:MI'), TO_DATE('13:20', 'HH24:MI'));
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (2, 100, 101, 'PARIS', 'BORDEAUX', TO_DATE('14:00', 'HH24:MI'), TO_DATE('15:00', 'HH24:MI'));
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (3, 101, 100, 'PARIS', 'BORDEAUX', TO_DATE('16:00', 'HH24:MI'), TO_DATE('17:30', 'HH24:MI'));
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (4, 204, 105, 'LYON', 'BREST', TO_DATE('06:30', 'HH24:MI'), TO_DATE('08:00', 'HH24:MI'));
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (5, 105, 102, 'NICE', 'PARIS', TO_DATE('18:30', 'HH24:MI'), TO_DATE('19:45', 'HH24:MI'));
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (6, 104, 103, 'NICE', 'MARSEILLE', TO_DATE('20:00', 'HH24:MI'), TO_DATE('21:00', 'HH24:MI'));
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (7, 100, 100, 'MARSEILLE', 'NICE', TO_DATE('08:00', 'HH24:MI'), TO_DATE('09:00', 'HH24:MI'));
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (8, 101, 101, 'PARIS', 'NICE', TO_DATE('10:00', 'HH24:MI'), TO_DATE('11:30', 'HH24:MI'));
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (9, 102, 104, 'NICE', 'PARIS', TO_DATE('19:00', 'HH24:MI'), TO_DATE('20:15', 'HH24:MI'));
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (10, 105, 102, 'NICE', 'LYON', TO_DATE('07:00', 'HH24:MI'), TO_DATE('08:15', 'HH24:MI'));
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (11, 106, 105, 'LYON', 'MARSEILLE', TO_DATE('09:00', 'HH24:MI'), TO_DATE('10:00', 'HH24:MI'));
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (12, 101, 101, 'NICE', 'MARSEILLE', TO_DATE('15:00', 'HH24:MI'), TO_DATE('16:00', 'HH24:MI'));
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (13, 104, 100, 'NICE', 'LYON', TO_DATE('11:00', 'HH24:MI'), TO_DATE('12:15', 'HH24:MI'));
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (14, 105, 101, 'NICE', 'BORDEAUX', TO_DATE('17:00', 'HH24:MI'), TO_DATE('18:30', 'HH24:MI'));
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (15, 204, 105, 'BREST', 'LYON', TO_DATE('14:00', 'HH24:MI'), TO_DATE('16:00', 'HH24:MI'));

PROMPT "Fin de la création de la base de données Airbase";
