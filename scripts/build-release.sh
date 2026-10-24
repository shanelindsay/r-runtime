#!/usr/bin/env bash
# Repackage an extracted, validated portable-R bundle. Keep binaries out of Git.
set -euo pipefail
[[ $# == 1 ]] || { echo "Usage: $0 <extracted-bundle>" >&2; exit 2; }
source_dir="$(cd "$1" && pwd)"
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ -d "$source_dir/dev/portable-r-library" ]] || { echo 'Package library missing' >&2; exit 1; }
(cd "$source_dir" && PORTABLE_R_ISOLATED=1 bash dev/use-portable-r.sh Rscript dev/validate-portable-r.R minimal)
mkdir -p "$repo/dist"
tar -C "$source_dir" -czf "$repo/dist/r-runtime-linux-x86_64.tar.gz" dev env BUILD-INFO.txt PACKAGE-MANIFEST.tsv
(cd "$repo/dist" && sha256sum r-runtime-linux-x86_64.tar.gz > SHA256SUMS)
ls -lh "$repo/dist/r-runtime-linux-x86_64.tar.gz"
