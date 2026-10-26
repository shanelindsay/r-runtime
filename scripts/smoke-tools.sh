#!/usr/bin/env bash
# Verify every tool in a fresh R-runtime installation, including an APA 7 PDF.
set -euo pipefail

[[ $# -eq 1 ]] || { echo "Usage: scripts/smoke-tools.sh <r-runtime-directory>" >&2; exit 2; }
root="$(cd -- "$1" && pwd)"
bin="$root/bin"

[[ "$("$bin/quarto" --version)" == "1.10.19" ]]
"$bin/pandoc" --version | sed -n '1p' | grep '^pandoc '
"$bin/typst" --version
[[ "$("$bin/micromamba" --version)" == "2.9.0" ]]

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
cat > "$scratch/apa-smoke.qmd" <<'QMD'
---
title: "APA 7 Research Runtime Smoke Test"
shorttitle: "Runtime Smoke Test"
author:
  - name: A. Researcher
    corresponding: true
    email: researcher@example.org
    affiliations:
      - name: Example University
abstract: "A reproducible typesetting check."
format:
  apaquarto-typst: default
---

This sample document verifies APAQUARTO and bundled Typst PDF generation.
QMD

# In a real R runtime, also check Quarto's knitr integration with the
# portable R launchers. A standalone tool-layer test can omit R itself.
if [[ -x "$bin/R" && -x "$bin/Rscript" ]]; then
  cat >> "$scratch/apa-smoke.qmd" <<'QMD'

```{r}
#| echo: false
stopifnot(sum(1:3) == 6L)
```
QMD
  export PATH="$bin:$PATH"
  export QUARTO_R="$bin/R"
fi

"$bin/apaquarto-add" "$scratch"
[[ -f "$scratch/_extensions/wjschne/apaquarto/_extension.yml" ]]
[[ -f "$scratch/_extensions/wjschne/apanote/_extension.yml" ]]
grep -Eq '^version: 7\.0\.1[[:space:]]*$' "$scratch/_extensions/wjschne/apaquarto/_extension.yml"

(cd "$scratch" &&
  "$bin/quarto" render apa-smoke.qmd --to apaquarto-typst --quiet &&
  "$bin/quarto" render apa-smoke.qmd --to apaquarto-docx --quiet &&
  "$bin/quarto" render apa-smoke.qmd --to apaquarto-html --quiet)
[[ -s "$scratch/apa-smoke.pdf" ]]
[[ -s "$scratch/apa-smoke.docx" ]]
[[ -s "$scratch/apa-smoke.html" ]]
# Repeated setup should not overwrite this project-local extension.
"$bin/apaquarto-add" "$scratch"
printf 'Passed: Quarto, Pandoc, Typst, micromamba, APAQUARTO 7.0.1, PDF, Word and HTML.\n'
