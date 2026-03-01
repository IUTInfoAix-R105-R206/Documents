## Description

<!-- Décrivez brièvement les modifications apportées. -->

## TD concerné(s)

<!-- Ex : R2.06 TD3, R1.05 TD6 -->

## Type de modification

- [ ] Correction d'une erreur (sujet ou correction SQL)
- [ ] Nouveau contenu (exercice, question, TD)
- [ ] Mise à jour des données de test
- [ ] Infrastructure (CI, scripts, compilation, templates)

## Checklist

- [ ] Le sujet compile sans erreur (`make r105` ou `make r206`)
- [ ] Le PDF généré a été vérifié visuellement
- [ ] Les corrections SQL sont validées (`make test-sql-sqlite-local` ou `make test-sql-oracle-docker`)
- [ ] Le lint SQL passe (`make lint-sql`) ou le hook pre-commit est installé (`make install-hooks`)
- [ ] Les annotations de résultats attendus (`-- QN - c:X, t:Y`) sont à jour pour les nouvelles questions
