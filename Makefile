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
DOCKER_SQLITE_CONTAINER = exploitation-bd-test-sqlite
DOCKER_ORACLE_CONTAINER = exploitation-bd-test-oracle

# Variables optionnelles pour les tests SQL (passées sur la ligne de commande)
# Usage : make test-sql-sqlite-local REPORT=results.csv TD=td3
REPORT =
TD =
_TEST_SQL_FLAGS = $(if $(REPORT),--report $(REPORT)) $(if $(TD),--td $(TD))

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
	$(OUTPUT_DIR)/r1.05/td1/td1-correction.pdf \
	$(OUTPUT_DIR)/r1.05/td2/td2-correction.pdf \
	$(OUTPUT_DIR)/r1.05/td6/td6-correction.pdf \
	$(OUTPUT_DIR)/r1.05/td7/td7-correction.pdf

R206_CORRECTION_PDFS = \
	$(OUTPUT_DIR)/r2.06/td1/td1-correction.pdf \
	$(OUTPUT_DIR)/r2.06/td2/td2-correction.pdf \
	$(OUTPUT_DIR)/r2.06/td3/td3-correction.pdf \
	$(OUTPUT_DIR)/r2.06/td4/td4-correction.pdf \
	$(OUTPUT_DIR)/r2.06/td5/td5-correction.pdf \
	$(OUTPUT_DIR)/r2.06/td6/td6-correction.pdf

# Corrigés enseignant (avec remarques @remark_teacher)
R105_TEACHER_PDFS = \
	$(OUTPUT_DIR)/r1.05/td6/td6-teacher.pdf \
	$(OUTPUT_DIR)/r1.05/td7/td7-teacher.pdf

R206_TEACHER_PDFS = \
	$(OUTPUT_DIR)/r2.06/td1/td1-teacher.pdf \
	$(OUTPUT_DIR)/r2.06/td2/td2-teacher.pdf \
	$(OUTPUT_DIR)/r2.06/td3/td3-teacher.pdf \
	$(OUTPUT_DIR)/r2.06/td4/td4-teacher.pdf \
	$(OUTPUT_DIR)/r2.06/td5/td5-teacher.pdf \
	$(OUTPUT_DIR)/r2.06/td6/td6-teacher.pdf

.PHONY: all clean r105 r206 r105-corrections r206-corrections teacher guide \
	test-sql-postgresql-local test-sql-postgresql-docker \
	test-sql-sqlite-local    test-sql-sqlite-docker    \
	test-sql-oracle-local    test-sql-oracle-docker    \
	test-sql-local test-sql-docker \
	web-td7 verify-web-td7 serve-web-td7 publish-web-td7 \
	web-td6 verify-web-td6 serve-web-td6 publish-web-td6 \
	web-td1-algebre verify-web-td1-algebre serve-web-td1-algebre publish-web-td1-algebre \
	web-td2-immobilier verify-web-td2-immobilier serve-web-td2-immobilier publish-web-td2-immobilier \
	web-td2-airbase verify-web-td2-airbase serve-web-td2-airbase publish-web-td2-airbase \
	clean-corrections bump help

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Variables optionnelles pour les tests SQL :"
	@echo "  \033[36mREPORT=file.csv\033[0m   Génère un rapport CSV (ex: make test-sql-sqlite-local REPORT=results.csv)"
	@echo "  \033[36mTD=tdN\033[0m            Filtre sur un TD spécifique (ex: make test-sql-oracle-docker TD=td3)"

all: r105 r206 guide ## Compile tous les TD (sujets + corrigés) et le guide

# --- Cibles par ressource ---

r105: $(filter $(OUTPUT_DIR)/r1.05/%,$(TD_PDFS)) $(R105_CORRECTION_PDFS) ## Compile tous les TD de R1.05 (sujets + corrigés)

r206: $(filter $(OUTPUT_DIR)/r2.06/%,$(TD_PDFS)) $(R206_CORRECTION_PDFS) ## Compile tous les TD de R2.06 (sujets + corrigés)

r105-corrections: $(R105_CORRECTION_PDFS) ## Compile uniquement les corrigés de R1.05

r206-corrections: $(R206_CORRECTION_PDFS) ## Compile uniquement les corrigés de R2.06

teacher: $(R105_TEACHER_PDFS) $(R206_TEACHER_PDFS) ## Compile les corrigés enseignant (avec @remark_teacher)

# ==============================================================================
# R2.06 - Exploitation d'une base de données
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

