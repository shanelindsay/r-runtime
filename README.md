# r-runtime

R with common packages, ready to download into an ephemeral Linux cloud session.
One compressed archive; no package compilation during setup. Binaries live in
GitHub Releases, keeping this repository small.

## Set up

This repository and its releases are private. The session needs authenticated
GitHub CLI (`gh`) access to `shanelindsay/r-runtime`, plus Bash, tar and sha256sum.
Clone this small repository, then run:

```bash
bash setup.sh
export PATH="$HOME/.local/share/r-runtime/v0.1.0/bin:$PATH"
Rscript -e 'library(ggplot2); print(packageVersion("ggplot2"))'
```

Use those two setup lines in the cloud environment's startup script after cloning.
An installation is reusable within that session; run setup once. R and Rscript
work from any project directory. Use an absolute path to setup.sh if necessary.
For another installation directory, pass it as the first argument. To select a
release, set `R_RUNTIME_VERSION` (default: `v0.1.0`). Existing destinations are
preserved; use their commands directly or choose a new destination.

## Contents and requirements

The initial bundle contains R 4.6.1 and the minimal package set inherited from
Interactions: ggplot2, ragg, svglite, dplyr, tidyr, purrr, tibble, readr, stringr,
forcats, here, yaml, lubridate, janitor, testthat, knitr, rmarkdown, broom and
patchwork, plus dependencies. The release's PACKAGE-MANIFEST.tsv records exact
versions; BUILD-INFO.txt records its original build provenance.

Linux x86-64 with glibc is required. The existing build expects
`/opt/R/4.6.1-glibc`: its launcher creates a symlink using root permissions or
passwordless sudo. Containers which forbid this are currently unsupported.
The initial release retains this known requirement to keep the first version
simple. Quarto/Pandoc executables and specialised modelling packages are separate.
An R package for rendering documents does not supply those executables.

The archive checksum is checked before extraction. Package versions remain fixed
within a release; research projects should pin the release they use.

## Maintaining a release

Start from an extracted portable bundle containing its runtime, package library,
package lists and validation scripts. Build and test before publishing:

```bash
bash scripts/build-release.sh /path/to/extracted-bundle
gh release create v0.1.0 dist/r-runtime-linux-x86_64.tar.gz dist/SHA256SUMS \
  --repo shanelindsay/r-runtime --title 'Portable R v0.1.0' --notes-file release-notes.md
```

The script validates package loading, PNG and SVG plotting before archiving.
Validate installation in a clean Ubuntu container as well. For future package
updates, use the bundle's dev/install-portable-r-packages.R and build a new
release. Do not overwrite an existing release archive.

R and bundled packages retain their upstream licences, included in the archive.
The initial runtime is copied from shanelindsay/interactions; its build record
and installed-package manifest are preserved.
