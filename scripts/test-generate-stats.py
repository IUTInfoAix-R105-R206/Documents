#!/usr/bin/env python3
"""Tests automatisés pour generate-stats.py.

Vérifie la collecte des questions, les statistiques agrégées et la génération
HTML à partir des fichiers de correction SQL annotés.

Usage:
    python3 scripts/test-generate-stats.py
    python3 -m pytest scripts/test-generate-stats.py -v
"""

import json
import os
import re
import sys
import tempfile
import unittest

# Ajouter le répertoire scripts/ au path pour les imports
sys.path.insert(0, os.path.dirname(__file__))

import importlib.util

_spec = importlib.util.spec_from_file_location(
    "generate_stats",
    os.path.join(os.path.dirname(__file__), "generate-stats.py"),
)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

collect_questions = _mod.collect_questions
compute_statistics = _mod.compute_statistics
generate_html = _mod.generate_html
generate_per_td_pages = _mod.generate_per_td_pages
td_report_filename = _mod.td_report_filename
read_td_titles = _mod.read_td_titles
VALID_TAGS = _mod.VALID_TAGS

# Répertoire docs/ du projet
DOCS_DIR = os.path.join(os.path.dirname(__file__), "..", "docs")


class TestCollectQuestions(unittest.TestCase):
    """Tests sur la collecte des questions depuis les fichiers SQL."""

    @classmethod
    def setUpClass(cls):
        cls.questions, cls.titles = collect_questions(DOCS_DIR)

    def test_total_questions_positive(self):
        """Au moins 100 questions doivent être détectées."""
        self.assertGreaterEqual(len(self.questions), 100)

    def test_all_questions_have_required_fields(self):
        """Chaque question a tous les champs requis."""
        required = {
            "td_id", "td_title", "resource", "num",
            "description", "difficulty", "tags", "section",
        }
        for q in self.questions:
            with self.subTest(q=f"{q['td_id']}/Q{q['num']}"):
                self.assertTrue(
                    required.issubset(q.keys()),
                    f"Champs manquants: {required - q.keys()}",
                )

    def test_all_questions_have_difficulty(self):
        """Chaque question doit avoir une difficulté annotée (1-5)."""
        for q in self.questions:
            with self.subTest(q=f"{q['td_id']}/Q{q['num']}"):
                self.assertIsNotNone(
                    q["difficulty"],
                    f"@difficulty manquant pour {q['td_id']}/Q{q['num']}",
                )
                self.assertIn(q["difficulty"], range(0, 6))

    def test_all_questions_have_tags(self):
        """Chaque question doit avoir au moins un tag."""
        for q in self.questions:
            with self.subTest(q=f"{q['td_id']}/Q{q['num']}"):
                self.assertGreater(
                    len(q["tags"]), 0,
                    f"@tags manquants pour {q['td_id']}/Q{q['num']}",
                )

    def test_all_tags_are_valid(self):
        """Tous les tags utilisés doivent être dans VALID_TAGS."""
        for q in self.questions:
            for tag in q["tags"]:
                with self.subTest(q=f"{q['td_id']}/Q{q['num']}", tag=tag):
                    self.assertIn(tag, VALID_TAGS)

    def test_expected_td_ids(self):
        """Les 8 TD attendus sont présents."""
        td_ids = {q["td_id"] for q in self.questions}
        expected = {
            "r1.05/td6", "r1.05/td7",
            "r2.06/td1", "r2.06/td2", "r2.06/td3",
            "r2.06/td4", "r2.06/td5", "r2.06/td6",
        }
        self.assertEqual(expected, td_ids)

    def test_resources(self):
        """Les deux ressources sont présentes."""
        resources = {q["resource"] for q in self.questions}
        self.assertEqual({"r1.05", "r2.06"}, resources)

    def test_descriptions_non_empty(self):
        """La plupart des questions ont une description non vide."""
        with_desc = sum(
            1 for q in self.questions if q["description"].strip()
        )
        # Au moins 90% des questions ont une description
        self.assertGreater(
            with_desc / len(self.questions), 0.9,
            f"Seulement {with_desc}/{len(self.questions)} questions "
            "ont une description",
        )

    def test_td_titles_exist(self):
        """Les titres des TD sont lus depuis les fichiers Markdown."""
        td_ids = {q["td_id"] for q in self.questions}
        for td_id in td_ids:
            with self.subTest(td_id=td_id):
                self.assertIn(td_id, self.titles)
                self.assertTrue(self.titles[td_id].strip())


