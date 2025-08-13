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
  (cd "$REPO" && dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz)
  echo "Repo built at: $REPO (serve this directory over HTTP)"
else
  echo "Copied debs to $REPO. Install dpkg-dev and run dpkg-scanpackages to generate Packages.gz"
fi


