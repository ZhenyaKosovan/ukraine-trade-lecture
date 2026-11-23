/* global d3 */
"use strict";

const $ = (id) => document.getElementById(id);
const usd = (value) => {
  if (value === null || value === undefined) return "No observation";
  if (value === 0) return "$0";
  if (value >= 1e9) return `$${d3.format(".2f")(value / 1e9)}bn`;
  if (value >= 1e6) return `$${d3.format(".1f")(value / 1e6)}m`;
  return `$${d3.format(",.0f")(value)}`;
};
const pct = (value) =>
  `${d3.format(value > 0 && value < 0.1 ? ".2f" : ".1f")(value)}%`;
const params = new URLSearchParams(location.search);
const initialYear = Number(params.get("year") || 2023);
const state = {
  dataset: params.get("dataset") === "it" ? "it" : "goods",
  flow: params.get("flow") === "import" ? "import" : "export",
  sector: params.get("sector") || "All goods",
  measure: params.get("measure") === "share" ? "share" : "value",
  year:
    Number.isInteger(initialYear) && initialYear >= 1991 && initialYear <= 2025
      ? initialYear
      : 2023,
  selected: params.get("partner") || null,
  view: "world",
};
let data;
let countries;
let projection;
let paths;
let zoom;
let timer = null;
let current = null;
let currentColor;
let fixedMaximum = 1;
let resizeTimer;
const MAX_MAP_PARTNERS = 6;
const seriesLabel = () =>
  state.dataset === "goods" ? "Goods" : "Computer services";
const snapshot = (year = state.year) =>
  data.snapshots[`${state.dataset}|${year}|${state.flow}|${state.sector}`] ||
  null;
const valueFor = (row, country) =>
  row && Object.hasOwn(row.partners, country) ? row.partners[country] : null;
const measured = (value, row) =>
  state.measure === "share"
    ? row?.total
      ? (value / row.total) * 100
      : 0
    : value;
function populateSectors() {
  const options =
    state.dataset === "goods"
      ? ["All goods", ...data.goodsSectors]
      : ["Computer services"];
  if (!options.includes(state.sector)) state.sector = options[0];
  d3.select("#sector")
    .selectAll("option")
    .data(options)
    .join("option")
    .attr("value", (d) => d)
    .text((d) => d);
  $("sector").value = state.sector;
  $("sector").disabled = state.dataset === "it";
}

function fixedScale() {
  const [first, last] = data.availability[state.dataset];
  const values = [];
  for (let year = first; year <= last; year += 1) {
    const row = snapshot(year);
    if (row)
      values.push(...Object.values(row.partners).map((v) => measured(v, row)));
  }
  fixedMaximum = d3.max(values) || 1;
  currentColor = d3
    .scaleSequentialSqrt(d3.interpolateBlues)
    .domain([0, fixedMaximum]);
  renderLegend();
}

function renderLegend() {
  const svg = d3.select("#legend");
  svg.selectAll("*").remove();
  const definitions = svg.append("defs");
  const gradient = definitions
    .append("linearGradient")
    .attr("id", "legend-gradient");
  d3.range(0, 1.001, 0.05).forEach((t) =>
    gradient
      .append("stop")
      .attr("offset", `${t * 100}%`)
      .attr("stop-color", currentColor(t * fixedMaximum)),
  );
  svg
    .append("rect")
    .attr("x", 1)
    .attr("y", 1)
    .attr("width", 252)
    .attr("height", 9)
    .attr("fill", "url(#legend-gradient)");
  const ticks = [0, fixedMaximum / 4, fixedMaximum];
  svg
    .selectAll("text")
    .data(ticks)
    .join("text")
    .attr("x", (_d, i) => [1, 64, 253][i])
    .attr("y", 27)
    .attr("text-anchor", (_d, i) => (i === 2 ? "end" : "start"))
    .attr("fill", "#587181")
    .attr("font-family", "Source, sans-serif")
    .attr("font-size", 10)
    .text((d) => (state.measure === "share" ? pct(d) : usd(d)));
  $("scale-note").textContent =
    `Fixed across ${data.availability[state.dataset].join(" to ")} · ${state.measure === "value" ? "current USD · square-root scale" : "share · square-root scale"}`;
}

