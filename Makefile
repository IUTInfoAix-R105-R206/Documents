# Makefile pour le projet "Exploitation d'une base de données"
# Génère les PDF des TD à partir des sources Markdown via Pandoc + LaTeX

PANDOC = pandoc
PDFLATEX = pdflatex
TEMPLATE_DIR = templates
FILTER_DIR = $(TEMPLATE_DIR)/filters
OUTPUT_DIR = output

# Options Pandoc communes
PANDOC_OPTS = \
	--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
	--pdf-engine=pdflatex \
	--template=$(TEMPLATE_DIR)/template.tex \
	--lua-filter=$(FILTER_DIR)/custom-styles.lua \
	--resource-path=.:$(TEMPLATE_DIR) \
	--variable=license-badge:$(TEMPLATE_DIR)/cc-by-nc-sa.png \
	--number-sections

# Lister tous les TD
TD_SOURCES = $(wildcard docs/*/td*-*.md)
TD_PDFS = $(patsubst docs/%,$(OUTPUT_DIR)/%,$(TD_SOURCES:.md=.pdf))

.PHONY: all clean td3 figures test-sql help

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
	cd docs/td3/figures && $(PDFLATEX) -interaction=nonstopmode hierarchie-modules.tex

docs/td3/figures/mcd.pdf: docs/td3/figures/mcd.tex
	cd docs/td3/figures && $(PDFLATEX) -interaction=nonstopmode mcd.tex

# Compilation TD3
$(OUTPUT_DIR)/td3/td3-interrogations-sql.pdf: docs/td3/td3-interrogations-sql.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(TD3_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/td3
	cd docs/td3 && $(PANDOC) $(PANDOC_OPTS) \
		--resource-path=.:../../$(TEMPLATE_DIR):figures \
		td3-interrogations-sql.md \
		-o ../../$@

# Validation SQL
test-sql: ## Exécute les corrections SQL et vérifie les résultats
	@echo "=== Validation des corrections SQL ==="
	./scripts/test-sql.sh

clean: ## Supprime les fichiers générés
	rm -rf $(OUTPUT_DIR)
	find docs -name "*.aux" -o -name "*.log" -o -name "*.synctex*" | xargs rm -f
	find docs/*/figures -name "*.aux" -o -name "*.log" | xargs rm -f
