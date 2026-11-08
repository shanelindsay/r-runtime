#!/usr/bin/env bash
# Configure an extracted, checksum-verified bundle without /opt writes or sudo.
set -euo pipefail
[[ $# == 1 ]] || { echo "Usage: $0 <runtime-directory>" >&2; exit 2; }
root="$(cd -- "$1" && pwd)"
prefix="$root/dev/linux/opt/R/4.6.1-glibc"
[[ -x "$prefix/bin/R" && -x "$prefix/bin/Rscript" ]] || {
  echo 'Expected the portable R 4.6.1 bundle.' >&2; exit 1;
}
mkdir -p "$root/dev/r-entry/bin" "$root/bin"
cat > "$root/dev/r-entry/bin/R" <<'ENTRY'
#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
exec bash "$root/dev/use-portable-r.sh" R "$@"
ENTRY
chmod +x "$root/dev/r-entry/bin/R"
for program in R Rscript; do
  cat > "$root/bin/$program" <<EOF
#!/usr/bin/env bash
root="\$(cd -- "\$(dirname -- "\${BASH_SOURCE[0]}")/.." && pwd)"
exec bash "\$root/dev/use-portable-r.sh" $program "\$@"
EOF
  chmod +x "$root/bin/$program"
done
# base/R/Rprofile runs even with --vanilla, before the default packages.
# Correct the build-time Sys.which path without replacing the caller's profile.
profile="$prefix/lib/R/library/base/R/Rprofile"
marker='# r-runtime: relocate base tools path'
if ! grep -qFx "$marker" "$profile"; then
  cat >> "$profile" <<'RPROFILE'

# r-runtime: relocate base tools path
local({
    f <- get('Sys.which', envir = baseenv())
    b <- body(f)
    # Fail explicitly if an upstream release changes the expected function.
    stopifnot(identical(b[[4]], quote(which <- "/opt/R/4.6.1-glibc/lib/R/tools/which")))
    b[[4]] <- substitute(which <- p, list(p = shQuote(file.path(R.home(), 'tools', 'which'))))
    body(f) <- b
    unlockBinding('Sys.which', baseenv())
    assign('Sys.which', f, envir = baseenv())
    lockBinding('Sys.which', baseenv())
})
RPROFILE
fi
