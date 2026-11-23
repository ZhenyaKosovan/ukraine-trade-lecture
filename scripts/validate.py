#!/usr/bin/env python3
"""Offline data checks and a report of source-level reconciliation differences."""

import csv
import hashlib
import json
import unittest
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load_json(path):
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"Cannot read {path}: {error}") from error


def rows(name):
    with (ROOT / "data" / name).open(encoding="utf-8", newline="") as handle:
        yield from csv.DictReader(handle)


def reconciliation():
    sums = defaultdict(float)
    for name in [
        "goods_partner_hs2_ukrstat_2011_2023.csv",
        "goods_special_products_ukrstat_2011_2023.csv",
    ]:
        for r in rows(name):
            sums[r["year"], r["flow"], r["partner_name_uk"]] += float(
                r["value_usd"] or 0
            )
    differences = []
    for r in rows("goods_partner_totals_ukrstat_2011_2023.csv"):
        k = r["year"], r["flow"], r["partner_name_uk"]
        if k not in sums or not r["value_usd"]:
            continue
        delta = sums[k] - float(r["value_usd"])
        if abs(delta) > 1:
            differences.append(
                {
                    "year": k[0],
                    "flow": k[1],
                    "partner_name_uk": k[2],
                    "published_total_usd": r["value_usd"],
                    "sum_published_products_usd": sums[k],
                    "difference_usd": delta,
                }
            )
    out = ROOT / "metadata/reconciliation_differences.csv"
    with out.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "year",
                "flow",
                "partner_name_uk",
                "published_total_usd",
                "sum_published_products_usd",
                "difference_usd",
            ],
        )
        writer.writeheader()
        writer.writerows(differences)
    return differences


def in_ring(point, ring):
    x, y = point
    inside = False
    for a, b in zip(ring, ring[1:] + ring[:1], strict=True):
        x1, y1 = a
        x2, y2 = b
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
            inside = not inside
    return inside


class DataChecks(unittest.TestCase):
    def test_downloads_and_checksums(self):
        manifest = load_json(ROOT / "manifest.json")
        self.assertEqual(len(manifest), len(load_json(ROOT / "sources.json")))
        for r in manifest:
            self.assertEqual(r["status"], "downloaded", r["id"])
            self.assertEqual(
                hashlib.sha256((ROOT / r["file"]).read_bytes()).hexdigest(), r["sha256"]
            )

    def test_geographical_years_and_flows(self):
        data = list(rows("goods_geographical_groups_ukrstat_1996_2023.csv"))
        self.assertEqual(len(data), 28 * 2 * 9)
        self.assertEqual({r["year"] for r in data}, {str(y) for y in range(1996, 2024)})
        self.assertEqual({r["flow"] for r in data}, {"export", "import"})

    def test_ukrstat_product_keys_and_units(self):
        seen = set()
        years = set()
        for r in rows("goods_partner_hs2_ukrstat_2011_2023.csv"):
            k = r["year"], r["flow"], r["partner_name_uk"], r["hs2"]
            self.assertNotIn(k, seen)
            seen.add(k)
            years.add(r["year"])
            self.assertEqual(len(r["hs2"]), 2)
            if r["value_usd"]:
                self.assertAlmostEqual(
                    float(r["value_usd"]), float(r["source_value"]) * 1000, places=2
                )
        self.assertEqual(years, {str(y) for y in range(2011, 2024)})

    def test_nbu_goods_products_exclude_percentages(self):
        counts = Counter()
        totals, sums = {}, defaultdict(float)
        for r in rows("goods_products_nbu.csv"):
            k = r["year"], r["flow"]
            counts[k] += 1
            if r["category_or_partner"].startswith("TOTAL"):
                totals[k] = float(r["value_usd"])
            else:
                sums[k] += float(r["value_usd"])
        self.assertEqual(len(counts), 42)
        self.assertTrue(all(v == 9 for v in counts.values()))
        for k, total in totals.items():
            # Tables round most component values to USD millions.
            self.assertLessEqual(abs(total - sums[k]), 5_000_000)

    def test_eurostat_actual_coverage_and_mirror_direction(self):
        ua = list(rows("goods_partner_sitc1_eurostat_ukraine.csv"))
        self.assertEqual({int(r["year"]) for r in ua}, set(range(2012, 2025)))
        self.assertEqual(sum(r["year"] == "2016" for r in ua), 412)
        eu = list(rows("goods_sitc1_eurostat_eu27_mirror.csv"))
        for r in eu:
            self.assertNotEqual(r["reporter_flow"], r["ukraine_flow"])
        self.assertEqual({int(r["year"]) for r in eu}, set(range(2002, 2026)))

    def test_macro_1991_present_missing_values_retained(self):
        data = list(rows("economic_context_wdi_1991_latest.csv"))
        self.assertEqual(len({r["indicator"] for r in data}), 11)
        self.assertTrue(
            any(
                r["year"] == "1991"
                and r["indicator"] == "NY.GDP.MKTP.KD"
                and r["value"]
                for r in data
            )
        )
        self.assertTrue(
            any(
                r["year"] == "1991"
                and r["indicator"] == "NV.IND.MANF.ZS"
                and not r["value"]
                for r in data
            )
        )

    def test_map_contains_ukraine_and_crimea(self):
        data = load_json(ROOT / "raw/geography/CNTR_RG_20M_2024_4326.geojson")
        features = [
            f for f in data["features"] if f["properties"]["ISO3_CODE"] == "UKR"
        ]
        self.assertEqual(len(features), 1)
        geometry = features[0]["geometry"]
        polygons = (
            geometry["coordinates"]
            if geometry["type"] == "MultiPolygon"
            else [geometry["coordinates"]]
        )
        self.assertTrue(
            any(
                in_ring((34.1, 44.95), p[0])
                and not any(in_ring((34.1, 44.95), hole) for hole in p[1:])
                for p in polygons
            )
        )


if __name__ == "__main__":
    differences = reconciliation()
    print(
        f"{len(differences)} source reconciliation differences exceed USD 1; see metadata/reconciliation_differences.csv",
        flush=True,
    )
    unittest.main(verbosity=2)
