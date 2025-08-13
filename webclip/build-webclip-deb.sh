#!/usr/bin/env bash
set -euo pipefail

# Build a jailbreak .deb that installs a Home Screen WebClip
# Usage:
#   ./webclip/build-webclip-deb.sh \
#     --label "Chimera ReJailbreak" \
#     --url "https://your-host/exploit-compact.html" \
#     [--bundleid com.tns.webclip] [--version 1.0-1]

LABEL=""
URL=""
BUNDLEID="com.tns.webclip"
VERSION="1.0-1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --label) LABEL="$2"; shift 2;;
    --url) URL="$2"; shift 2;;
    --bundleid) BUNDLEID="$2"; shift 2;;
    --version) VERSION="$2"; shift 2;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

if [[ -z "$LABEL" || -z "$URL" ]]; then
  echo "ERROR: --label and --url are required" >&2
  exit 1
fi

UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
PKGID="${BUNDLEID}.${UUID}" # unique per-build

ROOTDIR=$(cd "$(dirname "$0")/.." && pwd)
OUTBASE="$ROOTDIR/webclip/out"
BUILDDIR="$OUTBASE/${LABEL// /_}-${VERSION}"
DEBDIR="$BUILDDIR/DEBIAN"
CLIPDIR="$BUILDDIR/var/mobile/Library/WebClips/${UUID}.webclip"

rm -rf "$BUILDDIR"
mkdir -p "$DEBDIR" "$CLIPDIR"

# Try to reuse an icon from the repo if available
ICON_SRC=""
for c in icons/icon-180x180.png icons/icon-152x152.png icons/icon-120x120.png icons/TotallyNotSpyware.png; do
  if [[ -f "$ROOTDIR/$c" ]]; then ICON_SRC="$ROOTDIR/$c"; break; fi
done
if [[ -n "$ICON_SRC" ]]; then
  cp "$ICON_SRC" "$CLIPDIR/Icon.png"
fi

# Info.plist for the WebClip
cat > "$CLIPDIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>FullScreen</key><true/>
  <key>IconIsPrecomposed</key><true/>
  <key>IsRemovable</key><true/>
  <key>Label</key><string>${LABEL}</string>
  <key>URL</key><string>${URL}</string>
  <key>Precomposed</key><true/>
  <key>BundleIdentifier</key><string>${PKGID}</string>
</dict>
</plist>
PLIST

# DEBIAN control
cat > "$DEBDIR/control" <<CTRL
Package: ${BUNDLEID}
Name: ${LABEL} WebClip
Version: ${VERSION}
Architecture: iphoneos-arm
Maintainer: TNS Builder <you@example.com>
Depends: firmware (>= 8.0)
Description: Installs a Home Screen WebClip for ${LABEL}
CTRL

cat > "$DEBDIR/postinst" <<'POST'
#!/bin/sh
set -e
if command -v uicache >/dev/null 2>&1; then uicache || true; fi
exit 0
POST

cat > "$DEBDIR/prerm" <<'PRERM'
#!/bin/sh
set -e
if command -v uicache >/dev/null 2>&1; then uicache || true; fi
exit 0
PRERM

chmod 0755 "$DEBDIR/postinst" "$DEBDIR/prerm"

DEBNAME="${LABEL// /_}_${VERSION}_iphoneos-arm.deb"
DEBPATH="$OUTBASE/$DEBNAME"

fakeroot dpkg-deb -b "$BUILDDIR" "$DEBPATH"
echo "\nBuilt: $DEBPATH"
echo "\nInstall on device (SSH):"
echo "  scp '$DEBPATH' root@DEVICE:/tmp/ && ssh root@DEVICE 'dpkg -i /tmp/$(basename "$DEBPATH")'"