function setupMap() {
  projection = d3
    .geoNaturalEarth1()
    .rotate([-12, 0])
    .fitExtent(
      [
        [12, 25],
        [948, 452],
      ],
      {
        type: "FeatureCollection",
        features: countries.filter((f) => f.properties.ISO3_CODE !== "ATA"),
      },
    );
  const path = d3.geoPath(projection);
  const group = d3.select("#map-geography");
  group
    .append("path")
    .datum(d3.geoGraticule10())
    .attr("class", "graticule")
    .attr("d", path);
  paths = group
    .selectAll("path.country")
    .data(countries.filter((f) => f.properties.ISO3_CODE !== "ATA"))
    .join("path")
    .attr(
      "class",
      (f) => `country${f.properties.ISO3_CODE === "UKR" ? " reporter" : ""}`,
    )
    .attr("d", path)
    .on("pointermove", showTooltip)
    .on("pointerleave", hideTooltip)
    .on("click", (_event, f) => {
      const code = f.properties.ISO3_CODE;
      if (code !== "UKR" && valueFor(current, code) !== null)
        selectCountry(code);
    });
  paths.append("title").text((f) => f.properties.NAME_ENGL);
  // Keep the reporter visible over adjoining country outlines.
  paths.filter((f) => f.properties.ISO3_CODE === "UKR").raise();
  zoom = d3
    .zoom()
    .scaleExtent([1, 6])
    .translateExtent([
      [-100, -60],
      [1060, 560],
    ])
    .on("zoom", (event) => group.attr("transform", event.transform));
  d3.select("#map").call(zoom).on("dblclick.zoom", null);
}

function changeView(view) {
  state.view = view;
  $("world-view").setAttribute("aria-pressed", String(view === "world"));
  $("europe-view").setAttribute("aria-pressed", String(view === "europe"));
  const center = projection([24, 50]);
  const transform =
    view === "world"
      ? d3.zoomIdentity
      : d3.zoomIdentity
          .translate(480 - center[0] * 3, 250 - center[1] * 3)
          .scale(3);
  d3.select("#map").call(zoom.transform, transform);
  hideTooltip();
}

function showTooltip(event, feature) {
  const code = feature.properties.ISO3_CODE;
  const value = valueFor(current, code);
  const tip = d3.select("#tooltip");
  tip.selectAll("*").remove();
  tip.append("strong").text(data.names[code] || feature.properties.NAME_ENGL);
  if (code === "UKR") {
    tip.append("span").text("Ukraine is the reporting country.");
    tip
      .append("small")
      .text("Boundaries include Crimea. They do not show military control.");
  } else if (value === null) {
    tip.append("span").text("No observation in this selection");
    tip
      .append("small")
      .text(
        state.dataset === "it"
          ? "This series lists selected partners only. Missing does not mean zero."
          : "Missing records are not filled with zero.",
      );
  } else {
    tip.append("span").attr("class", "tip-value").text(usd(value));
    tip
      .append("small")
      .text(
        `${pct(current.total ? (value / current.total) * 100 : 0)} of ${current.denominator} · ${state.year}`,
      );
    tip.append("small").text("Click to follow this partner over time.");
  }
  $("tooltip").hidden = false;
  const bounds = $("tooltip").getBoundingClientRect();
  tip
    .style(
      "left",
      `${Math.max(8, Math.min(event.clientX + 15, innerWidth - bounds.width - 10))}px`,
    )
    .style(
      "top",
      `${Math.max(8, Math.min(event.clientY + 15, innerHeight - bounds.height - 10))}px`,
    );
}

function hideTooltip() {
  $("tooltip").hidden = true;
}

function selectCountry(code) {
  state.selected = state.selected === code ? null : code;
  render();
}

