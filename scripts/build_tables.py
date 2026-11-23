#!/usr/bin/env python3
"""Build teaching CSVs. Never impute missing values or merge different trade concepts."""

import csv
import gettext
import hashlib
import json
import re
import unicodedata
import zipfile
from collections import Counter
from pathlib import Path
from typing import TypeGuard

import openpyxl
import pycountry
import xlrd

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "data"
OUT.mkdir(exist_ok=True)
COVERAGE = []


def text(value):
    return str(value or "").strip()


def key(value):
    normalized = (
        unicodedata.normalize("NFKC", text(value))
        .upper()
        .replace("I", "І")
        .replace("Ї", "І")
        .replace("Ґ", "Г")
    )
    return re.sub(r"[^\w]", "", normalized).replace("_", "")


ALIASES = {
    "Turkey": "TUR",
    "russian federation": "RUS",
    "South Korea": "KOR",
    "Korea, Republic of": "KOR",
    "Iran": "IRN",
    "Venezuela": "VEN",
    "United States of America": "USA",
    "United Kingdom": "GBR",
    "Taiwan": "TWN",
    "Moldova": "MDA",
    "Bolivia": "BOL",
    "Viet Nam": "VNM",
    "EU27_2020": "",
    "EL": "GRC",
    "UK": "GBR",
    "XK": "XKX",
}


def iso(name):
    if name in ALIASES:
        return ALIASES[name]
    try:
        return pycountry.countries.lookup(name).alpha_3
    except LookupError:
        return ""


def number(value: object) -> TypeGuard[int | float]:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def load_json(path):
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"Cannot read JSON data {path}: {error}") from error


def save(name, rows):
    if not rows:
        raise ValueError(f"No rows produced for {name}")
    path = OUT / name
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    counts = Counter(str(r.get("year", "")) for r in rows)
    COVERAGE.append(
        {
            "file": f"data/{name}",
            "rows": len(rows),
            "rows_by_year": dict(sorted(counts.items())),
        }
    )
    print(name, len(rows), "rows")


def sector(code):
    c = int(code)
    for low, high, label in [
        (1, 24, "Agriculture and food"),
        (25, 26, "Minerals and ores"),
        (27, 27, "Fuels and energy"),
        (28, 38, "Chemicals"),
        (39, 40, "Plastics and rubber"),
        (41, 43, "Leather and hides"),
        (44, 49, "Wood and paper"),
        (50, 63, "Textiles"),
        (64, 67, "Footwear and accessories"),
        (68, 71, "Stone glass and precious materials"),
        (72, 83, "Metals"),
        (84, 85, "Machinery and electrical equipment"),
        (86, 89, "Transport equipment"),
        (90, 92, "Instruments and clocks"),
        (93, 93, "Arms and ammunition"),
        (94, 97, "Other manufactures and art"),
    ]:
        if low <= c <= high:
            return label
    return "Special or unclassified"


