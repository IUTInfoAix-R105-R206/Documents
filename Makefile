# Makefile pour le projet "Exploitation d'une base de données"
# Génère les PDF des TD à partir des sources Markdown via Pandoc + LaTeX

PANDOC = pandoc
PDFLATEX = pdflatex
TEMPLATE_DIR = templates
FILTER_DIR = $(TEMPLATE_DIR)/filters
OUTPUT_DIR = output
DOCKER_PG_CONTAINER     = exploitation-bd-test-pg
DOCKER_ORACLE_CONTAINER = exploitation-bd-test-oracle

# Version : tag exact si le commit courant en a un, sinon SHA1 court
GIT_VERSION := $(shell git describe --exact-match --tags HEAD 2>/dev/null || git rev-parse --short HEAD)

# Options Pandoc communes
PANDOC_OPTS = \
	--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
	--pdf-engine=pdflatex \
	--pdf-engine-opt=-shell-escape \
	--template=$(TEMPLATE_DIR)/template.tex \
	--lua-filter=$(FILTER_DIR)/custom-styles.lua \
	--resource-path=.:$(TEMPLATE_DIR) \
	--variable=license-badge:$(TEMPLATE_DIR)/cc-by-nc-sa \
	--variable=version:$(GIT_VERSION) \
	--number-sections

