#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PKG_DIR="$ROOT_DIR/packages/tnsjb-agent"
OUT_DIR="$ROOT_DIR/webclip/repo"
BUILD_DIR="$ROOT_DIR/.build/apt"

mkdir -p "$BUILD_DIR" "$OUT_DIR"

# Build .deb
DEB_OUT="$BUILD_DIR/tnsjb-agent_0.1.0-1_iphoneos-arm.deb"
echo "Building $DEB_OUT"
fakeroot dpkg-deb -Zxz -b "$PKG_DIR" "$DEB_OUT"

# Copy to repo
mkdir -p "$OUT_DIR/debs"
cp -f "$DEB_OUT" "$OUT_DIR/debs/"

# Generate Packages index
pushd "$OUT_DIR" >/dev/null
dpkg-scanpackages --multiversion ./debs > Packages || true
gzip -f -9 < Packages > Packages.gz
cat > Release <<REL
Origin: TotallyNotSpyware
Label: TNS ReJailbreak Repo
Suite: stable
Version: 1.0
Codename: tns
Architectures: iphoneos-arm
Components: main
Description: TNS agent and tools for PWA re-jailbreak utility.
REL
# lightweight listing for convenience
cat > index.html <<HTML
<!doctype html><meta charset="utf-8"><title>TNS APT Repo</title>
<h1>TNS APT Repo</h1>
<p>Add this repo:</p>
<pre id="u"></pre>
<ul>
  <li><a id="sileo" href="#">Add to Sileo</a></li>
  <li><a id="zebra" href="#">Add to Zebra</a></li>
</ul>
<p><a href="Packages">Packages</a> · <a href="Packages.gz">Packages.gz</a></p>
<script>
 var base = location.href.replace(/index.html$/,'');
 document.getElementById('u').textContent = base;
 document.getElementById('sileo').href = 'sileo://source/' + base;
 document.getElementById('zebra').href = 'zbra://sources/add/' + base;
</script>
HTML
popd >/dev/null

echo "Repo updated at $OUT_DIR"

