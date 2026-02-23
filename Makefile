# Makefile pour le projet "Exploitation d'une base de données"
# Génère les PDF des TD à partir des sources Markdown via Pandoc + LaTeX

PANDOC = pandoc
PDFLATEX = pdflatex
TEMPLATE_DIR = templates
FILTER_DIR = $(TEMPLATE_DIR)/filters
OUTPUT_DIR = output
DOCKER_PG_CONTAINER = exploitation-bd-test-pg

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

.PHONY: all clean td3 figures test-sql test-sql-docker test-sql-sqlite help

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
test-sql: ## Exécute les corrections SQL (PostgreSQL local requis)
	@echo "=== Validation des corrections SQL ==="
	./scripts/test-sql.sh

test-sql-docker: ## Exécute les corrections SQL via un conteneur PostgreSQL Docker (sans PostgreSQL local requis)
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

test-sql-sqlite: ## Exécute les corrections SQL avec SQLite (aucune dépendance externe)
	@command -v sqlite3 > /dev/null 2>&1 || { echo "Erreur : sqlite3 n'est pas installé."; exit 1; }; \
	echo "=== Validation des corrections SQL (SQLite) ==="; \
	SQLITE_DB=$$(mktemp /tmp/gestion_pedagogique_XXXXXX.db); \
	trap "rm -f $$SQLITE_DB" EXIT; \
	./scripts/test-sql.sh sqlite

clean: ## Supprime les fichiers générés
	rm -rf $(OUTPUT_DIR)
	find docs -name "*.aux" -o -name "*.log" -o -name "*.synctex*" | xargs rm -f
	find docs/*/figures -name "*.aux" -o -name "*.log" | xargs rm -f
