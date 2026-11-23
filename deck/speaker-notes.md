# Speaker notes

Published results and rounded-weight reconstruction are not a fresh estimator rerun.

## 1. Ukraine, 1991.

An independent country. An inherited economic system.

Keep this introduction under a minute. Parliament declared independence on 24 August 1991; the 1 December referendum confirmed it. Population is the saved World Bank estimate, not a referendum electorate. Ukraine inherited heavy industry, agriculture, and inter-republic supply chains. The map uses modern GISCO boundaries, includes Crimea in Ukraine, and is not a reconstruction of 1991 administrative boundaries. GISCO is for noncommercial use with the displayed credit.

Source keys: independence, wdi, transition, gisco.

## 2. An economy repeatedly interrupted.

Real GDP · 1991 = 100 · annual data through 2025

This is aggregate real GDP, not GDP per person. Values are indexed from the saved constant-2015-USD WDI series. The chart is descriptive. Do not treat an event marker as evidence that the whole subsequent change was caused by that event. The 2008 financial crisis hit annual GDP especially in 2009. Population and territorial coverage complicate long-run comparisons; keep that caution visible rather than claiming output on an unchanged geographic footprint.

Source keys: wdi, transition.

## 3. The economic mix changed, too.

Value added as a share of GDP · 1991 and 2023

Each sector is shown as a separate share, not a stacked bar forced to sum to 100%. GDP includes taxes less subsidies on products, so the three value-added shares need not sum to 100. Industry includes manufacturing. These are domestic economic sectors, not the product categories in our trade atlas. An increase in a share does not itself show an increase in the level of real sector output.

Source keys: wdi.

## 4. 2008 crisis. 2009 output collapse.

Global financial crisis

The global crisis arrived in late 2008. Annual real GDP still grew in 2008; the large annual contraction is 2009. Use the saved WDI vintage for the exact displayed growth figure. The IMF's contemporaneous account describes falling steel demand, reversal of capital flows, pressure on banks, and the exchange rate. Historical releases may show slightly different growth estimates because of revisions. These mechanisms are a historical explanation, not separately identified causal contributions.

Source keys: wdi, gfc.

## 5. 2014–2015: war and financial crisis.

Multiple shocks arrived together

Separate the chronology from causal identification. The 2013 political crisis preceded Russia's annexation of Crimea and fighting in Donbas in 2014. The World Bank's 2017 Country Partnership Framework describes conflict, commodity-price changes, currency depreciation and banking failures. Official territorial coverage changes mean that not every measured loss is necessarily a reduction of production within a fixed territory. This warning becomes central when we get to the paper.

Source keys: wdi, conflict2014.

## 6. 2022 collapsed. 2023 only partly recovered.

Russia's full-scale invasion

Do not describe 2023 as another annual contraction. The saved revised WDI series has a positive 2023 growth rate; earlier World Bank publications contain estimates and forecasts from older vintages. The recovery was partial relative to 2021. The historical source explains the role of more stable electricity, harvests, public spending, donor support and rerouted exports, but does not identify a separate causal contribution for each. The later synthetic-control paper does NOT estimate the 2022 invasion effect.

Source keys: wdi, invasion.

## 7. What would output have been without the crisis?

Now focus on the crisis beginning in 2013. We need an unobserved path.

Ask students to imagine the missing line before discussing an estimator. The pale alternative paths are explicitly illustrative, not forecasts or estimated potential outcomes. The observed curve uses aggregate GDP indexed to 2012, continuing the descriptive series. We will later switch to the paper's different outcome, real GDP per person at PPP, and label that change.

Source keys: wdi.

## 8. Why not just draw a line through the gap?

Interpolation fills missing observations. It cannot supply a different history.

Distinguish interpolation from extrapolation. Joining pre- and post-crisis actual outcomes is interpolation using an already-treated endpoint. Extending the earlier slope is extrapolation and assumes that slope would have continued. Neither identifies the no-crisis outcome. The chart intentionally shows both temptations. Do not say that a more complex method eliminates assumptions; it replaces a simple unsupported trajectory with a comparison whose assumptions can be examined.

Source keys: wdi.

## 9. Other countries help describe the world without this crisis.

But no single country is automatically a good comparison

This plot uses actual country observations from the authors' frozen 1995–2017 CSV, indexed to 2012 for comparability of movements. It is not a set of fitted placebos. Ukraine is highlighted; other lines are possible comparisons. Indexing can hide level differences, which is why the actual paper matches outcome levels and covariates as well. Shared exposure is useful only if it is not spillover from the treatment itself.

Source keys: paper, package.

## 10. Build one comparison from pieces of several countries.

Synthetic control is a weighted comparison

