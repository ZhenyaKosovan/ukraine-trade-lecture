/* global d3 */
"use strict";
const slides = window.LECTURE_SLIDES;
const $ = (id) => document.getElementById(id);
const C = {
  ink: "#163c55",
  blue: "#1675ae",
  teal: "#198a84",
  yellow: "#f5cc41",
  red: "#b94b56",
  muted: "#587181",
  line: "#d6e2e9",
  pale: "#edf4f7",
};
let data, geography;
let active = 0;
const fmt = d3.format(",.0f");
const signed = (v) => `${v > 0 ? "+" : ""}${d3.format(".1f")(v)}%`;
const macro = (year, indicator = "NY.GDP.MKTP.KD") =>
  data.macro[year]?.[indicator] ?? null;
const gdpSeries = (start, end, base) =>
  d3
    .range(start, end + 1)
    .map((year) => ({ year, value: (macro(year) / macro(base)) * 100 }));
const authorSeries = (name) =>
  data.countries
    .filter((r) => r.country === name)
    .map((r) => ({ year: r.year, value: r.gdppc }));
const syntheticSeries = () =>
  d3.range(1995, 2018).map((year) => ({
    year,
    value: d3.sum(
      data.weights,
      (w) =>
        w.weight *
        data.countries.find((r) => r.year === year && r.country === w.country)
          .gdppc,
    ),
  }));

function svgFor(element, width = 960, height = 440) {
  return d3
    .select(element)
    .append("svg")
    .attr("viewBox", `0 0 ${width} ${height}`)
    .attr("role", "img")
    .attr(
      "aria-label",
      element.closest("section").querySelector("h1, h2").textContent,
    );
}
function text(svg, x, y, label, options = {}) {
  return svg
    .append("text")
    .attr("x", x)
    .attr("y", y)
    .attr("fill", options.color || C.muted)
    .attr(
      "font-family",
      options.display ? "Barlow, sans-serif" : "Source, sans-serif",
    )
    .attr("font-size", options.size || 18)
    .attr("text-anchor", options.anchor || "start")
    .text(label);
}
function tip(event, title, description) {
  const t = d3.select("#tooltip");
  t.selectAll("*").remove();
  t.append("strong").text(title);
  t.append("span").text(description);
  $("tooltip").hidden = false;
  const rect = $("tooltip").getBoundingClientRect();
  t.style(
    "left",
    `${Math.max(8, Math.min(event.clientX + 14, innerWidth - rect.width - 10))}px`,
  ).style(
    "top",
    `${Math.max(8, Math.min(event.clientY + 14, innerHeight - rect.height - 10))}px`,
  );
}
function timeChart(element, series, options = {}) {
  const W = 960,
    H = 440,
    m = { left: 65, right: 35, top: 35, bottom: 58 };
  const svg = svgFor(element, W, H);
  const x = d3
    .scaleLinear()
    .domain(d3.extent(series, (d) => d.year))
    .range([m.left, W - m.right]);
  const low = d3.min(series, (d) => d.value),
    high = d3.max(series, (d) => d.value);
  const domain = options.domain || [
    Math.max(0, low - (high - low) * 0.18),
    high + (high - low) * 0.16,
  ];
  const y = d3
    .scaleLinear()
    .domain(domain)
    .nice()
    .range([H - m.bottom, m.top]);
  if (options.shade) {
    const [start, end] = options.shade;
    svg
      .append("rect")
      .attr("x", x(start))
      .attr("y", m.top)
      .attr("width", x(end) - x(start))
      .attr("height", H - m.bottom - m.top)
      .attr("fill", options.shadeColor || "#f8edf0");
  }
  svg
    .append("g")
    .attr("class", "axis")
    .attr("transform", `translate(${m.left},0)`)
    .call(
      d3
        .axisLeft(y)
        .ticks(5)
        .tickSize(-(W - m.left - m.right))
        .tickPadding(10),
    );
  svg
    .append("g")
    .attr("class", "axis")
    .attr("transform", `translate(0,${H - m.bottom})`)
    .call(
      d3
        .axisBottom(x)
        .tickValues(options.ticks || x.ticks(6).filter(Number.isInteger))
        .tickFormat(d3.format("d"))
        .tickSize(0)
        .tickPadding(25),
    );
  if (options.area)
    svg
      .append("path")
      .datum(series)
      .attr(
        "d",
        d3
          .area()
          .defined((d) => d.value !== null)
          .x((d) => x(d.year))
          .y0(y(0))
          .y1((d) => y(d.value)),
      )
      .attr("fill", "#e8f1f7");
  svg
    .append("path")
    .datum(series)
    .attr(
      "d",
      d3
        .line()
        .defined((d) => d.value !== null)
        .x((d) => x(d.year))
        .y((d) => y(d.value)),
    )
    .attr("fill", "none")
    .attr("stroke", C.ink)
    .attr("stroke-width", 3.5);
  text(svg, m.left, 17, options.unit || "Real GDP index", { size: 17 });
  if (options.event) {
    svg
      .append("line")
      .attr("class", "chart-event")
      .attr("x1", x(options.event))
      .attr("x2", x(options.event))
      .attr("y1", m.top)
      .attr("y2", H - m.bottom);
    text(
      svg,
      x(options.event) + 8,
      m.top + 20,
      options.eventLabel || String(options.event),
      { size: 18, color: C.red },
    );
  }
  svg
    .on("pointermove", (event) => {
      const [px] = d3.pointer(event, svg.node());
      const year = Math.round(x.invert(px));
      const point = series.find((d) => d.year === year);
      if (point)
        tip(
          event,
          String(year),
          `${d3.format(".1f")(point.value)} · ${options.unit || "index"}`,
        );
    })
    .on("pointerleave", () => {
      $("tooltip").hidden = true;
    });
  return { svg, x, y, W, H, m };
}
function addLine(plot, series, color, dash = null, width = 3) {
  plot.svg
    .append("path")
    .datum(series)
    .attr(
      "d",
      d3
        .line()
        .defined((d) => d.value !== null)
        .x((d) => plot.x(d.year))
        .y((d) => plot.y(d.value)),
    )
    .attr("fill", "none")
    .attr("stroke", color)
    .attr("stroke-width", width)
    .attr("stroke-dasharray", dash);
}

