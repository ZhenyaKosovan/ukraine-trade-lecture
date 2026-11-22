# Native highcharter widgets built from the frozen lecture data. No model fitting.
library(highcharter)
lecture_data <- jsonlite::fromJSON("data.json", simplifyVector = FALSE)
ink <- "#163c55"
teal <- "#198a84"
red <- "#b94b56"
yellow <- "#f5cc41"
macro <- function(year, indicator = "NY.GDP.MKTP.KD") {
  value <- lecture_data$macro[[as.character(year)]][[indicator]]
  if (is.null(value)) NA_real_ else value
}
signed_growth <- function(year) sprintf("%+.1f%%", macro(year, "NY.GDP.MKTP.KD.ZG"))
indexed_gdp <- function(start, end, base) {
  vapply(start:end, macro, numeric(1)) / macro(base) * 100
}
author_values <- function(country) {
  rows <- Filter(function(x) x$country == country, lecture_data$countries)
  rows <- rows[order(vapply(rows, function(x) x$year, numeric(1)))]
  vapply(rows, function(x) x$gdppc, numeric(1))
}
synthetic_values <- function() {
  Reduce(`+`, lapply(lecture_data$weights, function(w) author_values(w$country) * w$weight))
}
base_chart <- function(height = 430, type = "chart") {
  highchart(type = type, height = height) |>
    hc_chart(backgroundColor = "transparent", animation = FALSE,
             style = list(fontFamily = "Source, sans-serif", fontSize = "18px")) |>
    hc_title(text = NULL) |>
    hc_credits(enabled = FALSE) |>
    hc_exporting(enabled = FALSE) |>
    hc_plotOptions(series = list(animation = FALSE, marker = list(enabled = FALSE),
                                states = list(inactive = list(opacity = 1)))) |>
    hc_legend(itemStyle = list(fontSize = "16px", color = ink)) |>
    hc_yAxis(title = list(text = NULL), gridLineColor = "#d6e2e9",
             labels = list(style = list(fontSize = "16px"))) |>
    hc_xAxis(labels = list(style = list(fontSize = "16px"))) |>
    hc_tooltip(valueDecimals = 1)
}
add_path <- function(chart, years, values, name = "Observed Ukraine", color = ink,
                     dash = "Solid", width = 3) {
  points <- Map(function(x, y) list(x = x, y = if (is.na(y)) NULL else y), years, values)
  hc_add_series(chart, data = points, name = name, color = color,
                dashStyle = dash, lineWidth = width, type = "line")
}
time_chart <- function(years, values, unit, event = NULL, limits = NULL) {
  lines <- if (is.null(event)) list() else list(list(
    value = event, color = red, width = 2, dashStyle = "Dash",
    label = list(text = paste(event, "crisis"), style = list(color = red))))
  base_chart() |>
    hc_xAxis(title = list(text = NULL), allowDecimals = FALSE, plotLines = lines) |>
    hc_yAxis(title = list(text = unit), min = if (is.null(limits)) NULL else limits[1],
             max = if (is.null(limits)) NULL else limits[2]) |>
    add_path(years, values)
}
# Highmaps accepts SVG paths directly. Convert the saved GISCO rings in R;
# no map download, D3, sf, or browser-side geometry loader is needed.
geo <- jsonlite::fromJSON("../raw/geography/CNTR_RG_20M_2024_4326.geojson", simplifyVector = FALSE)
map_ring <- function(ring) {
  xy <- do.call(rbind, lapply(ring, unlist))
  lat <- pmax(-85, pmin(85, xy[, 2]))
  y <- -180 / pi * log(tan(pi / 4 + lat * pi / 360))
  paste("M", paste(sprintf("%.5f %.5f", xy[, 1], y), collapse = " L "), "Z")
}
map_shape <- function(feature) {
  polygons <- if (feature$geometry$type == "Polygon") list(feature$geometry$coordinates) else feature$geometry$coordinates
  list(code = feature$properties$ISO3_CODE, name = feature$properties$NAME_ENGL,
       path = paste(vapply(polygons, function(p) paste(vapply(p, map_ring, character(1)), collapse = " "), character(1)), collapse = " "))
}
lecture_map <- function(weights = FALSE) {
  codes <- if (weights) c("UKR", unlist(lecture_data$donors)) else
    c("UKR", "POL", "SVK", "HUN", "ROU", "MDA", "BLR")
  features <- Filter(function(f) f$properties$ISO3_CODE %in% codes, geo$features)
  shapes <- lapply(features, map_shape)
  points <- lapply(shapes, function(s) {
    w <- Filter(function(w) w$iso3 == s$code, lecture_data$weights)
    value <- if (length(w)) w[[1]]$weight * 100 else 0
    list(code = s$code, name = s$name, value = value,
         color = if (s$code == "UKR") yellow else if (!weights) "#dae5eb" else NULL,
         custom = list(status = if (s$code == "UKR") "Treated country, not a donor" else
           if (weights) sprintf("Published weight: %.1f%%", value) else "Neighbouring country"))
  })
  base_chart(460, "map") |>
    hc_add_series(type = "map", mapData = shapes, data = points,
                  joinBy = c("code", "code"), name = "Published donor weights",
                  borderColor = "white", borderWidth = 1,
                  dataLabels = list(enabled = TRUE, format = "{point.name}",
                    style = list(fontSize = "13px", textOutline = "none"))) |>
    hc_colorAxis(min = 0, max = 45.2, minColor = "#f7fbff", maxColor = "#08519c",
                 labels = list(format = "{value}%")) |>
    hc_legend(enabled = weights) |>
    hc_mapNavigation(enabled = TRUE, enableMouseWheelZoom = FALSE) |>
    hc_tooltip(headerFormat = "", pointFormat = "<b>{point.name}</b><br>{point.custom.status}")
}
lecture_chart <- function(name) {
  if (name == "intro-map") return(lecture_map())
  if (name == "weights") return(lecture_map(TRUE))
  if (name == "overview") {
    events <- list(c(1999, "Transition recession"), c(2009, "2008/09 GFC"),
                   c(2015, "2014/15 crisis"), c(2022, "2022 invasion"))
    chart <- time_chart(1991:2025, indexed_gdp(1991, 2025, 1991), "Real GDP, 1991 = 100", limits = c(0, 110)) |>
      hc_xAxis(labels = list(style = list(fontSize = "20px"))) |>
      hc_yAxis(labels = list(style = list(fontSize = "20px")),
               title = list(style = list(fontSize = "20px"))) |>
      hc_legend(itemStyle = list(fontSize = "20px", color = ink))
    points <- lapply(events, function(e) list(x = as.numeric(e[1]),
      y = macro(as.numeric(e[1])) / macro(1991) * 100, name = e[2]))
    return(hc_add_series(chart, type = "scatter", data = points, color = yellow,
      name = "Historical downturns", marker = list(enabled = TRUE, radius = 5),
      dataLabels = list(enabled = TRUE, format = "{point.name}", style = list(fontSize = "17px"))))
  }
  if (name == "structure") {
    keys <- c("NV.AGR.TOTL.ZS", "NV.IND.TOTL.ZS", "NV.SRV.TOTL.ZS")
    chart <- base_chart() |> hc_chart(type = "bar") |>
      hc_xAxis(categories = c("Agriculture", "Industry", "Services")) |>
      hc_yAxis(min = 0, title = list(text = "Value added, % of GDP")) |>
      hc_tooltip(valueSuffix = "%")
    for (year in c(1991, 2023)) chart <- hc_add_series(chart, name = as.character(year),
      data = lapply(keys, function(k) macro(year, k)), type = "bar", color = if (year == 1991) ink else teal)
    return(chart)
  }
  if (name %in% c("gfc", "conflict", "invasion")) {
    cfg <- switch(name, gfc = c(2005, 2012, 2007, 2009),
                  conflict = c(2010, 2017, 2013, 2014), invasion = c(2018, 2025, 2021, 2022))
    return(time_chart(cfg[1]:cfg[2], indexed_gdp(cfg[1], cfg[2], cfg[3]),
                      paste("Real GDP,", cfg[3], "= 100"), cfg[4]))
  }
  if (name %in% c("question", "interpolation")) {
    chart <- time_chart(2000:2017, indexed_gdp(2000, 2017, 2012), "Real GDP, 2012 = 100", 2013, c(35, 135))
    if (name == "interpolation") {
      chart <- add_path(chart, c(2012, 2017), c(100, indexed_gdp(2017, 2017, 2012)),
                        "Join affected endpoints? Illustration", red, "Dash")
      slope <- (100 - indexed_gdp(2005, 2005, 2012)) / 7
      return(add_path(chart, 2012:2017, 100 + slope * (0:5), "Extend earlier trend? Illustration", teal, "Dash"))
    }
    for (slope in c(-1, 2, 5)) chart <- add_path(chart, 2012:2017, 100 + slope * (0:5),
      paste("Illustrative no-crisis path, slope", slope), c("#b7cbd8", "#86aebe", teal)[match(slope, c(-1, 2, 5))], "Dash", 2)
    return(chart)
  }
  if (name == "donor-paths") {
    actual <- author_values("Ukraine")
    chart <- time_chart(1995:2017, actual / actual[18] * 100, "GDP per person, each country in 2012 = 100", 2013, c(0, 155))
    for (country in names(lecture_data$donors)) {
      values <- author_values(country)
      chart <- add_path(chart, 1995:2017, values / values[18] * 100, country, "#b7cbd8", width = 1)
    }
    return(hc_legend(chart, enabled = FALSE))
  }
  if (name == "synthetic-paths") return(time_chart(1995:2017, author_values("Ukraine"),
    "GDP per person, 2011 international dollars at PPP", 2013, c(0, 11000)) |>
    add_path(1995:2017, synthetic_values(), "Published-weight reconstruction", teal, "Dash"))
  if (name == "published-gap") return(base_chart() |>
    hc_xAxis(categories = vapply(lecture_data$published, function(x) as.character(x$year), character(1))) |>
    hc_yAxis(min = 0, max = 25, title = list(text = "Below the authors' counterfactual, %")) |>
    hc_add_series(type = "column", name = "Published shortfall", color = red,
      data = lapply(lecture_data$published, function(x) x$percent),
      dataLabels = list(enabled = TRUE, format = "{y:.2f}%")) |>
    hc_tooltip(valueDecimals = 2, valueSuffix = "%") |> hc_legend(enabled = FALSE))
  if (name == "sensitivity") return(base_chart() |>
    hc_chart(type = "bar") |>
    hc_xAxis(categories = vapply(lecture_data$leaveOneOut, function(x) x$label, character(1))) |>
    hc_yAxis(min = 0, title = list(text = "Average shortfall, 2011 PPP dollars per person")) |>
    hc_add_series(type = "bar", name = "Published shortfall", data = lapply(seq_along(lecture_data$leaveOneOut), function(i)
      list(y = lecture_data$leaveOneOut[[i]]$loss, color = if (i == 1) ink else teal)),
      dataLabels = list(enabled = TRUE, format = "{y:,.1f}")) |> hc_legend(enabled = FALSE))
  stop("Unknown chart: ", name)
}
