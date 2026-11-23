# Run from the repository root with the deck R packages on the library path.
setwd("deck")
source("charts.R")
stopifnot(
  is.na(macro(1900)),
  indexed_gdp(1991, 1991, 1991) == 100,
  abs(sum(vapply(lecture_data$weights, function(w) w$weight, numeric(1))) - 1) < 1e-12,
  length(author_values("Ukraine")) == 23,
  length(synthetic_values()) == 23,
  all(is.finite(synthetic_values()))
)
expected <- Reduce(`+`, lapply(lecture_data$weights, function(w) author_values(w$country) * w$weight))
stopifnot(identical(synthetic_values(), expected))
chart_names <- c("intro-map", "nominal-gdp", "cpi-inflation", "overview", "structure", "gfc", "conflict", "invasion",
                 "question", "interpolation", "donor-paths", "weights", "weights-central-asia", "synthetic-paths",
                 "published-gap", "sensitivity")
charts <- setNames(lapply(chart_names, lecture_chart), chart_names)
stopifnot(all(vapply(charts, inherits, logical(1), "highchart")))
for (chart in charts) {
  stopifnot(!chart$x$hc_opts$exporting$enabled)
  jsonlite::toJSON(chart$x, auto_unbox = TRUE, force = TRUE, null = "null", na = "null")
}
structure_series <- charts[["structure"]]$x$hc_opts$series
stopifnot(identical(vapply(structure_series, function(s) s$name, character(1)), c(rep("Change", 3), "Direction", "1991", "2023")))
stopifnot(identical(vapply(structure_series[[4]]$data, function(point) point$label, character(1)), c("←", "←", "→")))
for (i in 5:6) {
  year <- as.integer(structure_series[[i]]$name)
  values <- vapply(structure_series[[i]]$data, function(point) point$x, numeric(1))
  expected <- vapply(c("NV.AGR.TOTL.ZS", "NV.IND.TOTL.ZS", "NV.SRV.TOTL.ZS"), function(k) macro(year, k), numeric(1))
  stopifnot(isTRUE(all.equal(values, expected, check.attributes = FALSE)))
}
gap <- charts[["published-gap"]]$x$hc_opts$series[[1]]$data
stopifnot(identical(unlist(gap), c(5.23, 9.18, 19.63, 19.80, 21.67)))
europe <- charts$weights$x$hc_opts$series[[1]]
asia <- charts[["weights-central-asia"]]$x$hc_opts$series[[1]]
by_code <- function(points) setNames(points, vapply(points, function(p) p$code, character(1)))
eu_points <- by_code(europe$data)
asia_points <- by_code(asia$data)
stopifnot(identical(names(eu_points), names(by_code(europe$mapData))),
          identical(names(asia_points), names(by_code(asia$mapData))),
          all(c("ISL", "PRT", "GBR", "FRA", "DEU", "NOR", "GRC", "RUS") %in% names(eu_points)),
          all(c("KAZ", "KGZ", "TJK") %in% names(asia_points)))
points <- c(eu_points, asia_points)
is_donor <- names(points) %in% unlist(lecture_data$donors)
widths <- vapply(points, function(p) p$borderWidth, numeric(1))
stopifnot(setequal(names(points)[is_donor], unlist(lecture_data$donors)),
          min(widths[is_donor]) > max(widths[!is_donor]),
          all(vapply(points[!is_donor], function(p) is.null(p$value), logical(1))),
          eu_points$FRA$custom$status == "Outside the donor pool",
          eu_points$POL$value == 0, all(vapply(asia_points[c("KAZ", "KGZ", "TJK")], function(p) p$value == 0, logical(1))),
          eu_points$UKR$color == yellow, eu_points$UKR$custom$status == "Treated country, not a donor")
for (w in lecture_data$weights) stopifnot(eu_points[[w$iso3]]$value == w$weight * 100)
stopifnot(abs(inflation_data[["1993"]] - 4734.91434744584) < 1e-8)
stopifnot(length(charts[["cpi-inflation"]]$x$hc_opts$series[[1]]$data) == 30)
cat("Data checks and all", length(charts), "highcharter widget definitions passed.\n")
