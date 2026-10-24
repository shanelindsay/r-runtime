#!/usr/bin/env bash
set -euo pipefail
version="${R_RUNTIME_VERSION:-v0.1.0}"
destination="${1:-$HOME/.local/share/r-runtime/$version}"
case "$(uname -s):$(uname -m)" in
  Linux:x86_64) ;;
  *) echo 'This release requires Linux x86-64 with glibc.' >&2; exit 1 ;;
esac
for command in gh tar sha256sum; do
  command -v "$command" >/dev/null || { echo "Required command: $command" >&2; exit 1; }
done
if [[ -e "$destination" ]]; then
  echo "Destination already exists: $destination. Use its bin/Rscript or choose a new directory." >&2
  exit 1
fi
mkdir -p "$(dirname "$destination")"
destination="$(cd "$(dirname "$destination")" && pwd)/$(basename "$destination")"
stage="$(mktemp -d "$(dirname "$destination")/.r-runtime.XXXXXX")"
trap 'rm -rf "$stage"' EXIT
archive=r-runtime-linux-x86_64.tar.gz
gh release download "$version" --repo shanelindsay/r-runtime --pattern "$archive" --pattern SHA256SUMS --dir "$stage"
(cd "$stage" && sha256sum --check SHA256SUMS)
mkdir "$stage/runtime"
tar -xzf "$stage/$archive" -C "$stage/runtime"
mv "$stage/runtime" "$destination"
mkdir -p "$destination/bin"
for program in R Rscript; do
  cat > "$destination/bin/$program" <<EOF
#!/usr/bin/env bash
root="\$(cd -- "\$(dirname -- "\${BASH_SOURCE[0]}")/.." && pwd)"
exec bash "\$root/dev/use-portable-r.sh" $program "\$@"
EOF
  chmod +x "$destination/bin/$program"
done
"$destination/bin/Rscript" -e 'library(ggplot2); cat(R.version.string, "\n"); print(packageVersion("ggplot2"))'
printf 'Ready. Add this directory to PATH: %s/bin\n' "$destination"
