# Makefile pour le projet "Bases de données"
# Génère les PDF des TD à partir des sources Markdown via Pandoc + LaTeX
# Ressources : R1.05 (Introduction aux BD et SQL), R2.06 (Exploitation d'une BD)

PANDOC = pandoc
PDFLATEX = pdflatex
PYTHON = python3
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

# Lister tous les TD (sources Markdown) dans docs/r*/td*/
TD_SOURCES = $(shell find docs/r*/td* -name 'td*.md' ! -name '*.gen.md' 2>/dev/null)
TD_PDFS = $(patsubst docs/%,$(OUTPUT_DIR)/%,$(TD_SOURCES:.md=.pdf))

# Corrections PDF (générées depuis le SQL annoté)
R105_CORRECTION_PDFS = \
	$(OUTPUT_DIR)/r1.05/td6/td6-correction.pdf \
	$(OUTPUT_DIR)/r1.05/td7/td7-correction.pdf

R206_CORRECTION_PDFS = \
	$(OUTPUT_DIR)/r2.06/td1/td1-correction.pdf \
	$(OUTPUT_DIR)/r2.06/td2/td2-correction.pdf \
	$(OUTPUT_DIR)/r2.06/td3/td3-correction.pdf \
	$(OUTPUT_DIR)/r2.06/td4/td4-correction.pdf \
	$(OUTPUT_DIR)/r2.06/td5/td5-correction.pdf \
	$(OUTPUT_DIR)/r2.06/td6/td6-correction.pdf

.PHONY: all clean r105 r206 r105-corrections r206-corrections \
	test-sql-postgresql-local test-sql-postgresql-docker \
	test-sql-sqlite-local    test-sql-sqlite-docker    \
	test-sql-oracle-local    test-sql-oracle-docker    \
	test-sql-docker \
	help

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: r105 r206 ## Compile tous les TD (sujets + corrigés)

# --- Cibles par ressource ---

r105: $(filter $(OUTPUT_DIR)/r1.05/%,$(TD_PDFS)) $(R105_CORRECTION_PDFS) ## Compile tous les TD de R1.05 (sujets + corrigés)

r206: $(filter $(OUTPUT_DIR)/r2.06/%,$(TD_PDFS)) $(R206_CORRECTION_PDFS) ## Compile tous les TD de R2.06 (sujets + corrigés)

r105-corrections: $(R105_CORRECTION_PDFS) ## Compile uniquement les corrigés de R1.05

r206-corrections: $(R206_CORRECTION_PDFS) ## Compile uniquement les corrigés de R2.06

# ==============================================================================
# R2.06 — Exploitation d'une base de données
# ==============================================================================

# --- TD1 : Opérateurs ensemblistes, LDD et LCT (BD Voyages) ---

R206_TD1_FIGURES = docs/r2.06/td1/figures/mcd.pdf

docs/r2.06/td1/figures/mcd.pdf: docs/r2.06/td1/figures/mcd.tex
	cd docs/r2.06/td1/figures && TEXINPUTS="$(CURDIR)/$(TEMPLATE_DIR):" $(PDFLATEX) -interaction=nonstopmode mcd.tex

# Génération du Markdown depuis le SQL annoté
R206_TD1_SQL = docs/r2.06/td1/td1-correction.sql
R206_TD1_TEMPLATE = docs/r2.06/td1/td1.md
R206_TD1_GEN = scripts/generate-questions.py

docs/r2.06/td1/td1.gen.md: $(R206_TD1_TEMPLATE) $(R206_TD1_SQL) $(R206_TD1_GEN)
	$(PYTHON) $(R206_TD1_GEN) --mode subject --template $< --output $@ $(word 2,$^)

docs/r2.06/td1/td1-correction.gen.md: $(R206_TD1_TEMPLATE) $(R206_TD1_SQL) $(R206_TD1_GEN)
	$(PYTHON) $(R206_TD1_GEN) --mode correction --template $< --output $@ $(word 2,$^)

