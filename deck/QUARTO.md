# Quarto lecture with native highcharter charts

Edit `deck/lecture.qmd`. Each `##` starts a slide. The deck uses ordinary R chunks and `highcharter` htmlwidgets, not the legacy D3 renderer. `deck/charts.R` reads the frozen `data.json` and GISCO geometry at render time. It does not download data or fit a model.

## Build

Install R, Quarto, and the R dependencies. From the project root, install into a project-local library:

```sh
mkdir -p .R-library
Rscript -e 'install.packages(c("highcharter", "jsonlite", "knitr", "rmarkdown"), lib=".R-library", repos="https://cloud.r-project.org")'
bash scripts/render_deck.sh
```

The wrapper exposes `.R-library` to R and renders `deck/history.qmd` before `deck/lecture.qmd`. It embeds the generated `deck/history.html` as a self-contained frame on slide 4 (`#/timeline`). To preview just the story, run `quarto preview deck/history.qmd`.

The earlier Quarto deck was successfully built with R 4.6.1, Quarto 1.11.9, highcharter 0.9.5, jsonlite 2.0.0, knitr 1.52 and rmarkdown 2.32. The CRAN installation above is not version-locked, so it does not guarantee identical output or future compatibility.

To regenerate the frozen payload before rendering (Python 3, standard library only):

```sh
python3 scripts/build_deck_data.py
```

This reads `data/economic_context_wdi_1991_latest.csv` and `research/hybrid-wars/original/Bluszcz_Valente_repdata_countries.csv`. Rendering also needs the saved GISCO geometry in `raw/geography/`, local fonts and licenses, and `deck/images/timeline/` including attribution. Keep these inputs and the source files listed below. The WDI table can be rebuilt from the saved World Bank data using the broader data pipeline described in the root README.

Run the chart checks with:

```sh
R_LIBS_USER="$PWD/.R-library" Rscript scripts/test_highcharter.R
```

## Share

Send **`deck/lecture.html` alone**. Open it directly from disk in a browser. Quarto's `embed-resources: true` bundles the chart libraries, widget data, fonts, CSS, and Reveal navigation in that file. Students need neither an internet connection nor R, Quarto, a server, or the source folders. Source hyperlinks still require internet when clicked.

Use arrow keys to navigate the deck and S for presenter notes. The button at the top right switches light and dark mode, saving the choice when browser storage is available. Switch to light mode before printing if you want a light PDF. On the history slide, scroll or select a date to change the pinned photo. Left and right arrows move between events when the timeline has focus; press Escape to return focus to the deck. The print view substitutes a static chronology for the interactive timeline. Highcharts tooltips, legends, and map zoom buttons work offline. Mouse-wheel map zoom is disabled to avoid accidental zooming while presenting. Online exporting is disabled. To make a PDF, use Reveal's `?print-pdf` view and browser printing.

## Edit

- `lecture.qmd`: slide text, R chart calls, inline calculated statistics, and speaker notes.
- `charts.R`: native highcharter series, axes, tooltips, and maps. Missing macro values remain missing, not zero.
- `quarto-theme.css`: presentation layout and embedded local fonts.
- `history.qmd`, `history.css`, `history-controls.html`: seven Closeread triggers and their pinned photos, layout, and date controls. The [tutorial](https://github.com/KennethOdoh/closeread-tutorial) uses the same extension. Closeread v1.0.1 is included under `_extensions/qmd-lab/closeread/`, with two local guards in its JavaScript for pages without Observable cells or progress blocks.
- `highcharter-reveal.html`: a small chart-reflow hook for Reveal slide changes. It does not draw charts.
- `data.json`: frozen observations and published paper tables, rebuilt by `scripts/build_deck_data.py`. `cpi-inflation.json` is a separate World Bank CPI snapshot, with the API URL and update date.

The synthetic path remains a reconstruction using rounded published weights; the gap and sensitivity charts redraw published values. A separate national model rerun matches the headline and annual gaps to reported precision, but one donor-exclusion result differs and placebo inference has not been verified. See `research/hybrid-wars/teaching-R/replication-findings.md`. Rendering the deck does not fit the model.

The [GISCO country boundaries](https://gisco-services.ec.europa.eu/distribution/v2/countries/) retain their displayed EuroGeographics credit and [noncommercial-use conditions](https://ec.europa.eu/eurostat/web/gisco/geodata/administrative-units). Highcharts has separate licensing terms; check the terms applicable to your educational use and redistribution.
