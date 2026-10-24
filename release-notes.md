First portable R release for Ubuntu 24.04 x86-64 cloud sessions.

- R 4.6.1, 19 common requested packages and their dependencies.
- Supporting shared libraries and DejaVu fonts included.
- Verified in a clean Ubuntu 24.04 container: all requested namespaces, data manipulation, PNG and SVG plotting.
- Setup downloads a pinned archive and verifies SHA-256; no package compilation.
- Public downloads; use setup.sh from the main branch with curl. No GitHub account or token is needed. Root or passwordless sudo is required for the existing /opt/R symlink.

Initial runtime and packages came from Interactions artifact 11157351531, built 1 October 2026 from commit 88676d8748ff982dfeacba8b2f19b85f5a49c179. BUILD-INFO.txt and PACKAGE-MANIFEST.tsv preserve the original build record. SYSTEM-PACKAGES.tsv records the supporting-library builder environment; upstream licences are included.
