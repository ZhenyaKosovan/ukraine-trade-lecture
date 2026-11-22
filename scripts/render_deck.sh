#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export R_LIBS_USER="$ROOT/.R-library${R_LIBS_USER:+:$R_LIBS_USER}"
Rscript -e 'needed <- c("highcharter", "jsonlite", "knitr", "rmarkdown"); missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]; if (length(missing)) stop("Install R packages first: ", paste(missing, collapse = ", "))'
# Build the Closeread document before Quarto embeds it in the Reveal deck.
quarto render deck/history.qmd
quarto render deck/lecture.qmd "$@"
