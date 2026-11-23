#!/usr/bin/env python3
"""Make a compact browser payload from the checked teaching CSVs. No imputation."""

import csv
import json
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def rows(filename):
    with (ROOT / "data" / filename).open(encoding="utf-8", newline="") as handle:
        yield from csv.DictReader(handle)


def main():
    names = {}
    values = defaultdict(lambda: defaultdict(float))
    totals = {}
    sectors = set()
    for r in rows("goods_partner_totals_ukrstat_2011_2023.csv"):
        y, flow = int(r["year"]), r["flow"]
        if r["partner_name_uk"] == "ВСЬОГО:":
            totals[f"goods|{y}|{flow}|All goods"] = float(r["value_usd"])
        code = r["partner_iso3"]
        if code and r["value_usd"]:
            names[code] = r["partner_name_en"]
            values[f"goods|{y}|{flow}|All goods"][code] = float(r["value_usd"])
    for r in rows("goods_partner_hs2_ukrstat_2011_2023.csv"):
        code = r["partner_iso3"]
        if not code or not r["value_usd"]:
            continue
        sector = r["teaching_sector"]
        sectors.add(sector)
        values[f"goods|{r['year']}|{r['flow']}|{sector}"][code] += float(r["value_usd"])
    for r in rows("computer_services_partners_nbu.csv"):
        k = f"it|{r['year']}|{r['flow']}|Computer services"
        if r["row_type"] == "world_total":
            totals[k] = float(r["value_usd"])
        if r["row_type"] == "country_or_territory" and r["value_usd"]:
            code = r["partner_iso3"]
            names.setdefault(code, r["category_or_partner"])
            values[k][code] = float(r["value_usd"])
    snapshots = {}
    for k, partners in sorted(values.items()):
        snapshots[k] = {
            "partners": {c: round(v, 2) for c, v in sorted(partners.items())},
            "total": round(totals.get(k, sum(partners.values())), 2),
            "denominator": "published total"
            if k in totals
            else "sum of named partners",
        }
    macro = defaultdict(dict)
    indicator_names = {}
    for r in rows("economic_context_wdi_1991_latest.csv"):
        indicator_names[r["indicator"]] = r["indicator_label"]
        macro[r["year"]][r["indicator"]] = float(r["value"]) if r["value"] else None
    payload = {
        "snapshotDate": "2026-11-15",
        "names": names,
        "goodsSectors": sorted(sectors),
        "snapshots": snapshots,
        "macro": dict(macro),
        "indicatorNames": indicator_names,
        "availability": {
            "goods": [2011, 2023],
            "it": [2011, 2025],
            "macro": [1991, 2025],
        },
        "notes": {
            "goods": "Ukrstat, destination for exports and origin for imports. Product groups are not industries.",
            "it": "NBU, selected computer-services partners. Missing countries are not zero. Shares use the published computer-services total.",
            "sectors": "Sector totals sum named ISO3 partners, not the published world total. Special non-HS product lines are excluded from sector filters.",
        },
    }
    path = ROOT / "prototype/data/trade.json"
    path.parent.mkdir(exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":"), allow_nan=False)
        + "\n"
    )
    print(
        f"Wrote {path.relative_to(ROOT)}: {len(snapshots)} snapshots, {path.stat().st_size:,} bytes"
    )


if __name__ == "__main__":
    main()
