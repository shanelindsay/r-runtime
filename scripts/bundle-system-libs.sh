#!/usr/bin/env bash
# Run on Ubuntu 24.04 after installing the packages listed in README.md.
set -euo pipefail
[[ $# == 1 ]] || { echo "Usage: $0 <extracted-bundle>" >&2; exit 2; }
root="$(cd "$1" && pwd)"
mkdir -p "$root/dev/system-libs" "$root/dev/fontconfig/fonts" "$root/dev/system-licences"
find "$root/dev/linux" "$root/dev/portable-r-library" -type f \( -name '*.so' -o -name R \) -exec ldd {} \; 2>/dev/null |
  awk '/=> \/usr\/lib|=> \/lib/ {print $3}' | sort -u |
  while read -r library; do
    case "$(basename "$library")" in
      libc.so.*|libm.so.*|libpthread.so.*|librt.so.*|libdl.so.*|libresolv.so.*|libutil.so.*) continue ;;
    esac
    cp -L "$library" "$root/dev/system-libs/"
  done
cp /usr/share/fonts/truetype/dejavu/*.ttf "$root/dev/fontconfig/fonts/"
find /usr/share/doc -name copyright -exec cp --parents {} "$root/dev/system-licences/" \;
dpkg-query -W > "$root/SYSTEM-PACKAGES.tsv"