function partnerRanking() {
  d3.select("#partner-list").selectAll("p.empty-list").remove();
  const sorted = current
    ? Object.entries(current.partners)
        .filter(([code]) => code !== "UKR")
        .sort((a, b) => b[1] - a[1])
    : [];
  $("partner-count").textContent = current ? `${sorted.length} reported` : "";
  const top = sorted.slice(0, MAX_MAP_PARTNERS);
  const buttons = d3
    .select("#partner-list")
    .selectAll("button")
    .data(top, (d) => d[0])
    .join("button")
    .attr("class", "partner-row")
    .attr("aria-pressed", (d) => String(d[0] === state.selected))
    .on("click", (_event, d) => selectCountry(d[0]));
  buttons.selectAll("*").remove();
  buttons.each(function ([code, value], i) {
    const button = d3.select(this);
    button
      .append("span")
      .attr("class", "rank")
      .text(String(i + 1).padStart(2, "0"));
    button
      .append("span")
      .attr("class", "partner-name")
      .text(data.names[code] || code);
    const label = button
      .append("span")
      .attr("class", "partner-value")
      .text(usd(value));
    label
      .append("span")
      .attr("class", "partner-share")
      .text(` ${pct(current.total ? (value / current.total) * 100 : 0)}`);
    button
      .append("span")
      .attr("class", "bar-track")
      .attr("aria-hidden", "true")
      .append("span")
      .attr("class", "bar-fill")
      .style("width", `${top[0][1] > 0 ? (value / top[0][1]) * 100 : 0}%`);
  });
  if (!current)
    d3.select("#partner-list")
      .append("p")
      .attr("class", "empty-list")
      .text("No partner observations for this year.");
}

function countryChart() {
  const svg = d3.select("#country-chart");
  svg.selectAll("*").remove();
  $("clear-country").hidden = !state.selected;
  svg.attr("hidden", state.selected ? null : "");
  if (!state.selected) {
    $("country-title").textContent = "Choose a partner";
    $("country-subtitle").textContent =
      "Click a country or a ranked partner to see its history.";
    return;
  }
  const code = state.selected;
  const [start, end] = data.availability[state.dataset];
  const history = d3.range(start, end + 1).map((year) => {
    const row = snapshot(year);
    const value = valueFor(row, code);
    return { year, value: value === null ? null : measured(value, row) };
  });
  const value = valueFor(current, code);
  $("country-title").textContent = data.names[code] || code;
  $("country-subtitle").textContent =
    value === null
      ? `No observation for ${state.year}. Gaps remain blank.`
      : `${usd(value)} in ${state.year} · ${pct(current.total ? (value / current.total) * 100 : 0)} of ${current.denominator}`;
  const x = d3.scaleLinear().domain([start, end]).range([9, 305]);
  const y = d3
    .scaleLinear()
    .domain([0, d3.max(history, (r) => r.value) || 1])
    .nice()
    .range([83, 10]);
  const line = d3
    .line()
    .defined((r) => r.value !== null)
    .x((r) => x(r.year))
    .y((r) => y(r.value));
  svg
    .append("path")
    .datum(history)
    .attr("d", line)
    .attr("fill", "none")
    .attr("stroke", "#1675ae")
    .attr("stroke-width", 2);
  svg
    .append("g")
    .attr("class", "axis")
    .attr("transform", "translate(0,86)")
    .call(
      d3
        .axisBottom(x)
        .tickValues([start, end])
        .tickFormat(d3.format("d"))
        .tickSize(0),
    )
    .call((g) => g.select(".domain").remove());
  if (state.year >= start && state.year <= end) {
    svg
      .append("line")
      .attr("x1", x(state.year))
      .attr("x2", x(state.year))
      .attr("y1", 5)
      .attr("y2", 86)
      .attr("stroke", "#a2b5c1")
      .attr("stroke-dasharray", "3 3");
    if (value !== null)
      svg
        .append("circle")
        .attr("cx", x(state.year))
        .attr("cy", y(measured(value, current)))
        .attr("r", 4)
        .attr("fill", "#163c55")
        .attr("stroke", "white");
  }
  svg
    .append("text")
    .attr("x", 9)
    .attr("y", 8)
    .attr("font-size", 9)
    .attr("fill", "#587181")
    .text(state.measure === "share" ? "% of selected total" : "Current USD");
}

