# D3 lecture prototype

A local, interactive atlas built with D3 7.9.0 and the collected data. No frontend build step, external runtime requests, API keys, or analytics. D3 and the fonts are bundled locally.

## Open it

The preview server started during development is at:

**http://127.0.0.1:8765/prototype/**

To start it again:

```bash
cd /home/zhenya/ukraine-trade-lecture
uv run python -m http.server 8765 --bind 127.0.0.1
```

Serve the **parent data folder**, not just `prototype/`. The page loads its map from `../raw/geography/`. Double-clicking `index.html` will not work because browsers restrict local-file fetches. If port 8765 is occupied by this preview, use the existing URL or choose a different port.

## Interactions

- Choose goods or computer services, exports or imports, and a goods product group.
- Choose nominal USD or share of the selected total. The color domain stays fixed across years within each series, flow, product group, and measure. A square-root scale keeps smaller trading partners visible.
- Drag the year slider or use its keyboard arrows. Year buttons and previous/next controls also work. The blue slider band marks available trade years; gray years still have economic context.
- Play advances through available trade years and stops at the last one. Playback pauses when the tab becomes hidden.
- Hover a country for its value and share. Click a country or one of the six ranked partner buttons for its history. Click Clear to deselect it.
- Use World/Europe to change the map view. Drag or scroll the map to pan and zoom.
- Click the real-GDP chart to select a year. It is indexed to 1991 = 100.
- Download selection exports all named partners in the current selection, not just the six ranked countries. The CSV includes current USD, shares, source series, denominator value and basis, and snapshot date.
- Filter state and the selected partner are stored in the URL, so a lecture example can be bookmarked.

Examples:

- [All goods exports, 2013](http://127.0.0.1:8765/prototype/?year=2013&dataset=goods&flow=export)
- [Food exports, 2023](http://127.0.0.1:8765/prototype/?year=2023&dataset=goods&flow=export&sector=Agriculture%20and%20food)
- [Computer-services exports, 2025](http://127.0.0.1:8765/prototype/?year=2025&dataset=it&flow=export)
- [Economic context at independence](http://127.0.0.1:8765/prototype/?year=1991)

## Data choices

| View | Source | Actual coverage |
| --- | --- | --- |
| Goods partners and products | Ukrstat partner totals and two-digit UKTZED chapters | 2011 to 2023 |
| Computer-services partners | NBU selected partners and published total | 2011 to 2025 |
| Real GDP and sector shares | World Bank WDI | 1991 to 2025 |
| Country geometry | Eurostat GISCO 2024 | One fixed boundary file, not historical borders |

All goods uses the **published world total** as its denominator. Product filters sum **named ISO3 partners only**; the interface labels this different denominator. Non-HS special goods and unresolved historical partner codes are excluded from those product filters. Product groups are teaching categories, not NACE/KVED industries.

Computer services uses the **published total**, not the sum of the selected countries. Missing partners remain missing. Reported zero has a different map appearance from no observation. Named territories without a polygon at this resolution can still appear in the rankings and CSV export.

The GDP and economic-sector charts use WDI independently of the selected trade series. Agriculture, industry, and services shares are not required to sum to 100% of GDP. Industry includes manufacturing. Territorial coverage changes and displacement complicate historical GDP comparisons.

The prototype deliberately does not splice the NBU 2024/2025 selected goods partners onto Ukrstat's full panel, use incomplete Eurostat product coverage to fill gaps, or compare partial 2026 figures with full calendar years. See the [full data README](../README.md) for source links and methodological cautions.

## Files and rebuild

- `index.html`, `styles.css`, `app.js`: interface, responsive styling, and D3 rendering.
- `data/trade.json`: about 1 MB, containing 454 series/year/flow/product snapshots, country labels, and macro indicators.
- `vendor/` and `fonts/`: pinned local runtime assets and their licenses.
- `desktop-preview.png`, `mobile-preview.png`: browser screenshots at desktop and 390-pixel viewport widths.
- `qa-*.json`: condensed browser interaction and load-check evidence.
- `qa-it-import-2025.csv`: verified browser-export example, not an additional source dataset.

Rebuild and test from the parent directory:

```bash
uv run python scripts/build_prototype_data.py
uv run python scripts/test_prototype.py
uv run python scripts/validate.py
uv run ruff check scripts
node --check prototype/app.js
```

The browser payload derives from the existing checked CSVs, not new source downloads. Rebuild it after refreshing the parent data tables. The availability bounds and snapshot date are currently explicit in `scripts/build_prototype_data.py`; review them when updating the collection to new years.

Five payload regression tests and the seven original data-package tests passed. Browser checks covered product and share controls, partner selection, missing early trade years, GDP baseline, jump-to-data, series switching, import direction, Europe zoom, playback, CSV download, and responsive width. Page-load QA found no console errors, page errors, or failed network requests. Desktop and mobile checks found no horizontal document overflow. These are prototype checks, not a complete cross-browser or accessibility audit.

## Credits and terms

The page follows an atlas palette: blue trade values, yellow Ukraine, pale-blue water, and hatched missing observations. Display type is Barlow Condensed; body type is Source Sans 3.

Bundled assets came from these pinned packages:

- [D3 7.9.0](https://cdn.jsdelivr.net/npm/d3@7.9.0/dist/d3.min.js), [license](vendor/D3-LICENSE).
- [Barlow Condensed, Fontsource 5.2.6](https://cdn.jsdelivr.net/npm/@fontsource/barlow-condensed@5.2.6/files/barlow-condensed-latin-600-normal.woff2), [font license](fonts/BARLOW-LICENSE).
- [Source Sans 3, Fontsource 5.2.5](https://cdn.jsdelivr.net/npm/@fontsource/source-sans-3@5.2.5/files/source-sans-3-latin-400-normal.woff2), [font license](fonts/SOURCE-SANS-LICENSE).

Data retain their publishers' terms. **© EuroGeographics for the administrative boundaries** appears on the map. GISCO boundaries are subject to [noncommercial-use conditions](https://ec.europa.eu/eurostat/web/gisco/geodata/administrative-units). Crimea is included within Ukraine. The map does not show military control or statistical coverage.
