#!/usr/bin/env bash
# test-sql.sh — Valide les corrections SQL contre le jeu de données de test
#
# Usage: ./scripts/test-sql.sh [DBMS] [--report FILE] [--td TD_NUM]
#
# Ce script :
# 1. Charge le schéma et les données de test dans la base
# 2. Extrait les requêtes et les résultats attendus depuis les fichiers de correction
# 3. Exécute chaque requête et vérifie le nombre de colonnes et de lignes
# 4. Affiche un rapport de test
# 5. Écrit un rapport CSV si --report FILE est spécifié

set -euo pipefail

# --- Configuration ---
DBMS="postgres"
TD_FILTER=""
REPORT_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --report) REPORT_FILE="$2"; shift 2 ;;
        --td)     TD_FILTER="$2";   shift 2 ;;
        *)        DBMS="$1";         shift   ;;
    esac
done
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_DIR/docs/shared/data"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
SKIP=0
FAILED_LABELS=()

# Initialiser le fichier rapport CSV si demandé
if [[ -n "$REPORT_FILE" ]]; then
    echo "td_id;label;dbms;status;expected_cols;expected_rows;actual_cols;actual_rows" > "$REPORT_FILE"
fi

# --- Fonctions utilitaires ---
log_pass() { echo -e "  ${GREEN}✓${NC} $1"; ((PASS += 1)); }
log_fail() { echo -e "  ${RED}✗${NC} $1"; ((FAIL += 1)); FAILED_LABELS+=("$1"); }
log_skip() { echo -e "  ${YELLOW}⊘${NC} $1"; ((SKIP += 1)); }

# --- Fonction d'exécution SQL selon le SGBD ---
# Exécute une requête SELECT unique et retourne le résultat tabulaire
run_sql() {
    local query="$1"
    case "$DBMS" in
        postgres)
            psql -h "${PGHOST:-localhost}" -U "${PGUSER:-test}" -d "${PGDATABASE:-gestion_pedagogique}" \
                 -t -A -F'|' -c "$query" 2>/dev/null
            ;;
        oracle)
            {
                echo "SET HEADING OFF"
                echo "SET FEEDBACK OFF"
                echo "SET PAGESIZE 0"
                echo "SET NEWPAGE NONE"
                echo "SET COLSEP '|'"
                echo "SET LINESIZE 32767"
                echo "SET TRIMOUT ON"
                echo "SET TRIMSPOOL ON"
                echo "SET VERIFY OFF"
                echo "SET NULL ''"
                echo "$query;"
                echo "EXIT"
            } | sqlplus -s "${ORACLE_USER:-system}/${ORACLE_PASS:-oracle}@${ORACLE_SID:-XE}" 2>/dev/null
            ;;
        sqlite)
            sqlite3 "${SQLITE_DB:-/tmp/gestion_pedagogique.db}" "$query" 2>/dev/null
            ;;
    esac
}

# Exécute un bloc SQL brut (multi-statement, DDL, PL/SQL) pour ses effets de bord
# Ne retourne rien d'utile — utilisé pour CREATE VIEW, DROP, INSERT, ALTER, PL/SQL
run_sql_block() {
    local block="$1"
    case "$DBMS" in
        postgres)
            psql -h "${PGHOST:-localhost}" -U "${PGUSER:-test}" -d "${PGDATABASE:-gestion_pedagogique}" \
                 -c "$block" > /dev/null 2>&1 || true
            ;;
        oracle)
            {
                echo "SET HEADING OFF"
                echo "SET FEEDBACK OFF"
                echo "SET PAGESIZE 0"
                echo "SET VERIFY OFF"
                echo "WHENEVER SQLERROR CONTINUE"
                echo "$block"
                echo "EXIT"
            } | sqlplus -s "${ORACLE_USER:-system}/${ORACLE_PASS:-oracle}@${ORACLE_SID:-XE}" > /dev/null 2>&1 || true
            ;;
        sqlite)
            sqlite3 "${SQLITE_DB:-/tmp/gestion_pedagogique.db}" "$block" > /dev/null 2>&1 || true
            ;;
    esac
}

# Compte les lignes d'un résultat (en ignorant les lignes vides)
count_rows() {
    echo "$1" | tr -d '\r' | grep -c '[^[:space:]]' 2>/dev/null || true
}

# Compte les colonnes d'un résultat (en ignorant les lignes vides)
count_cols() {
    echo "$1" | tr -d '\r' | grep -v '^[[:space:]]*$' | head -1 | awk -F'|' '{print NF}' || echo "0"
}

