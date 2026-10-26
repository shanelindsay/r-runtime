# r-runtime

Portable R plus a pinned scientific publishing toolchain for ephemeral Linux
cloud sessions. R and its packages come from one prebuilt release archive, with
no R package compilation during setup. Quarto (including Pandoc and Typst) and
micromamba are installed alongside R from verified upstream binaries. APAQUARTO
is available through a project-local installer. Binaries stay outside Git.

## Set up

The repository and release downloads are public. Setup needs Bash, curl, tar and
sha256sum. In a fresh local or cloud Ubuntu 24.04 x86-64 session, run:

```bash
curl -fsSL https://raw.githubusercontent.com/shanelindsay/r-runtime/main/setup.sh -o /tmp/setup-r-runtime.sh
bash /tmp/setup-r-runtime.sh
export PATH="$HOME/.local/share/r-runtime/v0.1.0/bin:$PATH"
Rscript -e 'library(ggplot2); print(packageVersion("ggplot2"))'
quarto --version
pandoc --version
typst --version
micromamba --version
```

Use the download, setup and PATH lines in the cloud environment's startup
script. Installation is public and needs no GitHub account, token, Git clone or
GitHub CLI. In a cloned checkout, run `bash setup.sh` directly; when
`setup.sh` is downloaded alone it fetches the companion tool installer from
this public repository. R, Rscript and the tool binaries work from any
project directory.

The default R release remains `v0.1.0`; select a different published release
with `R_RUNTIME_VERSION` or pass an installation directory as the first
argument. The setup preserves existing destinations instead of overwriting
them. To **add the tools to an existing R installation** without downloading R
again, use:

```bash
bash scripts/install-tools.sh "$HOME/.local/share/r-runtime/v0.1.0"
```

The standalone tool installer is safe to rerun for the pinned versions.

## Size and startup time

The immutable R v0.1.0 archive is 211,832,710 bytes (212 MB / 202 MiB).
A GitHub-hosted Ubuntu 24.04 runner downloaded, verified, extracted and loaded
**R alone** in **8.1 seconds** on 24 October 2026; extracting the R archive
took 2.4 seconds locally. Those measurements predate the additional tools.
Quarto adds a 147 MB compressed download and micromamba adds an 18 MB binary.
Total cold-start time is therefore longer and depends on download speeds.
All downloads are checksum-verified, and the installed toolchain is reused
within the session. A complete clean installation on Legion on 26 October 2026
occupied approximately **960 MB** and took about 40 seconds. Allow at least
1.5 GB of free space for the installation and temporary download/extraction
files; cloud performance and filesystem layouts vary.

## Contents and requirements

The initial bundle contains R 4.6.1 and the minimal package set inherited from
Interactions: ggplot2, ragg, svglite, dplyr, tidyr, purrr, tibble, readr, stringr,
forcats, here, yaml, lubridate, janitor, testthat, knitr, rmarkdown, broom and
patchwork, plus dependencies. The release's PACKAGE-MANIFEST.tsv records exact
versions; BUILD-INFO.txt records its original build provenance.

Ubuntu 24.04 x86-64 is the tested platform. The archive includes supporting
shared libraries and DejaVu fonts; no apt installation is required to run it.
Other Linux glibc systems have not been validated. The existing build expects
`/opt/R/4.6.1-glibc`: its launcher creates a symlink using root permissions or
passwordless sudo. Containers which forbid this are currently unsupported.
The original R release retains this known requirement. The setup script
installs the additional command-line tools **outside** the immutable R release
archive:

| Tool | Pinned version | Notes |
|---|---|---|
| Quarto | 1.10.19 | Includes Pandoc, Typst, and document rendering |
| Pandoc | Bundled with Quarto | Available directly as `pandoc` via Quarto |
| Typst | Bundled with Quarto | Available directly as `typst` via Quarto |
| micromamba | 2.9.0-0 | Standalone binary; create Python/other environments when needed |
| APAQUARTO | 7.0.1 | Installed per project with `apaquarto-add` |

All binary versions and SHA-256 digests are pinned in
`scripts/install-tools.sh`. APAQUARTO is pinned to its release tag.
Specialised R modelling packages remain separate.

The archive checksum is checked before extraction. Package versions remain fixed
within a release; research projects should pin the release they use.

## APA 7 manuscripts

Quarto extensions are **project-local**. After installing the runtime and
adding its bin directory to `PATH`, run from any paper project:

```bash
apaquarto-add /path/to/manuscript-project
```

This installs **APAQUARTO 7.0.1** (and its companion figure/table note filters)
under that project's `_extensions/` directory. It is safe to rerun and
will not replace an extension at another version.

In the document YAML, choose the appropriate APA format:

```yaml
format:
  apaquarto-typst: default  # APA 7 PDF via Typst, no TeX required
  apaquarto-docx: default   # Word manuscript
  apaquarto-html: default   # Browser preview
```

Use `quarto render manuscript.qmd --to apaquarto-typst` for PDF or
`--to apaquarto-docx` for Word. The alternative LaTeX-based
`apaquarto-pdf` format needs a TeX distribution. Install **TinyTeX**
separately with `quarto install tinytex` only if that format is required.
The default installation stays smaller by relying on bundled Typst.

For Python or additional modelling tools, the micromamba binary creates
environments on demand. For example, after setting
`MAMBA_ROOT_PREFIX="$HOME/.local/share/micromamba"`, run
`micromamba create -n analysis -c conda-forge python=3.12`.
This does not modify the portable R installation.

Run `bash scripts/smoke-tools.sh <runtime-directory>` to verify the full
toolchain with an actual APAQUARTO Typst PDF render.

## Maintaining a release

Start from an extracted portable bundle containing its runtime, package library,
package lists and validation scripts. Build and test before publishing:

```bash
# On an Ubuntu 24.04 builder, install the supporting libraries once:
sudo apt-get update
sudo apt-get install -y libfontconfig1 libfreetype6 libfribidi0 libharfbuzz0b \
  libicu74 libjpeg-turbo8 libpng16-16t64 libtiff6 libuv1t64 libwebp7 \
  libwebpmux3 fonts-dejavu-core
bash scripts/bundle-system-libs.sh /path/to/extracted-bundle
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