$(OUTPUT_DIR)/r2.06/td1/td1.pdf: docs/r2.06/td1/td1.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R206_TD1_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/r2.06/td1
	cd docs/r2.06/td1 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR):figures \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td1.gen.md \
		-o ../../../$@

$(OUTPUT_DIR)/r2.06/td1/td1-correction.pdf: docs/r2.06/td1/td1-correction.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R206_TD1_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/r2.06/td1
	cd docs/r2.06/td1 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR):figures \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td1-correction.gen.md \
		-o ../../../$@

# --- TD2 : Jointures externes, partitionnement et synthèse (BD Voyages) ---

R206_TD2_FIGURES = docs/r2.06/td2/figures/mcd.pdf

docs/r2.06/td2/figures/mcd.pdf: docs/r2.06/td2/figures/mcd.tex
	cd docs/r2.06/td2/figures && TEXINPUTS="$(CURDIR)/$(TEMPLATE_DIR):" $(PDFLATEX) -interaction=nonstopmode mcd.tex

# Génération du Markdown depuis le SQL annoté
R206_TD2_SQL = docs/r2.06/td2/td2-correction.sql
R206_TD2_TEMPLATE = docs/r2.06/td2/td2.md
R206_TD2_GEN = scripts/generate-questions.py

docs/r2.06/td2/td2.gen.md: $(R206_TD2_TEMPLATE) $(R206_TD2_SQL) $(R206_TD2_GEN)
	$(PYTHON) $(R206_TD2_GEN) --mode subject --template $< --output $@ $(word 2,$^)

docs/r2.06/td2/td2-correction.gen.md: $(R206_TD2_TEMPLATE) $(R206_TD2_SQL) $(R206_TD2_GEN)
	$(PYTHON) $(R206_TD2_GEN) --mode correction --template $< --output $@ $(word 2,$^)

$(OUTPUT_DIR)/r2.06/td2/td2.pdf: docs/r2.06/td2/td2.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R206_TD2_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/r2.06/td2
	cd docs/r2.06/td2 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR):figures \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td2.gen.md \
		-o ../../../$@

$(OUTPUT_DIR)/r2.06/td2/td2-correction.pdf: docs/r2.06/td2/td2-correction.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R206_TD2_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/r2.06/td2
	cd docs/r2.06/td2 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR):figures \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td2-correction.gen.md \
		-o ../../../$@

# --- TD3 : Interrogations en SQL (BD Gestion pédagogique) ---

R206_TD3_FIGURES = docs/r2.06/td3/figures/hierarchie-modules.pdf docs/r2.06/td3/figures/mcd.pdf

docs/r2.06/td3/figures/hierarchie-modules.pdf: docs/r2.06/td3/figures/hierarchie-modules.tex
	cd docs/r2.06/td3/figures && TEXINPUTS="$(CURDIR)/$(TEMPLATE_DIR):" $(PDFLATEX) -interaction=nonstopmode hierarchie-modules.tex

docs/r2.06/td3/figures/mcd.pdf: docs/r2.06/td3/figures/mcd.tex
	cd docs/r2.06/td3/figures && TEXINPUTS="$(CURDIR)/$(TEMPLATE_DIR):" $(PDFLATEX) -interaction=nonstopmode mcd.tex

# Génération du Markdown depuis le SQL annoté
R206_TD3_SQL = docs/r2.06/td3/td3-correction.sql
R206_TD3_TEMPLATE = docs/r2.06/td3/td3.md
R206_TD3_GEN = scripts/generate-questions.py

docs/r2.06/td3/td3.gen.md: $(R206_TD3_TEMPLATE) $(R206_TD3_SQL) $(R206_TD3_GEN)
	$(PYTHON) $(R206_TD3_GEN) --mode subject --template $< --output $@ $(word 2,$^)

docs/r2.06/td3/td3-correction.gen.md: $(R206_TD3_TEMPLATE) $(R206_TD3_SQL) $(R206_TD3_GEN)
	$(PYTHON) $(R206_TD3_GEN) --mode correction --template $< --output $@ $(word 2,$^)