function macroCharts() {
  const yearData = data.macro[state.year] || {};
  const baseline = data.macro["1991"]["NY.GDP.MKTP.KD"];
  const series = d3.range(1991, 2026).map((year) => ({
    year,
    value: data.macro[year]?.["NY.GDP.MKTP.KD"] ?? null,
  }));
  series.forEach((d) => {
    d.value = d.value === null ? null : (d.value / baseline) * 100;
  });
  const selected = series.find((r) => r.year === state.year);
  $("gdp-value").textContent =
    selected?.value === null ? "No data" : d3.format(".1f")(selected.value);
  const svg = d3.select("#gdp-chart");
  svg.selectAll("*").remove();
  const x = d3.scaleLinear().domain([1991, 2025]).range([36, 598]);
  const y = d3
    .scaleLinear()
    .domain([
      0,
      Math.max(
        105,
        d3.max(series, (r) => r.value),
      ),
    ])
    .range([188, 18]);
  svg
    .append("g")
    .attr("class", "axis")
    .attr("transform", "translate(36,0)")
    .call(
      d3
        .axisLeft(y)
        .tickValues([0, 25, 50, 75, 100])
        .tickSize(-562)
        .tickPadding(9),
    );
  svg
    .append("g")
    .attr("class", "axis")
    .attr("transform", "translate(0,188)")
    .call(
      d3
        .axisBottom(x)
        .tickValues([1991, 2000, 2010, 2020, 2025])
        .tickFormat(d3.format("d"))
        .tickSize(0)
        .tickPadding(10),
    );
  const area = d3
    .area()
    .defined((r) => r.value !== null)
    .x((r) => x(r.year))
    .y0(y(0))
    .y1((r) => y(r.value));
  const line = d3
    .line()
    .defined((r) => r.value !== null)
    .x((r) => x(r.year))
    .y((r) => y(r.value));
  svg.append("path").datum(series).attr("d", area).attr("fill", "#e7f1f7");
  [2014, 2022].forEach((year) => {
    svg
      .append("line")
      .attr("class", "event-line")
      .attr("x1", x(year))
      .attr("x2", x(year))
      .attr("y1", 17)
      .attr("y2", 188);
    svg
      .append("text")
      .attr("class", "event-label")
      .attr("x", x(year) + 4)
      .attr("y", 12)
      .text(year);
  });
  svg
    .append("path")
    .datum(series)
    .attr("d", line)
    .attr("fill", "none")
    .attr("stroke", "#1675ae")
    .attr("stroke-width", 2.5);
  svg
    .append("line")
    .attr("x1", x(state.year))
    .attr("x2", x(state.year))
    .attr("y1", 17)
    .attr("y2", 188)
    .attr("stroke", "#163c55")
    .attr("stroke-width", 1);
  if (selected?.value !== null)
    svg
      .append("circle")
      .attr("cx", x(state.year))
      .attr("cy", y(selected.value))
      .attr("r", 4.5)
      .attr("fill", "#f5cc41")
      .attr("stroke", "#163c55");
  svg.on("click", (event) => {
    const [px] = d3.pointer(event, svg.node());
    setYear(Math.round(Math.max(1991, Math.min(2025, x.invert(px)))));
  });
  $("structure-year").textContent = state.year;
  const structure = [
    { label: "Agriculture", code: "NV.AGR.TOTL.ZS", color: "#b6a040" },
    { label: "Industry", code: "NV.IND.TOTL.ZS", color: "#507992" },
    { label: "Services", code: "NV.SRV.TOTL.ZS", color: "#1675ae" },
  ];
  const rows = d3
    .select("#structure-bars")
    .selectAll("div.structure-row")
    .data(structure)
    .join("div")
    .attr("class", "structure-row");
  rows.selectAll("*").remove();
  rows.each(function (row) {
    const value = yearData[row.code] ?? null;
    const element = d3.select(this);
    element.append("span").text(row.label);
    element
      .append("div")
      .attr("class", "structure-track")
      .append("div")
      .attr("class", "structure-fill")
      .style("background", row.color)
      .style("width", `${value ?? 0}%`);
    element
      .append("span")
      .attr("class", "structure-value")
      .text(value === null ? "No data" : pct(value));
  });
}