# Lister tous les TD
TD_SOURCES = $(wildcard docs/*/td*-*.md)
TD_PDFS = $(patsubst docs/%,$(OUTPUT_DIR)/%,$(TD_SOURCES:.md=.pdf))

.PHONY: all clean td3 figures \
	test-sql-postgresql-local test-sql-postgresql-docker \
	test-sql-sqlite-local    test-sql-sqlite-docker    \
	test-sql-oracle-local    test-sql-oracle-docker    \
	help

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

all: $(TD_PDFS) ## Compile tous les TD

td3: $(OUTPUT_DIR)/td3/td3-interrogations-sql.pdf ## Compile le TD3

# Règle générique : compiler les figures standalone LaTeX
docs/%/figures/%.pdf: docs/%/figures/%.tex
	cd $(dir $<) && $(PDFLATEX) -interaction=nonstopmode $(notdir $<)

# Figures du TD3
TD3_FIGURES = docs/td3/figures/hierarchie-modules.pdf docs/td3/figures/mcd.pdf

docs/td3/figures/hierarchie-modules.pdf: docs/td3/figures/hierarchie-modules.tex
	cd docs/td3/figures && TEXINPUTS="$(CURDIR)/$(TEMPLATE_DIR):" $(PDFLATEX) -interaction=nonstopmode hierarchie-modules.tex

docs/td3/figures/mcd.pdf: docs/td3/figures/mcd.tex
	cd docs/td3/figures && TEXINPUTS="$(CURDIR)/$(TEMPLATE_DIR):" $(PDFLATEX) -interaction=nonstopmode mcd.tex

# Compilation TD3
$(OUTPUT_DIR)/td3/td3-interrogations-sql.pdf: docs/td3/td3-interrogations-sql.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(TD3_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/td3
	cd docs/td3 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../$(TEMPLATE_DIR):figures \
		--variable=license-badge:../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td3-interrogations-sql.md \
		-o ../../$@

# Validation SQL
test-sql-postgresql-local: ## Exécute les corrections SQL avec PostgreSQL local
	@echo "=== Validation des corrections SQL ==="
	./scripts/test-sql.sh

test-sql-postgresql-docker: ## Exécute les corrections SQL via un conteneur PostgreSQL Docker (sans PostgreSQL local requis)
	@command -v docker > /dev/null 2>&1 || { echo "Erreur : Docker n'est pas installé."; exit 1; }; \
	CONTAINER=$(DOCKER_PG_CONTAINER); \
	trap "docker stop $$CONTAINER > /dev/null 2>&1 || true" EXIT INT TERM; \
	docker rm -f $$CONTAINER > /dev/null 2>&1 || true; \
	echo "=== Démarrage du conteneur PostgreSQL ==="; \
	docker run --rm -d \
		--name $$CONTAINER \
		-e POSTGRES_USER=test \
		-e POSTGRES_PASSWORD=test \
		-e POSTGRES_DB=gestion_pedagogique \
		-v "$(CURDIR):/project" \
		docker.io/library/postgres:16 > /dev/null; \
	echo "En attente de PostgreSQL..."; \
	i=0; \
	until docker exec $$CONTAINER pg_isready -U test -d gestion_pedagogique > /dev/null 2>&1; do \
		sleep 1; i=$$((i+1)); \
		if [ $$i -ge 30 ]; then echo "Timeout : PostgreSQL ne répond pas."; exit 1; fi; \
	done; \
	echo "PostgreSQL prêt."; \
	docker exec \
		-e PGHOST=localhost \
		-e PGUSER=test \
		-e PGPASSWORD=test \
		-e PGDATABASE=gestion_pedagogique \
		$$CONTAINER \
		bash /project/scripts/test-sql.sh postgres

test-sql-sqlite-local: ## Exécute les corrections SQL avec SQLite local (aucune dépendance externe)
	@command -v sqlite3 > /dev/null 2>&1 || { echo "Erreur : sqlite3 n'est pas installé."; exit 1; }; \
	echo "=== Validation des corrections SQL (SQLite local) ==="; \
	SQLITE_DB=$$(mktemp /tmp/gestion_pedagogique_XXXXXX.db); \
	trap "rm -f $$SQLITE_DB" EXIT; \
	SQLITE_DB=$$SQLITE_DB ./scripts/test-sql.sh sqlite

test-sql-sqlite-docker: ## Exécute les corrections SQL avec SQLite dans un conteneur Docker
	@command -v docker > /dev/null 2>&1 || { echo "Erreur : Docker n'est pas installé."; exit 1; }; \
	echo "=== Validation des corrections SQL (SQLite dans Docker) ==="; \
	docker run --rm \
		-v "$(CURDIR):/project" \
		docker.io/library/debian:bookworm-slim \
		bash -c "apt-get update -qq && apt-get install -y -qq sqlite3 2>/dev/null && bash /project/scripts/test-sql.sh sqlite"

test-sql-oracle-local: ## Exécute les corrections SQL avec Oracle local (sqlplus requis)
	@command -v sqlplus > /dev/null 2>&1 || { echo "Erreur : sqlplus n'est pas installé."; exit 1; }; \
	echo "=== Validation des corrections SQL (Oracle local) ==="; \
	./scripts/test-sql.sh oracle

test-sql-oracle-docker: ## Exécute les corrections SQL via un conteneur Oracle Free Docker
	@command -v docker > /dev/null 2>&1 || { echo "Erreur : Docker n'est pas installé."; exit 1; }; \
	CONTAINER=$(DOCKER_ORACLE_CONTAINER); \
	trap "docker stop $$CONTAINER > /dev/null 2>&1 || true" EXIT INT TERM; \
	docker rm -f $$CONTAINER > /dev/null 2>&1 || true; \
	echo "=== Démarrage du conteneur Oracle Free (peut prendre 1-2 minutes) ==="; \
	docker run --rm -d \
		--name $$CONTAINER \
		-e ORACLE_PASSWORD=test \
		-v "$(CURDIR):/project" \
		docker.io/gvenzl/oracle-free:23.5 > /dev/null; \
	echo "En attente d'Oracle Free..."; \
	i=0; \
	until docker exec $$CONTAINER healthcheck.sh > /dev/null 2>&1; do \
		sleep 5; i=$$((i+5)); \
		if [ $$i -ge 180 ]; then echo "Timeout : Oracle Free ne répond pas."; exit 1; fi; \
		printf "  %ds/180s\r" $$i; \
	done; \
	echo "Oracle Free prêt."; \
	docker exec \
		-e ORACLE_USER=system \
		-e ORACLE_PASS=test \
		-e ORACLE_SID=FREEPDB1 \
		$$CONTAINER \
		bash /project/scripts/test-sql.sh oracle

clean: ## Supprime les fichiers générés
	rm -rf $(OUTPUT_DIR)
	find docs -name "*.aux" -o -name "*.log" -o -name "*.synctex*" | xargs rm -f
	find docs/*/figures -name "*.aux" -o -name "*.log" -o -name "*.pdf" | xargs rm -f
	find docs -type d -name "svg-inkscape" | xargs rm -rf
