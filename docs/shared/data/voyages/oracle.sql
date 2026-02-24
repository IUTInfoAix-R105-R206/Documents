-- V1.6.0

PROMPT "Création de la base de données Voyages";

-- **************************************************************************** Définition des données

PROMPT "Définition des données";

DROP TABLE IF EXISTS Reservation CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS Carac CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS Planning CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS OptionV CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS Client CASCADE CONSTRAINTS PURGE;
DROP TABLE IF EXISTS Voyage CASCADE CONSTRAINTS PURGE;

CREATE TABLE Voyage (
	idV NUMBER(6, 0), 
	villeArr VARCHAR2(20), 
	paysArr VARCHAR2(20), 
	villeDep VARCHAR2(20), 
	hotel VARCHAR2(20), 
	nbEtoiles NUMBER(1, 0), 
	duree NUMBER(2, 0) NOT NULL, 
	CONSTRAINT pk_Voyage PRIMARY KEY (idV)
);

CREATE TABLE Client (
	numCl NUMBER(6, 0), 
	nom VARCHAR2(25), 
	prenom VARCHAR2(20), 
	adresse VARCHAR2(40), 
	cp VARCHAR2(5), 
	ville VARCHAR2(20), 
	categorie VARCHAR2(15),  
	CONSTRAINT pk_Client PRIMARY KEY (numCl),
	CONSTRAINT uk_Client_01 UNIQUE (nom, prenom)
);

CREATE TABLE OptionV (
	code NUMBER(3, 0), 
	libelle VARCHAR2(20), 
	CONSTRAINT pk_OptionV PRIMARY KEY (code),
	CONSTRAINT uk_OptionV_01 UNIQUE (libelle)
);

CREATE TABLE Planning (
	idV NUMBER(6, 0), 
	dateDep DATE, 
	tarif NUMBER(6, 2), 
	CONSTRAINT pk_Planning PRIMARY KEY (idV, dateDep), 
	CONSTRAINT fk_Planning_Voyage FOREIGN KEY (idV) REFERENCES Voyage(idV)
);

CREATE TABLE Carac (
	idV NUMBER(6, 0),  
	code NUMBER(3, 0), 
	prix NUMBER(6, 2), 
	CONSTRAINT pk_Carac PRIMARY KEY (idV, code), 
	CONSTRAINT fk_Carac_Voyage FOREIGN KEY (idV) REFERENCES Voyage(idV), 
	CONSTRAINT fk_Carac_OptionV FOREIGN KEY (code) REFERENCES OptionV(code)
);

CREATE TABLE Reservation (
	numCl NUMBER(6, 0), 
	idV NUMBER(6, 0),  
	dateDep DATE, 
	nbPers NUMBER(2, 0), 
	dateRes DATE, 
	CONSTRAINT pk_Reservation PRIMARY KEY (numCl, idV, dateDep), 
	CONSTRAINT fk_Reservation_Planning FOREIGN KEY (idV, dateDep) REFERENCES Planning(idV, dateDep), 
	CONSTRAINT fk_Reservation_Client FOREIGN KEY (numCl) REFERENCES Client(numCl)
);

-- **************************************************************************** Insertions des données

PROMPT "Insertions des données";

PROMPT "Insertions des données de la table Voyage";

INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (100, 'ISTANBUL', 'TURQUIE', 'BORDEAUX', 'ANTIQUE', 5, 5);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (105, 'DAKAR', 'SENEGAL', 'PARIS', 'ESPADON', 3, 6);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (110, 'MARRAKECH', 'MAROC', 'PARIS', 'EL ANDALOUS', 3, 5);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (120, 'MARRAKECH', 'MAROC', 'MARSEILLE', 'EL ANDALOUS', 3, 4);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (122, 'LIMASSOL', 'CHYPRE', 'PARIS', 'ELIAS BEACH', 5, 4);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (200, 'MARRAKECH', 'MAROC', 'STRASBOURG', 'KENZI CLUB', 3, 5);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (201, 'AGADIR', 'MAROC', 'TOULOUSE', 'TRANSATLANTIQUE', 4, 6);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (202, 'NAIROBI', 'KENYA', 'TOULOUSE', 'TRANSATLANTIQUE', 4, 6);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (321, 'FEZ', 'MAROC', 'MARSEILLE', 'DAR AL BAHAR' , 4, 6);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (354, 'BOMBASA', 'KENYA', 'MARSEILLE', 'SAFARI JAMBO', 4, 7);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (792, 'MARRAKECH', 'MAROC', 'PARIS', 'KENZI CLUB', 3, 5);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (857, 'ISTANBUL', 'TURQUIE', 'PARIS', 'ANTIQUE', 5, 6);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (860, 'SEVILLE', 'ESPAGNE', 'MARSEILLE', 'EL ALMARANTE', 5, 4);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (861, 'VICTORIA', 'ESPAGNE', 'MARSEILLE', 'CARLTON', 5, 3);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (862, 'AGADIR', 'MAROC', 'MARSEILLE', 'ATLAS', 4, 4);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (865, 'CASABLANCA', 'MAROC', 'MARSEILLE', 'BELLERIVE', 4, 6);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (866, 'CASABLANCA', 'MAROC', 'LYON', 'BELLERIVE', 4, 7);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (867, 'LISBONNE', 'PORTUGAL', 'MARSEILLE', 'MONDIAL', 3, 2);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (869, 'RABAT', 'MAROC', 'MARSEILLE', 'HASNA' , 3, 3);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (927, 'LARNACA', 'CHYPRE', 'PARIS', 'OLD BRIDGE', 4, 4);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (952, 'NAIROBI', 'KENYA', 'PARIS', 'BAMBURI', 3, 6);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (955, 'VICTORIA', 'KENYA', 'PARIS', 'SHERATON', 4, 6);
INSERT INTO Voyage (idV, villeArr, paysArr, villeDep, hotel, nbEtoiles, duree) VALUES (972, 'AGADIR', 'MAROC', 'PARIS', 'TRANSATLANTIQUE', 4, 6);

PROMPT "Insertions des données de la table Client";

INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2101, 'BARBIER', 'NICOLAS', '12 RUE DU CHERCHE MIDI', '75008', 'PARIS', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2102, 'BARTHALOIS', 'MYLENE', NULL, '13100', 'MARSEILLE', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2103, 'CHASPOUL', 'AUBIN', NULL, '13100', 'MARSEILLE', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2104, 'CORTES', 'SEBASTIEN', NULL, NULL, 'PARIS', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2105, 'COUMES', 'STEPHANIE', '20 RUE MILTON', '75009', 'PARIS', 'PRIVILEGIE');
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2106, 'FERRIER', 'JEAN-PHILIPPE', '26 RUE RODIER', '75009', 'PARIS', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2107, 'GALERA', 'AXELLE', '60 RUE CHAPON', '75003', 'PARIS', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2108, 'GANDELLI', 'JEAN-BAPTISTE', '70 RUE SAINT HONORE', '75001', 'PARIS', 'PRIVILEGIE');
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2109, 'GELIBERT', 'CLAIRE', '20 BOULEVARD SEBASTOPOL', '75001', 'PARIS', 'PRIVILEGIE');
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2110, 'GUZIK', 'DANIEL', '360 BOULEVARD NATIONAL', '13003', 'MARSEILLE', 'PRIVILEGIE');
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2111, 'JAROLIM', 'THOMAS', '21 RUE DOIZE', '13010', 'MARSEILLE', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2112, 'LA SALA', 'GUILLAUME', '6 TRAVERSE MALVINA', '13012', 'MARSEILLE', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2113, 'LAMIGEON', 'FABIEN', '30 RUE ANNONCIADE', '69001', 'LYON', 'BON');
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2114, 'LAMY', 'SEBASTIEN', '3 PLACE CROIX PAQUET', '69001', 'LYON', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2115, 'LATCHIMY', 'RUDY', '2 QUAI SAINT ANTOINE', '69002', 'LYON', 'BON');
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2116, 'LIBERATI', 'JORIS', '80 COURS LUZE', '33300', 'BORDEAUX', 'PRIVILEGIE');
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2117, 'MAGAUD', 'EVE', '9 RUE PORTE BASSE' , '33000', 'BORDEAUX', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2118, 'MARIN', 'HUBERT', '13 BOULEVARD ANDRE AUNE', '13006', 'MARSEILLE', 'BON');
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2119, 'MIETLICKI', 'PASCAL', '36 RUE PERRIN SOLIER', '13006', 'MARSEILLE', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2120, 'PEYROCHE', 'ARNAUD', '7 RUE JEAN MERMOZ', '13008', 'MARSEILLE', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2121, 'POTIER', 'NICOLAS', '10 RUE COURCELLE', '75008', 'PARIS', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2122, 'ROGGERO', 'GUILLAUME', '57 RUE PIERRE CHARRON', '75008', 'PARIS', 'BON');
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2123, 'TARAS', 'SEBASTIEN', '68 RUE DANZIG', '75010', 'PARIS', 'BON');
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2124, 'TASSARA', 'NICOLAS', '5 IMPASSE LABRADOR', '75010', 'PARIS', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2125, 'TORRES', 'ALEXANDRE', NULL, '75011', 'PARIS', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2201, 'ALLEMAND', 'GREGORY', '24 RUE DAVIEL', '75013', 'PARIS', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2202, 'BENSALAH', 'MALEK', '12 RUE SIMONE WEIL', '75013', 'PARIS', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2203, 'BEUF', 'FRANCOIS', '12 RUE ALPHAND', '75013', 'PARIS', 'PRIVILEGIE');
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2302, 'DUVAL', 'ROBERT', NULL, NULL, 'NICE', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2303, 'DUCHEMIN', 'MARIE', NULL, NULL, 'NICE', NULL);
INSERT INTO Client (numCl, nom, prenom, adresse, cp, ville, categorie) VALUES (2304, 'DUJARDIN', 'FRANCOIS', NULL, NULL, 'AIX', 'PRIVILEGIE');

PROMPT "Insertions des données de la table OptionV";

INSERT INTO OptionV (code, libelle) VALUES (10, 'VISITE GUIDEE');
INSERT INTO OptionV (code, libelle) VALUES (11, 'VISITE EN MINI-BUS');
INSERT INTO OptionV (code, libelle) VALUES (12, 'PISCINE');
INSERT INTO OptionV (code, libelle) VALUES (13, 'GARDERIE ENFANT');
INSERT INTO OptionV (code, libelle) VALUES (15, 'SAFARI PHOTO');
INSERT INTO OptionV (code, libelle) VALUES (16, 'SAFARI DECOUVERTE');
INSERT INTO OptionV (code, libelle) VALUES (20, 'SAUNA');
INSERT INTO OptionV (code, libelle) VALUES (21, 'PLAGE PRIVEE');
INSERT INTO OptionV (code, libelle) VALUES (22, 'TERRASSE PRIVATIVE');
INSERT INTO OptionV (code, libelle) VALUES (23, 'BAGAGERIE');
INSERT INTO OptionV (code, libelle) VALUES (24, 'JACUZZI');

PROMPT "Insertions des données de la table Planning";