docs/r2.06/td1/td1-teacher.gen.md: $(R206_TD1_TEMPLATE) $(R206_TD1_SQL) $(R206_TD1_GEN)
	$(PYTHON) $(R206_TD1_GEN) --mode teacher --template $< --output $@ $(word 2,$^)

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

$(OUTPUT_DIR)/r2.06/td1/td1-teacher.pdf: docs/r2.06/td1/td1-teacher.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R206_TD1_FIGURES)
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
		td1-teacher.gen.md \
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

docs/r2.06/td2/td2-teacher.gen.md: $(R206_TD2_TEMPLATE) $(R206_TD2_SQL) $(R206_TD2_GEN)
	$(PYTHON) $(R206_TD2_GEN) --mode teacher --template $< --output $@ $(word 2,$^)

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

$(OUTPUT_DIR)/r2.06/td2/td2-teacher.pdf: docs/r2.06/td2/td2-teacher.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R206_TD2_FIGURES)
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
		td2-teacher.gen.md \
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

docs/r2.06/td3/td3-teacher.gen.md: $(R206_TD3_TEMPLATE) $(R206_TD3_SQL) $(R206_TD3_GEN)
	$(PYTHON) $(R206_TD3_GEN) --mode teacher --template $< --output $@ $(word 2,$^)

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

$(OUTPUT_DIR)/r2.06/td3/td3-teacher.pdf: docs/r2.06/td3/td3-teacher.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R206_TD3_FIGURES)
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
		td3-teacher.gen.md \
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

docs/r2.06/td4/td4-teacher.gen.md: $(R206_TD4_TEMPLATE) $(R206_TD4_SQL) $(R206_TD4_GEN)
	$(PYTHON) $(R206_TD4_GEN) --mode teacher --template $< --output $@ $(word 2,$^)

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

$(OUTPUT_DIR)/r2.06/td4/td4-teacher.pdf: docs/r2.06/td4/td4-teacher.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R206_TD4_FIGURES)
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
		td4-teacher.gen.md \
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

docs/r2.06/td5/td5-teacher.gen.md: $(R206_TD5_TEMPLATE) $(R206_TD5_SQL) $(R206_TD5_GEN)
	$(PYTHON) $(R206_TD5_GEN) --mode teacher --template $< --output $@ $(word 2,$^)

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

$(OUTPUT_DIR)/r2.06/td5/td5-teacher.pdf: docs/r2.06/td5/td5-teacher.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R206_TD5_FIGURES)
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
		td5-teacher.gen.md \
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

docs/r2.06/td6/td6-teacher.gen.md: $(R206_TD6_TEMPLATE) $(R206_TD6_SQL) $(R206_TD6_GEN)
	$(PYTHON) $(R206_TD6_GEN) --mode teacher --template $< --output $@ $(word 2,$^)

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

$(OUTPUT_DIR)/r2.06/td6/td6-teacher.pdf: docs/r2.06/td6/td6-teacher.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R206_TD6_FIGURES)
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
		td6-teacher.gen.md \
		-o ../../../$@

# ==============================================================================
# R1.05 - Introduction aux bases de données et SQL
# ==============================================================================

# --- TD1 : L'algèbre relationnelle ---

$(OUTPUT_DIR)/r1.05/td1/td1.pdf: docs/r1.05/td1/td1.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua
	@mkdir -p $(OUTPUT_DIR)/r1.05/td1
	cd docs/r1.05/td1 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR) \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td1.md \
		-o ../../../$@

$(OUTPUT_DIR)/r1.05/td1/td1-correction.pdf: docs/r1.05/td1/td1-correction.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua
	@mkdir -p $(OUTPUT_DIR)/r1.05/td1
	cd docs/r1.05/td1 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR) \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		td1-correction.md \
		-o ../../../$@

# --- TD2 : Concepts relationnels et langage algébrique ---

$(OUTPUT_DIR)/r1.05/td2/td2.pdf: docs/r1.05/td2/td2.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua
	@mkdir -p $(OUTPUT_DIR)/r1.05/td2
	cd docs/r1.05/td2 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR) \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		td2.md \
		-o ../../../$@

$(OUTPUT_DIR)/r1.05/td2/td2-correction.pdf: docs/r1.05/td2/td2-correction.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua
	@mkdir -p $(OUTPUT_DIR)/r1.05/td2
	cd docs/r1.05/td2 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR) \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		td2-correction.md \
		-o ../../../$@

# --- TD3 : Dépendances fonctionnelles et normalisation ---