# --- Extraction et test des requêtes ---

# Sépare un bloc SQL en statements individuels.
# Gère les blocs PL/SQL (BEGIN...END; /) comme un seul statement.
# Retourne les statements séparés par un délimiteur NUL.
split_statements() {
    local block="$1"
    local current=""
    local in_plsql=false

    while IFS= read -r line; do
        # Détecter le début d'un bloc PL/SQL
        if [[ "$line" =~ ^[[:space:]]*(BEGIN|DECLARE) ]] && ! $in_plsql; then
            in_plsql=true
            current+="$line"$'\n'
            continue
        fi

        # Fin d'un bloc PL/SQL (ligne contenant juste /)
        if $in_plsql; then
            if [[ "$line" =~ ^[[:space:]]*/[[:space:]]*$ ]]; then
                current+="/"$'\n'
                printf '%s\0' "$current"
                current=""
                in_plsql=false
            else
                current+="$line"$'\n'
            fi
            continue
        fi

        # En dehors du PL/SQL, découper par ;
        if [[ "$line" =~ \;[[:space:]]*$ ]]; then
            current+="$line"$'\n'
            printf '%s\0' "$current"
            current=""
        else
            current+="$line"$'\n'
        fi
    done <<< "$block"

    # Reste éventuel (statement sans ; final)
    local trimmed
    trimmed=$(echo "$current" | sed '/^[[:space:]]*$/d')
    if [[ -n "$trimmed" ]]; then
        printf '%s\0' "$current"
    fi
}

# Détermine si un statement est un DDL/DML (non testable) ou un SELECT (testable)
is_setup_statement() {
    local stmt="$1"
    # Récupérer le premier mot significatif (ignorer espaces/newlines)
    local first_word
    first_word=$(echo "$stmt" | sed '/^[[:space:]]*$/d' | head -1 | sed 's/^[[:space:]]*//' | awk '{print toupper($1)}')
    case "$first_word" in
        CREATE|DROP|INSERT|UPDATE|DELETE|ALTER|BEGIN|DECLARE|GRANT|REVOKE|TRUNCATE|MERGE)
            return 0  # C'est un setup statement
            ;;
        *)
            return 1  # C'est un SELECT ou autre requête testable
            ;;
    esac
}

test_correction_file() {
    local correction_file="$1"
    local td_name resource_name
    td_name=$(basename "$(dirname "$correction_file")")
    resource_name=$(basename "$(dirname "$(dirname "$correction_file")")")

    local td_id="$resource_name/$td_name"

    echo ""
    echo "=== Testing: $td_id ($(basename "$correction_file")) ==="
    echo ""

    local current_block=""
    local current_label=""
    local expected_cols=""
    local expected_rows=""
    local in_query=false

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%$'\r'}"  # Supprimer le \r des fins de lignes Windows (CRLF)

        # Détecter les marqueurs de question avec résultats attendus
        # Format complet : -- Q1 - c:2, t:9
        if [[ "$line" =~ ^--\ Q([0-9]+).*c:([0-9]+).*t:([0-9]+) ]]; then
            # Si on avait un bloc en cours, le tester
            if [[ -n "$current_block" && -n "$current_label" ]]; then
                test_block "$td_id" "$current_label" "$current_block" "$expected_cols" "$expected_rows"
            fi

            current_label="Q${BASH_REMATCH[1]}"
            expected_cols="${BASH_REMATCH[2]}"
            expected_rows="${BASH_REMATCH[3]}"
            current_block=""
            in_query=false
            continue
        fi

        # Format partiel : -- QN - t:Y (seulement lignes, pas colonnes)
        if [[ "$line" =~ ^--\ Q([0-9]+)\ -\ t:([0-9]+) ]]; then
            if [[ -n "$current_block" && -n "$current_label" ]]; then
                test_block "$td_id" "$current_label" "$current_block" "$expected_cols" "$expected_rows"
            fi

            current_label="Q${BASH_REMATCH[1]}"
            expected_cols=""
            expected_rows="${BASH_REMATCH[2]}"
            current_block=""
            in_query=false
            continue
        fi

        # Format sans annotation : -- QN (sans c: ni t:)
        # Réinitialise les attentes pour éviter la propagation depuis la question précédente
        if [[ "$line" =~ ^--\ Q([0-9]+)[[:space:]]*$ ]]; then
            if [[ -n "$current_block" && -n "$current_label" ]]; then
                test_block "$td_id" "$current_label" "$current_block" "$expected_cols" "$expected_rows"
            fi

            current_label="Q${BASH_REMATCH[1]}"
            expected_cols=""
            expected_rows=""
            current_block=""
            in_query=false
            continue
        fi

        # Détecter les PROMPT (début d'une variante de requête)
        if [[ "$line" =~ ^PROMPT ]]; then
            # Si on avait un bloc en cours, le tester
            if [[ -n "$current_block" && -n "$current_label" ]]; then
                test_block "$td_id" "$current_label" "$current_block" "$expected_cols" "$expected_rows"
            fi

            # Extraire le label du PROMPT
            local prompt_label
            prompt_label=$(echo "$line" | sed 's/PROMPT "\(.*\)";/\1/')
            current_label="$prompt_label"
            current_block=""
            in_query=true
            continue
        fi

        # Accumuler les lignes SQL dans le bloc courant
        if $in_query; then
            if [[ "$line" =~ ^-- ]] || [[ -z "$line" ]]; then
                # Un commentaire après du SQL marque la fin du bloc
                if [[ -n "$current_block" && "$line" =~ ^-- ]]; then
                    in_query=false
                fi
                continue
            fi
            # Conserver les ; et sauts de ligne pour le support multi-statement
            current_block+="$line"$'\n'
        fi
    done < "$correction_file"

    # Tester le dernier bloc
    if [[ -n "$current_block" && -n "$current_label" ]]; then
        test_block "$td_id" "$current_label" "$current_block" "$expected_cols" "$expected_rows"
    fi
}

