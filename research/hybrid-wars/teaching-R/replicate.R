# Prepared teaching rerun. NOT EXECUTED during deck construction.
# Adapted from Julia Bluszcz and Marica Valente's 2020 replication package.
# Source DOI: 10.17632/9bwk589xz6.1, CC BY 4.0. Changes are documented in README.md.
# Choose the execution environment and pin Synth/dependency versions before use.
# Run from the project root only after approval:
# Rscript research/hybrid-wars/teaching-R/replicate.R [--placebos]
# No packages are installed by this script. No original files are modified.

if (!requireNamespace("Synth", quietly = TRUE)) {
  stop("Synth is required. Set up the approved isolated R project first.", call. = FALSE)
}

args <- commandArgs(trailingOnly = TRUE)
source_dir <- file.path("research", "hybrid-wars", "original")
output_dir <- file.path("research", "hybrid-wars", "teaching-R", "output")
input_file <- file.path(source_dir, "Bluszcz_Valente_repdata_countries.csv")
if (!file.exists(input_file)) {
  stop("Run from the ukraine-trade-lecture root directory.", call. = FALSE)
}

countries <- read.csv2(input_file, stringsAsFactors = FALSE)
countries$Country <- as.character(countries$Country)
countries$HDI <- as.numeric(as.character(countries$HDI))
# Match the original code's GDP-based predictor, not the paper's verbal trade-share definition.
# The original's two reversed import/export names cancel in their sum.
# Omit its two unused ratios that refer to absent Exports_goods/Imports_goods columns.
countries$russia_trade_dependence <-
  (countries$Import_Russia + countries$Export_Russia) * 1000 / countries$GDP_current_US

stopifnot(nrow(countries) == 414L, length(unique(countries$Id)) == 18L)
stopifnot(all(is.finite(countries$GDP_2011)))
stopifnot(identical(sort(unique(countries$Year)), 1995:2017))
stopifnot(!anyDuplicated(countries[c("Id", "Year")]))
set.seed(2026)

fit_one <- function(treated_id, control_ids) {
  prepared <- Synth::dataprep(
    foo = countries,
    predictors = c("russia_trade_dependence", "HDI", "Polity", "Inflation_prices", "GFCF"),
    special.predictors = list(
      list("GDP_2011", 2000, "mean"),
      list("GDP_2011", 2012, "mean")
    ),
    dependent = "GDP_2011",
    unit.variable = "Id",
    time.variable = "Year",
    controls.identifier = control_ids,
    treatment.identifier = treated_id,
    time.predictors.prior = 1995:2012,
    time.optimize.ssr = 1995:2012,
    time.plot = 1995:2017,
    unit.names.variable = "Country"
  )
  fitted <- Synth::synth(prepared)
  weights <- as.numeric(fitted$solution.w)
  stopifnot(all(is.finite(weights)), all(weights >= -1e-7), abs(sum(weights) - 1) < 1e-5)
  paths <- data.frame(
    year = 1995:2017,
    observed = as.numeric(prepared$Y1plot),
    synthetic = as.numeric(prepared$Y0plot %*% fitted$solution.w)
  )
  paths$gap <- paths$observed - paths$synthetic
  paths$shortfall_percent <- (paths$synthetic - paths$observed) / paths$synthetic * 100
  pre <- paths$year <= 2012
  post <- paths$year >= 2013
  pre_mspe <- mean(paths$gap[pre]^2)
  post_mspe <- mean(paths$gap[post]^2)
  summary <- data.frame(
    treated_id = treated_id,
    pre_rmspe = sqrt(pre_mspe),
    post_rmspe = sqrt(post_mspe),
    post_pre_mspe_ratio = if (pre_mspe > 0) post_mspe / pre_mspe else NA_real_,
    average_shortfall_percent = mean(paths$shortfall_percent[post]),
    average_shortfall_ppp2011 = mean(-paths$gap[post])
  )
  ids <- as.integer(colnames(prepared$Y0plot))
  units <- unique(countries[c("Id", "Country")])
  donor_weights <- data.frame(
    Id = ids,
    country = units$Country[match(ids, units$Id)],
    weight = weights
  )
  list(paths = paths, weights = donor_weights, summary = summary)
}

baseline <- fit_one(18L, 1:17)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
write.csv(baseline$paths, file.path(output_dir, "baseline_paths.csv"), row.names = FALSE)
write.csv(baseline$weights, file.path(output_dir, "baseline_weights.csv"), row.names = FALSE)
write.csv(baseline$summary, file.path(output_dir, "baseline_summary.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(output_dir, "session-info.txt"))
writeLines(c(
  "Re-estimation of the national author-code baseline, not all robustness blocks in the paper.",
  "Outcome: GDP per person, 2011 international dollars at PPP.",
  "Fit: 1995-2012. First treated year: 2013. Evaluate: 2013-2017.",
  "The implemented trade-dependence predictor is GDP-based, matching the archived R code.",
  "Do not claim numerical replication before comparing fit, weights, paths, and averages with the paper.",
  paste("Created at", format(Sys.time(), tz = "UTC", usetz = TRUE))
), file.path(output_dir, "provenance.txt"))

# Published positive-weight country IDs. Each model is REFITTED after exclusion.
excluded_ids <- c(1L, 4L, 14L, 17L)
checks <- lapply(excluded_ids, function(id) {
  result <- fit_one(18L, setdiff(1:17, id))
  result$summary$excluded_id <- id
  result$summary$excluded_country <- countries$Country[match(id, countries$Id)]
  result$summary
})
write.csv(do.call(rbind, checks), file.path(output_dir, "leave_one_out.csv"), row.names = FALSE)

if ("--placebos" %in% args) {
  placebo_fits <- lapply(1:17, function(id) fit_one(id, setdiff(1:17, id)))
  placebo_summary <- do.call(rbind, lapply(placebo_fits, function(x) x$summary))
  # Report all fit diagnostics; do not silently choose a pre-fit exclusion rule.
  write.csv(placebo_summary, file.path(output_dir, "placebo_summary.csv"), row.names = FALSE)
  placebo_paths <- do.call(rbind, lapply(seq_along(placebo_fits), function(i) {
    paths <- placebo_fits[[i]]$paths
    paths$treated_id <- i
    paths
  }))
  write.csv(placebo_paths, file.path(output_dir, "placebo_paths.csv"), row.names = FALSE)
}

print(baseline$summary)
message("Rerun outputs written. Inspect versions and compare with the paper before updating the deck's status.")
