# Prepared national replication script

**Status: national baseline and selected checks executed.** Using the existing R installation and project-local `.R-library`, the baseline reproduces the paper's rounded national headline. See `output/` for results and session details. Full paper replication remains incomplete.

`replicate.R` is a short teaching adaptation, not a claim that the full original replication script works unchanged. It leaves the archived originals untouched and writes only into `teaching-R/output/` when executed.

## Scope

The script targets the national 1995–2017 baseline:

- Train using 1995–2012 observations.
- Treat 2013 as the first post-intervention year.
- Use real GDP per person in 2011 international dollars at PPP.
- Preserve the original R code's GDP-based Russian-trade-dependence predictor, while flagging its difference from the paper's verbal description.
- Omit two unused preprocessing ratios that reference absent CSV columns.
- Fit Ukraine from the 17 original donor countries using Synth.
- Refit after excluding each of the four published positive-weight donors.
- Optionally run in-space placebos, recording pre-fit diagnostics without silently choosing an exclusion rule.

It does not reproduce the original script's regional analysis, 2009 adjustment, every inference statistic, or every robustness block. It does not establish that the paper's identifying assumptions hold.

## Running the script

Once an isolated R environment and package versions have been chosen, run from the data-project root:

```bash
Rscript research/hybrid-wars/teaching-R/replicate.R
# Include the 17 additional placebo fits:
Rscript research/hybrid-wars/teaching-R/replicate.R --placebos
```

The only directly requested external R package is Synth. Base R handles the small CSVs and outputs. The script does not install anything or change the working directory.

Expected outputs are baseline weights, observed/synthetic paths, pre/post prediction-error diagnostics, average shortfalls, leave-one-out summaries, session information and provenance. Optional outputs contain placebo paths and fit diagnostics.

Before declaring success, compare these outputs against the paper and archived data, including units, dates, the trade predictor, weights, pre-fit quality, and reported averages. The published mean shortfall is 15.1%, but that number is a comparison target, not a hard-coded target for tuning the model.

The D3 deck currently uses published-weight reconstruction and separately transcribed published tables. Running this script does **not** automatically replace those graphs or change their status labels. A subsequent integration should preserve the distinction between published results, reproduction results, and extensions.