$(OUTPUT_DIR)/r2.06/td3/td3.pdf: docs/r2.06/td3/td3.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R206_TD3_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/r2.06/td3
	cd docs/r2.06/td3 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR):figures \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td3.gen.md \
		-o ../../../$@

$(OUTPUT_DIR)/r2.06/td3/td3-correction.pdf: docs/r2.06/td3/td3-correction.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R206_TD3_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/r2.06/td3
	cd docs/r2.06/td3 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR):figures \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td3-correction.gen.md \
		-o ../../../$@

# --- TD4 : Recherche récursive, division et requêtes complexes (BD Questionnaire) ---

R206_TD4_FIGURES = docs/r2.06/td4/figures/mcd.pdf docs/r2.06/td4/figures/hierarchie-themes.pdf

docs/r2.06/td4/figures/mcd.pdf: docs/r2.06/td4/figures/mcd.tex
	cd docs/r2.06/td4/figures && TEXINPUTS="$(CURDIR)/$(TEMPLATE_DIR):" $(PDFLATEX) -interaction=nonstopmode mcd.tex

docs/r2.06/td4/figures/hierarchie-themes.pdf: docs/r2.06/td4/figures/hierarchie-themes.tex
	cd docs/r2.06/td4/figures && TEXINPUTS="$(CURDIR)/$(TEMPLATE_DIR):" $(PDFLATEX) -interaction=nonstopmode hierarchie-themes.tex

# Génération du Markdown depuis le SQL annoté
R206_TD4_SQL = docs/r2.06/td4/td4-correction.sql
R206_TD4_TEMPLATE = docs/r2.06/td4/td4.md
R206_TD4_GEN = scripts/generate-questions.py

docs/r2.06/td4/td4.gen.md: $(R206_TD4_TEMPLATE) $(R206_TD4_SQL) $(R206_TD4_GEN)
	$(PYTHON) $(R206_TD4_GEN) --mode subject --template $< --output $@ $(word 2,$^)

docs/r2.06/td4/td4-correction.gen.md: $(R206_TD4_TEMPLATE) $(R206_TD4_SQL) $(R206_TD4_GEN)
	$(PYTHON) $(R206_TD4_GEN) --mode correction --template $< --output $@ $(word 2,$^)

$(OUTPUT_DIR)/r2.06/td4/td4.pdf: docs/r2.06/td4/td4.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R206_TD4_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/r2.06/td4
	cd docs/r2.06/td4 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR):figures \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td4.gen.md \
		-o ../../../$@

$(OUTPUT_DIR)/r2.06/td4/td4-correction.pdf: docs/r2.06/td4/td4-correction.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R206_TD4_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/r2.06/td4
	cd docs/r2.06/td4 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR):figures \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td4-correction.gen.md \
		-o ../../../$@

# --- TD5 : Interrogations avancées en SQL (BD Gestion pédagogique) ---

R206_TD5_FIGURES = docs/r2.06/td5/figures/mcd.pdf docs/r2.06/td5/figures/hierarchie-modules.pdf

docs/r2.06/td5/figures/mcd.pdf: docs/r2.06/td5/figures/mcd.tex
	cd docs/r2.06/td5/figures && TEXINPUTS="$(CURDIR)/$(TEMPLATE_DIR):" $(PDFLATEX) -interaction=nonstopmode mcd.tex

docs/r2.06/td5/figures/hierarchie-modules.pdf: docs/r2.06/td5/figures/hierarchie-modules.tex
	cd docs/r2.06/td5/figures && TEXINPUTS="$(CURDIR)/$(TEMPLATE_DIR):" $(PDFLATEX) -interaction=nonstopmode hierarchie-modules.tex

# Génération du Markdown depuis le SQL annoté
R206_TD5_SQL = docs/r2.06/td5/td5-correction.sql
R206_TD5_TEMPLATE = docs/r2.06/td5/td5.md
R206_TD5_GEN = scripts/generate-questions.py

docs/r2.06/td5/td5.gen.md: $(R206_TD5_TEMPLATE) $(R206_TD5_SQL) $(R206_TD5_GEN)
	$(PYTHON) $(R206_TD5_GEN) --mode subject --template $< --output $@ $(word 2,$^)