$(OUTPUT_DIR)/r1.05/td3/td3.pdf: docs/r1.05/td3/td3.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua
	@mkdir -p $(OUTPUT_DIR)/r1.05/td3
	cd docs/r1.05/td3 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR) \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		td3.md \
		-o ../../../$@

# --- TD4 : Modèle Entité/Association et traduction relationnelle ---

R105_TD4_FIGURES = docs/r1.05/td4/figures/gestion-artistique-1.pdf \
	docs/r1.05/td4/figures/gestion-artistique-2.pdf \
	docs/r1.05/td4/figures/gestion-sportive-1.pdf \
	docs/r1.05/td4/figures/gestion-sportive-2.pdf

docs/r1.05/td4/figures/%.pdf: docs/r1.05/td4/figures/%.tex
	cd docs/r1.05/td4/figures && TEXINPUTS="$(CURDIR)/$(TEMPLATE_DIR):" $(PDFLATEX) -interaction=nonstopmode $*.tex

$(OUTPUT_DIR)/r1.05/td4/td4.pdf: docs/r1.05/td4/td4.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R105_TD4_FIGURES)
	@mkdir -p $(OUTPUT_DIR)/r1.05/td4
	cd docs/r1.05/td4 && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../../$(TEMPLATE_DIR):figures \
		--variable=license-badge:../../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		td4.md \
		-o ../../../$@

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

docs/r1.05/td6/td6-teacher.gen.md: $(R105_TD6_TEMPLATE) $(R105_TD6_SQL) $(R105_TD6_GEN)
	$(PYTHON) $(R105_TD6_GEN) --mode teacher --template $< --output $@ $(word 2,$^)

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

$(OUTPUT_DIR)/r1.05/td6/td6-teacher.pdf: docs/r1.05/td6/td6-teacher.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R105_TD6_FIGURES)
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
		td6-teacher.gen.md \
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

docs/r1.05/td7/td7-teacher.gen.md: $(R105_TD7_TEMPLATE) $(R105_TD7_SQL) $(R105_TD7_GEN)
	$(PYTHON) $(R105_TD7_GEN) --mode teacher --template $< --output $@ $(word 2,$^)

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

$(OUTPUT_DIR)/r1.05/td7/td7-teacher.pdf: docs/r1.05/td7/td7-teacher.gen.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua $(R105_TD7_FIGURES)
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
		td7-teacher.gen.md \
		-o ../../../$@

# ==============================================================================
# Guide de bonnes pratiques SQL
# ==============================================================================

guide: $(OUTPUT_DIR)/guide-bonnes-pratiques-sql.pdf ## Compile le guide de bonnes pratiques SQL

$(OUTPUT_DIR)/guide-bonnes-pratiques-sql.pdf: docs/shared/guide-bonnes-pratiques-sql.md $(TEMPLATE_DIR)/template.tex $(FILTER_DIR)/custom-styles.lua
	@mkdir -p $(OUTPUT_DIR)
	cd docs/shared && $(PANDOC) \
		--from markdown+footnotes+definition_lists+fenced_divs+bracketed_spans \
		--pdf-engine=pdflatex \
		--pdf-engine-opt=-shell-escape \
		--template=../../$(TEMPLATE_DIR)/template.tex \
		--lua-filter=../../$(FILTER_DIR)/custom-styles.lua \
		--resource-path=.:../../$(TEMPLATE_DIR) \
		--variable=license-badge:../../$(TEMPLATE_DIR)/cc-by-nc-sa \
		--variable=version:$(GIT_VERSION) \
		--number-sections \
		guide-bonnes-pratiques-sql.md \
		-o ../../$@

# ==============================================================================
# Validation SQL
# ==============================================================================

lint-sql: ## Vérifie le style des corrections SQL avec SQLFluff
	sqlfluff lint docs/

fix-sql: ## Corrige automatiquement le style des corrections SQL avec SQLFluff
	sqlfluff fix docs/

install-hooks: ## Installe les hooks Git du projet (pre-commit SQLFluff)
	git config core.hooksPath .githooks
	@echo "Hooks Git installés (.githooks/). Le pre-commit lancera sqlfluff fix automatiquement."