No equations are needed. Weights are nonnegative and add to 100%. They represent a statistical comparison, not ownership, trade shares, or a claim that Ukraine is literally made of these countries. Pre-treatment matching and validation are not a guarantee against post-treatment confounding. Only the method diagram is schematic on this slide; it is not an estimator result.

Source keys: paper.

## 11. A synthetic Ukraine, 1995 to 2017.

Bluszcz & Valente · Defence and Peace Economics · 2022

The original paper uses five averaged predictors plus GDP-per-capita values in 2000 and 2012, fitting on 1995–2012. Explain PPP simply as a common purchasing-power unit rather than market-exchange-rate dollars. The public files have 414 observations, 18 countries, 23 years. Four donors get positive published weights. We have inspected the paper, CSVs and source code, but have not run the optimizer.

Source keys: paper, package.

## 12. Four countries carry the published comparison.

Darker blue means a larger synthetic-control weight

Weights are the rounded values in published Table 2: Moldova 45.2%, Armenia 33.3%, Bulgaria 15.2%, Slovenia 6.3%. All other candidates have zero weights. A candidate with zero weight is distinct from a country outside the donor pool. Ukraine is yellow, not assigned a donor weight. The fact that Moldova and Armenia are heavily connected to the region is a possible spillover concern, not proof of the direction of bias. Modern boundaries include Crimea in Ukraine. © EuroGeographics for the administrative boundaries; noncommercial use.

Source keys: paper, gisco.

## 13. A close pre-crisis fit. A post-crisis divergence.

Reconstruction from the authors' data and rounded published weights

This is an arithmetic reconstruction using original country data and the four rounded published weights, not newly fitted synthetic-control estimates. Small differences from the paper may reflect rounded weights and code/version details. Do not claim exact replication or that we selected these weights ourselves. Units are GDP per person in 2011 PPP international dollars. The treatment boundary is 2013, with pre-treatment observations ending in 2012.

Source keys: paper, package.

## 14. The paper's headline: a shortfall against the counterfactual.

Published Table 5 · not a new replication result

Read the bars as the percentage by which observed GDP per person is below the authors' synthetic counterfactual in each year. The paper's Table 5 reports 5.23%, 9.18%, 19.63%, 19.80%, and 21.67%, averaging 15.10%. The blue line graph on the previous slide is a rounded-weight reconstruction; these bars transcribe the published table, so they are kept clearly separate. The paper's average dollar gap is 1,438.90 international 2011 dollars per person. These are model-based estimates, not observed accounting losses.

Source keys: paper.

## 15. What happens when an important donor is removed?

Published leave-one-out results · average annual shortfall per person

This chart redraws the paper's published Table 4, not estimates run here. Original average shortfall 1,438.9; removing Slovenia 1,501.0; Bulgaria 1,666.4; Armenia 1,737.9; Moldova 1,587.4, all in 2011 PPP dollars per person. The paper does not show a joint exclusion of Moldova and Armenia in this table. Do not replace a refit by mechanically renormalizing fixed published weights and call it a leave-one-out replication. The numbers here show larger shortfalls after each exclusion, not a disappearance of the result.

Source keys: paper.

## 16. Would the same method find a crisis in the donor countries?

Give each donor the same pretend intervention date

The country dots illustrate the placebo procedure; they are not a fresh set of fitted placebo paths or observed test statistics. The paper reports several different summaries: ATT ranking after six pre-fit exclusions gives 1/12, about 8.3%; the post/pre squared-error ranking gives 2/18, about 11.1%; its joint ATT–MPE comparison reports 1/18 while calling it significant at 5%. One over eighteen is about 5.6%, not below 5%. Do not turn these distinct criteria into one interchangeable p-value or present placebo ranks as randomized assignment probabilities without assumptions. We have not rerun these placebo fits.

Source keys: paper.

## 17. A replication should expose the choices.

What this prototype has done, and what the model rerun still needs

The original R script references two absent columns in unused preprocessing lines, and the implemented trade-dependence measure is GDP-based rather than the paper's verbal trade-share description. Those issues need explicit documentation in a cleaned teaching copy. A minimal rerun script is prepared but not executed, pending the requested execution-environment choice. Do not claim numerical replication before comparing fitted weights, source units, outcome paths, and average gaps. The national data are frozen historical observations; swapping in today's WDI data is an extension, not an exact reproduction.

Source keys: paper, package.

## 18. The economic loss depends on the missing path.

Discussion: what would make you trust that path?

End with the distinction between describing a downturn and estimating a crisis effect. The historical GDP chart and the paper's GDP-per-person counterfactual use different outcomes and vintages, deliberately labeled throughout. Sources are clickable in the browser and on printed PDFs when supported. Data snapshot 15 November 2026. All code, source notes, original replication files, and limitations are saved in the project. The GISCO boundaries have noncommercial-use conditions and require the displayed EuroGeographics credit.

Source keys: wdi, paper, package, gisco.