docs/r2.06/td5/td5-correction.gen.md: $(R206_TD5_TEMPLATE) $(R206_TD5_SQL) $(R206_TD5_GEN)
	$(PYTHON) $(R206_TD5_GEN) --mode correction --template $< --output $@ $(word 2,$^)

$(OUTPUT_DIR)/r2.06/td5/td5.pdf: docs/r2.06/td5/td5.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R206_TD5_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/r2.06/td5
	cd docs/r2.06/td5 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR):figures \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td5.gen.md \
		-o ../../../$@

$(OUTPUT_DIR)/r2.06/td5/td5-correction.pdf: docs/r2.06/td5/td5-correction.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R206_TD5_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/r2.06/td5
	cd docs/r2.06/td5 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR):figures \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td5-correction.gen.md \
		-o ../../../$@

# --- TD6 : Vues, tables système et rappels SQL (BD Gestion pédagogique) ---

R206_TD6_FIGURES = docs/r2.06/td6/figures/mcd.pdf docs/r2.06/td6/figures/hierarchie-modules.pdf

docs/r2.06/td6/figures/mcd.pdf: docs/r2.06/td6/figures/mcd.tex
	cd docs/r2.06/td6/figures && TEXINPUTS="$(CURDIR)/$(TEMPLATE_DIR):" $(PDFLATEX) -interaction=nonstopmode mcd.tex

docs/r2.06/td6/figures/hierarchie-modules.pdf: docs/r2.06/td6/figures/hierarchie-modules.tex
	cd docs/r2.06/td6/figures && TEXINPUTS="$(CURDIR)/$(TEMPLATE_DIR):" $(PDFLATEX) -interaction=nonstopmode hierarchie-modules.tex

# Génération du Markdown depuis le SQL annoté
R206_TD6_SQL = docs/r2.06/td6/td6-correction.sql
R206_TD6_TEMPLATE = docs/r2.06/td6/td6.md
R206_TD6_GEN = scripts/generate-questions.py

docs/r2.06/td6/td6.gen.md: $(R206_TD6_TEMPLATE) $(R206_TD6_SQL) $(R206_TD6_GEN)
	$(PYTHON) $(R206_TD6_GEN) --mode subject --template $< --output $@ $(word 2,$^)

docs/r2.06/td6/td6-correction.gen.md: $(R206_TD6_TEMPLATE) $(R206_TD6_SQL) $(R206_TD6_GEN)
	$(PYTHON) $(R206_TD6_GEN) --mode correction --template $< --output $@ $(word 2,$^)

$(OUTPUT_DIR)/r2.06/td6/td6.pdf: docs/r2.06/td6/td6.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R206_TD6_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/r2.06/td6
	cd docs/r2.06/td6 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR):figures \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td6.gen.md \
		-o ../../../$@

$(OUTPUT_DIR)/r2.06/td6/td6-correction.pdf: docs/r2.06/td6/td6-correction.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R206_TD6_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/r2.06/td6
	cd docs/r2.06/td6 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR):figures \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td6-correction.gen.md \
		-o ../../../$@

# ==============================================================================
# R1.05 — Introduction aux bases de données et SQL
# ==============================================================================

# --- TD5 : Conception avec le modèle Entité/Association ---

$(OUTPUT_DIR)/r1.05/td5/td5.pdf: docs/r1.05/td5/td5.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua
	@mkdir -p $(OUTPUT_DIR)/r1.05/td5
	cd docs/r1.05/td5 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR) \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		td5.md \
		-o ../../../$@

# --- TD6 : Interrogation en SQL (BD Airbase) ---

R105_TD6_FIGURES = docs/r1.05/td6/figures/mcd.pdf

docs/r1.05/td6/figures/mcd.pdf: docs/r1.05/td6/figures/mcd.tex
	cd docs/r1.05/td6/figures && TEXINPUTS="$(CURDIR)/$(TEMPLATE_DIR):" $(PDFLATEX) -interaction=nonstopmode mcd.tex