def ukrstat_goods():
    # Modern bilingual partner sheets supply exact source-language names, not fuzzy translations.
    names = {}
    with zipfile.ZipFile(ROOT / "raw/ukrstat/partners.zip") as archive:
        for member in archive.namelist():
            if not member.endswith(".xls"):
                continue
            sheet = xlrd.open_workbook(
                file_contents=archive.read(member)
            ).sheet_by_index(0)
            if sheet.ncols >= 7:
                for row in sheet.get_rows():
                    ua, en = text(row[0].value), text(row[6].value)
                    if ua and en:
                        names[key(ua)] = en
    translations = gettext.translation(
        "iso3166-1", pycountry.LOCALES_DIR, languages=["uk"]
    )
    for country in pycountry.countries:
        for field in ["name", "official_name", "common_name"]:
            name = getattr(country, field, "")
            if name:
                names.setdefault(key(translations.gettext(name)), country.name)
    aliases_path = ROOT / "metadata/country_aliases.csv"
    if aliases_path.exists():
        with aliases_path.open(encoding="utf-8") as handle:
            for alias in csv.DictReader(handle):
                country = pycountry.countries.get(alpha_3=alias["iso3"])
                if country:
                    names[key(alias["source_label"])] = country.name
    products, specials, totals, missing = [], [], [], {}
    with zipfile.ZipFile(ROOT / "raw/ukrstat/partner_product.zip") as archive:
        for member in archive.namelist():
            if not member.endswith(".xls"):
                continue
            year_match = re.search(r"20\d{2}", member)
            if year_match is None:
                raise ValueError(f"No year in archive member: {member}")
            year = int(year_match.group())
            sheet = xlrd.open_workbook(
                file_contents=archive.read(member)
            ).sheet_by_index(0)
            if "тис." not in text(sheet.cell_value(4, 1)):
                raise ValueError(f"Unexpected units in {member}")
            partner, en, code = "", "", ""
            for r in range(5, sheet.nrows):
                row = sheet.row_values(r)
                label = text(row[0])
                if not label or not (number(row[1]) or number(row[4])):
                    continue
                match = re.match(r"^(\d{2})\s+", label)
                special = key(label) in {key("Товари, придбані в портах"), key("Різне")}
                if not match and not special:
                    partner = label
                    en = names.get(key(label), "")
                    code = iso(en) if en else ""
                    if not code:
                        missing[key(label)] = {
                            "partner_name_uk": label,
                            "partner_name_en": en,
                        }
                for flow, col in [("export", 1), ("import", 4)]:
                    value = row[col]
                    base = {
                        "year": year,
                        "flow": flow,
                        "partner_name_uk": partner,
                        "partner_name_en": en,
                        "partner_iso3": code,
                        "partner_type": "country_or_territory"
                        if code
                        else "aggregate_or_unmapped",
                        "value_usd": value * 1000 if number(value) else "",
                        "source_value": value,
                        "source_unit": "thousand USD",
                        "source_file": "raw/ukrstat/partner_product.zip",
                        "source_member": member,
                        "source_sheet": sheet.name,
                        "source_row": r + 1,
                    }
                    if match:
                        base.update(
                            hs2=match.group(1),
                            product_name_uk=label,
                            teaching_sector=sector(match.group(1)),
                        )
                        products.append(base)
                    elif special:
                        base.update(
                            hs2="",
                            product_name_uk=label,
                            teaching_sector="Special or unclassified",
                        )
                        specials.append(base)
                    else:
                        totals.append(base)
    save("goods_partner_hs2_ukrstat_2011_2023.csv", products)
    save("goods_special_products_ukrstat_2011_2023.csv", specials)
    save("goods_partner_totals_ukrstat_2011_2023.csv", totals)
    save("ukrstat_unmapped_partner_labels.csv", list(missing.values()))
    book = xlrd.open_workbook(str(ROOT / "raw/ukrstat/geography_1996_2023.xls"))
    sheet = book.sheet_by_index(0)
    rows, flow = [], ""
    for r in range(3, sheet.nrows):
        first = sheet.cell_value(r, 0)
        if "Експорт" in str(first):
            flow = "export"
        elif "Імпорт" in str(first) or "Iмпорт" in str(first):
            flow = "import"
        elif year_match := re.match(r"^\s*(199\d|20[0-2]\d)\b", str(first)):
            year = int(year_match[1])
            for col in range(1, sheet.ncols):
                value = sheet.cell_value(r, col)
                rows.append(
                    {
                        "year": year,
                        "flow": flow,
                        "source_year_label": first,
                        "partner_group_source_label": sheet.cell_value(2, col),
                        "value_usd": value * 1_000_000 if number(value) else "",
                        "source_value": value,
                        "source_unit": "million USD",
                        "source_file": "raw/ukrstat/geography_1996_2023.xls",
                        "source_row": r + 1,
                        "source_column": col + 1,
                    }
                )
    save("goods_geographical_groups_ukrstat_1996_2023.csv", rows)


def nbu():
    file = "raw/nbu/Trade_y_en.xlsx"
    book = openpyxl.load_workbook(ROOT / file, read_only=True, data_only=True)
    # Table number, flow, name column, first value row, output family.
    tables = [
        ("1.10", "export", 5, 7, "goods_partners"),
        ("1.11", "import", 5, 7, "goods_partners"),
        ("2.3", "export", 2, 10, "computer_services_partners"),
        ("2.4", "import", 2, 10, "computer_services_partners"),
        ("1.1 ", "export", 2, 7, "goods_products"),
        ("1.2", "import", 2, 7, "goods_products"),
        ("2.1", "export", 2, 9, "services_types"),
        ("2.2", "import", 2, 9, "services_types"),
    ]
    families = {}
    for sn, flow, label_col, first_row, family in tables:
        sheet = book[sn]
        values = list(sheet.values)
        header_index = 4 if family == "goods_products" else 5
        years = [
            (i, int(str(v)))
            for i, v in enumerate(values[header_index])
            if str(v).isdigit() and 1991 <= int(str(v)) <= 2026
        ]
        if not years:
            raise ValueError(f"No year header in {sn}")
        for r in range(first_row - 1, len(values)):
            row = values[r]
            label = text(row[label_col])
            if not label or not any(number(row[c]) for c, _ in years):
                continue
            # Goods-products tables also contain percentage-change and percentage-share blocks.
            if family == "goods_products" and (
                "%" in label or "changes" in label.lower()
            ):
                break
            if family == "goods_products" and r >= 15:
                break
            is_total = label.upper().startswith("TOTAL") or label == "Computer services"
            if "partners" in family:
                kind = (
                    "world_total"
                    if is_total
                    else (
                        "country_or_territory"
                        if iso(label)
                        else "aggregate_or_unmapped"
                    )
                )
            else:
                kind = "hierarchical_category_do_not_sum_all_rows"
            for c, year in years:
                value = row[c]
                families.setdefault(family, []).append(
                    {
                        "year": year,
                        "flow": flow,
                        "category_or_partner": label,
                        "partner_iso3": iso(label) if "partners" in family else "",
                        "row_type": kind,
                        "value_usd": value * 1_000_000 if number(value) else "",
                        "source_value": "" if value is None else value,
                        "source_unit": "million USD",
                        "source_file": file,
                        "source_sheet": sn,
                        "source_row": r + 1,
                        "source_column": c + 1,
                    }
                )
    for family, rows in families.items():
        save(f"{family}_nbu.csv", rows)
    book.close()