class TestComputeStatistics(unittest.TestCase):
    """Tests sur le calcul des statistiques agrégées."""

    @classmethod
    def setUpClass(cls):
        cls.questions, _ = collect_questions(DOCS_DIR)
        cls.stats = compute_statistics(cls.questions)

    def test_total_matches(self):
        """Le total correspond au nombre de questions."""
        self.assertEqual(self.stats["total"], len(self.questions))

    def test_difficulty_counts_sum(self):
        """La somme des comptages par difficulté = total."""
        total = sum(self.stats["diff_counts"].values())
        self.assertEqual(total, self.stats["total"])

    def test_tag_counts_positive(self):
        """Au moins un tag a un comptage > 0."""
        self.assertGreater(len(self.stats["tag_counts"]), 0)

    def test_tag_counts_sorted_descending(self):
        """Les tags sont triés par fréquence décroissante."""
        counts = [c for _, c in self.stats["tag_counts"]]
        self.assertEqual(counts, sorted(counts, reverse=True))

    def test_used_tags_count(self):
        """Le nombre de tags utilisés est cohérent."""
        self.assertGreater(self.stats["used_tags"], 0)
        self.assertLessEqual(self.stats["used_tags"], self.stats["total_tags"])

    def test_avg_difficulty_in_range(self):
        """La difficulté moyenne est entre 1 et 3."""
        self.assertGreaterEqual(self.stats["avg_difficulty"], 1.0)
        self.assertLessEqual(self.stats["avg_difficulty"], 3.0)

    def test_matrix_consistency(self):
        """La matrice tag×difficulté est cohérente avec tag_counts."""
        matrix = self.stats["tag_diff_matrix"]
        for tag, count in self.stats["tag_counts"]:
            matrix_total = sum(matrix.get(tag, {}).values())
            with self.subTest(tag=tag):
                self.assertEqual(
                    matrix_total, count,
                    f"Matrice incohérente pour {tag}: "
                    f"{matrix_total} != {count}",
                )

    def test_num_tds(self):
        """Le nombre de TD est 8."""
        self.assertEqual(self.stats["num_tds"], 8)

    def test_num_resources(self):
        """Le nombre de ressources est 2."""
        self.assertEqual(self.stats["num_resources"], 2)


class TestGenerateHTML(unittest.TestCase):
    """Tests sur la génération de la page HTML."""

    @classmethod
    def setUpClass(cls):
        cls.questions, _ = collect_questions(DOCS_DIR)
        cls.stats = compute_statistics(cls.questions)
        cls.html = generate_html(cls.questions, cls.stats)

    def test_html_is_valid_structure(self):
        """Le HTML contient les balises de base."""
        self.assertIn("<!DOCTYPE html>", self.html)
        self.assertIn("<html lang=\"fr\">", self.html)
        self.assertIn("</html>", self.html)
        self.assertIn("<title>", self.html)

    def test_html_contains_title(self):
        """Le titre est présent."""
        self.assertIn("Statistiques des questions SQL", self.html)

    def test_html_contains_stat_boxes(self):
        """Les stat-boxes sont présentes."""
        self.assertIn("stat-box", self.html)
        self.assertIn(str(self.stats["total"]), self.html)

    def test_html_contains_bar_chart(self):
        """Le graphique de barres est présent."""
        self.assertIn("bar-row", self.html)
        self.assertIn("bar-label", self.html)

    def test_html_contains_difficulty_chart(self):
        """L'histogramme de difficulté est présent."""
        self.assertIn("difficulty-chart", self.html)
        self.assertIn("diff-col", self.html)

    def test_html_contains_matrix(self):
        """La matrice tag×difficulté est présente."""
        self.assertIn("matrix-table", self.html)

    def test_html_contains_json_data(self):
        """Les données JSON sont embarquées."""
        m = re.search(r"const DATA = ({.*?});", self.html, re.DOTALL)
        self.assertIsNotNone(m, "JSON DATA non trouvé dans le HTML")
        data = json.loads(m.group(1))
        self.assertEqual(len(data["questions"]), len(self.questions))

    def test_html_contains_all_tags_in_bars(self):
        """Chaque tag utilisé apparaît dans le graphique de barres."""
        for tag, _ in self.stats["tag_counts"]:
            with self.subTest(tag=tag):
                self.assertIn(
                    f'data-tag="{tag}"', self.html,
                    f"Tag {tag} absent du graphique",
                )

    def test_html_contains_javascript(self):
        """Le JavaScript interactif est présent."""
        self.assertIn("selectTag", self.html)
        self.assertIn("selectDifficulty", self.html)
        self.assertIn("applyFilter", self.html)

    def test_html_back_link(self):
        """Le lien de retour est présent."""
        self.assertIn("../index.html", self.html)

    def test_html_writes_to_file(self):
        """Le fichier HTML peut être écrit sur disque."""
        with tempfile.NamedTemporaryFile(
            suffix=".html", delete=False
        ) as f:
            f.write(self.html.encode("utf-8"))
            path = f.name
        try:
            self.assertGreater(os.path.getsize(path), 1000)
        finally:
            os.unlink(path)


