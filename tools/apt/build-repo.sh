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
popd >/dev/null

echo "Repo updated at $OUT_DIR"