# Teste un bloc SQL (possiblement multi-statement).
# - Sépare le bloc en statements individuels
# - Exécute les DDL/DML (setup) via run_sql_block pour leurs effets de bord
# - Teste le dernier SELECT via run_sql et compare avec les attentes
test_block() {
    local td_id="$1"
    local label="$2"
    local block="$3"
    local exp_cols="$4"
    local exp_rows="$5"

    # Nettoyer le bloc (supprimer lignes vides de début/fin)
    block=$(echo "$block" | sed '/^[[:space:]]*$/d')

    if [[ -z "$block" ]]; then
        log_skip "$label — bloc vide"
        if [[ -n "$REPORT_FILE" ]]; then echo "$td_id;$label;$DBMS;skip;$exp_cols;$exp_rows;0;0" >> "$REPORT_FILE"; fi
        return
    fi

    # Séparer le bloc en statements
    local statements=()
    while IFS= read -r -d $'\0' stmt; do
        statements+=("$stmt")
    done < <(split_statements "$block")

    # Si aucun statement n'a été trouvé (bloc sans ;), traiter le bloc entier comme un statement
    if [[ ${#statements[@]} -eq 0 ]]; then
        statements=("$block")
    fi

    # Identifier les setup statements et le dernier SELECT testable
    local setup_stmts=()
    local testable_query=""

    for stmt in "${statements[@]}"; do
        # Nettoyer le statement
        local trimmed
        trimmed=$(echo "$stmt" | sed '/^[[:space:]]*$/d')
        [[ -z "$trimmed" ]] && continue

        if is_setup_statement "$trimmed"; then
            setup_stmts+=("$trimmed")
        else
            testable_query="$trimmed"
        fi
    done

    # Exécuter les setup statements (DDL/DML) pour leurs effets de bord
    for setup in "${setup_stmts[@]}"; do
        run_sql_block "$setup"
    done

    # Si pas d'annotation c:t (et pas de t: seul), skip le test mais exécuter quand même
    if [[ -z "$exp_cols" && -z "$exp_rows" ]]; then
        # Exécuter le SELECT pour ses effets de bord éventuels, mais ne pas tester
        if [[ -n "$testable_query" ]]; then
            # Nettoyer le ; final pour run_sql
            local clean_query
            clean_query=$(echo "$testable_query" | sed 's/;[[:space:]]*$//')
            run_sql "$clean_query" > /dev/null 2>&1 || true
        fi
        log_skip "$label — pas d'annotation c:t"
        if [[ -n "$REPORT_FILE" ]]; then echo "$td_id;$label;$DBMS;skip;;;0;0" >> "$REPORT_FILE"; fi
        return
    fi

    # Pas de SELECT testable mais des annotations → skip
    if [[ -z "$testable_query" ]]; then
        log_skip "$label — pas de requête testable (DDL/DML uniquement)"
        if [[ -n "$REPORT_FILE" ]]; then echo "$td_id;$label;$DBMS;skip;$exp_cols;$exp_rows;0;0" >> "$REPORT_FILE"; fi
        return
    fi

    # Nettoyer le ; final pour run_sql
    local clean_query
    clean_query=$(echo "$testable_query" | sed 's/;[[:space:]]*$//')
    clean_query=$(echo "$clean_query" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

    if [[ -z "$clean_query" ]]; then
        log_skip "$label — requête vide"
        if [[ -n "$REPORT_FILE" ]]; then echo "$td_id;$label;$DBMS;skip;$exp_cols;$exp_rows;0;0" >> "$REPORT_FILE"; fi
        return
    fi

    # Exécuter la requête testable
    local result
    result=$(run_sql "$clean_query" 2>&1) || {
        log_fail "$label — erreur d'exécution SQL"
        if [[ -n "$REPORT_FILE" ]]; then echo "$td_id;$label;$DBMS;error;$exp_cols;$exp_rows;-1;-1" >> "$REPORT_FILE"; fi
        return
    }

    # Compter lignes et colonnes
    local actual_rows actual_cols
    actual_rows=$(count_rows "$result")
    actual_cols=$(count_cols "$result")

    # Vérifier selon les annotations disponibles
    local ok=true
    local details=""

    if [[ -n "$exp_cols" && "$actual_cols" -ne "$exp_cols" ]]; then
        ok=false
        details+=" colonnes: attendu=$exp_cols reçu=$actual_cols"
    fi

    if [[ -n "$exp_rows" && "$actual_rows" -ne "$exp_rows" ]]; then
        ok=false
        details+=" lignes: attendu=$exp_rows reçu=$actual_rows"
    fi

    local expected_str=""
    [[ -n "$exp_cols" ]] && expected_str+="${exp_cols}c"
    [[ -n "$exp_cols" && -n "$exp_rows" ]] && expected_str+=" × "
    [[ -n "$exp_rows" ]] && expected_str+="${exp_rows}r"
    local actual_str="${actual_cols}c × ${actual_rows}r"

    if $ok; then
        log_pass "$label — attendu: $expected_str, reçu: $actual_str"
        if [[ -n "$REPORT_FILE" ]]; then echo "$td_id;$label;$DBMS;pass;$exp_cols;$exp_rows;$actual_cols;$actual_rows" >> "$REPORT_FILE"; fi
    else
        log_fail "$label — attendu: $expected_str, reçu: $actual_str —$details"
        if [[ -n "$REPORT_FILE" ]]; then echo "$td_id;$label;$DBMS;fail;$exp_cols;$exp_rows;$actual_cols;$actual_rows" >> "$REPORT_FILE"; fi
    fi
}

# --- Charger le schéma et les données ---
# Paramètre optionnel : répertoire de données (défaut : $DATA_DIR)
load_data() {
    local data_dir="${1:-$DATA_DIR}"
    echo "Chargement du schéma et des données depuis $(basename "$data_dir")..."
    case "$DBMS" in
        oracle)
            # Nettoyage complet : supprimer toutes les vues et tables du schéma
            # pour éviter les interférences entre TD utilisant des bases différentes
            {
                echo "WHENEVER SQLERROR CONTINUE"
                echo "BEGIN"
                echo "   FOR v IN (SELECT view_name FROM user_views)"
                echo "   LOOP"
                echo "      EXECUTE IMMEDIATE 'DROP VIEW \"' || v.view_name || '\"';"
                echo "   END LOOP;"
                echo "   FOR t IN (SELECT table_name FROM user_tables)"
                echo "   LOOP"
                echo "      EXECUTE IMMEDIATE 'DROP TABLE \"' || t.table_name || '\" CASCADE CONSTRAINTS PURGE';"
                echo "   END LOOP;"
                echo "END;"
                echo "/"
                echo "EXIT"
            } | sqlplus -s "${ORACLE_USER:-system}/${ORACLE_PASS:-oracle}@${ORACLE_SID:-XE}" > /dev/null 2>&1 || true
            # Cherche oracle.sql dans le répertoire du TD, sinon gestion-pedagogique-oracle.sql dans shared
            local oracle_file="$data_dir/oracle.sql"
            [[ -f "$oracle_file" ]] || oracle_file="$data_dir/gestion-pedagogique-oracle.sql"
            if [[ -f "$oracle_file" ]]; then
                {
                    cat "$oracle_file"
                    echo "EXIT"
                } | sqlplus -s "${ORACLE_USER:-system}/${ORACLE_PASS:-oracle}@${ORACLE_SID:-XE}" > /dev/null 2>&1 || true
            fi
            ;;
        sqlite)
            # SQLite : charger en filtrant les constructions non supportées
            # - CASCADE dans DROP TABLE (non supporté par SQLite)
            # - ALTER TABLE ADD CONSTRAINT / FOREIGN KEY (non supporté par SQLite)
            if [[ -f "$data_dir/schema.sql" ]]; then
                sed 's/ CASCADE//gi' "$data_dir/schema.sql" \
                    | sqlite3 "${SQLITE_DB:-/tmp/gestion_pedagogique.db}" 2>/dev/null || true
            fi
            if [[ -f "$data_dir/insert.sql" ]]; then
                sed '/ADD CONSTRAINT/,/;/d' "$data_dir/insert.sql" \
                    | sqlite3 "${SQLITE_DB:-/tmp/gestion_pedagogique.db}" 2>/dev/null || true
            fi
            ;;
        *)
            if [[ -f "$data_dir/schema.sql" ]]; then
                run_sql "$(cat "$data_dir/schema.sql")" > /dev/null 2>&1 || true
            fi
            if [[ -f "$data_dir/insert.sql" ]]; then
                run_sql "$(cat "$data_dir/insert.sql")" > /dev/null 2>&1 || true
            fi
            ;;
    esac
    echo "Données chargées."
}

# Résout le répertoire de données pour un TD :
# - docs/tdN/data/ si ce répertoire existe
# - sinon docs/shared/data/
resolve_data_dir() {
    local td_dir="$1"
    local td_data="$td_dir/data"
    if [[ -d "$td_data" ]]; then
        echo "$td_data"
    else
        echo "$DATA_DIR"
    fi
}

# Vérifie que les fichiers de données nécessaires existent pour le SGBD courant
has_data_files() {
    local data_dir="$1"
    case "$DBMS" in
        oracle)
            [[ -f "$data_dir/oracle.sql" ]]
            ;;
        *)
            [[ -f "$data_dir/schema.sql" ]]
            ;;
    esac
}