class TestPerTDPages(unittest.TestCase):
    """Tests sur la génération des pages par TD."""

    @classmethod
    def setUpClass(cls):
        cls.questions, _ = collect_questions(DOCS_DIR)
        cls.output_dir = tempfile.mkdtemp()
        generate_per_td_pages(cls.questions, cls.output_dir)

    def test_all_td_pages_generated(self):
        """Une page HTML est générée pour chaque TD."""
        td_ids = sorted({q["td_id"] for q in self.questions})
        for td_id in td_ids:
            filename = td_report_filename(td_id)
            path = os.path.join(self.output_dir, filename)
            with self.subTest(td_id=td_id):
                self.assertTrue(
                    os.path.isfile(path),
                    f"Page manquante: {filename}",
                )

    def test_per_td_page_structure(self):
        """Chaque page par TD contient les éléments attendus."""
        td_ids = sorted({q["td_id"] for q in self.questions})
        for td_id in td_ids:
            filename = td_report_filename(td_id)
            path = os.path.join(self.output_dir, filename)
            with open(path, encoding="utf-8") as f:
                html = f.read()
            with self.subTest(td_id=td_id):
                self.assertIn("<!DOCTYPE html>", html)
                self.assertIn("bar-row", html)
                self.assertIn("difficulty-chart", html)
                self.assertIn("matrix-table", html)
                self.assertIn("const DATA =", html)

    def test_per_td_page_contains_only_its_questions(self):
        """Le JSON embarqué ne contient que les questions du TD."""
        td_ids = sorted({q["td_id"] for q in self.questions})
        for td_id in td_ids:
            filename = td_report_filename(td_id)
            path = os.path.join(self.output_dir, filename)
            with open(path, encoding="utf-8") as f:
                html = f.read()
            m = re.search(r"const DATA = ({.*?});", html, re.DOTALL)
            with self.subTest(td_id=td_id):
                self.assertIsNotNone(m)
                data = json.loads(m.group(1))
                for q in data["questions"]:
                    self.assertEqual(q["td_id"], td_id)

    def test_per_td_page_has_navigation(self):
        """Chaque page par TD contient la navigation inter-TD."""
        td_ids = sorted({q["td_id"] for q in self.questions})
        for td_id in td_ids:
            filename = td_report_filename(td_id)
            path = os.path.join(self.output_dir, filename)
            with open(path, encoding="utf-8") as f:
                html = f.read()
            with self.subTest(td_id=td_id):
                self.assertIn("td-nav", html)
                self.assertIn("td-nav-current", html)
                self.assertIn("index.html", html)

    def test_per_td_page_back_link(self):
        """Le lien de retour pointe vers la vue globale."""
        td_id = sorted({q["td_id"] for q in self.questions})[0]
        filename = td_report_filename(td_id)
        path = os.path.join(self.output_dir, filename)
        with open(path, encoding="utf-8") as f:
            html = f.read()
        self.assertIn('href="index.html"', html)
        self.assertIn("Vue globale", html)


if __name__ == "__main__":
    unittest.main()