test-sql-postgresql-local: ## Exécute les corrections SQL avec PostgreSQL local
	@echo "=== Validation des corrections SQL (PostgreSQL local) ==="
	$(PYTHON) scripts/test-sql.py postgres $(_TEST_SQL_FLAGS)

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
		docker.io/library/postgres:16 > /dev/null; \
	echo "En attente de PostgreSQL..."; \
	i=0; \
	until docker exec $$CONTAINER pg_isready -U test -d gestion_pedagogique > /dev/null 2>&1; do \
		sleep 1; i=$$((i+1)); \
		if [ $$i -ge 30 ]; then echo "Timeout : PostgreSQL ne répond pas."; exit 1; fi; \
	done; \
	echo "PostgreSQL prêt."; \
	PGHOST=localhost \
	PGUSER=test \
	PGPASSWORD=test \
	PGDATABASE=gestion_pedagogique \
	PG_DOCKER_CONTAINER=$$CONTAINER \
	$(PYTHON) scripts/test-sql.py postgres $(_TEST_SQL_FLAGS)

test-sql-sqlite-local: ## Exécute les corrections SQL avec SQLite local (aucune dépendance externe)
	@command -v sqlite3 > /dev/null 2>&1 || { echo "Erreur : sqlite3 n'est pas installé."; exit 1; }; \
	echo "=== Validation des corrections SQL (SQLite local) ==="; \
	SQLITE_DB=$$(mktemp /tmp/gestion_pedagogique_XXXXXX.db); \
	trap "rm -f $$SQLITE_DB" EXIT; \
	SQLITE_DB=$$SQLITE_DB $(PYTHON) scripts/test-sql.py sqlite $(_TEST_SQL_FLAGS)

test-sql-sqlite-docker: ## Exécute les corrections SQL avec SQLite dans un conteneur Docker
	@command -v docker > /dev/null 2>&1 || { echo "Erreur : Docker n'est pas installé."; exit 1; }; \
	CONTAINER=$(DOCKER_SQLITE_CONTAINER); \
	trap "docker stop $$CONTAINER > /dev/null 2>&1 || true" EXIT INT TERM; \
	docker rm -f $$CONTAINER > /dev/null 2>&1 || true; \
	echo "=== Validation des corrections SQL (SQLite dans Docker) ==="; \
	docker run --rm -d --name $$CONTAINER docker.io/library/debian:bookworm-slim sleep infinity > /dev/null; \
	docker exec $$CONTAINER sh -c "apt-get update -qq && apt-get install -y -qq sqlite3 > /dev/null 2>&1"; \
	SQLITE_DOCKER_CONTAINER=$$CONTAINER \
	SQLITE_DB=/tmp/gestion_pedagogique.db \
	$(PYTHON) scripts/test-sql.py sqlite $(_TEST_SQL_FLAGS)

test-sql-oracle-local: ## Exécute les corrections SQL avec Oracle (local ou docker exec)
	@if [ -z "$$ORACLE_DOCKER_CONTAINER" ]; then \
		command -v sqlplus > /dev/null 2>&1 || { echo "Erreur : sqlplus n'est pas installé."; exit 1; }; \
	fi; \
	echo "=== Validation des corrections SQL (Oracle) ==="; \
	$(PYTHON) scripts/test-sql.py oracle $(_TEST_SQL_FLAGS)

test-sql-oracle-docker: ## Exécute les corrections SQL via un conteneur Oracle Free Docker
	@command -v docker > /dev/null 2>&1 || { echo "Erreur : Docker n'est pas installé."; exit 1; }; \
	CONTAINER=$(DOCKER_ORACLE_CONTAINER); \
	trap "docker stop $$CONTAINER > /dev/null 2>&1 || true" EXIT INT TERM; \
	docker rm -f $$CONTAINER > /dev/null 2>&1 || true; \
	echo "=== Démarrage du conteneur Oracle Free (peut prendre 1-2 minutes) ==="; \
	docker run --rm -d \
		--name $$CONTAINER \
		-e ORACLE_PASSWORD=test \
		-e APP_USER=testuser \
		-e APP_USER_PASSWORD=test \
		docker.io/gvenzl/oracle-free:23.5 > /dev/null; \
	echo "En attente d'Oracle Free..."; \
	i=0; \
	until docker exec $$CONTAINER healthcheck.sh > /dev/null 2>&1; do \
		sleep 5; i=$$((i+5)); \
		if [ $$i -ge 180 ]; then echo "Timeout : Oracle Free ne répond pas."; exit 1; fi; \
		printf "  %ds/180s\r" $$i; \
	done; \
	echo "Oracle Free prêt."; \
	ORACLE_USER=testuser \
	ORACLE_PASS=test \
	ORACLE_SID=FREEPDB1 \
	ORACLE_DOCKER_CONTAINER=$$CONTAINER \
	$(PYTHON) scripts/test-sql.py oracle $(_TEST_SQL_FLAGS)

