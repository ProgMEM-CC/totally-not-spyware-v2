#!/usr/bin/env bash
set -euo pipefail

# Build a single visual debug report zip from a video + JSON issues file
# Requires: ffmpeg, zip

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <input-video.(mp4|mov|webm)> <issues.json> [out-dir]" >&2
  exit 1
fi

INVID=$(readlink -f "$1")
INJSON=$(readlink -f "$2")
OUTDIR=${3:-visual-report}

mkdir -p "$OUTDIR"

BASE=$(basename "$INVID")
NAME=${BASE%.*}

# Transcode to animated webp (balanced for size/quality)
# 10 fps, 480px width, loop forever
WEBP="$OUTDIR/${NAME}.webp"
ffmpeg -y -i "$INVID" -vf "fps=10,scale=480:-1:flags=lanczos" -loop 0 -c:v libwebp -q:v 60 "$WEBP"

# Copy JSON into output dir (normalized name)
cp "$INJSON" "$OUTDIR/issues.json"

ZIP="$OUTDIR/${NAME}-visual-report.zip"
rm -f "$ZIP"
(
  cd "$OUTDIR"
  zip -9 "$ZIP" "$(basename "$WEBP")" issues.json >/dev/null
)

echo "\nReport ready: $ZIP"
echo "Contains:"
echo "  - $(basename "$WEBP") (animated webp)"
echo "  - issues.json (visual debug data)"


