#!/usr/bin/env python3
"""Offline regression checks for the D3 payload and its source denominators."""

import csv
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read_json(path):
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"Cannot read {path}: {error}") from error


class PrototypeDataChecks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.payload = read_json(ROOT / "prototype/data/trade.json")
        cls.snapshots = cls.payload["snapshots"]

    def test_coverage_and_no_fabricated_early_trade(self):
        self.assertEqual(len(self.snapshots), 454)
        self.assertNotIn("goods|1991|export|All goods", self.snapshots)
        self.assertNotIn("goods|2025|export|All goods", self.snapshots)
        self.assertIn("it|2025|export|Computer services", self.snapshots)
        for year in range(2011, 2024):
            for flow in ["export", "import"]:
                self.assertIn(f"goods|{year}|{flow}|All goods", self.snapshots)

    def test_published_goods_denominator_and_partner_values(self):
        row = self.snapshots["goods|2023|export|All goods"]
        self.assertEqual(row["denominator"], "published total")
        with (
            ROOT / "data/goods_partner_totals_ukrstat_2011_2023.csv"
        ).open() as handle:
            for source in csv.DictReader(handle):
                if source["year"] != "2023" or source["flow"] != "export":
                    continue
                if source["partner_name_uk"] == "ВСЬОГО:":
                    self.assertAlmostEqual(
                        row["total"], float(source["value_usd"]), places=2
                    )
                if source["partner_iso3"] == "POL":
                    self.assertAlmostEqual(
                        row["partners"]["POL"], float(source["value_usd"]), places=2
                    )
        self.assertNotIn("WORLD", row["partners"])

    def test_sector_denominator_is_labeled_and_separate(self):
        row = self.snapshots["goods|2023|export|Metals"]
        self.assertEqual(row["denominator"], "sum of named partners")
        self.assertAlmostEqual(row["total"], sum(row["partners"].values()), delta=0.1)
        source_value = 0.0
        with (ROOT / "data/goods_partner_hs2_ukrstat_2011_2023.csv").open() as handle:
            for source in csv.DictReader(handle):
                if (
                    source["year"],
                    source["flow"],
                    source["partner_iso3"],
                    source["teaching_sector"],
                ) == ("2023", "export", "POL", "Metals"):
                    source_value += float(source["value_usd"])
        self.assertAlmostEqual(row["partners"]["POL"], source_value, places=2)

    def test_it_total_does_not_normalize_selected_partners_to_100(self):
        row = self.snapshots["it|2025|import|Computer services"]
        self.assertEqual(row["total"], 1_718_000_000)
        self.assertLess(sum(row["partners"].values()), row["total"])
        self.assertEqual(row["denominator"], "published total")
        self.assertAlmostEqual(row["partners"]["IRL"], 386_768_637.58, places=2)

    def test_macro_and_local_dependencies(self):
        self.assertTrue(self.payload["macro"]["1991"]["NY.GDP.MKTP.KD"])
        self.assertIsNone(self.payload["macro"]["1991"]["NV.IND.MANF.ZS"])
        for file in [
            "vendor/d3.v7.min.js",
            "vendor/D3-LICENSE",
            "fonts/barlow-condensed-600.woff2",
            "fonts/source-sans-3-400.woff2",
            "fonts/BARLOW-LICENSE",
            "fonts/SOURCE-SANS-LICENSE",
        ]:
            self.assertTrue((ROOT / "prototype" / file).is_file(), file)
        for snapshot in self.snapshots.values():
            self.assertTrue(all(len(code) == 3 for code in snapshot["partners"]))
            self.assertGreaterEqual(snapshot["total"], 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