# --- Main ---
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Test des corrections SQL — SGBD: $DBMS             "
echo "╚══════════════════════════════════════════════════════╝"

# Trouver et tester les fichiers de correction (chargement des données par TD)
LAST_DATA_DIR=""
for correction in "$PROJECT_DIR"/docs/r*/td*/*-correction.sql; do
    [[ -f "$correction" ]] || continue
    td_abs_dir=$(dirname "$correction")
    td_name=$(basename "$td_abs_dir")

    # Filtrer si demandé
    if [[ -n "$TD_FILTER" && "$td_name" != "$TD_FILTER" ]]; then
        continue
    fi

    # Recharger les données si on change de TD (base de données différente)
    current_data_dir=$(resolve_data_dir "$td_abs_dir")

    # Vérifier que les fichiers de données existent pour ce SGBD
    if ! has_data_files "$current_data_dir"; then
        resource_name=$(basename "$(dirname "$td_abs_dir")")
        echo ""
        echo -e "=== ${YELLOW}Skipping: $resource_name/$td_name — pas de données pour $DBMS${NC} ==="
        continue
    fi

    if [[ "$current_data_dir" != "$LAST_DATA_DIR" ]]; then
        load_data "$current_data_dir"
        LAST_DATA_DIR="$current_data_dir"
    fi

    test_correction_file "$correction"
done

# Rapport final
TESTED=$((PASS + FAIL))
if [[ $TESTED -gt 0 ]]; then
    PCT=$(( PASS * 100 / TESTED ))
else
    PCT=0
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo -e "  ${GREEN}✓ Passés  :${NC} $PASS"
echo -e "  ${RED}✗ Échoués :${NC} $FAIL"
echo    "  ─────────────────────────────────────────────────"
echo    "  Testés    : $TESTED  |  Taux de succès : ${PCT}%"
if [[ $SKIP -gt 0 ]]; then
    echo -e "  ${YELLOW}⊘ Ignorés :${NC} $SKIP (non comptabilisés)"
fi

if [[ ${#FAILED_LABELS[@]} -gt 0 ]]; then
    echo ""
    echo -e "  ${RED}Tests échoués :${NC}"
    for lbl in "${FAILED_LABELS[@]}"; do
        echo -e "    ${RED}•${NC} $lbl"
    done
fi
echo "═══════════════════════════════════════════════════════"

exit $FAIL
