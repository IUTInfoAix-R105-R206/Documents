# Contribuer au projet

Bienvenue ! Ce dépôt contient les sources des sujets de TD des cours de bases
de données de l'IUT d'Aix-Marseille (R1.05 et R2.06). Les sujets sont écrits
en Markdown et compilés en PDF. Les corrections SQL sont validées
automatiquement par l'intégration continue.

Ce guide explique comment contribuer, que ce soit pour corriger une coquille,
ajouter un exercice ou signaler un problème.

## Prérequis

### Indispensable

- Un compte [GitHub](https://github.com/)
- [Git](https://git-scm.com/) installé sur votre machine

### Optionnel (pour compiler les PDF localement)

```bash
# Ubuntu / Debian
sudo apt-get install build-essential pandoc texlive-latex-base texlive-latex-extra \
  texlive-latex-recommended texlive-fonts-recommended texlive-lang-french \
  texlive-pictures texlive-science texlive-plain-generic lmodern inkscape
```

### Optionnel (pour tester les corrections SQL localement)

```bash
# SQLite (le plus simple, aucune autre dépendance)
sudo apt-get install sqlite3

# Ou Docker pour tester avec Oracle (SGBD de référence du cours)
# Docker doit être installé et démarré
```

## Premiers pas

### 1. Cloner le dépôt

```bash
git clone https://github.com/IUTInfoAix-R105-R206/Documents.git
cd Documents
```

### 2. Installer les hooks Git

Le projet utilise un hook pre-commit qui corrige automatiquement le style des
fichiers SQL quand vous faites un commit. Pour l'activer :

```bash
make install-hooks
```

> **Note :** Si SQLFluff n'est pas installé sur votre machine, le hook est
> ignoré sans bloquer le commit. Vous pouvez l'installer avec
> `pip install sqlfluff`.

### 3. Vérifier que tout fonctionne

```bash
# Compiler tous les TD (nécessite pandoc + texlive + inkscape)
make all

# Ou un seul groupe de TD
make r105    # R1.05 uniquement
make r206    # R2.06 uniquement
```

Les PDF générés sont placés dans le dossier `output/`.

## Modifier un sujet de TD

### Workflow pas-à-pas

**1. Créer une branche pour vos modifications**

```bash
git checkout -b fix/td3-correction-q5
```

Conventions de nommage des branches :
- `fix/description` pour corriger une erreur
- `feat/description` pour ajouter du contenu
- `docs/description` pour de la documentation

**2. Modifier le fichier Markdown du TD**

Les sources se trouvent dans `docs/r1.05/tdN/` ou `docs/r2.06/tdN/`. Le
fichier principal est `tdN.md`.

**3. Compiler et vérifier le PDF**

```bash
make r206    # Compile tous les TD de R2.06
```

Ouvrez le PDF dans `output/r2.06/` et vérifiez visuellement que le rendu est
correct.

**4. Faire un commit**

```bash
git add docs/r2.06/td3/td3.md
git commit -m "fix: Corriger l'énoncé de la Q5 du TD3 R2.06"
```

**5. Pousser et créer une pull request**

```bash
git push -u origin fix/td3-correction-q5
```

Rendez-vous ensuite sur GitHub. Un bouton « Compare & pull request »
apparaît en haut de la page du dépôt. Cliquez dessus, remplissez la
description en suivant le template proposé, puis validez.

## Modifier une correction SQL

Les fichiers de correction se trouvent dans `docs/r*/td*/td*-correction.sql`.

### Annotations obligatoires

Chaque question doit avoir une annotation de résultats attendus :

```sql
-- Q1 - c:2, t:9
-- Description de la requête
SELECT ...;
```

- `c:N` = nombre de colonnes attendues
- `t:N` = nombre de lignes attendues

Ces annotations permettent à la CI de vérifier automatiquement les résultats.

### Annotations de métadonnées

Pour les statistiques, chaque question porte aussi des annotations de
difficulté et de tags :

```sql
-- Q1 - c:2, t:9
-- Description de la requête
-- @difficulty 2
-- @tags jointure, imbrication
SELECT ...;
```

### Tester les corrections localement

```bash
# Avec SQLite (le plus simple)
make test-sql-sqlite-local

# Tester un seul TD
make test-sql-sqlite-local TD=td3

# Avec Oracle via Docker (SGBD de référence)
make test-sql-oracle-docker

# Vérifier le style SQL
make lint-sql

# Corriger automatiquement le style SQL
make fix-sql
```

### Workflow

Le workflow est le même que pour modifier un sujet : créer une branche,
modifier, tester, commit, pousser, créer une PR.

## Conventions

### Messages de commit

Les messages suivent le format
[Conventional Commits](https://www.conventionalcommits.org/) :

| Préfixe  | Usage                              | Exemple                                          |
|----------|-------------------------------------|--------------------------------------------------|
| `feat:`  | Nouveau contenu ou fonctionnalité   | `feat: Ajouter la Q27 au TD3 R2.06`             |
| `fix:`   | Correction d'une erreur             | `fix: Corriger le résultat attendu de Q5 TD3`   |
| `docs:`  | Documentation                       | `docs: Mettre à jour le README`                 |
| `ci:`    | Intégration continue                | `ci: Ajouter le test Oracle dans le workflow`    |

### Styles Markdown

Les sujets utilisent des styles personnalisés via des spans Pandoc :

| Style          | Syntaxe                          | Rendu                    |
|----------------|----------------------------------|--------------------------|
| Clef primaire  | `[attr]{.pk}`                    | Souligné                 |
| Clef étrangère | `[*attr#*]{.fk}`                 | Italique                 |
| Les deux       | `[*attr#*]{.pkfk}`               | Souligné + italique      |
| Résultat       | `[2 attributs, 9 tuples]{.expected}` | Bleu italique        |

Pour les blocs spéciaux :

```markdown
::: remarques
*Remarques*
Contenu...
:::
```

## Intégration continue (CI)

Quand vous poussez des modifications ou créez une pull request, GitHub lance
automatiquement des vérifications. Voici ce qui se passe :

### Build PDF (`build.yml`)

Vérifie que tous les sujets compilent correctement en PDF. Déclenché quand
vous modifiez des fichiers dans `docs/`, `templates/` ou le `Makefile`.

### Tests SQL (`test-sql.yml`)

Déclenché quand vous modifiez des fichiers `.sql` ou les données de test.
Les vérifications sont exécutées dans cet ordre :

1. **Lint SQL** - Vérifie le style des fichiers SQL avec SQLFluff
2. **Test PostgreSQL** - Exécute les corrections sur PostgreSQL
3. **Test SQLite** - Exécute les corrections sur SQLite
4. **Test Oracle** - Exécute les corrections sur Oracle (SGBD de référence)
5. **Gate Oracle** - **Si Oracle échoue, la PR est bloquée**

> **Important :** Oracle est le SGBD cible du cours. Les corrections sont
> écrites en syntaxe Oracle. Des différences avec PostgreSQL ou SQLite sont
> attendues (ex : `MINUS` vs `EXCEPT`), mais les tests Oracle doivent passer
> à 100 %.

### Voir les résultats

1. Allez sur la page de votre pull request sur GitHub
2. En bas, une section « Checks » indique l'état de chaque vérification
3. Cliquez sur « Details » pour voir les logs détaillés en cas d'échec

Si une vérification échoue :
- Lisez les logs pour identifier l'erreur
- Corrigez localement, faites un nouveau commit et poussez
- La CI se relance automatiquement

## Signaler un problème sans modifier le code

Si vous repérez une erreur mais ne souhaitez pas la corriger vous-même :

1. Allez sur la page du dépôt sur GitHub
2. Cliquez sur l'onglet **Issues**
3. Cliquez sur **New issue**
4. Choisissez le template adapté :
   - **Signaler un problème** pour une erreur
   - **Proposer une amélioration** pour une suggestion
5. Remplissez le formulaire avec le maximum de contexte (numéro de question,
   TD concerné, résultat attendu vs obtenu)

## Licence

Les contenus pédagogiques sont sous licence
[CC BY-NC-SA](https://creativecommons.org/licenses/by-nc-sa/4.0/).
Toute contribution est soumise à cette même licence.
