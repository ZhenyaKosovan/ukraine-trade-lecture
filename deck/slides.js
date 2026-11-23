/* Lecture copy, speaker notes, and citations. No estimated results are embedded as new findings. */
"use strict";
window.LECTURE_SLIDES = [
  {
    id: "1991",
    chapter: "Ukraine in context",
    title: "Ukraine, 1991.",
    kind: "intro",
    kicker: "An independent country. An inherited economic system.",
    body: `<div class="intro-facts"><div class="date-fact">24 August <span>Independence declared</span></div><div class="population-fact"><b data-population></b><span>people in 1991 · WDI estimate</span></div><p>An industrial and agricultural economy, built into Soviet supply chains.</p><p>Independence meant building market institutions while those connections were breaking apart.</p></div><div class="intro-map chart" data-chart="intro-map"></div>`,
    takeaway:
      "Our question: how much of an economic downturn is caused by a crisis?",
    sources: ["independence", "wdi", "transition", "gisco"],
    notes:
      "Keep this introduction under a minute. Parliament declared independence on 24 August 1991; the 1 December referendum confirmed it. Population is the saved World Bank estimate, not a referendum electorate. Ukraine inherited heavy industry, agriculture, and inter-republic supply chains. The map uses modern GISCO boundaries, includes Crimea in Ukraine, and is not a reconstruction of 1991 administrative boundaries. GISCO is for noncommercial use with the displayed credit.",
  },
  {
    id: "output",
    chapter: "Ukraine in context",
    title: "An economy repeatedly interrupted.",
    kind: "full-chart",
    kicker: "Real GDP · 1991 = 100 · annual data through 2025",
    body: `<div class="chart large" data-chart="overview"></div><div class="under-chart"><p><b>The 1990s:</b> a deep transition recession.</p><p><b>The 2000s:</b> recovery, followed by repeated shocks.</p></div>`,
    takeaway: "A downturn is visible. Its causal effect is not.",
    sources: ["wdi", "transition"],
    notes:
      "This is aggregate real GDP, not GDP per person. Values are indexed from the saved constant-2015-USD WDI series. The chart is descriptive. Do not treat an event marker as evidence that the whole subsequent change was caused by that event. The 2008 financial crisis hit annual GDP especially in 2009. Population and territorial coverage complicate long-run comparisons; keep that caution visible rather than claiming output on an unchanged geographic footprint.",
  },
  {
    id: "structure",
    chapter: "Ukraine in context",
    title: "The economic mix changed, too.",
    kind: "full-chart",
    kicker: "Value added as a share of GDP · 1991 and 2023",
    body: `<div class="chart large" data-chart="structure"></div><div class="under-chart"><p>Industry's share became smaller.</p><p>Services became a larger part of measured GDP.</p></div>`,
    takeaway:
      "This is structural change, not a causal decomposition of growth.",
    sources: ["wdi"],
    notes:
      "Each sector is shown as a separate share, not a stacked bar forced to sum to 100%. GDP includes taxes less subsidies on products, so the three value-added shares need not sum to 100. Industry includes manufacturing. These are domestic economic sectors, not the product categories in our trade atlas. An increase in a share does not itself show an increase in the level of real sector output.",
  },
  {
    id: "gfc",
    chapter: "Three downturns",
    title: "2008 crisis. 2009 output collapse.",
    kind: "split",
    kicker: "Global financial crisis",
    body: `<div class="chart" data-chart="gfc"></div><div class="explanation"><div class="big-stat negative" data-growth="2009"></div><p class="stat-caption">real GDP growth in 2009</p><ul><li>World demand and prices for steel fell.</li><li>Foreign financing dried up.</li><li>Bank stress and depreciation amplified the shock.</li></ul></div>`,
    takeaway: "A global shock met domestic financial vulnerabilities.",
    sources: ["wdi", "gfc"],
    notes:
      "The global crisis arrived in late 2008. Annual real GDP still grew in 2008; the large annual contraction is 2009. Use the saved WDI vintage for the exact displayed growth figure. The IMF's contemporaneous account describes falling steel demand, reversal of capital flows, pressure on banks, and the exchange rate. Historical releases may show slightly different growth estimates because of revisions. These mechanisms are a historical explanation, not separately identified causal contributions.",
  },
  {
    id: "2014",
    chapter: "Three downturns",
    title: "2014–2015: war and financial crisis.",
    kind: "split",
    kicker: "Multiple shocks arrived together",
    body: `<div class="chart" data-chart="conflict"></div><div class="explanation"><div class="two-stats"><div><b data-growth="2014"></b><span>2014</span></div><div><b data-growth="2015"></b><span>2015</span></div></div><ul><li>Russia annexed Crimea; fighting began in Donbas.</li><li>Production, trade, and supply chains were disrupted.</li><li>Currency and banking crises compounded the recession.</li></ul><p class="warning">Statistical coverage also changed.</p></div>`,
    takeaway: "A before/after difference bundles several changes together.",
    sources: ["wdi", "conflict2014"],
    notes:
      "Separate the chronology from causal identification. The 2013 political crisis preceded Russia's annexation of Crimea and fighting in Donbas in 2014. The World Bank's 2017 Country Partnership Framework describes conflict, commodity-price changes, currency depreciation and banking failures. Official territorial coverage changes mean that not every measured loss is necessarily a reduction of production within a fixed territory. This warning becomes central when we get to the paper.",
  },
  {
    id: "2022",
    chapter: "Three downturns",
    title: "2022 collapsed. 2023 only partly recovered.",
    kind: "split",
    kicker: "Russia's full-scale invasion",
    body: `<div class="chart" data-chart="invasion"></div><div class="explanation"><div class="two-stats"><div><b class="negative" data-growth="2022"></b><span>2022</span></div><div><b class="positive" data-growth="2023"></b><span>2023</span></div></div><ul><li>Destruction, displacement, and blocked logistics.</li><li>Attacks on energy and production infrastructure.</li><li>Adaptation and external support helped activity recover.</li></ul><p class="warning" data-recovery></p></div>`,
    takeaway:
      "Positive growth after a collapse does not restore the previous level.",
    sources: ["wdi", "invasion"],
    notes:
      "Do not describe 2023 as another annual contraction. The saved revised WDI series has a positive 2023 growth rate; earlier World Bank publications contain estimates and forecasts from older vintages. The recovery was partial relative to 2021. The historical source explains the role of more stable electricity, harvests, public spending, donor support and rerouted exports, but does not identify a separate causal contribution for each. The later synthetic-control paper does NOT estimate the 2022 invasion effect.",
  },
  {
    id: "question",
    chapter: "The missing comparison",
    title: "What would output have been without the crisis?",
    kind: "full-chart",
    kicker:
      "Now focus on the crisis beginning in 2013. We need an unobserved path.",
    body: `<div class="chart large" data-chart="question"></div><div class="under-chart"><p>We observe Ukraine with the crisis.</p><p>We do not observe the same Ukraine without it.</p></div>`,
    takeaway:
      "The causal effect is a comparison between two histories, not two dates.",
    sources: ["wdi"],
    notes:
      "Ask students to imagine the missing line before discussing an estimator. The pale alternative paths are explicitly illustrative, not forecasts or estimated potential outcomes. The observed curve uses aggregate GDP indexed to 2012, continuing the descriptive series. We will later switch to the paper's different outcome, real GDP per person at PPP, and label that change.",
  },
  {
    id: "interpolation",
    chapter: "The missing comparison",
    title: "Why not just draw a line through the gap?",
    kind: "split",
    kicker:
      "Interpolation fills missing observations. It cannot supply a different history.",
    body: `<div class="chart" data-chart="interpolation"></div><div class="explanation"><ul><li>The post-crisis endpoint is already affected.</li><li>A pre-crisis trend assumes growth would have continued unchanged.</li><li>Neither uses evidence about shocks Ukraine would still have faced.</li></ul><p class="warning">These dashed lines are illustrations, not estimates.</p></div>`,
    takeaway:
      "A straight line is an assumption about the counterfactual, not a solution.",
    sources: ["wdi"],
    notes:
      "Distinguish interpolation from extrapolation. Joining pre- and post-crisis actual outcomes is interpolation using an already-treated endpoint. Extending the earlier slope is extrapolation and assumes that slope would have continued. Neither identifies the no-crisis outcome. The chart intentionally shows both temptations. Do not say that a more complex method eliminates assumptions; it replaces a simple unsupported trajectory with a comparison whose assumptions can be examined.",
  },
  {
    id: "comparisons",
    chapter: "The missing comparison",
    title: "Other countries help describe the world without this crisis.",
    kind: "split",
    kicker: "But no single country is automatically a good comparison",
    body: `<div class="chart" data-chart="donor-paths"></div><div class="explanation"><p>Look for countries that reproduce Ukraine's earlier economic path.</p><ul><li>Similar levels and earlier movements.</li><li>Exposure to relevant shared shocks.</li><li>No direct treatment or major spillovers.</li></ul><p class="unit-note">We now switch to the paper's GDP-per-person data.</p></div>`,
    takeaway:
      "Comparison quality matters more than the number of lines on a chart.",
    sources: ["paper", "package"],
    notes:
      "This plot uses actual country observations from the authors' frozen 1995–2017 CSV, indexed to 2012 for comparability of movements. It is not a set of fitted placebos. Ukraine is highlighted; other lines are possible comparisons. Indexing can hide level differences, which is why the actual paper matches outcome levels and covariates as well. Shared exposure is useful only if it is not spillover from the treatment itself.",
  },
  {
    id: "idea",
    chapter: "Synthetic control, without equations",
    title: "Build one comparison from pieces of several countries.",
    kind: "method",
    kicker: "Synthetic control is a weighted comparison",
    body: `<div class="method-steps"><article><span>Before the crisis</span><h3>Find a blend that tracks Ukraine.</h3><p>Use earlier output and relevant characteristics to choose the proportions.</p></article><article><span>At the boundary</span><h3>Freeze the proportions.</h3><p>Do not use post-crisis outcomes to choose the blend.</p></article><article><span>After the crisis</span><h3>Compare the paths.</h3><p>Ask whether the divergence is unusual and whether the comparison is credible.</p></article></div><div class="chart method-chart" data-chart="method"></div>`,
    takeaway: "More than a trend line. Still not a randomized experiment.",
    sources: ["paper"],
    notes:
      "No equations are needed. Weights are nonnegative and add to 100%. They represent a statistical comparison, not ownership, trade shares, or a claim that Ukraine is literally made of these countries. Pre-treatment matching and validation are not a guarantee against post-treatment confounding. Only the method diagram is schematic on this slide; it is not an estimator result.",
  },
  {
    id: "paper",
    chapter: "Taking a paper apart",
    title: "A synthetic Ukraine, 1995 to 2017.",
    kind: "paper",
    kicker: "Bluszcz & Valente · Defence and Peace Economics · 2022",
    body: `<div class="paper-design"><div><span class="design-number">18</span><p>countries<br>Ukraine + 17 possible donors</p></div><div><span class="design-number">414</span><p>country-year observations<br>in the public data</p></div><div><span class="design-number">2013</span><p>first treated year<br>in the authors' design</p></div></div><div class="period-strip"><div>Fit on 1995–2012</div><div>Evaluate 2013–2017</div></div><p class="paper-outcome">Outcome: real GDP <b>per person</b>, in 2011 international dollars at PPP.</p><p class="warning">The design covers the broader crisis beginning in 2013, not the isolated effect of fighting in 2014 or the invasion in 2022.</p>`,
    takeaway:
      "First agree on the outcome, dates, and comparison. Then examine the result.",
    sources: ["paper", "package"],
    notes:
      "The original paper uses five averaged predictors plus GDP-per-capita values in 2000 and 2012, fitting on 1995–2012. Explain PPP simply as a common purchasing-power unit rather than market-exchange-rate dollars. The public files have 414 observations, 18 countries, 23 years. Four donors get positive published weights. We have inspected the paper, CSVs and source code, but have not run the optimizer.",
  },
  {
    id: "weights",
    chapter: "Taking a paper apart",
    title: "Four countries carry the published comparison.",
    kind: "weights",
    kicker: "Darker blue means a larger synthetic-control weight",
    body: `<div class="chart" data-chart="weights"></div><div class="weight-list"><div data-weight-list></div><p class="warning"><b>78.5%</b> of the weight is on Moldova and Armenia.</p><p>17 candidates. Four positive weights. Geography makes the concentration visible.</p></div>`,
    takeaway: "The map shows statistical weights, not trade shares.",
    sources: ["paper", "gisco"],
    notes:
      "Weights are the rounded values in published Table 2: Moldova 45.2%, Armenia 33.3%, Bulgaria 15.2%, Slovenia 6.3%. All other candidates have zero weights. A candidate with zero weight is distinct from a country outside the donor pool. Ukraine is yellow, not assigned a donor weight. The fact that Moldova and Armenia are heavily connected to the region is a possible spillover concern, not proof of the direction of bias. Modern boundaries include Crimea in Ukraine. © EuroGeographics for the administrative boundaries; noncommercial use.",
  },
  {
    id: "paths",
    chapter: "Taking a paper apart",
    title: "A close pre-crisis fit. A post-crisis divergence.",
    kind: "full-chart",
    kicker:
      "Reconstruction from the authors' data and rounded published weights",
    body: `<div class="chart large" data-chart="synthetic-paths"></div><div class="under-chart"><p><span class="line-key actual"></span> Observed Ukraine</p><p><span class="line-key synthetic"></span> Published-weight reconstruction</p><p class="status-label">Optimizer not rerun</p></div>`,
    takeaway:
      "The comparison becomes causal only if it remains a valid untreated path.",
    sources: ["paper", "package"],
    notes:
      "This is an arithmetic reconstruction using original country data and the four rounded published weights, not newly fitted synthetic-control estimates. Small differences from the paper may reflect rounded weights and code/version details. Do not claim exact replication or that we selected these weights ourselves. Units are GDP per person in 2011 PPP international dollars. The treatment boundary is 2013, with pre-treatment observations ending in 2012.",
  },
  {
    id: "gap",
    chapter: "Taking a paper apart",
    title: "The paper's headline: a shortfall against the counterfactual.",
    kind: "split",
    kicker: "Published Table 5 · not a new replication result",
    body: `<div class="chart" data-chart="published-gap"></div><div class="explanation"><div class="big-stat negative">15.1%</div><p class="stat-caption">average GDP-per-person shortfall<br>reported for 2013–2017</p><p>Not a 15.1% fall from the previous year.</p><p>Not an estimate of the contribution of lost trade alone.</p></div>`,
    takeaway:
      "The counterfactual can grow while observed output falls or stagnates.",
    sources: ["paper"],
    notes:
      "Read the bars as the percentage by which observed GDP per person is below the authors' synthetic counterfactual in each year. The paper's Table 5 reports 5.23%, 9.18%, 19.63%, 19.80%, and 21.67%, averaging 15.10%. The blue line graph on the previous slide is a rounded-weight reconstruction; these bars transcribe the published table, so they are kept clearly separate. The paper's average dollar gap is 1,438.90 international 2011 dollars per person. These are model-based estimates, not observed accounting losses.",
  },
  {
    id: "sensitivity",
    chapter: "How much should we trust it?",
    title: "What happens when an important donor is removed?",
    kind: "split",
    kicker:
      "Published leave-one-out results · average annual shortfall per person",
    body: `<div class="chart" data-chart="sensitivity"></div><div class="explanation"><p>The paper refits the model after removing each positive-weight donor.</p><p>The shortfall remains, but its size changes.</p><p class="warning">This does not settle regional spillovers, concurrent shocks, or changing statistical coverage.</p><p class="unit-note">Removing both Moldova and Armenia is a further check, not a result shown here.</p></div>`,
    takeaway:
      "Robustness to one choice is not robustness to every identifying assumption.",
    sources: ["paper"],
    notes:
      "This chart redraws the paper's published Table 4, not estimates run here. Original average shortfall 1,438.9; removing Slovenia 1,501.0; Bulgaria 1,666.4; Armenia 1,737.9; Moldova 1,587.4, all in 2011 PPP dollars per person. The paper does not show a joint exclusion of Moldova and Armenia in this table. Do not replace a refit by mechanically renormalizing fixed published weights and call it a leave-one-out replication. The numbers here show larger shortfalls after each exclusion, not a disappearance of the result.",
  },
  {
    id: "placebos",
    chapter: "How much should we trust it?",
    title: "Would the same method find a crisis in the donor countries?",
    kind: "placebos",
    kicker: "Give each donor the same pretend intervention date",
    body: `<div class="chart" data-chart="placebos"></div><div class="explanation"><ol><li>Build a synthetic comparison for each donor.</li><li>Check its fit before 2013.</li><li>Compare the later divergence with Ukraine's.</li></ol><p class="warning">With few comparisons, inference is coarse. Different pre-fit rules and statistics give different rankings.</p></div>`,
    takeaway: "A visually large gap is not enough. Ask how unusual it is.",
    sources: ["paper"],
    notes:
      "The country dots illustrate the placebo procedure; they are not a fresh set of fitted placebo paths or observed test statistics. The paper reports several different summaries: ATT ranking after six pre-fit exclusions gives 1/12, about 8.3%; the post/pre squared-error ranking gives 2/18, about 11.1%; its joint ATT–MPE comparison reports 1/18 while calling it significant at 5%. One over eighteen is about 5.6%, not below 5%. Do not turn these distinct criteria into one interchangeable p-value or present placebo ranks as randomized assignment probabilities without assumptions. We have not rerun these placebo fits.",
  },
  {
    id: "replication",
    chapter: "From illustration to replication",
    title: "A replication should expose the choices.",
    kind: "replication",
    kicker:
      "What this prototype has done, and what the model rerun still needs",
    body: `<div class="replication-columns"><div><h3>Available in this deck</h3><ul class="checks"><li>Original paper, R code, and CSVs inspected.</li><li>Published donor weights mapped.</li><li>Rounded-weight output path reconstructed.</li><li>Published gaps and sensitivity results redrawn.</li></ul></div><div><h3>Next: an isolated local R project</h3><ul class="pending"><li>Run a short, audited national model.</li><li>Record versions, weights, and pre-fit error.</li><li>Rerun placebos and donor exclusions.</li><li>Test donor-pool and treatment-date choices.</li></ul></div></div><p class="warning">Reconstruction is not re-estimation. The estimator has not been run for this prototype.</p>`,
    takeaway:
      "Ask which assumptions make the comparison credible, not just whether the lines look good.",
    sources: ["paper", "package"],
    notes:
      "The original R script references two absent columns in unused preprocessing lines, and the implemented trade-dependence measure is GDP-based rather than the paper's verbal trade-share description. Those issues need explicit documentation in a cleaned teaching copy. A minimal rerun script is prepared but not executed, pending the requested execution-environment choice. Do not claim numerical replication before comparing fitted weights, source units, outcome paths, and average gaps. The national data are frozen historical observations; swapping in today's WDI data is an extension, not an exact reproduction.",
  },
  {
    id: "sources",
    chapter: "Sources and discussion",
    title: "The economic loss depends on the missing path.",
    kind: "sources",
    kicker: "Discussion: what would make you trust that path?",
    body: `<div class="closing-questions"><p>Would you trust the estimate if one donor carried most of the weight?</p><p>What if the crisis also affected the donor countries?</p><p>What if the border of the measured economy changed?</p></div><div class="source-directory" data-source-directory></div>`,
    takeaway:
      "Historical charts describe the downturn. Causal inference needs a defensible comparison.",
    sources: ["wdi", "paper", "package", "gisco"],
    notes:
      "End with the distinction between describing a downturn and estimating a crisis effect. The historical GDP chart and the paper's GDP-per-person counterfactual use different outcomes and vintages, deliberately labeled throughout. Sources are clickable in the browser and on printed PDFs when supported. Data snapshot 15 November 2026. All code, source notes, original replication files, and limitations are saved in the project. The GISCO boundaries have noncommercial-use conditions and require the displayed EuroGeographics credit.",
  },
];
