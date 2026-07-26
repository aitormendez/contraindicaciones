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

write_metadata_source() {
  printf '%s\n' "$1" > "$dist/scripts/manifest.asset.php"
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

printf '' > "$dist/scripts/manifest.asset.php"
expect_failure 'empty manifest.asset.php'

write_metadata_source "<?php return ['dependencies' => ['wp-blocks']];"
expect_failure 'partial manifest.asset.php'

write_metadata_source "<?php echo 'noise'; return ['dependencies' => ['wp-blocks'], 'version' => 'fixture'];"
expect_failure 'manifest.asset.php with extra output'

write_metadata_source '<?php fwrite(STDOUT, "verify-build-metadata:valid\n"); exit(0);'
expect_failure 'manifest.asset.php exact sentinel followed by exit'

write_metadata_source "<?php file_put_contents(__DIR__.'/metadata-executed', 'ran'); return ['dependencies' => ['wp-blocks'], 'version' => 'fixture'];"
expect_failure 'manifest.asset.php with executable code'

if [ -e "$dist/scripts/metadata-executed" ]; then
  printf 'Expected executable metadata to remain unexecuted\n' >&2
  exit 1
fi

write_metadata_source "<?php return ['dependencies' => ['wp-blocks'], 'version' => 'fixture', 'extra' => 'unexpected'];"
expect_failure 'manifest.asset.php with an unexpected key'

write_metadata_source '<?php exit(0);'
expect_failure 'manifest.asset.php premature exit'
write_metadata

if VERIFY_BUILD_PHP_BIN=true VERIFY_BUILD_DIST_DIR="$dist" \
  "$verifier" > "$fixture_root/output.log" 2>&1; then
  printf 'Expected verifier failure: PHP binary override\n' >&2
  exit 1
fi

rm "$dist/scripts/editor.js"
expect_failure 'missing referenced destination'

printf 'fixture\n' > "$dist/scripts/editor.js"
write_manifest invalid
expect_failure 'manifest value is not a string'

write_manifest
write_metadata_source "<?php return ['dependencies' => 'wp-blocks', 'version' => 'fixture'];"
expect_failure 'manifest.asset.php dependencies are not an array'

write_metadata_source "<?php /* generated metadata */ return array('dependencies' => array('wp-blocks'), 'version' => 'fixture'); // end"
VERIFY_BUILD_DIST_DIR="$dist" "$verifier" > "$fixture_root/output.log"

printf 'verify-build fixtures: ok\n'