function updateURL() {
  const p = new URLSearchParams({
    year: String(state.year),
    dataset: state.dataset,
    flow: state.flow,
    sector: state.sector,
    measure: state.measure,
  });
  if (state.selected) p.set("partner", state.selected);
  history.replaceState(null, "", `?${p}`);
}

function updateDownload() {
  const link = $("download");
  link.setAttribute("aria-disabled", String(!current));
  if (!current) {
    link.removeAttribute("href");
    link.removeAttribute("download");
    return;
  }
  const exportRows = Object.entries(current.partners)
    .sort((a, b) => b[1] - a[1])
    .map(([code, value]) => ({
      year: state.year,
      series: seriesLabel(),
      flow: state.flow,
      product_group: state.sector,
      iso3: code,
      partner: data.names[code],
      value_usd: value,
      share_percent: current.total ? (value / current.total) * 100 : "",
      denominator_usd: current.total,
      denominator_basis: current.denominator,
      snapshot_date: data.snapshotDate,
    }));
  link.href = `data:text/csv;charset=utf-8,${encodeURIComponent(d3.csvFormat(exportRows))}`;
  link.download = `ukraine-${state.dataset}-${state.flow}-${state.year}.csv`;
}

function render() {
  hideTooltip();
  current = snapshot();
  $("year").value = state.year;
  $("year-value").textContent = state.year;
  $("map-year").textContent = state.year;
  $("map-kicker").textContent =
    state.flow === "export" ? "Exports from Ukraine" : "Imports into Ukraine";
  $("map-title").textContent = state.sector;
  $("map-svg-title").textContent =
    `${state.sector}, ${state.flow}s, ${state.year}`;
  $("dataset").value = state.dataset;
  $("measure").value = state.measure;
  document
    .querySelectorAll("[data-flow]")
    .forEach((b) =>
      b.setAttribute("aria-pressed", String(b.dataset.flow === state.flow)),
    );
  const [first, last] = data.availability[state.dataset];
  $("year").style.setProperty(
    "--range-start",
    `${((first - 1991) / 34) * 100}%`,
  );
  $("year").style.setProperty("--range-end", `${((last - 1991) / 34) * 100}%`);
  $("availability").textContent =
    `Blue band: ${seriesLabel().toLowerCase()} maps, ${first} to ${last}. GDP context: 1991 to 2025.`;
  paths
    .attr("fill", (feature) => {
      const code = feature.properties.ISO3_CODE;
      if (code === "UKR") return "#f5cc41";
      const value = valueFor(current, code);
      return value === null
        ? "url(#missing)"
        : currentColor(measured(value, current));
    })
    .classed("selected", (f) => f.properties.ISO3_CODE === state.selected);
  $("map-empty").hidden = Boolean(current);
  $("empty-year").textContent = state.year;
  $("empty-explanation").textContent =
    `This ${seriesLabel().toLowerCase()} series has partner observations for ${first} to ${last}. Earlier and later records are not assumed to be zero.`;
  $("jump-to-data").textContent = `Go to ${first}, the first trade year`;
  updateDownload();
  $("previous-year").disabled = state.year === 1991;
  $("next-year").disabled = state.year === 2025;
  $("total-label").textContent =
    `${current?.denominator === "sum of named partners" ? "Named-partner" : "Published"} ${state.flow}s`;
  $("trade-total").textContent = current ? usd(current.total) : "No data";
  $("total-note").textContent = current
    ? state.dataset === "it"
      ? "World total; list contains selected partners."
      : current.denominator === "sum of named partners"
        ? "Selected product group; named ISO3 partners only."
        : "World total, including residual and unallocated trade."
    : "The economic timeline is still available below.";
  $("selection-note").textContent =
    `${state.dataset === "goods" ? data.notes.goods : data.notes.it} ${state.dataset === "goods" && state.sector !== "All goods" ? data.notes.sectors : ""} ${state.year >= 2014 ? "Territorial and reporting coverage differ from earlier years." : ""}`;
  partnerRanking();
  countryChart();
  macroCharts();
  updateURL();
}

