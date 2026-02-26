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
	heureDep VARCHAR2(5),
	heureArr VARCHAR2(5),
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

INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (1, 100, 100, 'MARSEILLE', 'PARIS', '12:00', '13:20');
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (2, 100, 101, 'PARIS', 'BORDEAUX', '14:00', '15:00');
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (3, 101, 100, 'PARIS', 'BORDEAUX', '16:00', '17:30');
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (4, 204, 105, 'LYON', 'BREST', '06:30', '08:00');
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (5, 105, 102, 'NICE', 'PARIS', '18:30', '19:45');
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (6, 104, 103, 'NICE', 'MARSEILLE', '20:00', '21:00');
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (7, 100, 100, 'MARSEILLE', 'NICE', '08:00', '09:00');
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (8, 101, 101, 'PARIS', 'NICE', '10:00', '11:30');
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (9, 102, 104, 'NICE', 'PARIS', '19:00', '20:15');
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (10, 105, 102, 'NICE', 'LYON', '07:00', '08:15');
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (11, 106, 105, 'LYON', 'MARSEILLE', '09:00', '10:00');
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (12, 101, 101, 'NICE', 'MARSEILLE', '15:00', '16:00');
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (13, 104, 100, 'NICE', 'LYON', '11:00', '12:15');
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (14, 105, 101, 'NICE', 'BORDEAUX', '17:00', '18:30');
INSERT INTO Vol (numVol, numPil, numAv, villeDep, villeArr, heureDep, heureArr) VALUES (15, 204, 105, 'BREST', 'LYON', '14:00', '16:00');

PROMPT "Fin de la création de la base de données Airbase";