function introMap(element) {
  const svg = svgFor(element, 800, 500),
    projection = d3
      .geoMercator()
      .center([31, 48.5])
      .scale(780)
      .translate([400, 250]);
  const path = d3.geoPath(projection);
  svg
    .append("defs")
    .append("clipPath")
    .attr("id", "intro-clip")
    .append("rect")
    .attr("width", 800)
    .attr("height", 500);
  const g = svg.append("g").attr("clip-path", "url(#intro-clip)");
  g.selectAll("path")
    .data(geography.features)
    .join("path")
    .attr("d", path)
    .attr("class", "country-shape")
    .attr("fill", (f) =>
      f.properties.ISO3_CODE === "UKR" ? C.yellow : "#dae5eb",
    )
    .attr("stroke", (f) =>
      f.properties.ISO3_CODE === "UKR" ? "#b99327" : "white",
    );
  const kyiv = projection([30.52, 50.45]);
  svg
    .append("circle")
    .attr("cx", kyiv[0])
    .attr("cy", kyiv[1])
    .attr("r", 4)
    .attr("fill", C.ink);
}
function overview(element) {
  const p = timeChart(element, gdpSeries(1991, 2025, 1991), {
    domain: [0, 110],
    area: true,
    unit: "Real GDP · 1991 = 100",
    ticks: [1991, 2000, 2008, 2014, 2022, 2025],
  });
  const labels = [
    { year: 1999, label: "Transition recession", dx: 12, dy: 25 },
    { year: 2009, label: "2008/09 GFC", dx: -85, dy: 35 },
    { year: 2015, label: "2014/15 crisis", dx: -10, dy: -50 },
    { year: 2022, label: "2022 invasion", dx: -120, dy: 45 },
  ];
  labels.forEach((d) => {
    const v = (macro(d.year) / macro(1991)) * 100;
    p.svg
      .append("circle")
      .attr("cx", p.x(d.year))
      .attr("cy", p.y(v))
      .attr("r", 5)
      .attr("fill", C.yellow)
      .attr("stroke", C.ink);
    text(p.svg, p.x(d.year) + d.dx, p.y(v) + d.dy, d.label, {
      color: C.ink,
      size: 18,
    });
  });
}
function structure(element) {
  const svg = svgFor(element),
    keys = [
      { label: "Agriculture", id: "NV.AGR.TOTL.ZS" },
      { label: "Industry", id: "NV.IND.TOTL.ZS" },
      { label: "Services", id: "NV.SRV.TOTL.ZS" },
    ];
  const x = d3.scaleLinear().domain([0, 75]).range([180, 840]);
  [1991, 2023].forEach((year, yi) => {
    text(svg, 180 + yi * 350, 22, `${year}`, {
      size: 21,
      color: yi ? C.teal : C.ink,
    });
    svg
      .append("rect")
      .attr("x", 145 + yi * 350)
      .attr("y", 6)
      .attr("width", 20)
      .attr("height", 18)
      .attr("fill", yi ? C.teal : C.ink);
  });
  keys.forEach((k, i) => {
    const y = 80 + i * 108;
    text(svg, 5, y + 20, k.label, { size: 25, color: C.ink });
    [1991, 2023].forEach((year, j) => {
      const value = macro(year, k.id);
      svg
        .append("rect")
        .attr("x", 180)
        .attr("y", y + j * 31)
        .attr("width", x(value) - 180)
        .attr("height", 23)
        .attr("fill", j ? C.teal : C.ink);
      text(svg, x(value) + 10, y + j * 31 + 18, `${d3.format(".1f")(value)}%`, {
        size: 20,
        color: j ? C.teal : C.ink,
      });
    });
  });
  text(
    svg,
    180,
    429,
    "Shares need not add to 100%: GDP also includes taxes less subsidies.",
    { size: 18 },
  );
}
function crisis(element, type) {
  const config = {
    gfc: {
      start: 2005,
      end: 2012,
      base: 2007,
      event: 2009,
      label: "2009",
      shade: [2008, 2010],
    },
    conflict: {
      start: 2010,
      end: 2017,
      base: 2013,
      event: 2014,
      label: "2014",
      shade: [2013, 2016],
    },
    invasion: {
      start: 2018,
      end: 2025,
      base: 2021,
      event: 2022,
      label: "2022",
      shade: [2022, 2023],
    },
  }[type];
  const p = timeChart(
    element,
    gdpSeries(config.start, config.end, config.base),
    {
      unit: `Real GDP · ${config.base} = 100`,
      event: config.event,
      eventLabel: config.label,
      shade: config.shade,
    },
  );
  const last = type === "gfc" ? 2009 : type === "conflict" ? 2015 : 2023;
  p.svg
    .append("circle")
    .attr("cx", p.x(last))
    .attr("cy", p.y((macro(last) / macro(config.base)) * 100))
    .attr("r", 6)
    .attr("fill", C.red)
    .attr("stroke", "white")
    .attr("stroke-width", 2);
}
function missingComparison(element, interpolation = false) {
  const actual = gdpSeries(2000, 2017, 2012),
    p = timeChart(element, actual, {
      unit: "Real GDP · 2012 = 100",
      domain: [35, 135],
      shade: [2013, 2017],
      shadeColor: C.pale,
      event: 2013,
      eventLabel: "Crisis begins",
    });
  const start = actual.find((d) => d.year === 2012).value,
    end = actual.find((d) => d.year === 2017).value;
  if (interpolation) {
    addLine(
      p,
      [
        { year: 2012, value: start },
        { year: 2017, value: end },
      ],
      C.red,
      "8 6",
    );
    const previous = actual.find((d) => d.year === 2005).value,
      slope = (start - previous) / 7;
    addLine(
      p,
      d3
        .range(2012, 2018)
        .map((year) => ({ year, value: start + slope * (year - 2012) })),
      C.teal,
      "8 6",
    );
    text(p.svg, p.x(2014), p.y(119), "Extend an earlier trend?", {
      color: C.teal,
      size: 19,
    });
    text(p.svg, p.x(2013) + 8, p.y(79), "Join affected endpoints?", {
      color: C.red,
      size: 19,
    });
    p.svg
      .append("circle")
      .attr("cx", p.x(2017))
      .attr("cy", p.y(end))
      .attr("r", 10)
      .attr("fill", "none")
      .attr("stroke", C.red)
      .attr("stroke-width", 2);
  } else {
    [-1, 2, 5].forEach((s, i) =>
      addLine(
        p,
        d3
          .range(2012, 2018)
          .map((year) => ({ year, value: start + s * (year - 2012) })),
        ["#b7cbd8", "#86aebe", C.teal][i],
        "7 6",
        2.5,
      ),
    );
    text(p.svg, p.x(2014), p.y(114), "No-crisis path?", {
      size: 25,
      color: C.teal,
    });
    text(p.svg, p.x(2014), p.y(69), "Observed Ukraine", {
      size: 20,
      color: C.ink,
    });
  }
}
function donorPaths(element) {
  const actual = authorSeries("Ukraine"),
    base = actual.find((d) => d.year === 2012).value;
  const p = timeChart(
    element,
    actual.map((d) => ({ year: d.year, value: (d.value / base) * 100 })),
    {
      domain: [0, 155],
      unit: "GDP per person · each country in 2012 = 100",
      event: 2013,
      eventLabel: "2013",
    },
  );
  Object.keys(data.donors).forEach((country) => {
    const s = authorSeries(country),
      b = s.find((d) => d.year === 2012).value;
    addLine(
      p,
      s.map((d) => ({ year: d.year, value: (d.value / b) * 100 })),
      "#cbd9e1",
      null,
      1.5,
    );
  });
  addLine(
    p,
    actual.map((d) => ({ year: d.year, value: (d.value / base) * 100 })),
    C.ink,
    null,
    4,
  );
  text(p.svg, p.x(2015), p.y(85), "Ukraine", { size: 22, color: C.ink });
}
function methodDiagram(element) {
  const svg = svgFor(element, 960, 180);
  const x = d3.scaleLinear().domain([1995, 2017]).range([30, 920]);
  svg
    .append("rect")
    .attr("x", x(1995))
    .attr("y", 25)
    .attr("width", x(2013) - x(1995))
    .attr("height", 85)
    .attr("fill", C.pale);
  svg
    .append("rect")
    .attr("x", x(2013))
    .attr("y", 25)
    .attr("width", x(2017) - x(2013))
    .attr("height", 85)
    .attr("fill", C.ink);
  text(svg, x(2004), 77, "Choose proportions using earlier information", {
    size: 22,
    anchor: "middle",
    color: C.ink,
  });
  text(svg, x(2015), 59, "Keep weights", {
    size: 21,
    anchor: "middle",
    color: "white",
  });
  text(svg, x(2015), 94, "fixed", {
    size: 21,
    anchor: "middle",
    color: "white",
  });
  [1995, 2012, 2013, 2017].forEach((year) =>
    text(svg, x(year), 145, String(year), { size: 20, anchor: "middle" }),
  );
  svg
    .append("line")
    .attr("x1", x(2013))
    .attr("x2", x(2013))
    .attr("y1", 10)
    .attr("y2", 120)
    .attr("stroke", C.yellow)
    .attr("stroke-width", 5);
}
function weightsMap(element) {
  const W = 960,
    H = 480,
    svg = svgFor(element, W, H),
    donors = new Set(Object.values(data.donors));
  const weights = new Map(data.weights.map((d) => [d.iso3, d.weight]));
  const fit = geography.features.filter(
    (f) =>
      donors.has(f.properties.ISO3_CODE) || f.properties.ISO3_CODE === "UKR",
  );
  const projection = d3.geoMercator().fitExtent(
    [
      [45, 18],
      [925, 375],
    ],
    { type: "FeatureCollection", features: fit },
  );
  const path = d3.geoPath(projection),
    color = d3.scaleSequential(d3.interpolateBlues).domain([0, 0.452]);
  svg
    .append("defs")
    .append("clipPath")
    .attr("id", "weight-clip")
    .append("rect")
    .attr("width", W)
    .attr("height", 400);
  const g = svg.append("g").attr("clip-path", "url(#weight-clip)");
  g.selectAll("path")
    .data(geography.features)
    .join("path")
    .attr("class", "country-shape")
    .attr("d", path)
    .attr("fill", (f) => {
      const code = f.properties.ISO3_CODE;
      return code === "UKR"
        ? C.yellow
        : weights.has(code)
          ? color(weights.get(code))
          : donors.has(code)
            ? "#f7fbff"
            : "#e0e7eb";
    })
    .attr("stroke", (f) =>
      donors.has(f.properties.ISO3_CODE) ? "#8daec2" : "white",
    )
    .on("pointermove", (event, f) => {
      const code = f.properties.ISO3_CODE;
      tip(
        event,
        f.properties.NAME_ENGL,
        code === "UKR"
          ? "Ukraine is the treated country."
          : donors.has(code)
            ? `${d3.format(".1f")((weights.get(code) || 0) * 100)}% published weight`
            : "Not in the donor pool",
      );
    })
    .on("pointerleave", () => {
      $("tooltip").hidden = true;
    });
  const callouts = [
    { iso: "SVN", name: "Slovenia", point: [14.9, 46.1], dx: -110, dy: -50 },
    { iso: "MDA", name: "Moldova", point: [28.5, 47.2], dx: -10, dy: -115 },
    { iso: "BGR", name: "Bulgaria", point: [25.5, 42.7], dx: -100, dy: 58 },
    { iso: "ARM", name: "Armenia", point: [44.9, 40.3], dx: 65, dy: 28 },
  ];
  callouts.forEach((d) => {
    const a = projection(d.point),
      b = [a[0] + d.dx, a[1] + d.dy];
    svg
      .append("path")
      .attr("d", `M${a[0]},${a[1]}L${b[0]},${b[1] + (d.dy > 0 ? -46 : 38)}`)
      .attr("fill", "none")
      .attr("stroke", C.ink)
      .attr("stroke-width", 1);
    svg
      .append("circle")
      .attr("cx", a[0])
      .attr("cy", a[1])
      .attr("r", 3)
      .attr("fill", C.ink);
    text(svg, b[0], b[1] - 20, d.name, { size: 21, color: C.ink });
    text(
      svg,
      b[0],
      b[1] + 22,
      `${d3.format(".1f")(weights.get(d.iso) * 100)}%`,
      { size: 29, display: true, color: C.ink },
    );
  });
  const ukr = projection([32, 50]);
  text(svg, ukr[0], ukr[1], "Ukraine", {
    size: 24,
    display: true,
    color: C.ink,
    anchor: "middle",
  });
  const defs = svg.select("defs"),
    gradient = defs.append("linearGradient").attr("id", "weight-gradient");
  d3.range(0, 1.01, 0.1).forEach((t) =>
    gradient
      .append("stop")
      .attr("offset", `${t * 100}%`)
      .attr("stop-color", color(t * 0.452)),
  );
  svg
    .append("rect")
    .attr("x", 30)
    .attr("y", 421)
    .attr("width", 230)
    .attr("height", 13)
    .attr("fill", "url(#weight-gradient)");
  text(svg, 30, 458, "0%", { size: 18 });
  text(svg, 260, 458, "45.2%", { size: 18, anchor: "end" });
  [
    ["#f7fbff", "Candidate, zero weight", 310],
    ["#e0e7eb", "Outside pool", 620],
    [C.yellow, "Ukraine", 810],
  ].forEach(([fill, label, x]) => {
    svg
      .append("rect")
      .attr("class", "svg-swatch")
      .attr("x", x)
      .attr("y", 420)
      .attr("width", 18)
      .attr("height", 16)
      .attr("fill", fill);
    text(svg, x + 25, 435, label, { size: 17 });
  });
}
function syntheticPaths(element) {
  const actual = authorSeries("Ukraine"),
    synthetic = syntheticSeries();
  const p = timeChart(element, actual, {
    domain: [0, 11000],
    unit: "GDP per person · 2011 international dollars at PPP",
    shade: [2013, 2017],
    shadeColor: C.pale,
    event: 2013,
    eventLabel: "2013",
  });
  addLine(p, synthetic, C.teal, "9 5", 3.5);
}
function publishedGap(element) {
  const svg = svgFor(element),
    m = { left: 65, right: 25, top: 30, bottom: 65 },
    x = d3
      .scaleBand()
      .domain(data.published.map((d) => d.year))
      .range([m.left, 935])
      .padding(0.34),
    y = d3.scaleLinear().domain([0, 25]).range([375, m.top]);
  svg
    .append("g")
    .attr("class", "axis")
    .attr("transform", `translate(${m.left},0)`)
    .call(
      d3
        .axisLeft(y)
        .ticks(5)
        .tickFormat((v) => `${v}%`)
        .tickSize(-870)
        .tickPadding(10),
    );
  svg
    .append("g")
    .attr("class", "axis")
    .attr("transform", "translate(0,375)")
    .call(d3.axisBottom(x).tickSize(0).tickPadding(16));
  svg
    .selectAll("rect.loss")
    .data(data.published)
    .join("rect")
    .attr("class", "loss")
    .attr("x", (d) => x(d.year))
    .attr("y", (d) => y(d.percent))
    .attr("width", x.bandwidth())
    .attr("height", (d) => y(0) - y(d.percent))
    .attr("fill", C.red);
  data.published.forEach((d) =>
    text(
      svg,
      x(d.year) + x.bandwidth() / 2,
      y(d.percent) - 12,
      `${d3.format(".2f")(d.percent)}%`,
      { size: 23, color: C.red, anchor: "middle" },
    ),
  );
  text(svg, 65, 18, "Below the authors' counterfactual", { size: 18 });
}
function sensitivity(element) {
  const svg = svgFor(element),
    x = d3.scaleLinear().domain([0, 2000]).range([245, 890]);
  data.leaveOneOut.forEach((d, i) => {
    const y = 54 + i * 69;
    text(svg, 5, y + 20, d.label, { size: 23, color: C.ink });
    svg
      .append("rect")
      .attr("x", 245)
      .attr("y", y)
      .attr("width", x(d.loss) - 245)
      .attr("height", 28)
      .attr("fill", i === 0 ? C.ink : C.teal);
    text(svg, x(d.loss) + 12, y + 22, fmt(d.loss), {
      size: 24,
      color: i === 0 ? C.ink : C.teal,
    });
  });
  text(svg, 245, 423, "Average shortfall · 2011 PPP dollars per person", {
    size: 19,
  });
}
function placebos(element) {
  const svg = svgFor(element, 760, 460),
    names = ["Ukraine", ...Object.keys(data.donors)];
  names.forEach((name, i) => {
    const x = 70 + (i % 6) * 116,
      y = 75 + Math.floor(i / 6) * 115;
    svg
      .append("circle")
      .attr("cx", x)
      .attr("cy", y)
      .attr("r", 29)
      .attr("fill", i === 0 ? C.yellow : C.pale)
      .attr("stroke", i === 0 ? "#bd9325" : "#a2bdce");
    text(svg, x, y + 6, i === 0 ? "UA" : data.donors[name], {
      size: 21,
      anchor: "middle",
      color: C.ink,
    });
    text(svg, x, y + 49, name === "Kyrgyz Republic" ? "Kyrgyz Rep." : name, {
      size: 15,
      anchor: "middle",
    });
  });
  text(svg, 30, 405, "1 treated country + 17 donor comparisons", {
    size: 25,
    color: C.ink,
  });
  text(
    svg,
    30,
    437,
    "Procedure illustration. No new placebo estimates are shown.",
    { size: 19 },
  );
}

