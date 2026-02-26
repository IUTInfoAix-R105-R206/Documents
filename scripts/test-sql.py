#!/usr/bin/env python3
"""test-sql.py — Valide les corrections SQL contre le jeu de données de test.

Usage: python3 scripts/test-sql.py [DBMS] [--report FILE] [--td TD_NUM]

Ce script :
1. Charge le schéma et les données de test dans la base
2. Extrait les requêtes et les résultats attendus depuis les fichiers de correction
3. Exécute chaque requête et vérifie le nombre de colonnes et de lignes
4. Affiche un rapport de test
5. Écrit un rapport CSV si --report FILE est spécifié
"""

import os
import re
import sys
import glob
import subprocess
from dataclasses import dataclass
from pathlib import Path

# ── Couleurs ANSI ─────────────────────────────────────────────────────────────

RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
NC = "\033[0m"

# ── Mots-clés DDL/DML (setup, non testables) ─────────────────────────────────

SETUP_KEYWORDS = frozenset({
    "CREATE", "DROP", "INSERT", "UPDATE", "DELETE", "ALTER",
    "BEGIN", "DECLARE", "GRANT", "REVOKE", "TRUNCATE", "MERGE",
})

# ── Dataclasses ───────────────────────────────────────────────────────────────


@dataclass
class TestBlock:
    """Bloc SQL extrait d'un fichier de correction, prêt à être testé."""
    td_id: str
    label: str
    sql: str
    expected_cols: str  # "" si non spécifié
    expected_rows: str  # "" si non spécifié


@dataclass
class TestResult:
    """Résultat d'un test SQL."""
    td_id: str
    label: str
    status: str         # pass, fail, error, skip
    expected_cols: str
    expected_rows: str
    actual_cols: int
    actual_rows: int
    message: str = ""


# ── Moteurs de base de données ────────────────────────────────────────────────


class DBEngine:
    """Interface de base pour un moteur SGBD.

    Si la variable d'environnement ``<DBMS>_DOCKER_CONTAINER`` est définie,
    toutes les commandes CLI sont préfixées par ``docker exec -i <container>``.
    Cela permet d'exécuter le script Python sur l'hôte tout en communiquant
    avec un SGBD tournant dans un conteneur Docker.
    """

    name: str = "unknown"
    container_env: str = ""  # nom de la variable d'env. Docker, ex: "PG_DOCKER_CONTAINER"

    def __init__(self):
        self.container = (os.environ.get(self.container_env, "")
                          if self.container_env else "")

    def _wrap_cmd(self, cmd: list) -> list:
        """Préfixe *cmd* avec ``docker exec -i`` si un conteneur est configuré."""
        if self.container:
            return ["docker", "exec", "-i", self.container] + cmd
        return cmd

    def _run(self, cmd: list, **kwargs) -> subprocess.CompletedProcess:
        """Exécute *cmd*, éventuellement dans un conteneur Docker."""
        return subprocess.run(
            self._wrap_cmd(cmd), capture_output=True, text=True, **kwargs,
        )

    def execute_query(self, sql: str) -> str:
        """Exécute un SELECT et retourne le résultat pipe-delimited."""
        raise NotImplementedError

    def execute_block(self, sql: str) -> bool:
        """Exécute un DDL/DML pour ses effets de bord. Retourne True si OK."""
        raise NotImplementedError

    def load_schema(self, data_dir: Path) -> None:
        """Charge schéma + données depuis data_dir."""
        raise NotImplementedError

    def cleanup_schema(self) -> None:
        """Nettoie le schéma avant rechargement."""
        pass

    def has_data_files(self, data_dir: Path) -> bool:
        """Vérifie que les fichiers de données existent pour ce SGBD."""
        raise NotImplementedError


