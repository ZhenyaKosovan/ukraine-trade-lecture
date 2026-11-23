# Candidate teaching replication: a synthetic Ukraine

Status: paper, author code, and author data downloaded and inspected on 15 November 2026. No estimation has been run, and the reported findings below are the authors' findings, not a new replication result.

## Recommendation

Start with the national synthetic-control exercise in Julia Bluszcz and Marica Valente, "The Economic Costs of Hybrid Wars: The Case of Ukraine," Defence and Peace Economics 33(1), 1–25, 2022. First published online in 2020.

- [Article DOI](https://doi.org/10.1080/10242694.2020.1791616)
- [Open institutional paper copy](https://edoc.hu-berlin.de/server/api/core/bitstreams/dff77e75-ef58-481b-aaf0-6ab546798e15/content)
- [Author replication package](https://data.mendeley.com/datasets/9bwk589xz6/1), DOI 10.17632/9bwk589xz6.1, version 1, 1 July 2020, CC BY 4.0.

The question for students is: "How much lower was Ukraine's real GDP per person after the crisis than the path predicted by a weighted combination of comparable countries?"

This is an estimate of a missing counterfactual, not an observed accounting total. Its causal interpretation depends on assumptions about the comparison countries, concurrent shocks, spillovers, and the measurement of Ukrainian output.

## Why this is manageable

The country data contain 414 rows: 18 countries observed annually from 1995 through 2017. Ukraine is the treated country, leaving 17 donors. The package includes an R replication script and an auxiliary R script. The main packages requested by the code are Synth, ggplot2, and reshape2.

The authors' fitted comparison is approximately:

```
Synthetic Ukraine =
    45.2% Moldova
  + 33.3% Armenia
  + 15.2% Bulgaria
  +  6.3% Slovenia
```

These are published weights from Table 2, rounded to three decimal places, not weights newly estimated here. They make the method easy to explain as a weighted comparison. For a real replication, estimate weights from the specified pre-treatment data rather than selecting countries after seeing the result.

The main national outcome is real GDP per capita in 2011 international dollars at PPP. It is NOT the aggregate constant-2015-dollar GDP series used in our existing D3 timeline. Reuse the authors' frozen data for exact replication, not a current WDI download with different PPP benchmarks and revisions.

## Exact baseline to target

- Training and predictor-averaging period: 1995 through 2012.
- Treated period: 2013 through 2017.
- Outcome: `GDP_2011`.
- Predictors in the supplied code: Russian-trade dependence, HDI, Polity, inflation, and gross fixed capital formation, plus GDP-per-capita values in 2000 and 2012.
- Donors: Armenia, Azerbaijan, Belarus, Bulgaria, Czech, Estonia, Hungary, Kazakhstan, Kyrgyz Republic, Latvia, Lithuania, Moldova, Poland, Romania, Slovakia, Slovenia, and Tajikistan.
- Author headline: GDP per capita 15.1% below the synthetic counterfactual on average in 2013 through 2017. Their yearly reported percentage shortfalls are 5.23, 9.18, 19.63, 19.80, and 21.67.

The shortfall for a year can be displayed as:

```
100 * (synthetic GDPpc - observed GDPpc) / synthetic GDPpc
```

A positive value means output per person is below the constructed counterfactual. Keep this sign convention distinct from the negative observed-minus-synthetic gap in the R code.

## Minimal undergraduate lab

1. Plot actual Ukraine and an unweighted donor average. Ask why a simple before/after comparison or an arbitrary comparison country is not enough.
2. Estimate a synthetic control with weights constrained to be nonnegative and sum to one. Fit using pre-treatment information only. Plot actual and synthetic output with the intervention date marked.
3. Plot the percentage gap. Compare with the authors' reported 15.1% average; do not label a new result as a successful replication until the data definition, weights, fit, and average agree within a documented tolerance.
4. Run placebo treatments on the donor countries and compare pre-fit quality and post/pre prediction-error ratios. Poorly fitted placebos should not be treated as equally informative. Explain the small number of comparison countries.
5. Remove the largest-weight donor, Moldova, and refit. Discuss whether the conclusion depends heavily on one comparison country.

A simpler classroom demonstration can use the published four weights to draw the comparison curve before students learn the optimization. Label that as reconstruction from published weights, not a fresh causal estimate or an exact replication using full-precision weights.

The original script also contains regional estimates and many robustness checks. They are outside the minimal first lab.

## What we can and cannot call causal

**Treatment starts in 2013 in the paper, not 2014.** The authors include the political crisis and possible anticipation before fighting began. Therefore the clean teaching label is the effect of the crisis beginning in 2013 under the synthetic-control assumptions, not the isolated effect of armed conflict or of a particular trade policy. A later exercise can compare treatment-date specifications. Simply relabeling the same fitted graph as a 2014 experiment is not a sensitivity analysis.

**A good pre-fit is necessary but not sufficient.** The approach assumes the comparison would have continued to represent Ukraine without the crisis. Domestic political changes, exchange-rate and financial shocks, commodity markets, and policy responses can also produce divergence. The method does not separately identify their contributions.

**Donors can be affected too.** Moldova and Armenia have substantial connections to Russia and the region. Trade disruption, Russian recession, sanctions, migration, or security responses can affect the donor outcomes. Russia's exclusion from the donor pool does not by itself solve spillovers.

**Geography and population need an audit.** Occupation and loss of statistical coverage can change measured GDP and the population denominator. We must review the vintage-specific territorial definitions before interpreting the whole gap as lost production within a constant geographic area. Until then, retain this as a central limitation, not a footnote that disappears from the graph.

**GDP per person is not total GDP.** Migration and displacement change the denominator. A later extension can examine aggregate real GDP separately, but that changes the estimand and is not an exact replication of the national headline.

**Placebo inference is coarse.** With one treated country and 17 donors, the finest all-unit rank probability with the usual inclusion of the treated unit is 1/18, about 0.056, before any donor exclusions. Do not round that down into an unqualified claim of significance at 5%. The paper discusses multiple inferential statistics; reproduce their precise conventions before judging or reporting their p-values.

**Trade is a mechanism, not an identified mediation effect here.** Our trade maps can show which relationships changed. They do not establish how many percentage points of the GDP gap came from lost Russian trade, physical destruction, displaced workers, or other channels.

## Static code checks before execution

The original files are preserved without edits in `original/`. Two issues are visible without running the model:

1. The script creates `export_russia_share_export` and `import_russia_share_import` using `countries$Exports_goods` and `countries$Imports_goods`. Neither column exists in the supplied country CSV. Those lines need to be audited and removed or resolved in a separate teaching copy. The main national model uses `russia_trade_dependence`, not these two auxiliary ratios. We have not yet executed the original script, so this is a static compatibility finding rather than a runtime test.
2. The code computes the trade-dependence predictor as Russian trade divided by GDP, while the paper describes dependence using shares of international trade. The import/export variable labels are also swapped in two preprocessing assignments, although summing the two makes their combined GDP-based measure unchanged. Preserve the original implementation for a code-replication baseline and document the paper/code distinction. A changed predictor definition is a robustness exercise, not a silent correction.

The CSVs use semicolon delimiters and comma decimal marks for many values. The original script uses `read.csv2` and explicitly converts HDI. Do not read them as ordinary comma-delimited CSVs.

Before execution, choose an environment explicitly. Suggested next step: a separate local R project with pinned package versions, a short cleaned teaching script, and the original files left untouched. No packages have been installed for this replication and no author code has been executed.

## Local files and provenance

- `paper.pdf`: open institutional copy of the published paper.
- `paper.txt`: local text extraction for source inspection.
- `replication-original.zip`: unmodified author package downloaded from the verified public Mendeley ZIP URL.
- `original/Bluszcz_Valente_repcode.R`: author replication script.
- `original/Bluszcz_Valente_auxiliary_fx.R`: author helper functions.
- `original/Bluszcz_Valente_repdata_countries.csv`: 414 country-year observations.
- `original/Bluszcz_Valente_repdata_regions.csv`: 375 regional observations; not needed for the first national exercise.
- `manifest.json`: URLs, version, retrieval date, file sizes, and SHA-256 hashes of downloaded/extracted research materials. This README is a later planning artifact and is not part of the source-file manifest.

The PDF content tool could not extract the paper, so the institutional PDF was downloaded and inspected with the installed pdftotext utility. Mendeley's public page exposed the four file names and CC BY 4.0 license. Browser download attempts were blocked by the cookie overlay; the verified public ZIP URL was downloaded directly without credentials or access-control workarounds.
