# Ukraine: the path we don't observe

An undergraduate lecture on Ukraine's economic development, the counterfactual problem, and synthetic control, accompanied by trade data and an interactive atlas.

**[View the lecture](https://zhenyakosovan.github.io/ukraine-trade-lecture/)** · [Data reference](docs/data-reference.md) · [Replication findings](research/hybrid-wars/teaching-R/replication-findings.md)

## Lecture

The current presentation is a Quarto Reveal.js deck in [`deck/lecture.qmd`](deck/lecture.qmd), with charts defined in [`deck/charts.R`](deck/charts.R). Navigate with the arrow keys; press **S** for presenter notes. The deployed page uses the committed, self-contained `deck/lecture.html`.

To rebuild after editing, install R, Quarto, and the required R packages, then run:

```sh
bash scripts/render_deck.sh
R_LIBS_USER="$PWD/.R-library" Rscript scripts/test_highcharter.R
```

See [deck/QUARTO.md](deck/QUARTO.md) for dependencies, build details, and attribution. Pushes to `master` deploy the committed HTML to GitHub Pages; the workflow does not rebuild it.

The paper's national synthetic-control model has been rerun. The headline and annual gaps match published rounding, but an Armenia-exclusion result differs and placebo inference remains unverified. See the [replication findings](research/hybrid-wars/teaching-R/replication-findings.md) for details. Charts using published weights are labeled as reconstructions, not newly fitted estimates.

## Trade atlas and data

The [interactive atlas](prototype/README.md) is a separate D3 prototype. To run it locally from the project root:

```sh
uv run python -m http.server 8765 --bind 127.0.0.1
```

Open <http://127.0.0.1:8765/prototype/>. The older D3 lecture in `deck/` is a historical prototype, not the source of the current Quarto presentation.

The collection includes Ukrainian official trade statistics, Eurostat extracts, and World Bank economic indicators. There is no verified continuous country-by-industry trade panel from 1991 onward; missing observations should not be treated as zero. The [data reference](docs/data-reference.md) describes coverage, source files, units, limitations, and regeneration.

## Repository layout

- `deck/` — current lecture source and generated HTML; legacy deck files.
- `prototype/` — interactive trade atlas.
- `data/`, `raw/`, `metadata/` — derived tables, source downloads, and provenance.
- `research/` — paper, replication materials, and findings.
- `scripts/` — data processing, validation, and deck rendering.

## Attribution

Data sources and reuse terms differ; cite the relevant publisher and dataset. GISCO boundaries have [noncommercial-use conditions](https://ec.europa.eu/eurostat/web/gisco/geodata/administrative-units) and require the credit **© EuroGeographics for the administrative boundaries**. The boundaries include Crimea within Ukraine and do not depict territorial control.