class PostgresEngine(DBEngine):

    name = "postgres"
    container_env = "PG_DOCKER_CONTAINER"

    def __init__(self):
        super().__init__()
        self.host = os.environ.get("PGHOST", "localhost")
        self.user = os.environ.get("PGUSER", "test")
        self.db = os.environ.get("PGDATABASE", "gestion_pedagogique")

    def _psql(self, *extra):
        return ["psql", "-h", self.host, "-U", self.user, "-d", self.db] + list(extra)

    def execute_query(self, sql: str) -> str:
        r = self._run(self._psql("-t", "-A", "-F|", "-c", sql))
        if r.returncode != 0:
            raise RuntimeError(r.stderr)
        return r.stdout

    def execute_block(self, sql: str) -> bool:
        return self._run(self._psql("-c", sql)).returncode == 0

    def cleanup_schema(self) -> None:
        """Supprime toutes les tables et vues du schéma PostgreSQL."""
        self.execute_block(
            "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
        )

    def load_schema(self, data_dir: Path) -> None:
        self.cleanup_schema()
        for name in ("schema.sql", "insert.sql"):
            f = data_dir / name
            if f.exists():
                self._run(self._psql("-f", "-"),
                          input=f.read_text(encoding="utf-8"))

    def has_data_files(self, data_dir: Path) -> bool:
        return (data_dir / "schema.sql").exists()


class SQLiteEngine(DBEngine):

    name = "sqlite"
    container_env = "SQLITE_DOCKER_CONTAINER"

    def __init__(self):
        super().__init__()
        self.db_path = os.environ.get("SQLITE_DB", "/tmp/gestion_pedagogique.db")

    def _sqlite(self, *extra):
        return ["sqlite3", self.db_path] + list(extra)

    def execute_query(self, sql: str) -> str:
        r = self._run(self._sqlite(sql))
        if r.returncode != 0:
            raise RuntimeError(r.stderr)
        return r.stdout

    def execute_block(self, sql: str) -> bool:
        return self._run(self._sqlite(), input=sql).returncode == 0

    def cleanup_schema(self) -> None:
        """Supprime le fichier SQLite pour repartir d'une base vide."""
        if self.container:
            self._run(["rm", "-f", self.db_path])
        else:
            db = Path(self.db_path)
            if db.exists():
                db.unlink()

    def load_schema(self, data_dir: Path) -> None:
        self.cleanup_schema()
        schema = data_dir / "schema.sql"
        insert = data_dir / "insert.sql"
        if schema.exists():
            # Filtrer CASCADE (non supporté par SQLite)
            text = re.sub(r" CASCADE", "", schema.read_text(encoding="utf-8"),
                          flags=re.IGNORECASE)
            self._run(self._sqlite(), input=text)
        if insert.exists():
            # Filtrer les blocs ALTER TABLE ... ADD CONSTRAINT ... ;
            text = insert.read_text(encoding="utf-8")
            lines = text.splitlines(keepends=True)
            filtered = []
            skip = False
            for line in lines:
                if re.match(r"^\s*ALTER\s+TABLE.*ADD\s+CONSTRAINT",
                            line, re.IGNORECASE):
                    skip = True
                if skip:
                    if ";" in line:
                        skip = False
                    continue
                filtered.append(line)
            self._run(self._sqlite(), input="".join(filtered))

    def has_data_files(self, data_dir: Path) -> bool:
        return (data_dir / "schema.sql").exists()


