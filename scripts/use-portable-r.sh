#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
R_PREFIX="$REPO_ROOT/dev/linux/opt/R/4.6.1-glibc"
PORTABLE_LIBRARY="$REPO_ROOT/dev/portable-r-library"
export LD_LIBRARY_PATH="$REPO_ROOT/dev/system-libs${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export FONTCONFIG_FILE="$REPO_ROOT/dev/fontconfig/fonts.conf"
export TZ="${TZ:-UTC}"

if [[ ! -x "$R_PREFIX/bin/R" || ! -x "$R_PREFIX/bin/Rscript" ]]; then
  echo "Portable R was not found under $R_PREFIX" >&2
  exit 1
fi

PROGRAM="${1:-R}"
case "$PROGRAM" in
  R|Rscript)
    shift
    ;;
  *)
    echo "Usage: $0 R|Rscript [arguments...]" >&2
    exit 2
    ;;
esac

# This R build has /opt/R/4.6.1-glibc as its compiled-in prefix.
# Create the expected path when this container permits it.
if [[ ! -e /opt/R/4.6.1-glibc ]]; then
  mkdir -p /opt/R 2>/dev/null || true
  ln -s "$R_PREFIX" /opt/R/4.6.1-glibc 2>/dev/null || true
fi

# GitHub-hosted runners usually require passwordless sudo for /opt, whereas
# ChatGPT containers commonly run as root. Support either without prompting.
if [[ ! -e /opt/R/4.6.1-glibc ]] && command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
  sudo mkdir -p /opt/R
  sudo ln -s "$R_PREFIX" /opt/R/4.6.1-glibc
fi

if [[ ! -e /opt/R/4.6.1-glibc ]]; then
  echo "Portable R needs /opt/R/4.6.1-glibc, or a symlink to $R_PREFIX" >&2
  exit 1
fi

# Package-bearing portable bundles place their non-base packages here. During
# build and validation, isolate the bundle from any host R libraries so missing
# dependencies cannot be masked by the runner. Normal use keeps an explicitly
# supplied user library after the validated portable library.
if [[ -d "$PORTABLE_LIBRARY" ]]; then
  if [[ "${PORTABLE_R_ISOLATED:-0}" == "1" ]]; then
    export R_LIBS_USER="$PORTABLE_LIBRARY"
    unset R_LIBS_SITE
  elif [[ -n "${R_LIBS_USER:-}" ]]; then
    export R_LIBS_USER="$PORTABLE_LIBRARY:$R_LIBS_USER"
  else
    export R_LIBS_USER="$PORTABLE_LIBRARY"
  fi
fi

exec "$R_PREFIX/bin/$PROGRAM" "$@"