test-sql-local: ## Exécute les corrections SQL avec tous les SGBD locaux (continue même en cas d'échec)
	@rc=0; \
	$(MAKE) test-sql-postgresql-local || rc=1; \
	$(MAKE) test-sql-sqlite-local     || rc=1; \
	$(MAKE) test-sql-oracle-local     || rc=1; \
	exit $$rc

test-sql-docker: ## Exécute les corrections SQL avec tous les SGBD via Docker (continue même en cas d'échec)
	@rc=0; \
	$(MAKE) test-sql-postgresql-docker || rc=1; \
	$(MAKE) test-sql-sqlite-docker     || rc=1; \
	$(MAKE) test-sql-oracle-docker     || rc=1; \
	exit $$rc

# ==============================================================================
# Corrections nettoyées (pour la release)
# ==============================================================================

CORRECTION_SQLS = $(shell find docs -name '*-correction.sql' 2>/dev/null)
CLEAN_CORRECTIONS = $(patsubst docs/%,$(OUTPUT_DIR)/%,$(CORRECTION_SQLS))

$(OUTPUT_DIR)/%-correction.sql: docs/%-correction.sql scripts/strip-sql-annotations.py
	@mkdir -p $(dir $@)
	$(PYTHON) scripts/strip-sql-annotations.py $< -o $@

clean-corrections: $(CLEAN_CORRECTIONS) ## Génère les corrections SQL nettoyées (sans annotations)

# ==============================================================================
# Sites web des TD (SQLite WASM)
# ==============================================================================
# Génère un site statique par TP : sql.js exécute les requêtes des étudiants dans
# le navigateur, le résultat est comparé à un hash SHA-256 précalculé (la correction
# n'est jamais embarquée). Le générateur émet aussi un sidecar output/web-verify/
# (solutions + fixtures) qui NE DOIT PAS être publié.

NODE ?= node
WEB_TD_TEMPLATE = $(TEMPLATE_DIR)/web-td

# PDF sujets consommés par les pages web (copiés dans le site + lien « Ouvrir le sujet »).
# Absents en local (non compilés) → --pdf omis via $(wildcard), la page est générée sans
# lien (dégradation propre). En CI, l'artefact « td-pdfs » de build.yml les fournit.
WEB_TD6_PDF          = $(OUTPUT_DIR)/r1.05/td6/td6.pdf
WEB_TD7_PDF          = $(OUTPUT_DIR)/r1.05/td7/td7.pdf
WEB_TD1_ALGEBRE_PDF  = $(OUTPUT_DIR)/r1.05/td1/td1.pdf
WEB_TD2_PDF          = $(OUTPUT_DIR)/r1.05/td2/td2.pdf
pdf-arg = $(if $(wildcard $(1)),--pdf $(1),)

web-td7: ## Génère le site web du TD7 R1.05 (output/web/td7)
	$(PYTHON) scripts/generate-web-td.py docs/r1.05/td7/td7-correction.sql \
		--data-dir docs/shared/data/voyages \
		--output $(OUTPUT_DIR)/web/td7 --verify-out $(OUTPUT_DIR)/web-verify/td7 \
		--td-id r1.05-td7 --td-label "R1.05 - TD7" --template-dir $(WEB_TD_TEMPLATE) \
		$(call pdf-arg,$(WEB_TD7_PDF))

verify-web-td7: web-td7 ## Vérifie hash Python == hash WASM pour toutes les questions du TD7
	$(NODE) scripts/verify-web-td.mjs $(OUTPUT_DIR)/web/td7 $(OUTPUT_DIR)/web-verify/td7

serve-web-td7: web-td7 ## Sert le site du TD7 en local (http://localhost:8000)
	@echo "→ http://localhost:8000  (Ctrl-C pour arrêter)"
	@cd $(OUTPUT_DIR)/web/td7 && $(PYTHON) -m http.server 8000

publish-web-td7: verify-web-td7 ## Publie le site du TD7 dans le dépôt étudiant (WEB_TD7_REPO=chemin)
	@if [ -z "$(WEB_TD7_REPO)" ]; then \
		echo "Erreur : définissez WEB_TD7_REPO=chemin/vers/depot"; exit 1; fi
	scripts/publish-web-td.sh $(OUTPUT_DIR)/web/td7 $(WEB_TD7_REPO)

