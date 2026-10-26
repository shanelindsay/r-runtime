#!/usr/bin/env bash
# Install pinned scientific command-line tools alongside an existing R runtime.
# This is deliberately separate from the immutable R v0.1.0 release archive.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: bash scripts/install-tools.sh <r-runtime-installation-directory>" >&2
  exit 2
fi

destination="$1"
[[ -d "$destination/bin" ]] || {
  echo "Expected an existing R runtime with bin/: $destination" >&2
  exit 1
}
destination="$(cd "$destination" && pwd)"

case "$(uname -s):$(uname -m)" in
  Linux:x86_64) ;;
  *) echo "The scientific tool bundle requires Linux x86-64." >&2; exit 1 ;;
esac
for command in curl tar sha256sum; do
  command -v "$command" >/dev/null || {
    echo "Required command: $command" >&2
    exit 1
  }
done

# Versions and SHA-256 values are from the publishers' GitHub releases.
quarto_version="1.10.19"
quarto_sha256="8e38c2b2df6a6dbd369ea16e15acded6894545258d13a02f777f81ad18fd7973"
micromamba_version="2.9.0-0"
micromamba_sha256="366cd9cd8be14df1ab8ed50352a82111082a36686b2d389fdb79a92c3fafb3e3"

quarto_dir="$destination/tools/quarto-$quarto_version"
micromamba_bin="$destination/bin/micromamba"
mkdir -p "$destination/tools"
stage="$(mktemp -d "$destination/.tool-install.XXXXXX")"
trap 'rm -rf "$stage"' EXIT

if [[ ! -e "$quarto_dir" ]]; then
  echo "Downloading pinned Quarto $quarto_version..."
  filename="quarto-$quarto_version-linux-amd64.tar.gz"
  curl -fL --retry 2 "https://github.com/quarto-dev/quarto-cli/releases/download/v$quarto_version/$filename" -o "$stage/$filename"
  printf '%s  %s\n' "$quarto_sha256" "$stage/$filename" | sha256sum --check --status
  mkdir "$stage/quarto"
  tar -xzf "$stage/$filename" -C "$stage/quarto" --strip-components=1
  [[ -x "$stage/quarto/bin/quarto" ]] || {
    echo "Quarto archive did not contain bin/quarto." >&2
    exit 1
  }
  mv "$stage/quarto" "$quarto_dir"
fi

[[ -x "$quarto_dir/bin/quarto" ]] || {
  echo "Incomplete Quarto installation: $quarto_dir" >&2
  exit 1
}
if [[ ! -e "$destination/bin/quarto" && ! -L "$destination/bin/quarto" ]]; then
  ln -s "../tools/quarto-$quarto_version/bin/quarto" "$destination/bin/quarto"
fi
[[ "$(readlink "$destination/bin/quarto")" == "../tools/quarto-$quarto_version/bin/quarto" ]] || {
  echo "Conflicting Quarto launcher exists: $destination/bin/quarto" >&2
  exit 1
}

if [[ ! -e "$micromamba_bin" ]]; then
  echo "Downloading pinned micromamba $micromamba_version..."
  curl -fL --retry 2 "https://github.com/mamba-org/micromamba-releases/releases/download/$micromamba_version/micromamba-linux-64" -o "$stage/micromamba"
  printf '%s  %s\n' "$micromamba_sha256" "$stage/micromamba" | sha256sum --check --status
  install -m 0755 "$stage/micromamba" "$micromamba_bin"
fi

[[ -x "$micromamba_bin" ]] || {
  echo "Incomplete micromamba installation: $micromamba_bin" >&2
  exit 1
}
[[ "$("$micromamba_bin" --version)" == "2.9.0" ]] || {
  echo "Existing micromamba version differs from the pinned $micromamba_version." >&2
  exit 1
}

# These launch Quarto's own Pandoc and Typst, ensuring the same pinned version
# of the document toolchain is used regardless of host PATH.
for program in pandoc typst; do
  cat > "$destination/bin/$program" <<'WRAPPER'
#!/usr/bin/env bash
# Managed by r-runtime. Quarto supplies Pandoc and Typst internally.
set -euo pipefail
bin="$(cd -- "$(dirname -- "$0")" && pwd)"
exec "$bin/quarto" "$(basename -- "$0")" "$@"
WRAPPER
  chmod +x "$destination/bin/$program"
done

# Quarto extensions are project-local, not globally installed CLI programs.
# The helper installs the pinned APA 7 extension and its companion filters
# into the project selected by the caller. Existing installations are kept.
cat > "$destination/bin/apaquarto-add" <<'WRAPPER'
#!/usr/bin/env bash
# Managed by r-runtime. Install APAQUARTO into one Quarto project.
set -euo pipefail
[[ $# -le 1 ]] || { echo "Usage: apaquarto-add [project-directory]" >&2; exit 2; }
project="$(cd -- "${1:-.}" && pwd)"
bin="$(cd -- "$(dirname -- "$0")" && pwd)"
if [[ -e "$project/_extensions/wjschne/apaquarto/_extension.yml" ]]; then
  if grep -Eq '^version: 7\.0\.1[[:space:]]*$' "$project/_extensions/wjschne/apaquarto/_extension.yml"; then
    echo "APAQUARTO 7.0.1 is already installed in $project"
    exit 0
  fi
  echo "The project already has an APAQUARTO extension at another version; not overwriting it." >&2
  exit 1
fi
(cd "$project" && "$bin/quarto" add wjschne/apaquarto@v7.0.1 --no-prompt)
test -f "$project/_extensions/wjschne/apaquarto/_extension.yml"
WRAPPER
chmod +x "$destination/bin/apaquarto-add"

# Confirm the real executables, not just the existence of files/symlinks.
[[ "$("$destination/bin/quarto" --version)" == "$quarto_version" ]] || {
  echo "Quarto version check failed." >&2; exit 1
}
"$destination/bin/pandoc" --version | sed -n '1p'
"$destination/bin/typst" --version
"$destination/bin/micromamba" --version
printf 'Scientific tools ready. Add to PATH: %s/bin\n' "$destination"
printf 'For APA 7 manuscripts, run: apaquarto-add /path/to/project\n'