class OracleEngine(DBEngine):

    name = "oracle"
    container_env = "ORACLE_DOCKER_CONTAINER"

    def __init__(self):
        super().__init__()
        self.user = os.environ.get("ORACLE_USER", "system")
        self.password = os.environ.get("ORACLE_PASS", "oracle")
        self.sid = os.environ.get("ORACLE_SID", "XE")

    def _sqlplus(self):
        return ["sqlplus", "-s", f"{self.user}/{self.password}@{self.sid}"]

    def _sqlplus_query_settings(self):
        return (
            "SET HEADING OFF\n"
            "SET FEEDBACK OFF\n"
            "SET PAGESIZE 0\n"
            "SET NEWPAGE NONE\n"
            "SET COLSEP '|'\n"
            "SET LINESIZE 32767\n"
            "SET TRIMOUT ON\n"
            "SET TRIMSPOOL ON\n"
            "SET VERIFY OFF\n"
            "SET NULL ''\n"
        )

    def execute_query(self, sql: str) -> str:
        stdin = self._sqlplus_query_settings() + sql + ";\nEXIT\n"
        r = self._run(self._sqlplus(), input=stdin)
        if r.returncode != 0:
            raise RuntimeError(r.stderr)
        return r.stdout

    def execute_block(self, sql: str) -> bool:
        stdin = (
            "SET HEADING OFF\n"
            "SET FEEDBACK OFF\n"
            "SET PAGESIZE 0\n"
            "SET VERIFY OFF\n"
            "WHENEVER SQLERROR CONTINUE\n"
            + sql + "\n"
            "EXIT\n"
        )
        return self._run(self._sqlplus(), input=stdin).returncode == 0

    def cleanup_schema(self) -> None:
        """Supprime toutes les vues et tables du schéma Oracle courant."""
        plsql = (
            "WHENEVER SQLERROR CONTINUE\n"
            "BEGIN\n"
            "   FOR v IN (SELECT view_name FROM user_views)\n"
            "   LOOP\n"
            '      EXECUTE IMMEDIATE \'DROP VIEW "\' || v.view_name || \'"\';\n'
            "   END LOOP;\n"
            "   FOR t IN (SELECT table_name FROM user_tables)\n"
            "   LOOP\n"
            '      EXECUTE IMMEDIATE \'DROP TABLE "\' || t.table_name '
            '|| \'" CASCADE CONSTRAINTS PURGE\';\n'
            "   END LOOP;\n"
            "END;\n"
            "/\n"
            "EXIT\n"
        )
        self._run(self._sqlplus(), input=plsql)

    def load_schema(self, data_dir: Path) -> None:
        self.cleanup_schema()
        oracle_file = data_dir / "oracle.sql"
        if not oracle_file.exists():
            oracle_file = data_dir / "gestion-pedagogique-oracle.sql"
        if oracle_file.exists():
            stdin = oracle_file.read_text(encoding="utf-8") + "\nEXIT\n"
            self._run(self._sqlplus(), input=stdin)

    def has_data_files(self, data_dir: Path) -> bool:
        return ((data_dir / "oracle.sql").exists()
                or (data_dir / "gestion-pedagogique-oracle.sql").exists())


# ── Parsing des fichiers de correction ────────────────────────────────────────

# Regex pour les annotations de question
RE_FULL_ANNOTATION = re.compile(r"^-- Q(\d+).*c:(\d+).*t:(\d+)")
RE_ROWS_ONLY = re.compile(r"^-- Q(\d+) - t:(\d+)")
RE_NO_ANNOTATION = re.compile(r"^-- Q(\d+)\s*$")
RE_PROMPT = re.compile(r'^PROMPT "(.*)";?')


def parse_correction_file(path: Path, td_id: str) -> list[TestBlock]:
    """Parse un fichier SQL de correction et retourne les blocs à tester."""
    blocks: list[TestBlock] = []
    text = path.read_text(encoding="utf-8")

    current_label = ""
    current_block = ""
    expected_cols = ""
    expected_rows = ""
    in_query = False

    def flush_block():
        nonlocal current_block
        if current_block.strip() and current_label:
            blocks.append(TestBlock(
                td_id=td_id,
                label=current_label,
                sql=current_block,
                expected_cols=expected_cols,
                expected_rows=expected_rows,
            ))
        current_block = ""

    for raw_line in text.splitlines():
        line = raw_line.rstrip("\r")

        # ── Annotation complète : -- Q1 - c:2, t:9 ──
        m = RE_FULL_ANNOTATION.match(line)
        if m:
            flush_block()
            current_label = f"Q{m.group(1)}"
            expected_cols = m.group(2)
            expected_rows = m.group(3)
            current_block = ""
            in_query = False
            continue

        # ── Annotation partielle : -- Q1 - t:9 ──
        m = RE_ROWS_ONLY.match(line)
        if m:
            flush_block()
            current_label = f"Q{m.group(1)}"
            expected_cols = ""
            expected_rows = m.group(2)
            current_block = ""
            in_query = False
            continue

        # ── Sans annotation : -- Q1 ──
        m = RE_NO_ANNOTATION.match(line)
        if m:
            flush_block()
            current_label = f"Q{m.group(1)}"
            expected_cols = ""
            expected_rows = ""
            current_block = ""
            in_query = False
            continue

        # ── PROMPT (variante Oracle) ──
        m = RE_PROMPT.match(line)
        if m:
            flush_block()
            current_label = m.group(1)
            current_block = ""
            in_query = True
            continue

        # ── Accumulation des lignes SQL ──
        if in_query:
            if line.startswith("--") or not line.strip():
                # Un commentaire après du SQL marque la fin du bloc
                if current_block.strip() and line.startswith("--"):
                    in_query = False
                continue
            current_block += line + "\n"

    # Dernier bloc
    flush_block()
    return blocks


