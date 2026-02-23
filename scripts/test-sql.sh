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
    echo "label;dbms;status;expected_cols;expected_rows;actual_cols;actual_rows" > "$REPORT_FILE"
fi

# --- Fonctions utilitaires ---
log_pass() { echo -e "  ${GREEN}✓${NC} $1"; ((PASS += 1)); }
log_fail() { echo -e "  ${RED}✗${NC} $1"; ((FAIL += 1)); FAILED_LABELS+=("$1"); }
log_skip() { echo -e "  ${YELLOW}⊘${NC} $1"; ((SKIP += 1)); }

# --- Fonction d'exécution SQL selon le SGBD ---
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

# Compte les lignes d'un résultat (en ignorant les lignes vides)
count_rows() {
    echo "$1" | grep -c '[^[:space:]]' 2>/dev/null || true
}

# Compte les colonnes d'un résultat (en ignorant les lignes vides)
count_cols() {
    echo "$1" | grep -v '^[[:space:]]*$' | head -1 | awk -F'|' '{print NF}'
}

# --- Extraction et test des requêtes ---
test_correction_file() {
    local correction_file="$1"
    local td_name
    td_name=$(basename "$(dirname "$correction_file")")
    
    echo ""
    echo "=== Testing: $td_name ($(basename "$correction_file")) ==="
    echo ""

    local current_query=""
    local current_label=""
    local expected_cols=""
    local expected_rows=""
    local in_query=false

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%$'\r'}"  # Supprimer le \r des fins de lignes Windows (CRLF)
        # Détecter les marqueurs de question avec résultats attendus
        # Format: -- Q1 - c:2, t:9
        if [[ "$line" =~ ^--\ Q([0-9]+).*c:([0-9]+).*t:([0-9]+) ]]; then
            # Si on avait une requête en cours, la tester
            if [[ -n "$current_query" && -n "$current_label" ]]; then
                test_query "$current_label" "$current_query" "$expected_cols" "$expected_rows"
            fi
            
            current_label="Q${BASH_REMATCH[1]}"
            expected_cols="${BASH_REMATCH[2]}"
            expected_rows="${BASH_REMATCH[3]}"
            current_query=""
            in_query=false
            continue
        fi

        # Détecter les PROMPT (début d'une variante de requête)
        if [[ "$line" =~ ^PROMPT ]]; then
            # Si on avait une requête en cours, la tester
            if [[ -n "$current_query" && -n "$current_label" ]]; then
                test_query "$current_label" "$current_query" "$expected_cols" "$expected_rows"
            fi
            
            # Extraire le label du PROMPT
            local prompt_label
            prompt_label=$(echo "$line" | sed 's/PROMPT "\(.*\)";/\1/')
            current_label="$prompt_label"
            current_query=""
            in_query=true
            continue
        fi

        # Ignorer les commentaires et lignes vides quand on construit la requête
        if $in_query; then
            if [[ "$line" =~ ^-- ]] || [[ -z "$line" ]]; then
                # Si on a déjà du contenu dans la requête et on rencontre un commentaire,
                # ça pourrait être la fin de la requête
                if [[ -n "$current_query" && "$line" =~ ^-- ]]; then
                    in_query=false
                fi
                continue
            fi
            # Ajouter la ligne à la requête (en enlevant le ; final)
            current_query+=" ${line%;}"
        fi
    done < "$correction_file"

    # Tester la dernière requête
    if [[ -n "$current_query" && -n "$current_label" ]]; then
        test_query "$current_label" "$current_query" "$expected_cols" "$expected_rows"
    fi
}