INSERT INTO Planning (idV, dateDep, tarif) VALUES (100, TO_DATE('2004-05-04','YYYY-MM-DD'), 470);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (100, TO_DATE('2004-06-05','YYYY-MM-DD'), 470);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (857, TO_DATE('2004-05-04','YYYY-MM-DD'), 370);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (857, TO_DATE('2004-05-15','YYYY-MM-DD'), 370);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (857, TO_DATE('2004-06-03','YYYY-MM-DD'), 390);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (857, TO_DATE('2004-06-18','YYYY-MM-DD'), 390);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (857, TO_DATE('2004-07-04','YYYY-MM-DD'), 500);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (857, TO_DATE('2004-07-10','YYYY-MM-DD'), 500);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (857, TO_DATE('2004-08-02','YYYY-MM-DD'), 500);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (857, TO_DATE('2004-08-10','YYYY-MM-DD'), 500);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (857, TO_DATE('2004-08-14','YYYY-MM-DD'), 500);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (857, TO_DATE('2004-08-21','YYYY-MM-DD'), 500);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (857, TO_DATE('2004-09-04','YYYY-MM-DD'), 390);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (927, TO_DATE('2004-05-07','YYYY-MM-DD'), 420);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (927, TO_DATE('2004-07-10','YYYY-MM-DD'), 490);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (927, TO_DATE('2004-07-17','YYYY-MM-DD'), 490);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (927, TO_DATE('2004-07-23','YYYY-MM-DD'), 490);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (927, TO_DATE('2004-06-10','YYYY-MM-DD'), 420);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (927, TO_DATE('2004-08-01','YYYY-MM-DD'), 490);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (122, TO_DATE('2004-04-05','YYYY-MM-DD'), 448);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (122, TO_DATE('2004-05-15','YYYY-MM-DD'), 448);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (122, TO_DATE('2004-06-20','YYYY-MM-DD'), 490);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (122, TO_DATE('2004-07-01','YYYY-MM-DD'), 530);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (122, TO_DATE('2004-08-02','YYYY-MM-DD'), 530);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (122, TO_DATE('2004-09-11','YYYY-MM-DD'), 490);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (122, TO_DATE('2004-10-01','YYYY-MM-DD'), 450);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (122, TO_DATE('2004-11-02','YYYY-MM-DD'), 423);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (122, TO_DATE('2004-12-17','YYYY-MM-DD'), 450);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (122, TO_DATE('2005-01-04','YYYY-MM-DD'), 405);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (354, TO_DATE('2004-05-04','YYYY-MM-DD'), 999);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (354, TO_DATE('2004-06-03','YYYY-MM-DD'), 999);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (354, TO_DATE('2004-06-11','YYYY-MM-DD'), 999);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (952, TO_DATE('2004-06-13','YYYY-MM-DD'), 890);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (952, TO_DATE('2004-05-11','YYYY-MM-DD'), 890);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (952, TO_DATE('2004-04-23','YYYY-MM-DD'), 890);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (972, TO_DATE('2004-04-13','YYYY-MM-DD'), 179);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (972, TO_DATE('2004-05-15','YYYY-MM-DD'), 179);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (972, TO_DATE('2004-05-30','YYYY-MM-DD'), 179);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (972, TO_DATE('2004-06-10','YYYY-MM-DD'), 199);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (972, TO_DATE('2004-06-17','YYYY-MM-DD'), 199);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-04-13','YYYY-MM-DD'), 299);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-04-20','YYYY-MM-DD'), 299);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-05-02','YYYY-MM-DD'), 299);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-05-15','YYYY-MM-DD'), 299);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-06-01','YYYY-MM-DD'), 325);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-06-12','YYYY-MM-DD'), 325);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-06-21','YYYY-MM-DD'), 325);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-07-01','YYYY-MM-DD'), 352);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-07-10','YYYY-MM-DD'), 352);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-07-21','YYYY-MM-DD'), 352);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-08-01','YYYY-MM-DD'), 352);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-08-13','YYYY-MM-DD'), 352);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-08-22','YYYY-MM-DD'), 352);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-09-01','YYYY-MM-DD'), 325);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-09-10','YYYY-MM-DD'), 325);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (105, TO_DATE('2003-08-18','YYYY-MM-DD'), 825);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (105, TO_DATE('2003-09-20','YYYY-MM-DD'), 825);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (105, TO_DATE('2003-10-18','YYYY-MM-DD'), 825);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (105, TO_DATE('2003-11-18','YYYY-MM-DD'), 825);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (105, TO_DATE('2003-11-23','YYYY-MM-DD'), 925);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (105, TO_DATE('2004-01-10','YYYY-MM-DD'), 825);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-10-01','YYYY-MM-DD'), 325);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-11-01','YYYY-MM-DD'), 300);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-12-01','YYYY-MM-DD'), 300);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (792, TO_DATE('2004-12-22','YYYY-MM-DD'), 375);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (861, TO_DATE('2003-08-15','YYYY-MM-DD'), 605);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (862, TO_DATE('2003-08-15','YYYY-MM-DD'), 575);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (862, TO_DATE('2003-08-22','YYYY-MM-DD'), 575);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (862, TO_DATE('2003-09-15','YYYY-MM-DD'), 500);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (862, TO_DATE('2003-10-01','YYYY-MM-DD'), 475);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (860, TO_DATE('2003-05-15','YYYY-MM-DD'), 275);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (860, TO_DATE('2003-06-17','YYYY-MM-DD'), 300);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (860, TO_DATE('2003-07-15','YYYY-MM-DD'), 325);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (860, TO_DATE('2003-07-01','YYYY-MM-DD'), 325);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (860, TO_DATE('2003-07-05','YYYY-MM-DD'), 325);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (860, TO_DATE('2003-08-05','YYYY-MM-DD'), 325);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (867, TO_DATE('2004-04-05','YYYY-MM-DD'), 305);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (867, TO_DATE('2004-05-15','YYYY-MM-DD'), 325);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (869, TO_DATE('2004-08-07','YYYY-MM-DD'), 315);
INSERT INTO Planning (idV, dateDep, tarif) VALUES (955, TO_DATE('2004-02-14','YYYY-MM-DD'), 899);