web-td6: ## Génère le site web du TD6 R1.05 (output/web/td6)
	$(PYTHON) scripts/generate-web-td.py docs/r1.05/td6/td6-correction.sql \
		--data-dir docs/shared/data/airbase \
		--output $(OUTPUT_DIR)/web/td6 --verify-out $(OUTPUT_DIR)/web-verify/td6 \
		--td-id r1.05-td6 --td-label "R1.05 - TD6" --template-dir $(WEB_TD_TEMPLATE) \
		$(call pdf-arg,$(WEB_TD6_PDF))

verify-web-td6: web-td6 ## Vérifie hash Python == hash WASM pour toutes les questions du TD6
	$(NODE) scripts/verify-web-td.mjs $(OUTPUT_DIR)/web/td6 $(OUTPUT_DIR)/web-verify/td6

serve-web-td6: web-td6 ## Sert le site du TD6 en local (http://localhost:8000)
	@echo "→ http://localhost:8000  (Ctrl-C pour arrêter)"
	@cd $(OUTPUT_DIR)/web/td6 && $(PYTHON) -m http.server 8000

publish-web-td6: verify-web-td6 ## Publie le site du TD6 dans le dépôt étudiant (WEB_TD6_REPO=chemin)
	@if [ -z "$(WEB_TD6_REPO)" ]; then \
		echo "Erreur : définissez WEB_TD6_REPO=chemin/vers/depot"; exit 1; fi
	scripts/publish-web-td.sh $(OUTPUT_DIR)/web/td6 $(WEB_TD6_REPO)

web-td1-algebre: ## Génère le site web d'algèbre du TD1 R1.05 (output/web/td1-algebre)
	$(PYTHON) scripts/generate-web-td-algebra.py docs/r1.05/td1/td1-correction.md \
		--data-dir docs/shared/data/airbase \
		--output $(OUTPUT_DIR)/web/td1-algebre --verify-out $(OUTPUT_DIR)/web-verify/td1-algebre \
		--td-id r1.05-td1-algebre --td-label "R1.05 - TD1 (algèbre)" \
		--title "Requêtes avec le langage algébrique" \
		--manifest docs/r1.05/td1/web-td.json --template-dir $(WEB_TD_TEMPLATE) \
		$(call pdf-arg,$(WEB_TD1_ALGEBRE_PDF))

verify-web-td1-algebre: web-td1-algebre ## Vérifie hash Python == hash WASM pour le TD1 algèbre
	$(NODE) scripts/verify-web-td-algebra.mjs $(OUTPUT_DIR)/web/td1-algebre $(OUTPUT_DIR)/web-verify/td1-algebre

serve-web-td1-algebre: web-td1-algebre ## Sert le site du TD1 algèbre en local (http://localhost:8000)
	@echo "→ http://localhost:8000  (Ctrl-C pour arrêter)"
	@cd $(OUTPUT_DIR)/web/td1-algebre && $(PYTHON) -m http.server 8000

publish-web-td1-algebre: verify-web-td1-algebre ## Publie le TD1 algèbre dans le dépôt étudiant (WEB_TD1_ALGEBRE_REPO=chemin)
	@if [ -z "$(WEB_TD1_ALGEBRE_REPO)" ]; then \
		echo "Erreur : définissez WEB_TD1_ALGEBRE_REPO=chemin/vers/depot"; exit 1; fi
	scripts/publish-web-td.sh $(OUTPUT_DIR)/web/td1-algebre $(WEB_TD1_ALGEBRE_REPO)

web-td2-immobilier: ## Génère le site d'algèbre du TD2 R1.05 exercice 2 (agence immobilière)
	$(PYTHON) scripts/generate-web-td-algebra.py docs/r1.05/td2/td2-correction.md \
		--data-dir docs/shared/data/immobilier \
		--output $(OUTPUT_DIR)/web/td2-immobilier --verify-out $(OUTPUT_DIR)/web-verify/td2-immobilier \
		--td-id r1.05-td2-immobilier --td-label "R1.05 - TD2 (agence immobilière)" \
		--title "Agence immobilière - langage algébrique" \
		--section-marker "Exercice n° 2" --schema-md docs/r1.05/td2/td2.md \
		--manifest docs/r1.05/td2/web-td-ex2.json --template-dir $(WEB_TD_TEMPLATE) \
		$(call pdf-arg,$(WEB_TD2_PDF))

verify-web-td2-immobilier: web-td2-immobilier ## Vérifie hash Python == hash WASM pour le TD2 immobilier
	$(NODE) scripts/verify-web-td-algebra.mjs $(OUTPUT_DIR)/web/td2-immobilier $(OUTPUT_DIR)/web-verify/td2-immobilier

