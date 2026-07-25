#!/usr/bin/env bash
set -euo pipefail

theme_dir=$(cd "$(dirname "$0")/../.." && pwd)
verifier="$theme_dir/scripts/verify-build.sh"
fixture_root=$(mktemp -d "${TMPDIR:-/tmp}/contra-verify-build.XXXXXX")
chmod 700 "$fixture_root"
trap 'rm -rf -- "$fixture_root"' EXIT

dist="$fixture_root/dist"
mkdir -p "$dist/scripts" "$dist/styles"

write_manifest() {
  php -r '
    $path = $argv[1];
    $editor = $argv[2] === "string" ? "/scripts/editor.js?id=fixture" : 42;
    $manifest = [
        "/scripts/manifest.js" => "/scripts/manifest.js?id=fixture",
        "/scripts/vendor.js" => "/scripts/vendor.js?id=fixture",
        "/scripts/app.js" => "/scripts/app.js?id=fixture",
        "/scripts/editor.js" => $editor,
        "/scripts/customizer.js" => "/scripts/customizer.js?id=fixture",
        "/styles/app.css" => "/styles/app.css?id=fixture",
        "/styles/editor.css" => "/styles/editor.css?id=fixture",
    ];
    file_put_contents($path, json_encode($manifest, JSON_THROW_ON_ERROR));
  ' "$dist/mix-manifest.json" "${1:-string}"
}

write_assets() {
  local asset

  for asset in \
    scripts/manifest.js \
    scripts/vendor.js \
    scripts/app.js \
    scripts/editor.js \
    scripts/customizer.js \
    styles/app.css \
    styles/editor.css; do
    printf 'fixture\n' > "$dist/$asset"
  done
}

write_metadata() {
  printf '%s\n' "<?php return ['dependencies' => ['wp-blocks'], 'version' => 'fixture'];" \
    > "$dist/scripts/manifest.asset.php"
}

expect_failure() {
  local label=$1

  if VERIFY_BUILD_DIST_DIR="$dist" "$verifier" > "$fixture_root/output.log" 2>&1; then
    printf 'Expected verifier failure: %s\n' "$label" >&2
    exit 1
  fi
}

write_manifest
write_assets
write_metadata

rm "$dist/scripts/editor.js"
expect_failure 'missing referenced destination'

printf 'fixture\n' > "$dist/scripts/editor.js"
write_manifest invalid
expect_failure 'manifest value is not a string'

write_manifest
printf '%s\n' "<?php return ['dependencies' => 'wp-blocks', 'version' => 'fixture'];" \
  > "$dist/scripts/manifest.asset.php"
expect_failure 'manifest.asset.php dependencies are not an array'

write_metadata
VERIFY_BUILD_DIST_DIR="$dist" "$verifier" > "$fixture_root/output.log"

printf 'verify-build fixtures: ok\n'