PROMPT "Insertions des données de la table Carac";

INSERT INTO Carac (idV, code, prix) VALUES (354, 16, 36);
INSERT INTO Carac (idV, code, prix) VALUES (354, 15, 36);
INSERT INTO Carac (idV, code, prix) VALUES (869, 23, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (867, 23, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (952, 16, 45);
INSERT INTO Carac (idV, code, prix) VALUES (952, 15, 45);
INSERT INTO Carac (idV, code, prix) VALUES (952, 12, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (952, 22, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (354, 12, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (354, 23, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (354, 24, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (100, 13, 10);
INSERT INTO Carac (idV, code, prix) VALUES (100, 20, 5.5);
INSERT INTO Carac (idV, code, prix) VALUES (105, 13, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (120, 13, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (100, 22, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (927, 11, 35);
INSERT INTO Carac (idV, code, prix) VALUES (857, 11, 35);
INSERT INTO Carac (idV, code, prix) VALUES (857, 12, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (857, 13, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (857, 20, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (105, 12, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (110, 12, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (120, 12, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (862, 16, 40);
INSERT INTO Carac (idV, code, prix) VALUES (862, 21, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (860, 12, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (860, 10, 10);
INSERT INTO Carac (idV, code, prix) VALUES (860, 13, NULL);
INSERT INTO Carac (idV, code, prix) VALUES (860, 23, NULL);

PROMPT "Insertions des données de la table Réservation";
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2107, 122, TO_DATE('2004-06-20','YYYY-MM-DD'), 2, TO_DATE('2004-03-25','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2101, 122, TO_DATE('2004-06-20','YYYY-MM-DD'), 1, TO_DATE('2004-04-20','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2110, 122, TO_DATE('2004-06-20','YYYY-MM-DD'), 2, TO_DATE('2004-02-12','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2124, 122, TO_DATE('2004-08-02','YYYY-MM-DD'), 2, TO_DATE('2004-03-14','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2122, 122, TO_DATE('2004-10-01','YYYY-MM-DD'), 2, TO_DATE('2004-07-24','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2118, 354, TO_DATE('2004-06-11','YYYY-MM-DD'), 1, TO_DATE('2003-12-22','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2118, 857, TO_DATE('2004-05-04','YYYY-MM-DD'), 1, TO_DATE('2004-01-22','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2110, 857, TO_DATE('2004-05-04','YYYY-MM-DD'), 1, TO_DATE('2004-01-22','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2102, 860, TO_DATE('2003-06-17','YYYY-MM-DD'), 2, TO_DATE('2002-12-05','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2103, 860, TO_DATE('2003-07-15','YYYY-MM-DD'), 2, TO_DATE('2002-12-05','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2102, 862, TO_DATE('2003-10-01','YYYY-MM-DD'), 1, TO_DATE('2003-07-05','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2111, 862, TO_DATE('2003-09-15','YYYY-MM-DD'), 2, TO_DATE('2003-05-25','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2101, 857, TO_DATE('2004-05-04','YYYY-MM-DD'), 2, TO_DATE('2003-12-10','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2104, 857, TO_DATE('2004-05-04','YYYY-MM-DD'), 3, TO_DATE('2004-01-04','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2121, 857, TO_DATE('2004-05-04','YYYY-MM-DD'), 2, TO_DATE('2004-01-10','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2125, 857, TO_DATE('2004-05-04','YYYY-MM-DD'), 1, TO_DATE('2003-11-08','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2117, 100, TO_DATE('2004-06-05','YYYY-MM-DD'), 2, TO_DATE('2003-12-05','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2107, 105, TO_DATE('2003-10-18','YYYY-MM-DD'), 2, TO_DATE('2003-09-25','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2109, 105, TO_DATE('2003-11-23','YYYY-MM-DD'), 4, TO_DATE('2003-09-23','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2113, 105, TO_DATE('2003-11-23','YYYY-MM-DD'), 1, TO_DATE('2003-07-17','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2111, 354, TO_DATE('2004-05-04','YYYY-MM-DD'), 2, TO_DATE('2002-01-14','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2119, 354, TO_DATE('2004-05-04','YYYY-MM-DD'), 2, TO_DATE('2004-02-07','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2111, 354, TO_DATE('2004-06-03','YYYY-MM-DD'), 2, TO_DATE('2003-03-20','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2120, 354, TO_DATE('2004-06-11','YYYY-MM-DD'), 1, TO_DATE('2004-03-05','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2102, 354, TO_DATE('2004-06-11','YYYY-MM-DD'), 1, TO_DATE('2004-01-30','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2110, 354, TO_DATE('2004-06-11','YYYY-MM-DD'), 1, TO_DATE('2003-12-22','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2109, 867, TO_DATE('2004-04-05','YYYY-MM-DD'), 1, TO_DATE('2004-01-22','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2120, 869, TO_DATE('2004-08-07','YYYY-MM-DD'), 2, TO_DATE('2004-06-13','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2201, 867, TO_DATE('2004-04-05','YYYY-MM-DD'), 1, TO_DATE('2004-01-13','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2201, 869, TO_DATE('2004-08-07','YYYY-MM-DD'), 1, TO_DATE('2004-04-03','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2202, 869, TO_DATE('2004-08-07','YYYY-MM-DD'), 1, TO_DATE('2004-06-25','YYYY-MM-DD'));
INSERT INTO Reservation (numCl, idV, dateDep, nbPers, dateRes) VALUES (2203, 867, TO_DATE('2004-05-15','YYYY-MM-DD'), 1, TO_DATE('2004-03-23','YYYY-MM-DD'));

PROMPT "Fin de la création de la base de données Voyages";