# National replication results

The teaching adaptation was run with the existing local R installation and packages installed in `.R-library`. Command from the project root:

```sh
R_LIBS_USER="$PWD/.R-library" Rscript research/hybrid-wars/teaching-R/replicate.R --placebos
```

The run completed using R 4.6.1 and Synth 1.1-10; see `output/session-info.txt` and `output/provenance.txt`. The original author code was not run unchanged. Two unused references to absent columns were omitted and the original code's GDP-based trade predictor retained. Synth reports missing predictor observations and averages available values.

The re-estimated mean shortfall is 15.10313%, and 1,438.902 international 2011 dollars per person, agreeing with the paper's rounded 15.10% and 1,438.90. Annual percentages round to 5.23, 9.18, 19.63, 19.80 and 21.67. The major weights round to Moldova 0.452, Armenia 0.333, Bulgaria 0.152 and Slovenia 0.063, as published; smaller nonzero weights exist.

Leave-one-out refits produce average dollar shortfalls of Armenia 1,754.99, Bulgaria 1,666.71, Slovenia 1,501.04, Moldova 1,587.36. The deck transcribes paper values of 1,737.9, 1,666.4, 1,501.0 and 1,587.4 respectively. The Armenia discrepancy is not explained; the Bulgaria result also differs slightly. Do not call all robustness checks replicated. The script's original donor IDs for the last two exclusions were wrong and have been corrected to Slovenia 14 and Moldova 17 before this run.

Placebo paths and summaries are saved, but paper inference conventions have not been verified. Regional results, other specifications and full original-script execution have not been checked. Therefore this is a successful numerical check of the national baseline, not a full replication of the paper or validation of its causal assumptions. The deck has not been updated and still describes the previous status.
