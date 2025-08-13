#!/usr/bin/env bash
set -euo pipefail

# Build .deb via build-webclip-deb.sh then generate a simple APT repo structure under webclip/repo

ROOTDIR=$(cd "$(dirname "$0")/.." && pwd)
REPO="$ROOTDIR/webclip/repo"
OUT="$ROOTDIR/webclip/out"

mkdir -p "$REPO" "$OUT"

# Require dpkg-scanpackages (apt-utils)
if ! command -v dpkg-scanpackages >/dev/null 2>&1; then
  echo "WARNING: dpkg-scanpackages not found. Install: sudo apt-get install dpkg-dev" >&2
fi

# Copy any .deb to repo dir
find "$OUT" -name '*.deb' -maxdepth 1 -print0 | while IFS= read -r -d '' f; do
  cp -f "$f" "$REPO/"
done

if command -v dpkg-scanpackages >/dev/null 2>&1; then
  (cd "$REPO" && dpkg-scanpackages . /dev/null > Packages)
  (cd "$REPO" && gzip -9c Packages > Packages.gz)
else
  echo "Copied debs to $REPO. Install dpkg-dev and run dpkg-scanpackages to generate Packages/Packages.gz" >&2
fi

# Minimal Release file (optional but helps some clients)
DATE=$(date -Ru)
cat > "$REPO/Release" <<REL
Origin: TNS WebClip Repo
Label: TNS
Suite: stable
Version: 1.0
Codename: tns
Architectures: iphoneos-arm
Components: main
Description: TNS local webclip repository
Date: $DATE
REL

# Simple index for browsing/deb direct install
cat > "$REPO/index.html" <<HTML
<!doctype html><meta charset="utf-8"><title>TNS WebClip Repo</title>
<h1>TNS WebClip Repo</h1>
<p>If your package manager can't add the source, tap the .deb below to download/install directly.</p>
<ul>
$(for f in "$REPO"/*.deb; do bn=$(basename "$f"); echo "<li><a href='$bn'>$bn</a></li>"; done)
</ul>
<p>APT metadata: <a href="Packages">Packages</a> · <a href="Packages.gz">Packages.gz</a> · <a href="Release">Release</a></p>
HTML

echo "Repo built at: $REPO (commit/push and serve over GitHub Pages)."


