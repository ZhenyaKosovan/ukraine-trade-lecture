# Native highcharter widgets built from the frozen lecture data. No model fitting.
library(highcharter)
lecture_data <- jsonlite::fromJSON("data.json", simplifyVector = FALSE)
inflation_data <- jsonlite::fromJSON("cpi-inflation.json", simplifyVector = FALSE)$values
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
             style = list(fontFamily = "JetBrains Mono, monospace", fontSize = "18px")) |>
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
svg_ring <- function(x, y) {
  paste("M", paste(sprintf("%.5f %.5f", x, y), collapse = " L "), "Z")
}
map_ring <- function(ring) {
  xy <- do.call(rbind, lapply(ring, unlist))
  lat <- pmax(-85, pmin(85, xy[, 2]))
  y <- -180 / pi * log(tan(pi / 4 + lat * pi / 360))
  svg_ring(xy[, 1], y)
}
map_shape <- function(feature) {
  polygons <- if (feature$geometry$type == "Polygon") list(feature$geometry$coordinates) else feature$geometry$coordinates
  list(code = feature$properties$ISO3_CODE, name = feature$properties$NAME_ENGL,
       path = paste(vapply(polygons, function(p) paste(vapply(p, map_ring, character(1)), collapse = " "), character(1)), collapse = " "))
}
lecture_map <- function() {
  codes <- c("UKR", "POL", "SVK", "HUN", "ROU", "MDA", "BLR")
  features <- Filter(function(f) f$properties$ISO3_CODE %in% codes, geo$features)
  shapes <- lapply(features, map_shape)
  points <- lapply(shapes, function(s) {
    list(code = s$code, name = s$name, value = 0,
         color = if (s$code == "UKR") yellow else "#dae5eb",
         custom = list(status = if (s$code == "UKR") "Treated country, not a donor" else
           "Neighbouring country"))
  })
  base_chart(460, "map") |>
    hc_add_series(type = "map", mapData = shapes, data = points,
                  joinBy = c("code", "code"), borderColor = "white", borderWidth = 1,
                  dataLabels = list(enabled = TRUE, format = "{point.name}",
                    style = list(fontSize = "13px", textOutline = "none"))) |>
    hc_legend(enabled = FALSE) |>
    hc_mapNavigation(enabled = TRUE, enableMouseWheelZoom = FALSE) |>
    hc_tooltip(headerFormat = "", pointFormat = "<b>{point.name}</b><br>{point.custom.status}")
}
# Clip the GISCO rings to a regional window. This keeps overseas territories
# and Russia's Pacific coast out of the fit without dropping the countries.
clip_ring <- function(xy, bounds) {
  for (i in seq_along(bounds)) {
    axis <- if (i <= 2) 1L else 2L
    edge <- bounds[i]
    inside <- if (i %% 2L == 1L) xy[, axis] >= edge else xy[, axis] <= edge
    if (!any(inside)) return(NULL)
    if (all(inside)) next
    previous <- c(nrow(xy), seq_len(nrow(xy) - 1L))
    xy <- do.call(rbind, lapply(seq_len(nrow(xy)), function(j) {
      k <- previous[j]
      crossing <- if (inside[k] != inside[j]) {
        fraction <- (edge - xy[k, axis]) / (xy[j, axis] - xy[k, axis])
        xy[k, ] + fraction * (xy[j, ] - xy[k, ])
      }
      rbind(crossing, if (inside[j]) xy[j, ])
    }))
  }
  if (nrow(xy) >= 3) xy else NULL
}
regional_shape <- function(feature, bounds) {
  geometry <- feature$geometry
  polygons <- if (geometry$type == "Polygon") list(geometry$coordinates) else geometry$coordinates
  rings <- lapply(unlist(polygons, recursive = FALSE), function(ring) {
    xy <- clip_ring(do.call(rbind, lapply(ring, unlist)), bounds)
    if (!is.null(xy)) svg_ring(xy[, 1] * 0.72, -xy[, 2])
  })
  rings <- Filter(Negate(is.null), rings)
  if (length(rings)) list(code = feature$properties$ISO3_CODE,
                          name = feature$properties$NAME_ENGL,
                          path = paste(rings, collapse = " "))
}
weights_map <- function(central_asia = FALSE) {
  bounds <- if (central_asia) c(46, 88, 36, 56) else c(-32, 52, 34, 72)
  donors <- unlist(lecture_data$donors, use.names = FALSE)
  weights <- setNames(vapply(lecture_data$weights, function(w) w$weight * 100, numeric(1)),
                      vapply(lecture_data$weights, function(w) w$iso3, character(1)))
  labels <- if (central_asia) {
    list(KAZ = c(0, 0), KGZ = c(13, -3), TJK = c(-26, 6))
  } else {
    list(UKR = c(0, 0), SVN = c(-32, -6), BGR = c(0, 0), MDA = c(42, 12), ARM = c(-4, 15))
  }
  shapes <- Filter(Negate(is.null), lapply(geo$features, regional_shape, bounds = bounds))
  # Draw donors last so neighboring fills cannot cover their bold outlines.
  shapes <- shapes[order(vapply(shapes, function(s) s$code %in% donors, logical(1)))]
  points <- lapply(shapes, function(s) {
    donor <- s$code %in% donors
    treated <- s$code == "UKR"
    value <- if (donor) {
      if (s$code %in% names(weights)) weights[[s$code]] else 0
    }
    offset <- labels[[s$code]]
    list(code = s$code, name = s$name, value = value,
         color = if (treated) yellow else if (!donor) "#e7ecef" else NULL,
         borderColor = if (donor) "#294b63" else "#a9b8bf",
         borderWidth = if (donor) 2.1 else 0.65,
         dataLabels = if (!is.null(offset)) list(enabled = TRUE, x = offset[1], y = offset[2]) else NULL,
         custom = list(status = if (treated) "Treated country, not a donor" else
           if (donor) sprintf("Donor pool · Published weight: %.1f%%", value) else "Outside the donor pool"))
  })
  tooltip <- "<b>{point.name}</b><br>{point.custom.status}"
  base_chart(if (central_asia) 190 else 550, "map") |>
    hc_add_series(type = "map", mapData = shapes, data = points,
                  joinBy = c("code", "code"), nullInteraction = TRUE,
                  dataLabels = list(enabled = FALSE, format = "{point.name}",
                    style = list(color = ink, fontSize = if (central_asia) "13px" else "16px",
                                 textOutline = "2px #fff"))) |>
    hc_colorAxis(min = 0, max = max(weights), tickPositions = c(0, 15, 30, max(weights)),
                 minColor = "#f7fbff", maxColor = "#08519c",
                 labels = list(format = "{value}%", style = list(fontSize = "13px", textOverflow = "none"))) |>
    hc_legend(enabled = !central_asia, symbolWidth = 232, symbolHeight = 13) |>
    hc_mapNavigation(enabled = !central_asia, enableMouseWheelZoom = FALSE) |>
    hc_tooltip(headerFormat = "", pointFormat = tooltip, nullFormat = tooltip)
}
lecture_chart <- function(name) {
  if (name == "nominal-gdp") {
    return(base_chart(220) |>
      hc_xAxis(min = 1991, max = 2025, allowDecimals = FALSE, tickInterval = 5) |>
      hc_yAxis(title = list(text = "US$ bn"), min = 0) |>
      hc_tooltip(enabled = FALSE) |>
      add_path(1991:2025, vapply(1991:2025, function(y) macro(y, "NY.GDP.MKTP.CD") / 1e9, numeric(1))) |>
      hc_legend(enabled = FALSE))
  }
  if (name == "cpi-inflation") {
    years <- 1996:2025
    values <- vapply(years, function(y) {
      value <- inflation_data[[as.character(y)]]
      if (is.null(value)) NA_real_ else value
    }, numeric(1))
    return(base_chart(220) |>
      hc_xAxis(min = 1991, max = 2025, allowDecimals = FALSE, tickInterval = 5) |>
      hc_yAxis(title = list(text = "Annual %")) |>
      hc_tooltip(enabled = FALSE) |>
      add_path(years, values, name = "CPI inflation", color = teal) |>
      hc_legend(enabled = FALSE))
  }
  if (name == "intro-map") return(lecture_map())
  if (name == "weights") return(weights_map())
  if (name == "weights-central-asia") return(weights_map(central_asia = TRUE))
  if (name == "overview") {
    # Shaded calendar years are visual guides, not estimates of causal effects.
    periods <- list(list(1991, 1999, "Transition"), list(2008, 2009, "GFC"),
                    list(2014, 2015, "2014/15"), list(2022, 2025, "Invasion"))
    bands <- lapply(periods, function(p) list(
      from = p[[1]] - 0.5, to = p[[2]] + 0.5, color = "rgba(245, 204, 65, 0.18)",
      label = list(text = p[[3]], align = "center", verticalAlign = "top", y = 18,
                   style = list(color = ink, fontSize = "16px"))))
    return(time_chart(1991:2025, indexed_gdp(1991, 2025, 1991), "", limits = c(0, 110)) |>
      hc_xAxis(labels = list(style = list(fontSize = "20px")), plotBands = bands) |>
      hc_yAxis(labels = list(style = list(fontSize = "20px"))) |>
      hc_legend(enabled = FALSE))
  }
  if (name == "structure") {
    keys <- c("NV.AGR.TOTL.ZS", "NV.IND.TOTL.ZS", "NV.SRV.TOTL.ZS")
    chart <- base_chart() |>
      hc_chart(type = "scatter", marginLeft = 155, marginRight = 55) |>
      hc_xAxis(min = 0, max = 70, tickInterval = 10,
               title = list(text = "Value added, % of GDP"),
               gridLineWidth = 1, gridLineColor = "#e4edf1") |>
      hc_yAxis(categories = c("Agriculture", "Industry", "Services"),
               reversed = TRUE, min = -0.5, max = 2.5, tickPositions = c(0, 1, 2),
               gridLineWidth = 0, labels = list(style = list(fontSize = "20px", color = ink))) |>
      hc_legend(enabled = FALSE) |> hc_tooltip(valueSuffix = "%")
    for (i in seq_along(keys)) {
      values <- vapply(c(1991, 2023), function(year) macro(year, keys[i]), numeric(1))
      chart <- hc_add_series(chart, type = "line", name = "Change",
        data = list(list(x = values[1], y = i - 1), list(x = values[2], y = i - 1)),
        color = "#b7cbd8", lineWidth = 4, enableMouseTracking = FALSE, showInLegend = FALSE)
    }
    arrow_points <- lapply(seq_along(keys), function(i) {
      start <- macro(1991, keys[i])
      end <- macro(2023, keys[i])
      list(x = (start + end) / 2, y = i - 1,
           label = if (end > start) "→" else "←")
    })
    chart <- hc_add_series(chart, type = "scatter", name = "Direction",
      data = arrow_points, enableMouseTracking = FALSE,
      marker = list(enabled = FALSE),
      dataLabels = list(enabled = TRUE, format = "{point.label}",
        padding = 2, y = 7,
        style = list(fontSize = "22px", fontWeight = "bold", color = teal, textOutline = "none")))
    for (year in c(1991, 2023)) {
      chart <- hc_add_series(chart, type = "scatter", name = as.character(year),
        data = lapply(seq_along(keys), function(i) list(x = macro(year, keys[i]), y = i - 1)),
        color = if (year == 1991) ink else teal,
        marker = list(enabled = TRUE, radius = 7, symbol = "circle"),
        dataLabels = list(enabled = TRUE, format = paste0(year, "  {point.x:.1f}%"),
          y = if (year == 1991) -14 else 30,
          style = list(fontSize = "16px", fontWeight = "bold", textOutline = "none",
                       color = if (year == 1991) ink else teal)))
    }
    return(chart)
  }
  if (name %in% c("gfc", "conflict", "invasion")) {
    cfg <- switch(name, gfc = c(2005, 2012, 2007, 2009),
                  conflict = c(2010, 2017, 2013, 2014), invasion = c(2018, 2025, 2021, 2022))
    chart <- time_chart(cfg[1]:cfg[2], indexed_gdp(cfg[1], cfg[2], cfg[3]),
                        paste("Real GDP,", cfg[3], "= 100"), cfg[4])
    if (name %in% c("conflict", "invasion")) chart <- hc_legend(chart, enabled = FALSE)
    return(chart)
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
    NULL, 2013, c(0, 11000)) |>
    hc_yAxis(labels = list(enabled = FALSE)) |>
    add_path(1995:2017, synthetic_values(), "Published-weight reconstruction", teal, "Dash") |>
    hc_legend(enabled = FALSE))
  if (name == "published-gap") return(base_chart() |>
    hc_xAxis(categories = vapply(lecture_data$published, function(x) as.character(x$year), character(1))) |>
    hc_yAxis(min = 0, max = 25, title = list(text = NULL), labels = list(enabled = FALSE)) |>
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