# ── Splitting multi-statements ────────────────────────────────────────────────


def split_statements(sql: str) -> list[str]:
    """Sépare un bloc SQL en statements individuels.

    Gère les blocs PL/SQL (BEGIN...END; /) comme un seul statement.
    """
    statements: list[str] = []
    current = ""
    in_plsql = False

    for line in sql.splitlines(keepends=True):
        # Début d'un bloc PL/SQL
        if not in_plsql and re.match(r"^\s*(BEGIN|DECLARE)", line, re.IGNORECASE):
            in_plsql = True
            current += line
            continue

        # Fin d'un bloc PL/SQL (ligne contenant juste /)
        if in_plsql:
            if re.match(r"^\s*/\s*$", line):
                current += "/\n"
                statements.append(current)
                current = ""
                in_plsql = False
            else:
                current += line
            continue

        # En dehors du PL/SQL, découper par ;
        if re.search(r";\s*$", line):
            current += line
            statements.append(current)
            current = ""
        else:
            current += line

    # Reste éventuel (statement sans ; final)
    if current.strip():
        statements.append(current)

    return statements


def is_setup_statement(stmt: str) -> bool:
    """Détermine si un statement est un DDL/DML (non testable)."""
    # Premier mot significatif
    for line in stmt.splitlines():
        stripped = line.strip()
        if stripped:
            first_word = stripped.split()[0].upper()
            return first_word in SETUP_KEYWORDS
    return False


# ── Comptage lignes/colonnes ──────────────────────────────────────────────────


def count_rows(result: str) -> int:
    """Compte les lignes non vides d'un résultat."""
    return sum(1 for line in result.replace("\r", "").splitlines()
               if line.strip())


def count_cols(result: str) -> int:
    """Compte les colonnes (séparateur |) de la première ligne non vide."""
    for line in result.replace("\r", "").splitlines():
        if line.strip():
            return len(line.split("|"))
    return 0


# ── Exécution des tests ──────────────────────────────────────────────────────


