# Collection notes

Collected 2026-11-15 UTC. This is a data-availability investigation and a usable data package, not a claim that all Ukrainian historical statistics have been located.

## Source selection

1. Started with the [State Statistics Service goods dataset](https://stat.gov.ua/uk/datasets/zovnishnya-torhivlya-tovaramy). Its archive links supplied the geographical history, country-by-product tables, and national/EU product and geography archives. Archive filenames and spreadsheet headers confirmed years and units.
2. Used the [Ukrstat services page](https://stat.gov.ua/uk/datasets/zovnishnya-torhivlya-posluhamy) for country-by-service workbooks. The archive contains 2014–2021; the page separately links final annual 2022, 2023, 2024, and 2025 workbooks. All were downloaded, but not normalized into one derived panel.
3. Used the [NBU external-sector page](https://bank.gov.ua/en/statistic/sector-external) to identify official English-language annual and monthly workbooks. The page listed annual 2025 and monthly September 2026. Header inspection confirmed September 2026 columns in the monthly workbook. Annual commodity and services sheets carry different update dates from the country sheets. See the original sheets rather than applying a single workbook-level release date.
4. Queried Eurostat's dedicated Comext statistics endpoint for DS-059331 with annual frequency, VALUE_EUR, products TOTAL and 0–9, and two separate reporters. Reporter UA produces Ukraine's global partner trade. Reporter EU27_2020 and partner UA produce EU-reported mirror trade. The original JSON-stat files preserve dimension labels, sparse observation indexes, and metadata.
5. Verified actual Eurostat values rather than trusting its title or the time dimension. The Ukraine extract has observations only in 2012–2024, and its 2016 observations are exclusively TOTAL. The EU mirror extract has observations in 2002–2025. Both responses list years without observations in their time dimensions. There is no attempt to fill those cells.
6. Used [World Bank WDI](https://data.worldbank.org/country/ukraine) as an explicitly labeled international supplement for economic structure and output since 1991. The combined-indicator API request repeatedly timed out. Separate single-indicator requests succeeded. This does not establish that all WDI values are original Ukrainian official estimates on unchanged territory.
7. Downloaded [GISCO 2024 country geometry](https://gisco-services.ec.europa.eu/distribution/v2/countries/) for a practical map join. Checked the required [noncommercial-use and attribution terms](https://ec.europa.eu/eurostat/web/gisco/geodata/administrative-units). An offline geometry test confirms a Crimea point is included in Ukraine. This is not a historical border reconstruction or a control map.

Every retained download has its exact URL, retrieval timestamp, byte count, SHA-256 hash, and available HTTP metadata in `manifest.json`. The original download code used httpx; the final downloader uses Python's standard HTTPS client and was smoke-tested against registered sources. Transformation scripts retain original files and do not modify source bytes.

## Remaining leads and limits

- The Ukrainian Customs [statistics page](https://customs.gov.ua/en/statistika-ta-reiestri) returned HTTP 403 to direct content retrieval. Search results identified the official statistics and open-data routes, but no Customs file is included. No authenticated access or access-control workaround was attempted.
- The [UN Comtrade availability explorer](https://comtradeplus.un.org/en/data-availability) is the next source to check for earlier country-by-commodity coverage. A public preview query for annual Ukraine-reported 1992 total goods trade returned zero records. That single check does not prove the absence of all 1991–1995 data across classifications or mirror reporters. The response was exploratory and is not a retained dataset.
- [WITS Ukraine 1996](https://wits.worldbank.org/CountryProfile/en/Country/UKR/Year/1996/Summary) confirms a Comtrade-sourced 1996 profile, but a 1996–2010 bilateral panel was not downloaded here.
- [Eurostat DS-045409](https://ec.europa.eu/eurostat/databrowser/view/DS-045409/default/table?lang=en) can provide finer HS/CN mirror detail. Its "since 1988" title does not establish Ukraine-specific observations in 1991. That coverage needs checking by actual reporter/partner/year.
- The Ukrstat goods page also lists enterprise economic-activity and employment-size archives. These may help with actual industry rather than commodity composition, but do not by themselves establish a partner-by-industry series. They were not downloaded.
- Early Ukrstat Word documents remain in their original archives. Their contents should be checked before claiming a complete country panel for each early year. The archive inventory is a file-level listing, not a declaration that every file shares one schema.

## Transformation decisions

- HS2 labels are commodity chapters. The broad teaching-sector field is a hand-defined chapter grouping, not a statistical industry concordance.
- A country's "Різне" and "Товари, придбані в портах" lines are special product lines. They are stored separately and never treated as additional partner countries.
- The geographical-history workbook writes footnotes into some year cells. The parser keeps the original year-cell label and extracts the four-digit year rather than dropping 2014 onward.
- NBU commodity sheets contain value, percentage-share, and growth blocks. Only the first value block is exported to the goods-products CSV.
- Country matching is deterministic. Source bilingual labels, pycountry's Ukrainian names, and explicit overrides map to current ISO3 codes. No fuzzy matching is used. The dissolved Netherlands Antilles and aggregates retain their source labels and do not receive invented current-country geometry joins.
- Sparse API observations remain sparse. Missing values are not imputed, and the original USD and EUR concepts are not combined.
- Sixteen published partner totals differ from the component sums by more than USD 1. The difference report records the discrepancies without changing either source total or component values.

## Completion checks

All 38 source downloads succeeded and their hashes passed the offline check. All 102 archive member files are listed in `data/archive_inventory.csv`. Fourteen derived CSV files have row counts and year coverage recorded in `coverage.json`. Seven offline validation tests passed, and Ruff passed on the three scripts. These checks validate the package's transformations and selected coverage, not the accuracy of every original statistical observation.
