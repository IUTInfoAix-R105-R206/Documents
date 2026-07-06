-- Airbase - Schéma adapté pour PostgreSQL/SQLite
-- Base de données de gestion simplifiée d'une compagnie aérienne

DROP TABLE IF EXISTS Vol;
DROP TABLE IF EXISTS Avion;
DROP TABLE IF EXISTS Pilote;

CREATE TABLE Pilote (
    numPil      INTEGER,
    nomPil      VARCHAR(25),
    adresse     VARCHAR(20),
    salaire     NUMERIC(8,2),
    CONSTRAINT pk_Pilote PRIMARY KEY (numPil)
);

CREATE TABLE Avion (
    numAv       INTEGER,
    nomAv       VARCHAR(20),
    capacite    INTEGER,
    localisation VARCHAR(20),
    CONSTRAINT pk_Avion PRIMARY KEY (numAv)
);

CREATE TABLE Vol (
    numVol      INTEGER,
    numPil      INTEGER,
    numAv       INTEGER,
    villeDep    VARCHAR(20),
    villeArr    VARCHAR(20),
    heureDep    TIME,
    heureArr    TIME,
    CONSTRAINT pk_Vol PRIMARY KEY (numVol),
    CONSTRAINT fk_Vol_Pilote FOREIGN KEY (numPil) REFERENCES Pilote(numPil),
    CONSTRAINT fk_Vol_Avion  FOREIGN KEY (numAv)  REFERENCES Avion(numAv)
);
