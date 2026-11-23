#!/usr/bin/env python3
"""Package existing observations and published paper tables for slides. No model fitting."""

import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESEARCH = ROOT / "research/hybrid-wars"


def read_rows(path, delimiter=","):
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle, delimiter=delimiter))


def main():
    macro = {}
    for row in read_rows(ROOT / "data/economic_context_wdi_1991_latest.csv"):
        macro.setdefault(row["year"], {})[row["indicator"]] = (
            float(row["value"]) if row["value"] else None
        )
    countries = []
    for row in read_rows(
        RESEARCH / "original/Bluszcz_Valente_repdata_countries.csv", ";"
    ):
        countries.append(
            {
                "id": int(row["Id"]),
                "country": row["Country"],
                "year": int(row["Year"]),
                "gdppc": float(row["GDP_2011"].replace(",", ".")),
            }
        )
    weights = [
        {"country": "Moldova", "iso3": "MDA", "weight": 0.452},
        {"country": "Armenia", "iso3": "ARM", "weight": 0.333},
        {"country": "Bulgaria", "iso3": "BGR", "weight": 0.152},
        {"country": "Slovenia", "iso3": "SVN", "weight": 0.063},
    ]
    donors = {
        "Armenia": "ARM",
        "Azerbaijan": "AZE",
        "Belarus": "BLR",
        "Bulgaria": "BGR",
        "Czech": "CZE",
        "Estonia": "EST",
        "Hungary": "HUN",
        "Kazakhstan": "KAZ",
        "Kyrgyz Republic": "KGZ",
        "Latvia": "LVA",
        "Lithuania": "LTU",
        "Moldova": "MDA",
        "Poland": "POL",
        "Romania": "ROU",
        "Slovakia": "SVK",
        "Slovenia": "SVN",
        "Tajikistan": "TJK",
    }
    published = [
        {"year": 2013, "synthetic": 8799.18, "shortfall": 460.26, "percent": 5.23},
        {"year": 2014, "synthetic": 9076.43, "shortfall": 832.96, "percent": 9.18},
        {"year": 2015, "synthetic": 9280.71, "shortfall": 1823.78, "percent": 19.63},
        {"year": 2016, "synthetic": 9561.48, "shortfall": 1893.38, "percent": 19.80},
        {"year": 2017, "synthetic": 10078.52, "shortfall": 2184.13, "percent": 21.67},
    ]
    payload = {
        "snapshotDate": "2026-11-15",
        "macro": macro,
        "countries": countries,
        "weights": weights,
        "donors": donors,
        "published": published,
        "leaveOneOut": [
            {"label": "Original comparison", "loss": 1438.9},
            {"label": "Without Slovenia", "loss": 1501.0},
            {"label": "Without Bulgaria", "loss": 1666.4},
            {"label": "Without Armenia", "loss": 1737.9},
            {"label": "Without Moldova", "loss": 1587.4},
        ],
        "replicationStatus": {
            "estimatorRun": False,
            "mode": "published-weight reconstruction",
            "note": "Rounded published weights and author observations; no weights were re-estimated. Published table results are labeled separately.",
        },
        "sources": {
            "wdi": {
                "label": "World Bank WDI, saved 15 Nov 2026",
                "url": "https://data.worldbank.org/country/ukraine",
            },
            "independence": {
                "label": "Verkhovna Rada: independence and the 1991 referendum",
                "url": "https://www.rada.gov.ua/en/news/News/top_news/230954.html",
            },
            "transition": {
                "label": "World Bank: Ukraine Country Private Sector Diagnostic, 2021",
                "url": "https://documents1.worldbank.org/curated/en/791871621302772828/pdf/Main-Report.pdf",
            },
            "gfc": {
                "label": "IMF: Ukraine's 2008 financial crisis",
                "url": "https://www.imf.org/en/news/articles/2015/09/28/04/53/socar081110a",
            },
            "conflict2014": {
                "label": "World Bank: Ukraine Country Partnership Framework, 2017",
                "url": "https://documents1.worldbank.org/curated/en/847421498183265026/pdf/Ukraine-Country-Partnership-Framework-FY2017-21-05262017.pdf",
            },
            "invasion": {
                "label": "World Bank: recovery during war, 2023",
                "url": "https://www.worldbank.org/en/results/2023/11/30/the-world-bank-and-ukraine-laying-the-groundwork-for-reconstruction-in-the-midst-of-war",
            },
            "paper": {
                "label": "Bluszcz & Valente, Defence and Peace Economics, 2022",
                "url": "https://doi.org/10.1080/10242694.2020.1791616",
            },
            "package": {
                "label": "Author replication package, version 1, CC BY 4.0",
                "url": "https://data.mendeley.com/datasets/9bwk589xz6/1",
            },
            "gisco": {
                "label": "GISCO 2024. © EuroGeographics for the administrative boundaries",
                "url": "https://ec.europa.eu/eurostat/web/gisco/geodata/administrative-units",
            },
        },
    }
    path = ROOT / "deck/data.json"
    path.parent.mkdir(exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, allow_nan=False) + "\n"
    )
    print(
        f"Packaged {len(countries)} original country-year observations. No estimator run."
    )


if __name__ == "__main__":
    main()
