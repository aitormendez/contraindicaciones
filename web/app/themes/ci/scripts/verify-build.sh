#!/usr/bin/env bash
set -euo pipefail

theme_dir=$(cd "$(dirname "$0")/.." && pwd)
manifest="$theme_dir/dist/mix-manifest.json"

test -s "$manifest"
for asset in \
  /scripts/manifest.js \
  /scripts/vendor.js \
  /scripts/app.js \
  /styles/app.css; do
  grep -Fq "\"$asset\"" "$manifest"
done