def jsonstat_rows(data):
    dims = data["id"]
    codes = []
    for dim in dims:
        index = data["dimension"][dim]["category"]["index"]
        codes.append(
            [code for code, _ in sorted(index.items(), key=lambda item: item[1])]
        )
    for flat, value in data.get("value", {}).items():
        offset, positions = int(flat), []
        for size in reversed(data["size"]):
            positions.append(offset % size)
            offset //= size
        row = {
            dim: codes[i][pos]
            for i, (dim, pos) in enumerate(zip(dims, reversed(positions), strict=True))
        }
        row["value"] = value
        row["status"] = data.get("status", {}).get(flat, "")
        yield row


def eurostat():
    for filename, outname in [
        (
            "ukraine_world_partners_sitc1.json",
            "goods_partner_sitc1_eurostat_ukraine.csv",
        ),
        ("eu27_ukraine_sitc1.json", "goods_sitc1_eurostat_eu27_mirror.csv"),
    ]:
        path = ROOT / "raw/eurostat" / filename
        data = load_json(path)
        labels = data["dimension"]["partner"]["category"]["label"]
        products = data["dimension"]["product"]["category"]["label"]
        rows = []
        for r in jsonstat_rows(data):
            partner = r["partner"]
            country = iso(partner)
            year = int(r["time"])
            rows.append(
                {
                    "year": year,
                    "reporter": r["reporter"],
                    "partner_code": partner,
                    "partner_name": labels[partner],
                    "partner_iso3": country,
                    "partner_type": "country_or_territory"
                    if country
                    else "aggregate_or_unmapped",
                    "reporter_flow": "import" if r["flow"] == "1" else "export",
                    "ukraine_flow": ("export" if r["flow"] == "1" else "import")
                    if r["reporter"] != "UA"
                    else ("import" if r["flow"] == "1" else "export"),
                    "sitc1": r["product"],
                    "product_name": products[r["product"]],
                    "value_eur": r["value"],
                    "status": r["status"],
                    "period_scope": "partial_current_year"
                    if year == 2026
                    else "annual",
                    "source_file": str(path.relative_to(ROOT)),
                    "dataset": "DS-059331",
                }
            )
        save(outname, rows)
    path = ROOT / "raw/eurostat/eu27_ukraine_totals.json"
    data = load_json(path)
    rows = []
    for r in jsonstat_rows(data):
        rows.append(
            {
                "year": int(r["time"]),
                "reporter": r["geo"],
                "partner": r["partner"],
                "indicator": r["indic_et"],
                "indicator_label": data["dimension"]["indic_et"]["category"]["label"][
                    r["indic_et"]
                ],
                "value": r["value"],
                "status": r["status"],
                "source_file": str(path.relative_to(ROOT)),
                "dataset": "ext_lt_maineu",
            }
        )
    save("goods_eu27_totals_eurostat.csv", rows)


def wdi():
    rows = []
    for path in sorted((ROOT / "raw/worldbank").glob("*.json")):
        data = load_json(path)
        if not isinstance(data, list) or len(data) != 2 or data[0]["pages"] != 1:
            raise ValueError(f"Invalid or paginated WDI response: {path}")
        for r in data[1]:
            year = int(r["date"])
            if not 1991 <= year <= 2026:
                continue
            rows.append(
                {
                    "year": year,
                    "indicator": r["indicator"]["id"],
                    "indicator_label": r["indicator"]["value"],
                    "value": "" if r["value"] is None else r["value"],
                    "obs_status": r["obs_status"],
                    "api_unit": r["unit"],
                    "source_last_updated": data[0]["lastupdated"],
                    "source_file": str(path.relative_to(ROOT)),
                }
            )
    save("economic_context_wdi_1991_latest.csv", rows)


def inventory_and_integrity():
    manifest = load_json(ROOT / "manifest.json")
    for entry in manifest:
        if entry["status"] != "downloaded":
            raise ValueError(f"Failed download remains: {entry['id']}")
        path = ROOT / entry["file"]
        if hashlib.sha256(path.read_bytes()).hexdigest() != entry["sha256"]:
            raise ValueError(f"Checksum mismatch: {path}")
    rows = []
    for path in sorted((ROOT / "raw").rglob("*.zip")):
        with zipfile.ZipFile(path) as archive:
            if archive.testzip() is not None:
                raise ValueError(f"Corrupt ZIP: {path}")
            for entry in archive.infolist():
                if not entry.is_dir():
                    rows.append(
                        {
                            "archive": str(path.relative_to(ROOT)),
                            "member": entry.filename,
                            "uncompressed_bytes": entry.file_size,
                        }
                    )
    save("archive_inventory.csv", rows)


def main():
    inventory_and_integrity()
    ukrstat_goods()
    nbu()
    eurostat()
    wdi()
    (ROOT / "coverage.json").write_text(
        json.dumps(COVERAGE, ensure_ascii=False, indent=2) + "\n"
    )


if __name__ == "__main__":
    main()
