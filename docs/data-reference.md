# Data reference

## Start here

For a map with year and product filters, use:

- `data/goods_partner_hs2_ukrstat_2011_2023.csv`. Ukraine-reported exports and imports by partner and two-digit UKTZED commodity chapter, 2011–2023. There are 232,586 rows before filtering aggregates. Values are current USD.
- `data/goods_partner_totals_ukrstat_2011_2023.csv`. Published partner totals, including world and regional aggregates. Use this instead of summing product rows when you want total bilateral trade.
- `data/goods_partner_sitc1_eurostat_ukraine.csv`. Ukraine as reporter, global partners, ten broad SITC product sections and TOTAL, actual observations in 2012–2024. Values are current EUR. **2016 has only TOTAL trade, with no SITC section observations**, and 412 rows versus roughly 2,300–3,500 in most other years. The dataset title says "since 2002", but Ukraine does not have observations in 2002–2011 in this extract.
- `data/goods_partners_nbu.csv`. Selected partner countries and the published world total, 2010–2025. This is not an exhaustive country list. Useful for more recent snapshots and for Russia, China, and Poland over time.
- `data/computer_services_partners_nbu.csv`. Computer-services exports and imports, selected partners, a total, and an "Other countries" residual, 2011–2025. This adds the services economy that a goods-only map misses.
- `raw/geography/CNTR_RG_20M_2024_4326.geojson`. Eurostat GISCO world country polygons, WGS84 longitude/latitude, simplified at 1:20 million scale. Join `partner_iso3` to feature property `ISO3_CODE`. Keep Ukraine highlighted as the reporting country.

For economy-wide change, use `data/economic_context_wdi_1991_latest.csv`. It contains GDP, real GDP growth, real GDP per capita, broad sector shares, trade-to-GDP ratios, and population. Nonmissing observations extend through 2025 in this snapshot. Manufacturing share starts in 1992; its 1991 entry stays blank.

## What is actually available

Coverage below describes the downloaded files, not a guarantee that every cell is available.

| Source and subject | Verified coverage | Detail | Files |
| --- | --- | --- | --- |
| Ukrstat goods, geographical groups | 1996–2023 | World, CIS, EU27, continents; annual exports and imports | `raw/ukrstat/geography_1996_2023.xls`; derived geographical-groups CSV |
| Ukrstat goods, partner × commodity | 2011–2023 | Countries × two-digit UKTZED chapters; annual exports and imports | `raw/ukrstat/partner_product.zip`; derived HS2, special-products, and totals CSVs |
| Ukrstat goods, alternative partner definitions | 2013–2023 | Destination, origin, consignment, trading country | `raw/ukrstat/partners.zip` |
| Ukrstat goods, annual product and geography archives | Files dated 2001–2023 | Early files are Word documents, later files are spreadsheets; some years have multiple releases | `raw/ukrstat/products.zip`, `geography.zip` |
| Ukrstat goods, EU product composition | 2018–2023 | Commodities, EU aggregate | `raw/ukrstat/eu_products.zip` |
| NBU goods, broad commodity composition | 2005–2025 | Eight product groups plus total, BPM6 | `raw/nbu/Trade_y_en.xlsx`, sheets `1.1 ` and `1.2`; `data/goods_products_nbu.csv` |
| NBU goods, selected partner countries | 2010–2025 | Exports and imports; world total and selected countries | Same workbook, sheets `1.10`, `1.11`; derived partners CSV |
| NBU services, service types | 2010–2025 | Detailed hierarchical service categories, BPM6 | Same workbook, sheets `2.1`, `2.2`; `data/services_types_nbu.csv` |
| NBU computer services, selected partners | 2011–2025 | Partner × computer services, exports and imports | Same workbook, sheets `2.3`, `2.4`; derived computer-services CSV |
| NBU latest monthly goods and services | Monthly tables include January–September 2026 | Commodity and services series; table layouts and start dates vary | `raw/nbu/Trade_m_en.xlsx`, retained as an original workbook |
| NBU EU trade | Annual workbook through 2025 | Goods and services, EU relationship | `raw/nbu/EU_y_en.xlsx` |
| NBU historical balance of payments | 1994–2014 | BPM5 macro balance-of-payments history | `raw/nbu/DIN_BOP_BPM5_y_en.xlsx` |
| NBU old goods methodology | Commodity tables include 2001–2014 | BPM5, keep separate from BPM6 | `raw/nbu/Tov_BPM5_y_en.xlsx` |
| NBU balance of payments and inward FDI | Current annual workbooks through 2025; starting dates vary by sheet | External accounts; FDI positions by country and economic activity | `raw/nbu/BOP_y_en.xlsx`, `FDI_Ls_y_en.xlsx` |
| Ukrstat services, historical geography | 1996–2021 | Geographical-group history | `raw/ukrstat/services_geography_1996_2021.zip` |
| Ukrstat services, country and type histories | 2000–2021 | Separate country and service-type series | `raw/ukrstat/services_countries_2000_2021.zip`, `services_types_2000_2021.zip` |
| Ukrstat services, partner × service type | 2014–2025 | Eight annual XLS files for 2014–2021 and four XLSX files for 2022–2025 | `raw/ukrstat/services_country_type_archive.zip`, `services_partner_type_2022.xlsx` through `services_partner_type_2025.xlsx` |
| Eurostat, Ukraine-reported global trade | Actual observations 2012–2024; 2016 has TOTAL only | Global partner × SITC section, in EUR | `raw/eurostat/ukraine_world_partners_sitc1.json`; derived Ukraine-reporter CSV |
| Eurostat, EU-reported trade with Ukraine | Actual observations 2002–2025 | Fixed EU27_2020 reporter, SITC sections, in EUR | `raw/eurostat/eu27_ukraine_sitc1.json`; derived mirror CSV |
| Eurostat, EU aggregate totals | 2002–2025 | Imports, exports, balance in EUR millions; partner shares in percent | `raw/eurostat/eu27_ukraine_totals.json`; `data/goods_eu27_totals_eurostat.csv` |
| World Bank WDI, economic context | 1991–2025, with indicator-specific missing values | Eleven indicators for Ukraine | `raw/worldbank/*.json`; derived economic-context CSV |

