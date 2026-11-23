# Ukraine: the path we don't observe

An 18-slide undergraduate lecture prototype with D3 charts, speaker notes, keyboard navigation, source footers, and a 16:9 PDF export.

## Open the deck

**http://127.0.0.1:8765/deck/**

The existing local preview server serves this folder. To restart it:

```bash
cd /home/zhenya/ukraine-trade-lecture
uv run python -m http.server 8765 --bind 127.0.0.1
```

Serve the parent project, not `deck/` alone. D3, fonts, and map geometry are shared with the existing atlas. Everything needed for presentation loads locally. No analytics, API keys, or remote runtime dependencies.

- [Presentation PDF](ukraine-lecture.pdf): 18 pages, 16:9, with vector charts and text.
- [Donor-weight map preview](preview-weights.png)
- [Counterfactual plot preview](preview-counterfactual.png)
- [Original interactive trade atlas](../prototype/)

## Controls

- Right/left arrows, Page Down/Page Up, or Space advance through slides.
- Home and End jump to the first and last slide.
- The dropdown goes directly to a slide; slide IDs are bookmarkable, such as `#weights` or `#interpolation`.
- **N** opens speaker notes; Escape closes them.
- **F** requests fullscreen. The browser may require a direct user action.
- Print / PDF prints all slides, not just the current one.
- Hover donor countries for their published weight or donor-pool status. Hover time-series charts for values.

Use a desktop or landscape display for teaching. The narrow-screen layout stacks the content for review; a phone is not the intended projection format.

## Lecture sequence

| Slides | Purpose |
| --- | --- |
| 1 | A brief introduction to Ukraine at independence in 1991 |
| 2–3 | Long-run output and the changing domestic economic mix |
| 4 | The 2008 global crisis and the large annual contraction in 2009 |
| 5 | The overlapping war, trade, currency, and banking shocks of 2014–2015 |
| 6 | The 2022 collapse and incomplete 2023 rebound |
| 7–8 | The missing counterfactual; why interpolation and a projected trend do not identify it |
| 9–10 | Comparison countries and synthetic control, without equations |
| 11 | The paper's outcome, donor sample, training years, and treatment date |
| 12 | Published donor weights mapped using a common sequential color scale |
| 13 | Actual and reconstructed synthetic GDP per person |
| 14 | Published percentage shortfalls, explicitly distinguished from annual growth |
| 15 | Published leave-one-out sensitivity results |
| 16 | Placebo-test intuition and the limits of a small comparison sample |
| 17–18 | What replication still requires and questions about identification |

The historical introduction is intentionally short. The crisis descriptions are explanations from historical sources, not a decomposition identifying each mechanism's contribution.

## Important corrections and distinctions

1. **2008 is the crisis onset, not the year of the largest annual output contraction.** The slide explicitly pairs late-2008 financial stress with the 2009 decline.
2. **2023 was a recovery year, not another annual downturn.** Growth was positive, but output remained well below 2021. Numbers come from the saved WDI vintage. Earlier news releases used different estimates and forecasts.
3. **The paper's first treated year is 2013.** The deck pivots explicitly back to that crisis after discussing 2022. The paper does not estimate the 2022 invasion's effect.
4. **Two GDP outcomes are kept separate.** Historical charts use aggregate real GDP from WDI in constant 2015 US dollars, indexed to a named base year. The paper uses real GDP per person in 2011 international dollars at PPP. The switch is labeled on the slides.
5. **A close pre-fit is not proof of identification.** Concurrent political/financial shocks, donor spillovers, migration, and territorial/statistical coverage affect interpretation.
6. **Trade maps do not identify a mediation effect.** The deck does not assign a share of the GDP gap to lost Russian trade.

## Replication status

**The synthetic-control estimator has not been run for this prototype.** Execution is waiting for an explicit environment choice. A separate local R project was proposed in the conversation; no packages have been installed for it.

The deck makes four different kinds of graphic explicit:

- **Observed data:** WDI aggregate output and sector shares, plus country observations from the authors' frozen CSV.
- **Illustrations:** the alternative no-crisis paths, interpolation/trend examples, method timeline, and placebo-country grid. These are not fitted causal estimates or new placebo results.
- **Published-weight reconstruction:** the path obtained arithmetically from the authors' observations and rounded published weights. Moldova 45.2%, Armenia 33.3%, Bulgaria 15.2%, Slovenia 6.3%. These weights were not estimated by us. Small differences from the original figure may follow from rounding.
- **Redrawn published results:** the 2013–2017 percentage shortfalls and Table 4's leave-one-out average dollar shortfalls. The 15.1% headline is the authors' estimate, not a result reproduced by rerunning their optimizer here.