def test_block(engine: DBEngine, block: TestBlock) -> TestResult:
    """Teste un bloc SQL et retourne le résultat."""
    sql = block.sql.strip()
    if not sql:
        return TestResult(
            block.td_id, block.label, "skip",
            block.expected_cols, block.expected_rows, 0, 0,
            "bloc vide",
        )

    # Séparer en statements
    statements = split_statements(sql)
    if not statements:
        statements = [sql]

    # Classifier : setup vs testable
    setup_stmts: list[str] = []
    testable_query = ""

    for stmt in statements:
        trimmed = stmt.strip()
        if not trimmed:
            continue
        if is_setup_statement(trimmed):
            setup_stmts.append(trimmed)
        else:
            testable_query = trimmed  # Le dernier SELECT gagne

    # Exécuter les setup statements
    for setup in setup_stmts:
        engine.execute_block(setup)

    # Pas d'annotation → skip (mais exécuter le SELECT pour ses effets de bord)
    if not block.expected_cols and not block.expected_rows:
        if testable_query:
            clean = re.sub(r";\s*$", "", testable_query).strip()
            try:
                engine.execute_query(clean)
            except Exception:
                pass
        return TestResult(
            block.td_id, block.label, "skip",
            block.expected_cols, block.expected_rows, 0, 0,
            "pas d'annotation c:t",
        )

    # Pas de SELECT testable
    if not testable_query:
        return TestResult(
            block.td_id, block.label, "skip",
            block.expected_cols, block.expected_rows, 0, 0,
            "pas de requête testable (DDL/DML uniquement)",
        )

    # Nettoyer le ; final et les espaces
    clean_query = re.sub(r";\s*$", "", testable_query).strip()
    if not clean_query:
        return TestResult(
            block.td_id, block.label, "skip",
            block.expected_cols, block.expected_rows, 0, 0,
            "requête vide",
        )

    # Exécuter la requête
    try:
        result = engine.execute_query(clean_query)
    except Exception:
        return TestResult(
            block.td_id, block.label, "error",
            block.expected_cols, block.expected_rows, -1, -1,
            "erreur d'exécution SQL",
        )

    actual_rows = count_rows(result)
    actual_cols = count_cols(result)

    # Vérifier
    ok = True
    details = []

    exp_cols = block.expected_cols
    exp_rows = block.expected_rows

    if exp_cols and actual_cols != int(exp_cols):
        ok = False
        details.append(f"colonnes: attendu={exp_cols} reçu={actual_cols}")

    if exp_rows and actual_rows != int(exp_rows):
        ok = False
        details.append(f"lignes: attendu={exp_rows} reçu={actual_rows}")

    # Formater les chaînes attendu/reçu
    parts = []
    if exp_cols:
        parts.append(f"{exp_cols}c")
    if exp_rows:
        parts.append(f"{exp_rows}r")
    expected_str = " × ".join(parts)
    actual_str = f"{actual_cols}c × {actual_rows}r"

    if ok:
        return TestResult(
            block.td_id, block.label, "pass",
            exp_cols, exp_rows, actual_cols, actual_rows,
            f"attendu: {expected_str}, reçu: {actual_str}",
        )
    else:
        detail_str = " ".join(details)
        return TestResult(
            block.td_id, block.label, "fail",
            exp_cols, exp_rows, actual_cols, actual_rows,
            f"attendu: {expected_str}, reçu: {actual_str} — {detail_str}",
        )


# ── Affichage console ────────────────────────────────────────────────────────


def log_result(r: TestResult):
    """Affiche un résultat de test sur la console."""
    if r.status == "pass":
        print(f"  {GREEN}✓{NC} {r.label} — {r.message}")
    elif r.status == "fail":
        print(f"  {RED}✗{NC} {r.label} — {r.message}")
    elif r.status == "error":
        print(f"  {RED}•{NC} {r.label} — {r.message}")
    elif r.status == "skip":
        print(f"  {YELLOW}⊘{NC} {r.label} — {r.message}")


# ── Rapport CSV ──────────────────────────────────────────────────────────────


def write_csv_header(f):
    f.write("td_id;label;dbms;status;expected_cols;expected_rows;"
            "actual_cols;actual_rows\n")


def write_csv_row(f, r: TestResult, dbms: str):
    f.write(f"{r.td_id};{r.label};{dbms};{r.status};"
            f"{r.expected_cols};{r.expected_rows};"
            f"{r.actual_cols};{r.actual_rows}\n")


# ── Résolution des données ───────────────────────────────────────────────────


def resolve_data_dir(td_dir: Path, shared_data: Path) -> Path:
    """Résout le répertoire de données pour un TD.

    Retourne le chemin brut (sans résoudre les symlinks) pour que chaque
    TD avec son propre data/ déclenche un rechargement des données.
    """
    td_data = td_dir / "data"
    if td_data.is_dir():
        return td_data
    return shared_data


# ── Main ─────────────────────────────────────────────────────────────────────