function renderSlideContent(section, s) {
  section.querySelectorAll("[data-growth]").forEach((e) => {
    e.textContent = signed(macro(e.dataset.growth, "NY.GDP.MKTP.KD.ZG"));
  });
  const population = section.querySelector("[data-population]");
  if (population)
    population.textContent = `${d3.format(".1f")(macro(1991, "SP.POP.TOTL") / 1e6)}m`;
  const recovery = section.querySelector("[data-recovery]");
  if (recovery)
    recovery.textContent = `In 2023, real GDP was still ${d3.format(".1f")((1 - macro(2023) / macro(2021)) * 100)}% below its 2021 level.`;
  const list = section.querySelector("[data-weight-list]");
  if (list) {
    const color = d3.scaleSequential(d3.interpolateBlues).domain([0, 0.452]);
    data.weights.forEach((w) => {
      const row = d3.select(list).append("div").attr("class", "weight-row");
      row.append("span").text(w.country);
      row.append("strong").text(`${(w.weight * 100).toFixed(1)}%`);
      row
        .append("div")
        .attr("class", "weight-bar")
        .append("span")
        .style("width", `${(w.weight / 0.452) * 100}%`)
        .style("background", color(w.weight));
    });
  }
  const sourceDirectory = section.querySelector("[data-source-directory]");
  if (sourceDirectory) {
    Object.values(data.sources).forEach((source) => {
      const a = document.createElement("a");
      a.textContent = source.label;
      a.href = source.url;
      a.target = "_blank";
      a.rel = "noreferrer";
      sourceDirectory.append(a);
    });
    const p = document.createElement("p");
    p.textContent =
      "Snapshot: 15 November 2026. Geography is not a map of statistical coverage or military control. GISCO boundaries: noncommercial use.";
    sourceDirectory.append(p);
  }
  section.querySelectorAll("[data-chart]").forEach((element) => {
    const type = element.dataset.chart;
    const renderers = {
      "intro-map": introMap,
      overview,
      structure,
      gfc: (e) => crisis(e, "gfc"),
      conflict: (e) => crisis(e, "conflict"),
      invasion: (e) => crisis(e, "invasion"),
      question: (e) => missingComparison(e),
      interpolation: (e) => missingComparison(e, true),
      "donor-paths": donorPaths,
      method: methodDiagram,
      weights: weightsMap,
      "synthetic-paths": syntheticPaths,
      "published-gap": publishedGap,
      sensitivity,
      placebos,
    };
    renderers[type](element);
  });
  if (s.id === "weights" || s.id === "1991")
    section
      .querySelector(".source-links")
      .append(
        document.createTextNode(
          "© EuroGeographics for the administrative boundaries",
        ),
      );
}
function go(index, updateHash = true) {
  active = Math.max(0, Math.min(slides.length - 1, index));
  document.querySelectorAll("section.slide").forEach((section, i) => {
    section.classList.toggle("active", i === active);
    section.setAttribute("aria-hidden", String(i !== active));
  });
  $("counter").textContent = `${active + 1} / ${slides.length}`;
  $("slide-select").value = String(active);
  $("previous").disabled = active === 0;
  $("next").disabled = active === slides.length - 1;
  $("progress").style.width = `${((active + 1) / slides.length) * 100}%`;
  $("notes-title").textContent = `${active + 1}. ${slides[active].title}`;
  $("notes-text").textContent = slides[active].notes;
  $("tooltip").hidden = true;
  document.title = `${active + 1}. ${slides[active].title} | Ukraine lecture`;
  if (updateHash) history.replaceState(null, "", `#${slides[active].id}`);
  if (innerWidth <= 760) window.scrollTo({ top: 0, behavior: "instant" });
}
function toggleNotes() {
  const open = $("notes").hidden;
  $("notes").hidden = !open;
  $("notes-button").setAttribute("aria-pressed", String(open));
}
async function fullscreen() {
  try {
    if (document.fullscreenElement) await document.exitFullscreen();
    else await document.documentElement.requestFullscreen();
  } catch {
    $("fullscreen").textContent = "Fullscreen unavailable";
  }
}
function bind() {
  $("previous").addEventListener("click", () => go(active - 1));
  $("next").addEventListener("click", () => go(active + 1));
  $("slide-select").addEventListener("change", (event) =>
    go(Number(event.target.value)),
  );
  $("notes-button").addEventListener("click", toggleNotes);
  $("close-notes").addEventListener("click", toggleNotes);
  $("fullscreen").addEventListener("click", fullscreen);
  $("print").addEventListener("click", () => window.print());
  window.addEventListener("hashchange", () => {
    const index = slides.findIndex((s) => s.id === location.hash.slice(1));
    if (index >= 0) go(index, false);
  });
  document.addEventListener("keydown", (event) => {
    if (
      event.altKey ||
      event.ctrlKey ||
      event.metaKey ||
      ["SELECT", "INPUT", "TEXTAREA"].includes(
        document.activeElement?.tagName,
      ) ||
      (event.key === " " &&
        ["BUTTON", "A"].includes(document.activeElement?.tagName))
    )
      return;
    const actions = {
      ArrowRight: () => go(active + 1),
      PageDown: () => go(active + 1),
      " ": () => go(active + 1),
      ArrowLeft: () => go(active - 1),
      PageUp: () => go(active - 1),
      Home: () => go(0),
      End: () => go(slides.length - 1),
      n: toggleNotes,
      N: toggleNotes,
      f: fullscreen,
      F: fullscreen,
      Escape: () => {
        if (!$("notes").hidden) toggleNotes();
      },
    };
    if (actions[event.key]) {
      event.preventDefault();
      actions[event.key]();
    }
  });
  document.addEventListener("fullscreenchange", () => {
    $("fullscreen").textContent = document.fullscreenElement
      ? "Exit fullscreen"
      : "Fullscreen";
  });
}
function element(tag, className, label) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (label !== undefined) node.textContent = label;
  return node;
}
function appendSlideTemplate(container, markup) {
  // Author-written slide bodies use a tiny markup vocabulary; strip everything else.
  const parsed = new DOMParser().parseFromString(markup, "text/html");
  const tags = new Set([
    "DIV",
    "P",
    "SPAN",
    "B",
    "STRONG",
    "UL",
    "OL",
    "LI",
    "ARTICLE",
    "H3",
    "BR",
  ]);
  const attributes = new Set([
    "class",
    "data-chart",
    "data-growth",
    "data-population",
    "data-recovery",
    "data-weight-list",
    "data-source-directory",
  ]);
  parsed.body.querySelectorAll("*").forEach((node) => {
    if (!tags.has(node.tagName)) {
      node.remove();
      return;
    }
    [...node.attributes].forEach((attribute) => {
      if (!attributes.has(attribute.name)) node.removeAttribute(attribute.name);
    });
  });
  container.append(
    ...[...parsed.body.childNodes].map((node) =>
      document.importNode(node, true),
    ),
  );
}
async function start() {
  const responses = await Promise.all([
    fetch("data.json"),
    fetch("../raw/geography/CNTR_RG_20M_2024_4326.geojson"),
  ]);
  if (responses.some((r) => !r.ok))
    throw new Error(
      "Serve the parent ukraine-trade-lecture folder and run scripts/build_deck_data.py.",
    );
  [data, geography] = await Promise.all(responses.map((r) => r.json()));
  $("loading").remove();
  slides.forEach((s, i) => {
    const section = element("section", `slide ${s.kind}`);
    section.id = `slide-${s.id}`;
    section.setAttribute("aria-labelledby", `title-${s.id}`);
    const header = element("header", "slide-head"),
      title = element("h1", "", s.title);
    title.id = `title-${s.id}`;
    header.append(
      element("p", "chapter", s.chapter),
      title,
      element("p", "kicker", s.kicker),
    );
    const content = element("div", "slide-content");
    appendSlideTemplate(content, s.body);
    const bottom = element("div", "slide-bottom"),
      footer = element("footer", "slide-footer");
    footer.append(
      element("div", "source-links"),
      element(
        "span",
        "slide-number",
        `${String(i + 1).padStart(2, "0")} / ${slides.length}`,
      ),
    );
    bottom.append(element("p", "takeaway", s.takeaway), footer);
    section.append(header, content, bottom);
    const sourceLinks = section.querySelector(".source-links");
    s.sources.forEach((key) => {
      const source = data.sources[key],
        a = document.createElement("a");
      a.href = source.url;
      a.textContent = source.label;
      a.target = "_blank";
      a.rel = "noreferrer";
      sourceLinks.append(a);
    });
    $("stage").append(section);
    renderSlideContent(section, s);
    const option = document.createElement("option");
    option.value = String(i);
    option.textContent = `${String(i + 1).padStart(2, "0")} · ${s.title}`;
    $("slide-select").append(option);
  });
  bind();
  const first = slides.findIndex((s) => s.id === location.hash.slice(1));
  go(first >= 0 ? first : 0);
}
// Quarto owns slide markup and navigation; share only the data/chart renderer.
window.renderQuartoLecture = async () => {
  if (window.LECTURE_BUNDLE) {
    ({ data, geography } = window.LECTURE_BUNDLE);
  } else {
    const responses = await Promise.all([
      fetch("data.json"),
      fetch("../raw/geography/CNTR_RG_20M_2024_4326.geojson"),
    ]);
    if (responses.some((response) => !response.ok))
      throw new Error("Lecture data or geometry could not load.");
    [data, geography] = await Promise.all(responses.map((response) => response.json()));
  }
  document.querySelectorAll(".reveal .slides > section").forEach((section) => {
    renderSlideContent(section, { id: section.id });
  });
  document.documentElement.dataset.chartsReady = "true";
};
if (!window.QUARTO_LECTURE) start().catch((error) => {
  const p = document.createElement("p");
  p.id = "loading";
  p.textContent = `Could not load the lecture. ${error.message}`;
  $("stage").replaceChildren(p);
  console.error(error);
});