The archives are deliberately retained intact. `data/archive_inventory.csv` lists all 102 contained files, including their original filenames and years. Word tables and the services workbooks have **not** all been converted into a common schema. The derived CSVs are a selected, checked teaching subset, not an exhaustive transcription of every source file.

## Product groups are not industries

UKTZED is Ukraine's commodity classification, based on the Harmonized System. SITC is another product classification. Neither directly measures the industry of the exporting firm or domestic value added.

The `teaching_sector` field groups HS chapters into readable lecture categories, such as agriculture and food, metals, and machinery. These are our groupings, not an official NACE or KVED industry concordance. The exact ranges are in `scripts/build_tables.py`, function `sector`. Keep the original two-digit codes, including leading zeros, when importing CSV files into Excel.

For actual domestic economic structure, use the WDI agriculture, industry, manufacturing, and services shares of GDP. Manufacturing is a subset of industry, not a fourth category to add to the other three. Value-added shares need not add to 100% of GDP because GDP also includes taxes less subsidies on products. For services trade, use the separate service classifications in the original Ukrstat and NBU workbooks. FDI by economic activity is available in the NBU download but is investment, not trade.

Ukrstat also lists goods trade by enterprise economic activity and employment size on its [goods dataset page](https://stat.gov.ua/uk/datasets/zovnishnya-torhivlya-tovaramy). Those additional archives were identified but not downloaded. A historical partner × actual-industry panel remains an additional research task.

## A workable lecture sequence

1. Begin in 1991 with real GDP indexed to 1991 = 100, annual GDP growth, and sector shares. Use constant-price GDP, not current-dollar GDP, to discuss output growth.
2. Use the 1996–2023 geographical-group table to show the changing EU share of goods exports and imports. Divide the published EU27 value by the published world total within the same year and flow. Do not add overlapping geographical groups.
3. Show country maps for 2011, 2013, 2019, 2021, and 2023 from the same Ukrstat dataset. Switch between food, metals, and machinery; keep exports and imports separate.
4. Add a 2025 selected-partner snapshot from NBU, clearly marking the source change and limited country coverage. Do not treat it as a seamless extension of the full Ukrstat panel.
5. Contrast goods with computer-services exports by partner and the broader NBU service-type composition.
6. End with January–September 2026 as a separate partial-year panel. Compare it with January–September of earlier years in the monthly workbook, not with full-year 2025.

For a country map, filter `partner_type = country_or_territory`. For Eurostat also select one `sitc1`, or select sections 0–9 and exclude TOTAL before summing. Use a fixed color scale across years, and show both dollar/euro values and shares of the relevant world total. Missing observations must have a different appearance from reported zeros.

For NBU maps, filter `row_type = country_or_territory`. Calculate shares using the source's world or computer-services total, not the sum of the displayed countries. Selected partner lists are not necessarily the top partners in each historical year.

## Comparability cautions

- **1991–1995 is a trade-data gap in this package.** NBU provides aggregate external accounts from 1994, but no verified country-by-product panel for these early years was downloaded. Soviet inter-republic deliveries and later international trade do not have identical coverage. Do not extrapolate the 1996 partner mix back to independence.
- **Territorial and reporting coverage changes.** Ukrstat and NBU footnotes exclude temporarily occupied territories and, in relevant series, some areas affected by hostilities. Mark 2014 and 2022 as breaks in the charts. A decline can reflect changed coverage as well as changed activity. The map geometry is not a map of statistical coverage or military control.
- **Goods versus balance of payments.** Customs/statistical goods series and BPM6 ownership-based goods series have adjustments. NBU's country sheets carry the footnote "According to State Statistics Service of Ukraine data" despite the workbook's BPM6 headings. Do not assume that the country-sheet totals equal the commodity-sheet totals. The reconciliation is also documented in workbook sheet `3.2` and `raw/methodology/ukrstat_customs_nbu_differences.pdf`.
- **BPM5 versus BPM6.** The old NBU workbooks are useful historical material, not a continuation to append without adjustment.
- **Mirror trade is different.** EU imports from Ukraine correspond to Ukrainian exports, and EU exports to Ukraine correspond to Ukrainian imports. The Eurostat mirror CSV contains both `reporter_flow` and the reversed `ukraine_flow`. Different valuation, timing, partner attribution, and coverage mean mirror values need not match Ukrainian reports.
- **Partner attribution matters.** Country of origin, destination, consignment, and trading-counterparty residence can differ. The Ukrstat HS2 workbook specifies origin/destination; the separate `partners.zip` shows alternatives. The country of an IT client is not necessarily the location of the ultimate user.
- **Current prices and currencies.** USD and EUR series are nominal. Do not combine them without an explicit conversion. Commodity-price and exchange-rate changes can move values even when quantities do not change.
- **Classification changes.** HS/UKTZED and SITC are different. HS revisions can affect comparisons even within broad chapters. Do not join them by code or present a teaching grouping as an official industry measure.
- **Aggregates and residuals.** World, continents, EU, CIS, "Other", and undistributed trade are not additional countries. Group labels can overlap. The geographical-history workbook stops filling the CIS/other-world split in later years; those blanks remain blank.
- **Missing and confidential cells.** Source symbols remain in `source_value`; the numeric value field stays blank when a cell is nonnumeric. No missing country-product records have been invented as zero. In original services workbooks, `c` marks confidential cells; retain source footnotes when interpreting `-` and other symbols.
- **Published component discrepancies.** Sixteen partner-year-flow totals differ from the sum of published product lines by more than USD 1. The largest is USD 1,181.33 for Réunion imports in 2017. See `metadata/reconciliation_differences.csv`. No balancing item was invented.
- **Historical country names.** Source labels remain intact. Modern ISO3 joins use source bilingual labels, pycountry's Ukrainian translations, and the explicit overrides in `metadata/country_aliases.csv`. The dissolved Netherlands Antilles and statistical aggregates remain unmatched. Review `data/ukrstat_unmapped_partner_labels.csv` rather than silently deleting them.
- **Latest does not mean final.** 2025 is the latest full calendar year in the collected annual series. NBU's monthly workbook includes September 2026. Revisions are possible. A year appearing in API metadata is not proof of an observation; `coverage.json` counts actual exported rows.

## Files, units, and provenance

```text
raw/                 Unmodified source bytes, grouped by publisher
  ukrstat/           Goods and services archives and workbooks
  nbu/               English-language trade, BOP, and FDI workbooks
  eurostat/          JSON-stat API extracts
  worldbank/         One WDI API response per indicator
  geography/         GISCO GeoJSON
  methodology/       Ukrainian official methodological PDFs
data/                UTF-8 CSV teaching tables and archive inventory
metadata/            Country-name overrides, reconciliation report, research notes
prototype/           Local D3 atlas, compact JSON payload, screenshots, browser QA
deck/                Quarto lecture, charts, and legacy D3 prototype
research/            Original paper/data/code, audit notes, and R replication results
scripts/             Download, transformation, and offline validation
sources.json         Exact URLs and destination paths
manifest.json        Retrieval times, sizes, SHA-256 hashes, HTTP metadata
coverage.json        Derived row counts by file and year
uv.lock              Locked Python dependencies
```

`value_usd` and `value_eur` are single currency units, not thousands or millions. Ukrstat inputs in thousands of USD are multiplied by 1,000; NBU inputs in millions are multiplied by 1,000,000. Original `source_value`, `source_unit`, workbook sheet, row, and often column are retained. Rows/columns use one-based spreadsheet numbering. Eurostat inputs are sparse JSON-stat; only returned observations are exported, and source status flags are preserved. In `goods_eu27_totals_eurostat.csv`, values retain the indicator's original units rather than a common currency column.

NBU service-type rows are hierarchical. Do not sum the total and all subcategories together. The NBU goods-products CSV includes only the value block, not the workbook's following percentage and growth-rate blocks. Special non-HS goods lines, including purchases in ports, are in `data/goods_special_products_ukrstat_2011_2023.csv` and must be considered when reconciling totals.

WDI indicator labels carry their units. `api_unit` is often empty and must not be interpreted as "unitless". The real-GDP series is labeled in constant 2015 US dollars in this download. Population and GDP per capita need special care during displacement and changes in territorial coverage.

## Reproduce and check

Python 3.11+ and [uv](https://docs.astral.sh/uv/) are sufficient. No API keys or subscriptions are required for the registered downloads.

```bash
uv sync --locked
uv run python scripts/build_tables.py
uv run python scripts/validate.py
uv run ruff check scripts
```

Validation checks all 38 source hashes, year/flow coverage, unique HS2 keys, unit conversion, exclusion of percentage blocks, Eurostat mirror directions, missing early macro values, and the Ukraine map geometry. Seven offline tests passed when this folder was prepared. The geometry check confirms that the point 34.1°E, 44.95°N in Crimea lies inside the supplied Ukraine polygon.

To retrieve a fresh snapshot, which **overwrites** registered raw files and their manifest entries:

```bash
uv run python scripts/download.py
# Or refresh only a selected file:
uv run python scripts/download.py --id nbu_trade_monthly
```

Copy the folder first if you need to preserve this snapshot. Rerun the build and validation afterwards. Coverage assertions deliberately describe this snapshot and may need review when publishers add years. Source links can move; the registry does not scrape for replacement URLs. Single-indicator WDI requests were used because combined requests timed out during collection.

## Official source pages and further access

- [Ukrstat goods dataset and archives](https://stat.gov.ua/uk/datasets/zovnishnya-torhivlya-tovaramy)
- [Ukrstat services dataset and archives](https://stat.gov.ua/uk/datasets/zovnishnya-torhivlya-posluhamy)
- [NBU external-sector statistics](https://bank.gov.ua/en/statistic/sector-external)
- [Eurostat DS-059331 browser](https://ec.europa.eu/eurostat/databrowser/view/DS-059331/default/table?lang=en)
- [Eurostat detailed goods metadata](https://ec.europa.eu/eurostat/cache/metadata/en/ext_go_detail_sims.htm)
- [Eurostat dedicated Comext API instructions](https://ec.europa.eu/eurostat/web/user-guides/data-browser/api-data-access/api-getting-started/comext-database)
- [Eurostat detailed HS/CN dataset DS-045409](https://ec.europa.eu/eurostat/databrowser/view/DS-045409/default/table?lang=en). Further detailed EU mirror data, not bulk-downloaded here.
- [Ukrainian Customs statistics and registers](https://customs.gov.ua/en/statistika-ta-reiestri) and [open data](https://customs.gov.ua/en/open-data). Potential latest country/product source, but direct access returned HTTP 403 during this collection. Customs data are not silently substituted with another source.
- [UN Comtrade availability explorer](https://comtradeplus.un.org/en/data-availability) and [WITS Ukraine 1996](https://wits.worldbank.org/CountryProfile/en/Country/UKR/Year/1996/Summary). Useful next stops for extending the early bilateral series. Ukraine's reporter code is 804. Availability must be checked by year and classification. These are additional leads, not downloaded panels.
- [World Bank Ukraine indicators](https://data.worldbank.org/country/ukraine)
- [GISCO country boundaries](https://gisco-services.ec.europa.eu/distribution/v2/countries/)

## Attribution and reuse

Cite the publisher, dataset, relevant year, and retrieval date on slides. Keep Ukrainian, Eurostat mirror, and World Bank series clearly labeled. Downloadable does not mean public domain, and the datasets do not share one blanket license.

**GISCO boundaries have specific noncommercial-use conditions.** Put this required credit in the map legend and introductory slide: **© EuroGeographics for the administrative boundaries**. Review the [GISCO download provisions](https://ec.europa.eu/eurostat/web/gisco/geodata/administrative-units) before publication, redistribution, or any commercial use. The supplied geometry includes Crimea within Ukraine; it does not depict current territorial control. Review the other publishers' reuse policies before redistributing their source files.