def main():
    # --- Parsing des arguments ---
    dbms_name = "postgres"
    report_file = ""
    td_filter = ""

    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--report":
            report_file = args[i + 1]
            i += 2
        elif args[i] == "--td":
            td_filter = args[i + 1]
            i += 2
        else:
            dbms_name = args[i]
            i += 1

    # --- Initialiser le moteur ---
    engines = {
        "postgres": PostgresEngine,
        "sqlite":   SQLiteEngine,
        "oracle":   OracleEngine,
    }
    if dbms_name not in engines:
        print(f"SGBD inconnu : {dbms_name} (attendu: postgres, sqlite, oracle)",
              file=sys.stderr)
        sys.exit(1)
    engine = engines[dbms_name]()

    # --- Chemins ---
    script_dir = Path(__file__).resolve().parent
    project_dir = script_dir.parent
    shared_data = project_dir / "docs" / "shared" / "data"

    # --- Bannière ---
    print("╔══════════════════════════════════════════════════════╗")
    print(f"║  Test des corrections SQL — SGBD: {dbms_name}             ")
    print("╚══════════════════════════════════════════════════════╝")

    # --- Rapport CSV ---
    csv_file = None
    if report_file:
        os.makedirs(os.path.dirname(report_file) or ".", exist_ok=True)
        csv_file = open(report_file, "w", encoding="utf-8")
        write_csv_header(csv_file)

    # --- Découverte et test des fichiers de correction ---
    pass_count = 0
    fail_count = 0
    skip_count = 0
    failed_labels: list[str] = []

    last_data_dir = ""
    corrections = sorted(glob.glob(
        str(project_dir / "docs" / "r*" / "td*" / "*-correction.sql")))

    for correction_path in corrections:
        correction = Path(correction_path)
        td_dir = correction.parent
        td_name = td_dir.name
        resource_name = td_dir.parent.name
        td_id = f"{resource_name}/{td_name}"

        # Filtrer si demandé
        if td_filter and td_name != td_filter:
            continue

        # Résoudre le répertoire de données
        current_data_dir = resolve_data_dir(td_dir, shared_data)

        # Vérifier que les fichiers de données existent
        if not engine.has_data_files(current_data_dir):
            print()
            print(f"=== {YELLOW}Skipping: {td_id}"
                  f" — pas de données pour {dbms_name}{NC} ===")
            continue

        # Recharger les données si on change de répertoire
        data_dir_str = str(current_data_dir)
        if data_dir_str != last_data_dir:
            print(f"\nChargement du schéma et des données"
                  f" depuis {current_data_dir.name}...")
            engine.load_schema(current_data_dir)
            print("Données chargées.")
            last_data_dir = data_dir_str

        # Parser et tester
        print(f"\n=== Testing: {td_id} ({correction.name}) ===\n")

        blocks = parse_correction_file(correction, td_id)
        for block in blocks:
            result = test_block(engine, block)
            log_result(result)

            if csv_file:
                write_csv_row(csv_file, result, dbms_name)

            if result.status == "pass":
                pass_count += 1
            elif result.status in ("fail", "error"):
                fail_count += 1
                failed_labels.append(result.label + " — " + result.message)
            elif result.status == "skip":
                skip_count += 1

    if csv_file:
        csv_file.close()

    # --- Rapport final ---
    tested = pass_count + fail_count
    pct = (pass_count * 100 // tested) if tested > 0 else 0

    print()
    print("═══════════════════════════════════════════════════════")
    print(f"  {GREEN}✓ Passés  :{NC} {pass_count}")
    print(f"  {RED}✗ Échoués :{NC} {fail_count}")
    print("  ─────────────────────────────────────────────────────")
    print(f"  Testés    : {tested}  |  Taux de succès : {pct}%")
    if skip_count > 0:
        print(f"  {YELLOW}⊘ Ignorés :{NC} {skip_count} (non comptabilisés)")

    if failed_labels:
        print()
        print(f"  {RED}Tests échoués :{NC}")
        for lbl in failed_labels:
            print(f"    {RED}•{NC} {lbl}")
    print("═══════════════════════════════════════════════════════")

    sys.exit(fail_count)


if __name__ == "__main__":
    main()