# Génération du Markdown depuis le SQL annoté
R105_TD6_SQL = docs/r1.05/td6/td6-correction.sql
R105_TD6_TEMPLATE = docs/r1.05/td6/td6.md
R105_TD6_GEN = scripts/generate-questions.py

docs/r1.05/td6/td6.gen.md: $(R105_TD6_TEMPLATE) $(R105_TD6_SQL) $(R105_TD6_GEN)
	$(PYTHON) $(R105_TD6_GEN) --mode subject --template $< --output $@ $(word 2,$^)

docs/r1.05/td6/td6-correction.gen.md: $(R105_TD6_TEMPLATE) $(R105_TD6_SQL) $(R105_TD6_GEN)
	$(PYTHON) $(R105_TD6_GEN) --mode correction --template $< --output $@ $(word 2,$^)

$(OUTPUT_DIR)/r1.05/td6/td6.pdf: docs/r1.05/td6/td6.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R105_TD6_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/r1.05/td6
	cd docs/r1.05/td6 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR):figures \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td6.gen.md \
		-o ../../../$@

$(OUTPUT_DIR)/r1.05/td6/td6-correction.pdf: docs/r1.05/td6/td6-correction.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R105_TD6_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/r1.05/td6
	cd docs/r1.05/td6 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR):figures \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td6-correction.gen.md \
		-o ../../../$@

# --- TD7 : Interrogation en SQL interprété (BD Voyages) ---

R105_TD7_FIGURES = docs/r1.05/td7/figures/mcd.pdf

docs/r1.05/td7/figures/mcd.pdf: docs/r1.05/td7/figures/mcd.tex
	cd docs/r1.05/td7/figures && TEXINPUTS="$(CURDIR)/$(TEMPLATE_DIR):" $(PDFLATEX) -interaction=nonstopmode mcd.tex

# Génération du Markdown depuis le SQL annoté
R105_TD7_SQL = docs/r1.05/td7/td7-correction.sql
R105_TD7_TEMPLATE = docs/r1.05/td7/td7.md
R105_TD7_GEN = scripts/generate-questions.py

docs/r1.05/td7/td7.gen.md: $(R105_TD7_TEMPLATE) $(R105_TD7_SQL) $(R105_TD7_GEN)
	$(PYTHON) $(R105_TD7_GEN) --mode subject --template $< --output $@ $(word 2,$^)

docs/r1.05/td7/td7-correction.gen.md: $(R105_TD7_TEMPLATE) $(R105_TD7_SQL) $(R105_TD7_GEN)
	$(PYTHON) $(R105_TD7_GEN) --mode correction --template $< --output $@ $(word 2,$^)

$(OUTPUT_DIR)/r1.05/td7/td7.pdf: docs/r1.05/td7/td7.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R105_TD7_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/r1.05/td7
	cd docs/r1.05/td7 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR):figures \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td7.gen.md \
		-o ../../../$@

$(OUTPUT_DIR)/r1.05/td7/td7-correction.pdf: docs/r1.05/td7/td7-correction.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R105_TD7_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/r1.05/td7
	cd docs/r1.05/td7 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR):figures \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td7-correction.gen.md \
		-o ../../../$@

# ==============================================================================
# Validation SQL
# ==============================================================================

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

test-sql-docker: ## Exécute les corrections SQL avec tous les SGBD via Docker (continue même en cas d'échec)
	@rc=0; \
	$(MAKE) test-sql-postgresql-docker || rc=1; \
	$(MAKE) test-sql-sqlite-docker     || rc=1; \
	$(MAKE) test-sql-oracle-docker     || rc=1; \
	exit $$rc

# ==============================================================================
# Nettoyage
# ==============================================================================

clean: ## Supprime les fichiers générés
	rm -rf $(OUTPUT_DIR)
	find docs -name "*.gen.md" | xargs rm -f
	find docs -name "*.aux" -o -name "*.log" -o -name "*.synctex*" | xargs rm -f
	find docs -path "*/figures/*.aux" -o -path "*/figures/*.log" -o -path "*/figures/*.pdf" | xargs rm -f
	find docs -type d -name "svg-inkscape" | xargs rm -rf