serve-web-td2-immobilier: web-td2-immobilier ## Sert le site du TD2 immobilier en local (http://localhost:8000)
	@echo "→ http://localhost:8000  (Ctrl-C pour arrêter)"
	@cd $(OUTPUT_DIR)/web/td2-immobilier && $(PYTHON) -m http.server 8000

publish-web-td2-immobilier: verify-web-td2-immobilier ## Publie le TD2 immobilier dans le sous-dossier immobilier/ (WEB_TD2_REPO=chemin)
	@if [ -z "$(WEB_TD2_REPO)" ]; then \
		echo "Erreur : définissez WEB_TD2_REPO=chemin/vers/depot"; exit 1; fi
	scripts/publish-web-td.sh $(OUTPUT_DIR)/web/td2-immobilier $(WEB_TD2_REPO) immobilier

WEB_TD2_AIRBASE_SCHEMA_EXTRA = <strong>PILOTE</strong> (<u>NUMPIL</u>, NOMPIL, ADR, SALAIRE)|<strong>AVION</strong> (<u>NUMAV</u>, NOMAV, CAPACITE, LOCALISATION)|<strong>VOL</strong> (<u>NUMVOL</u>, <em>NUMPIL\#</em>, <em>NUMAV\#</em>, VILLE_DEP, VILLE_ARR)

web-td2-airbase: ## Génère le site d'algèbre du TD2 R1.05 exercice 1 (Airbase, formations)
	$(PYTHON) scripts/generate-web-td-algebra.py docs/r1.05/td2/td2-correction.md \
		--data-dir docs/shared/data/airbase-td2 \
		--output $(OUTPUT_DIR)/web/td2-airbase --verify-out $(OUTPUT_DIR)/web-verify/td2-airbase \
		--td-id r1.05-td2-airbase --td-label "R1.05 - TD2 (Airbase, formations)" \
		--title "Airbase - langage algébrique" \
		--section-marker "Exercice n° 1" --schema-md docs/r1.05/td2/td2.md \
		--schema-extra '$(WEB_TD2_AIRBASE_SCHEMA_EXTRA)' \
		--manifest docs/r1.05/td2/web-td-ex1.json --template-dir $(WEB_TD_TEMPLATE) \
		$(call pdf-arg,$(WEB_TD2_PDF))

verify-web-td2-airbase: web-td2-airbase ## Vérifie hash Python == hash WASM pour le TD2 Airbase
	$(NODE) scripts/verify-web-td-algebra.mjs $(OUTPUT_DIR)/web/td2-airbase $(OUTPUT_DIR)/web-verify/td2-airbase

serve-web-td2-airbase: web-td2-airbase ## Sert le site du TD2 Airbase en local (http://localhost:8000)
	@echo "→ http://localhost:8000  (Ctrl-C pour arrêter)"
	@cd $(OUTPUT_DIR)/web/td2-airbase && $(PYTHON) -m http.server 8000

publish-web-td2-airbase: verify-web-td2-airbase ## Publie le TD2 Airbase dans le sous-dossier airbase/ (WEB_TD2_REPO=chemin)
	@if [ -z "$(WEB_TD2_REPO)" ]; then \
		echo "Erreur : définissez WEB_TD2_REPO=chemin/vers/depot"; exit 1; fi
	scripts/publish-web-td.sh $(OUTPUT_DIR)/web/td2-airbase $(WEB_TD2_REPO) airbase

# ── Pages minimales (lien PDF seul) : R1.05 TD3/TD4/TD5 (sans contenu interactif) ──
# Ces TD se font sur feuille (dépendances fonctionnelles, modèle E/A) : la page ne
# contient qu'un lien vers le PDF du sujet, copié dans le dépôt étudiant pour rester
# accessible quand Documents sera privé. Le PDF doit exister (make r105 / artefact CI).
WEB_TD3_PDF = $(OUTPUT_DIR)/r1.05/td3/td3.pdf
WEB_TD4_PDF = $(OUTPUT_DIR)/r1.05/td4/td4.pdf
WEB_TD5_PDF = $(OUTPUT_DIR)/r1.05/td5/td5.pdf
WEB_LANDING_DEPLOY = $(WEB_TD_TEMPLATE)/.github/workflows/deploy-pages.yml

.PHONY: web-td3 web-td4 web-td5 publish-web-td3 publish-web-td4 publish-web-td5

web-td3: ## Génère la page minimale (lien PDF) du TD3 R1.05
	$(PYTHON) scripts/generate-web-td-landing.py --output $(OUTPUT_DIR)/web/td3 \
		--td-label "R1.05 - TD3" --title "Dépendances fonctionnelles et normalisation" \
		--pdf $(WEB_TD3_PDF) --deploy-workflow $(WEB_LANDING_DEPLOY)

publish-web-td3: web-td3 ## Publie la page du TD3 dans le dépôt étudiant (WEB_TD3_REPO=chemin)
	@if [ -z "$(WEB_TD3_REPO)" ]; then \
		echo "Erreur : définissez WEB_TD3_REPO=chemin/vers/depot"; exit 1; fi
	scripts/publish-web-td.sh $(OUTPUT_DIR)/web/td3 $(WEB_TD3_REPO)

web-td4: ## Génère la page minimale (lien PDF) du TD4 R1.05
	$(PYTHON) scripts/generate-web-td-landing.py --output $(OUTPUT_DIR)/web/td4 \
		--td-label "R1.05 - TD4" --title "Modèle Entité/Association et traduction relationnelle" \
		--pdf $(WEB_TD4_PDF) --deploy-workflow $(WEB_LANDING_DEPLOY)

publish-web-td4: web-td4 ## Publie la page du TD4 dans le dépôt étudiant (WEB_TD4_REPO=chemin)
	@if [ -z "$(WEB_TD4_REPO)" ]; then \
		echo "Erreur : définissez WEB_TD4_REPO=chemin/vers/depot"; exit 1; fi
	scripts/publish-web-td.sh $(OUTPUT_DIR)/web/td4 $(WEB_TD4_REPO)

web-td5: ## Génère la page minimale (lien PDF) du TD5 R1.05
	$(PYTHON) scripts/generate-web-td-landing.py --output $(OUTPUT_DIR)/web/td5 \
		--td-label "R1.05 - TD5" --title "Conception avec le modèle Entité/Association" \
		--pdf $(WEB_TD5_PDF) --deploy-workflow $(WEB_LANDING_DEPLOY)

publish-web-td5: web-td5 ## Publie la page du TD5 dans le dépôt étudiant (WEB_TD5_REPO=chemin)
	@if [ -z "$(WEB_TD5_REPO)" ]; then \
		echo "Erreur : définissez WEB_TD5_REPO=chemin/vers/depot"; exit 1; fi
	scripts/publish-web-td.sh $(OUTPUT_DIR)/web/td5 $(WEB_TD5_REPO)

# ==============================================================================
# Versionnage
# ==============================================================================

# Usage :
#   make bump           → incrémente le patch   (v1.0.0 → v1.0.1)
#   make bump PART=minor → incrémente le minor  (v1.0.1 → v1.1.0)
#   make bump PART=major → incrémente le major  (v1.1.0 → v2.0.0)
PART ?= patch

bump: ## Crée un tag de version (PART=patch|minor|major, défaut: patch)
	@LAST=$$(git tag --sort=-v:refname | head -1); \
	if [ -z "$$LAST" ]; then \
		NEXT="v1.0.0"; \
	else \
		MAJOR=$$(echo "$$LAST" | sed 's/^v//' | cut -d. -f1); \
		MINOR=$$(echo "$$LAST" | sed 's/^v//' | cut -d. -f2); \
		PATCH=$$(echo "$$LAST" | sed 's/^v//' | cut -d. -f3); \
		case "$(PART)" in \
			major) MAJOR=$$((MAJOR + 1)); MINOR=0; PATCH=0 ;; \
			minor) MINOR=$$((MINOR + 1)); PATCH=0 ;; \
			patch) PATCH=$$((PATCH + 1)) ;; \
			*) echo "Erreur : PART doit être patch, minor ou major"; exit 1 ;; \
		esac; \
		NEXT="v$$MAJOR.$$MINOR.$$PATCH"; \
	fi; \
	echo "$$LAST → $$NEXT"; \
	git commit --allow-empty -m "$$NEXT" && \
	git tag "$$NEXT" && \
	git push origin main "$$NEXT" && \
	echo "Tag $$NEXT poussé sur origin."

# ==============================================================================
# Nettoyage
# ==============================================================================

clean: ## Supprime les fichiers générés
	rm -rf $(OUTPUT_DIR)
	find docs -name "*.gen.md" | xargs rm -f
	find docs -name "*.aux" -o -name "*.log" -o -name "*.synctex*" | xargs rm -f
	find docs -path "*/figures/*.aux" -o -path "*/figures/*.log" -o -path "*/figures/*.pdf" | xargs rm -f
	find docs -type d -name "svg-inkscape" | xargs rm -rf