test_query() {
    local label="$1"
    local query="$2"
    local exp_cols="$3"
    local exp_rows="$4"

    # Nettoyer la requête
    query=$(echo "$query" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

    if [[ -z "$query" ]]; then
        log_skip "$label — requête vide"
        if [[ -n "$REPORT_FILE" ]]; then echo "$label;$DBMS;skip;$exp_cols;$exp_rows;0;0" >> "$REPORT_FILE"; fi
        return
    fi

    # Exécuter la requête
    local result
    result=$(run_sql "$query" 2>&1) || {
        log_fail "$label — erreur d'exécution SQL"
        if [[ -n "$REPORT_FILE" ]]; then echo "$label;$DBMS;error;$exp_cols;$exp_rows;-1;-1" >> "$REPORT_FILE"; fi
        return
    }

    # Compter lignes et colonnes
    local actual_rows actual_cols
    actual_rows=$(count_rows "$result")
    actual_cols=$(count_cols "$result")

    local expected="${exp_cols}c × ${exp_rows}r"
    local actual="${actual_cols}c × ${actual_rows}r"

    # Vérifier
    if [[ "$actual_rows" -eq "$exp_rows" && "$actual_cols" -eq "$exp_cols" ]]; then
        log_pass "$label — attendu: $expected, reçu: $actual"
        if [[ -n "$REPORT_FILE" ]]; then echo "$label;$DBMS;pass;$exp_cols;$exp_rows;$actual_cols;$actual_rows" >> "$REPORT_FILE"; fi
    else
        local details=""
        if [[ "$actual_cols" -ne "$exp_cols" ]]; then
            details+=" colonnes: attendu=$exp_cols reçu=$actual_cols"
        fi
        if [[ "$actual_rows" -ne "$exp_rows" ]]; then
            details+=" lignes: attendu=$exp_rows reçu=$actual_rows"
        fi
        log_fail "$label — attendu: $expected, reçu: $actual —$details"
        if [[ -n "$REPORT_FILE" ]]; then echo "$label;$DBMS;fail;$exp_cols;$exp_rows;$actual_cols;$actual_rows" >> "$REPORT_FILE"; fi
    fi
}

# --- Charger le schéma et les données ---
load_data() {
    echo "Chargement du schéma et des données..."
    case "$DBMS" in
        oracle)
            local oracle_file="$DATA_DIR/gestion-pedagogique-oracle.sql"
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
            if [[ -f "$DATA_DIR/schema.sql" ]]; then
                sed 's/ CASCADE//gi' "$DATA_DIR/schema.sql" \
                    | sqlite3 "${SQLITE_DB:-/tmp/gestion_pedagogique.db}" 2>/dev/null || true
            fi
            if [[ -f "$DATA_DIR/insert.sql" ]]; then
                sed '/ADD CONSTRAINT/,/;/d' "$DATA_DIR/insert.sql" \
                    | sqlite3 "${SQLITE_DB:-/tmp/gestion_pedagogique.db}" 2>/dev/null || true
            fi
            ;;
        *)
            if [[ -f "$DATA_DIR/schema.sql" ]]; then
                run_sql "$(cat "$DATA_DIR/schema.sql")" > /dev/null 2>&1 || true
            fi
            if [[ -f "$DATA_DIR/insert.sql" ]]; then
                run_sql "$(cat "$DATA_DIR/insert.sql")" > /dev/null 2>&1 || true
            fi
            ;;
    esac
    echo "Données chargées."
}

# --- Main ---
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Test des corrections SQL — SGBD: $DBMS             "
echo "╚══════════════════════════════════════════════════════╝"

# Charger les données
load_data

# Trouver et tester les fichiers de correction
for correction in "$PROJECT_DIR"/docs/td*/*-correction.sql; do
    [[ -f "$correction" ]] || continue
    td_dir=$(basename "$(dirname "$correction")")
    
    # Filtrer si demandé
    if [[ -n "$TD_FILTER" && "$td_dir" != "$TD_FILTER" ]]; then
        continue
    fi
    
    test_correction_file "$correction"
done

# Rapport final
TOTAL=$((PASS + FAIL + SKIP))
if [[ $TOTAL -gt 0 ]]; then
    PCT=$(( PASS * 100 / TOTAL ))
else
    PCT=0
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo -e "  ${GREEN}✓ Passés  :${NC} $PASS"
echo -e "  ${RED}✗ Échoués :${NC} $FAIL"
echo -e "  ${YELLOW}⊘ Ignorés :${NC} $SKIP"
echo    "  ─────────────────────────────────────────────────"
echo    "  Total     : $TOTAL tests  |  Taux de succès : ${PCT}%"

if [[ ${#FAILED_LABELS[@]} -gt 0 ]]; then
    echo ""
    echo -e "  ${RED}Tests échoués :${NC}"
    for lbl in "${FAILED_LABELS[@]}"; do
        echo -e "    ${RED}•${NC} $lbl"
    done
fi
echo "═══════════════════════════════════════════════════════"

exit $FAIL
