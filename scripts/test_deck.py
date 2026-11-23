#!/usr/bin/env python3
"""Check lecture data, units, chronology, and explicit replication status. No estimator runs."""

import json
import re
import unittest
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load_json(path):
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"Cannot read {path}: {error}") from error


class DeckChecks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data = load_json(ROOT / "deck/data.json")
        cls.copy = (ROOT / "deck/slides.js").read_text()

    def test_slide_outline_and_notes(self):
        ids = re.findall(r'id:\s*"([^"]+)"', self.copy)
        self.assertEqual(len(ids), 18)
        self.assertEqual(len(set(ids)), 18)
        self.assertEqual(len(re.findall(r"\bnotes:", self.copy)), 18)
        self.assertIn("weights", ids)
        self.assertIn("interpolation", ids)
        self.assertIn("2023 only partly recovered", self.copy)

    def test_recovery_is_not_another_downturn(self):
        macro = self.data["macro"]
        self.assertLess(macro["2022"]["NY.GDP.MKTP.KD.ZG"], 0)
        self.assertGreater(macro["2023"]["NY.GDP.MKTP.KD.ZG"], 0)
        self.assertLess(
            macro["2023"]["NY.GDP.MKTP.KD"], macro["2021"]["NY.GDP.MKTP.KD"]
        )
        self.assertGreater(macro["2008"]["NY.GDP.MKTP.KD.ZG"], 0)
        self.assertLess(macro["2009"]["NY.GDP.MKTP.KD.ZG"], -10)

    def test_crisis_growth_matches_level_series(self):
        macro = self.data["macro"]
        for year in [2009, 2014, 2015, 2022, 2023]:
            calculated = (
                macro[str(year)]["NY.GDP.MKTP.KD"]
                / macro[str(year - 1)]["NY.GDP.MKTP.KD"]
                - 1
            ) * 100
            self.assertAlmostEqual(
                calculated, macro[str(year)]["NY.GDP.MKTP.KD.ZG"], delta=0.1
            )

    def test_paper_observations_and_weights(self):
        rows = self.data["countries"]
        self.assertEqual(len(rows), 414)
        self.assertEqual(len({r["country"] for r in rows}), 18)
        self.assertEqual({r["year"] for r in rows}, set(range(1995, 2018)))
        self.assertEqual(len({(r["country"], r["year"]) for r in rows}), 414)
        self.assertTrue(all(r["gdppc"] > 0 for r in rows))
        self.assertEqual(len(self.data["weights"]), 4)
        self.assertAlmostEqual(sum(w["weight"] for w in self.data["weights"]), 1)
        self.assertAlmostEqual(
            sum(
                w["weight"]
                for w in self.data["weights"]
                if w["country"] in {"Moldova", "Armenia"}
            ),
            0.785,
        )

    def test_published_gap_is_not_a_new_fit(self):
        published = self.data["published"]
        self.assertEqual([r["year"] for r in published], list(range(2013, 2018)))
        self.assertAlmostEqual(
            sum(r["percent"] for r in published) / 5, 15.1, delta=0.01
        )
        self.assertAlmostEqual(
            sum(r["shortfall"] for r in published) / 5, 1438.9, delta=0.01
        )
        self.assertIs(self.data["replicationStatus"]["estimatorRun"], False)
        self.assertIn("Reconstruction is not re-estimation", self.copy)
        self.assertIn("2011 international dollars", self.copy)

    def test_maps_and_local_runtime(self):
        geometry = load_json(ROOT / "raw/geography/CNTR_RG_20M_2024_4326.geojson")
        codes = {f["properties"]["ISO3_CODE"] for f in geometry["features"]}
        self.assertTrue(set(self.data["donors"].values()).issubset(codes))
        self.assertIn("UKR", codes)
        self.assertTrue((ROOT / "prototype/vendor/d3.v7.min.js").is_file())
        self.assertEqual(len(self.data["donors"]), 17)
        self.assertTrue(
            (ROOT / "research/hybrid-wars/teaching-R/replicate.R").is_file()
        )


class HistoryMarkup(HTMLParser):
    def __init__(self, text):
        super().__init__()
        self.frames = []
        self.triggers = []
        self.stickies = []
        self.images = []
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        classes = (attrs.get("class") or "").split()
        if tag == "iframe" and "history-frame" in classes:
            self.frames.append(attrs)
        elif "new-trigger" in classes:
            self.triggers.append(attrs.get("data-focus-on"))
        elif "sticky" in classes:
            self.stickies.append(attrs.get("id"))
        elif tag == "img":
            self.images.append(attrs)


class HistoryChecks(unittest.TestCase):
    def test_closeread_story_is_bundled_in_lecture(self):
        deck = HistoryMarkup((ROOT / "deck/lecture.html").read_text())
        self.assertEqual(len(deck.frames), 1)
        frame = deck.frames[0]
        self.assertTrue(frame["title"])
        self.assertNotIn("src", frame)
        story = HistoryMarkup(frame["srcdoc"])
        self.assertEqual(len(set(story.triggers)), 7)
        self.assertEqual(story.triggers, story.stickies)
        self.assertEqual(len(story.images), 7)
        for image in story.images:
            self.assertTrue(image["alt"])
            self.assertTrue(image["src"].startswith("data:image/jpeg;"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