function setYear(year) {
  state.year = Math.max(1991, Math.min(2025, Number(year)));
  render();
}

function stopPlayback() {
  if (timer) clearInterval(timer);
  timer = null;
  $("play").textContent = "▶ Play";
  $("play").setAttribute("aria-label", "Play available trade years");
}

function bindControls() {
  $("dataset").addEventListener("change", (event) => {
    stopPlayback();
    state.dataset = event.target.value;
    populateSectors();
    fixedScale();
    render();
  });
  $("sector").addEventListener("change", (event) => {
    state.sector = event.target.value;
    fixedScale();
    render();
  });
  $("measure").addEventListener("change", (event) => {
    state.measure = event.target.value;
    fixedScale();
    render();
  });
  document.querySelectorAll("[data-flow]").forEach((b) =>
    b.addEventListener("click", () => {
      state.flow = b.dataset.flow;
      fixedScale();
      render();
    }),
  );
  $("year").addEventListener("input", (event) => {
    stopPlayback();
    setYear(event.target.value);
  });
  document.querySelectorAll("[data-year]").forEach((b) => {
    b.style.left = `${((Number(b.dataset.year) - 1991) / 34) * 100}%`;
    b.addEventListener("click", () => {
      stopPlayback();
      setYear(b.dataset.year);
    });
  });
  $("previous-year").addEventListener("click", () => {
    stopPlayback();
    setYear(state.year - 1);
  });
  $("next-year").addEventListener("click", () => {
    stopPlayback();
    setYear(state.year + 1);
  });
  $("jump-to-data").addEventListener("click", () => {
    stopPlayback();
    setYear(data.availability[state.dataset][0]);
  });
  $("play").addEventListener("click", () => {
    if (timer) {
      stopPlayback();
      return;
    }
    const [start, end] = data.availability[state.dataset];
    if (state.year < start || state.year >= end) setYear(start);
    $("play").textContent = "Ⅱ Pause";
    $("play").setAttribute("aria-label", "Pause year playback");
    timer = setInterval(() => {
      if (state.year >= end) {
        stopPlayback();
        return;
      }
      setYear(state.year + 1);
    }, 1000);
  });
  $("clear-country").addEventListener("click", () => {
    state.selected = null;
    render();
  });
  $("world-view").addEventListener("click", () => changeView("world"));
  $("europe-view").addEventListener("click", () => changeView("europe"));
  document.addEventListener("visibilitychange", () => {
    if (document.hidden) stopPlayback();
  });
  $("download").addEventListener("click", (event) => {
    if (!current) event.preventDefault();
  });
  window.addEventListener("resize", () => {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(hideTooltip, 100);
  });
}

async function start() {
  if (typeof d3 === "undefined")
    throw new Error(
      "The local D3 file is missing. Restore prototype/vendor/d3.v7.min.js.",
    );
  const [tradeResponse, geographyResponse] = await Promise.all([
    fetch("data/trade.json"),
    fetch("../raw/geography/CNTR_RG_20M_2024_4326.geojson"),
  ]);
  if (!tradeResponse.ok || !geographyResponse.ok)
    throw new Error(
      "A local data file could not be loaded. Run scripts/build_prototype_data.py and serve the whole ukraine-trade-lecture folder.",
    );
  [data, { features: countries }] = await Promise.all([
    tradeResponse.json(),
    geographyResponse.json(),
  ]);
  if (!data.names[state.selected]) state.selected = null;
  populateSectors();
  setupMap();
  bindControls();
  fixedScale();
  render();
  ["controls", "atlas", "timeline", "context"].forEach((id) => {
    $(id).hidden = false;
  });
  $("load-status").hidden = true;
}
start().catch((error) => {
  $("load-status").hidden = false;
  $("load-status").textContent =
    `Could not load the atlas. ${error.message} Open it through a local HTTP server, not a file:// URL.`;
  console.error(error);
});
