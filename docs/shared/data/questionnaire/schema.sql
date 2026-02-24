-- Schéma de la base de données Questionnaire (PostgreSQL/SQLite)
-- Adapté depuis oracle.sql

DROP TABLE IF EXISTS Evalue CASCADE;
DROP TABLE IF EXISTS Traite CASCADE;
DROP TABLE IF EXISTS Theme CASCADE;
DROP TABLE IF EXISTS Question CASCADE;
DROP TABLE IF EXISTS Etudiant CASCADE;

CREATE TABLE Etudiant (
	numEt INTEGER,
	nom VARCHAR(20) NOT NULL,
	prenom VARCHAR(15) NOT NULL,
	typeBac VARCHAR(15) NOT NULL,
	groupe INTEGER NOT NULL,
	CONSTRAINT pk_Etudiant PRIMARY KEY (numEt),
	CONSTRAINT uk_Etudiant_01 UNIQUE (nom, prenom),
	CONSTRAINT ch_Etudiant_typeBac CHECK (typeBac IN ('GENERAL', 'TECHNOLOGIQUE', 'INTERNATIONAL')),
	CONSTRAINT ch_Etudiant_groupe CHECK (groupe BETWEEN 1 AND 4)
);

CREATE TABLE Question (
	idQ INTEGER,
	numTP INTEGER NOT NULL,
	niveau VARCHAR(15) NOT NULL,
	temps INTEGER NOT NULL,
	nbVariantes INTEGER DEFAULT 1,
	nbPoints INTEGER DEFAULT 1,
	CONSTRAINT pk_Question PRIMARY KEY (idQ),
	CONSTRAINT ch_Question_numTP CHECK (numTP BETWEEN 1 AND 4),
	CONSTRAINT ch_Etudiant_niveau CHECK (niveau IN ('FACILE', 'NORMAL', 'DIFFICILE', 'COMPLEXE')),
	CONSTRAINT ch_Question_nbVariantes CHECK (nbVariantes BETWEEN 1 AND 3),
	CONSTRAINT ch_Question_nbPoints CHECK (nbPoints BETWEEN 1 AND 5)
);

CREATE TABLE Theme (
	idT INTEGER,
	libelle VARCHAR(40) NOT NULL,
	idTPere INTEGER,
	CONSTRAINT pk_Theme PRIMARY KEY (idT),
	CONSTRAINT fk_Theme_Theme FOREIGN KEY (idTPere) REFERENCES Theme(idT),
	CONSTRAINT uk_Theme_01 UNIQUE (libelle)
);

CREATE TABLE Traite (
	idQ INTEGER,
	idT INTEGER,
	CONSTRAINT pk_ThemQuest PRIMARY KEY (idQ, idT),
	CONSTRAINT fk_ThemQuest_Question FOREIGN KEY (idQ) REFERENCES Question(idQ),
	CONSTRAINT fk_ThemQuest_Theme FOREIGN KEY (idT) REFERENCES Theme(idT)
);

CREATE TABLE Evalue (
	idQ INTEGER,
	numEt INTEGER,
	resultat VARCHAR(30),
	temps INTEGER,
	nbVariantes INTEGER DEFAULT 1,
	nbPoints NUMERIC(4, 2) DEFAULT 1,
	CONSTRAINT pk_Evaluation PRIMARY KEY (idQ, numEt),
	CONSTRAINT fk_Evaluation_Question FOREIGN KEY (idQ) REFERENCES Question(idQ),
	CONSTRAINT fk_Evaluation_Etudiant FOREIGN KEY (numEt) REFERENCES Etudiant(numEt),
	CONSTRAINT ch_Evaluation_resultat CHECK (resultat IN ('FAUX', 'ERREUR MINIME', 'JUSTE MAIS NON OPTIMAL', 'JUSTE'))
);