The prepared but **unexecuted** national R script is at [research/hybrid-wars/teaching-R/replicate.R](../research/hybrid-wars/teaching-R/replicate.R). It is intended to produce weights, output paths, fit diagnostics, leave-one-out refits, optional placebo paths, and a session-info record after the execution environment is agreed. See its [setup notes](../research/hybrid-wars/teaching-R/README.md).

The archived code has preprocessing and definition issues documented in [the research README](../research/hybrid-wars/README.md). The teaching copy omits two unused ratios whose source columns are absent and explicitly preserves the original code's GDP-based trade-dependence predictor. It has not been runtime-validated. Do not claim exact numerical replication until a rerun is audited against the paper.

Speaker notes also discuss the paper's distinct placebo summaries and the issue that one out of eighteen is about 5.6%, not below 5%. No generic "statistically significant at 5%" claim is made on the slides.

## Edit and rebuild

- `slides.js`: slide order, titles, short visible copy, speaker notes, source keys.
- `deck.js`: D3 charts, map callouts, presenter controls, and template sanitization.
- `deck.css`: 16:9 presentation styling, narrow-screen layout, and print rules.
- `data.json`: packaged observations and transcribed published tables. Its status metadata explicitly records that no estimator was run.
- `../scripts/build_deck_data.py`: copies the existing saved data into the deck payload; performs no fitting.
- `../scripts/test_deck.py`: six checks covering chronology, GDP growth/levels, source sample, weights, published summaries, map codes, and status labels.
- `speaker-notes.md`: an editable reading copy generated from `slides.js` during preparation.

From the project root:

```bash
uv run python scripts/build_deck_data.py
uv run python scripts/test_deck.py
uv run ruff check scripts
node --check deck/slides.js
node --check deck/deck.js
```

Six deck-data tests passed. Browser checks inspected all 18 slides at 1440 × 900 for document overflow, invalid SVG path coordinates, and overlapping chart text. Speaker-note and navigation controls were checked. The final chart check found no overlapping SVG text boxes. This is not a complete cross-browser or accessibility audit.

### PDF export

`ukraine-lecture-print.pdf` is the browser tool's original 18-page print export. That tool forced Letter page dimensions despite the CSS page-size declaration, leaving blank bands above and below the centered slides. `ukraine-lecture.pdf` is the 16:9 derivative made by cropping those blank bands, retaining vector text and charts. The final file was checked with `pdfinfo` and a rendered sample page.

For the same native export dimensions, the derivative can be regenerated with the installed Ghostscript:

```bash
gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dAutoRotatePages=/None \
  -dFIXEDMEDIA -dDEVICEWIDTHPOINTS=792 -dDEVICEHEIGHTPOINTS=445.5 \
  -sOutputFile=deck/ukraine-lecture.pdf \
  -c '<</PageOffset [0 -83.25]>> setpagedevice' \
  -f deck/ukraine-lecture-print.pdf
```

Do not reuse these crop offsets blindly for a differently sized print export. The browser deck itself is 16:9. Source links and speaker notes are most conveniently used in the browser.

## Sources and attribution

Source links appear on each slide and in the final slide. Historical GDP, growth, population, and sector shares use the original collection's [WDI files](../raw/worldbank/) and snapshot date, 15 November 2026.

The main paper is Julia Bluszcz and Marica Valente, [The Economic Costs of Hybrid Wars: The Case of Ukraine](https://doi.org/10.1080/10242694.2020.1791616), Defence and Peace Economics 33(1), 1–25, 2022. The [author package](https://data.mendeley.com/datasets/9bwk589xz6/1), version 1, is CC BY 4.0.

Historical explanations draw on the [Verkhovna Rada](https://www.rada.gov.ua/en/news/News/top_news/230954.html), [IMF's account of the 2008 crisis](https://www.imf.org/en/news/articles/2015/09/28/04/53/socar081110a), the [World Bank's 2017 partnership framework](https://documents1.worldbank.org/curated/en/847421498183265026/pdf/Ukraine-Country-Partnership-Framework-FY2017-21-05262017.pdf), and its [account of recovery during war](https://www.worldbank.org/en/results/2023/11/30/the-world-bank-and-ukraine-laying-the-groundwork-for-reconstruction-in-the-midst-of-war). These historical reports may quote older data vintages than the WDI snapshot used for the chart numbers.

The maps use the shared GISCO 2024 geometry. They show Ukraine including Crimea, not military control or statistical coverage. **© EuroGeographics for the administrative boundaries** is displayed on the map slides. [GISCO's noncommercial-use and attribution conditions apply](https://ec.europa.eu/eurostat/web/gisco/geodata/administrative-units). D3 and font licenses remain in the shared `prototype/vendor/` and `prototype/fonts/` folders.
