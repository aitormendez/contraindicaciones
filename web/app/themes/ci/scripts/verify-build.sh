#!/usr/bin/env bash
set -euo pipefail

theme_dir=$(cd "$(dirname "$0")/.." && pwd)
dist_dir=${VERIFY_BUILD_DIST_DIR:-"$theme_dir/dist"}

if [ "${VERIFY_BUILD_PHP_BIN+x}" = x ]; then
  printf 'verify-build: VERIFY_BUILD_PHP_BIN is not supported\n' >&2
  exit 1
fi

if ! php_bin=$(command -v php); then
  printf 'verify-build: PHP is not available\n' >&2
  exit 1
fi

if [ -z "$php_bin" ] || [ ! -x "$php_bin" ]; then
  printf 'verify-build: PHP is not available\n' >&2
  exit 1
fi

readonly manifest_sentinel='verify-build-manifest:7'
readonly metadata_sentinel='verify-build-metadata:valid'

if ! manifest_protocol=$(VERIFY_BUILD_DIST_RESOLVED="$dist_dir" "$php_bin" <<'PHP'
<?php

declare(strict_types=1);

$fail = static function (string $message): never {
    fwrite(STDERR, "verify-build: {$message}\n");
    exit(1);
};

$dist = getenv('VERIFY_BUILD_DIST_RESOLVED');

if (! is_string($dist) || $dist === '') {
    $fail('the build directory is not configured');
}

$dist = rtrim($dist, DIRECTORY_SEPARATOR);
$manifestPath = $dist.DIRECTORY_SEPARATOR.'mix-manifest.json';

if (! is_file($manifestPath) || ! is_readable($manifestPath) || filesize($manifestPath) === 0) {
    $fail('mix-manifest.json is missing, unreadable, or empty');
}

try {
    $manifest = json_decode(
        file_get_contents($manifestPath) ?: '',
        true,
        512,
        JSON_THROW_ON_ERROR
    );
} catch (JsonException $exception) {
    $fail('mix-manifest.json is not valid JSON');
}

if (! is_array($manifest)) {
    $fail('mix-manifest.json must contain a JSON object');
}

$requiredAssets = [
    '/scripts/manifest.js',
    '/scripts/vendor.js',
    '/scripts/app.js',
    '/scripts/editor.js',
    '/scripts/customizer.js',
    '/styles/app.css',
    '/styles/editor.css',
];

$realDist = realpath($dist);

if ($realDist === false || ! is_dir($realDist)) {
    $fail('the build directory does not exist');
}

foreach ($requiredAssets as $asset) {
    if (! array_key_exists($asset, $manifest)) {
        $fail("missing manifest asset: {$asset}");
    }

    $versionedPath = $manifest[$asset];

    if (! is_string($versionedPath) || $versionedPath === '') {
        $fail("manifest asset must be a non-empty string: {$asset}");
    }

    $path = parse_url($versionedPath, PHP_URL_PATH);

    if (! is_string($path) || $path === '' || ! str_starts_with($path, '/')) {
        $fail("manifest asset must resolve to a root-relative path: {$asset}");
    }

    $target = realpath($realDist.DIRECTORY_SEPARATOR.ltrim($path, '/'));

    if (
        $target === false ||
        ! str_starts_with($target, $realDist.DIRECTORY_SEPARATOR) ||
        ! is_file($target) ||
        ! is_readable($target) ||
        filesize($target) === 0
    ) {
        $fail("manifest destination is missing, unreadable, or empty: {$asset}");
    }
}

printf("verify-build-manifest:%d\n", count($requiredAssets));
PHP
); then
  exit 1
fi

if [ "$manifest_protocol" != "$manifest_sentinel" ]; then
  printf 'verify-build: manifest validator returned an invalid protocol\n' >&2
  exit 1
fi

if ! metadata_protocol=$(VERIFY_BUILD_DIST_RESOLVED="$dist_dir" "$php_bin" <<'PHP'
<?php

declare(strict_types=1);

$fail = static function (string $message): never {
    fwrite(STDERR, "verify-build: {$message}\n");
    exit(1);
};

$dist = getenv('VERIFY_BUILD_DIST_RESOLVED');

if (! is_string($dist) || $dist === '') {
    $fail('the build directory is not configured');
}

$realDist = realpath(rtrim($dist, DIRECTORY_SEPARATOR));

if ($realDist === false || ! is_dir($realDist)) {
    $fail('the build directory does not exist');
}

$metadataPath = $realDist.DIRECTORY_SEPARATOR.'scripts'.DIRECTORY_SEPARATOR.'manifest.asset.php';

if (! is_file($metadataPath) || ! is_readable($metadataPath) || filesize($metadataPath) === 0) {
    $fail('scripts/manifest.asset.php is missing, unreadable, or empty');
}

set_error_handler(static function (int $severity, string $message): never {
    throw new ErrorException($message, 0, $severity);
});

try {
    $metadata = require $metadataPath;
} catch (Throwable $exception) {
    $fail('scripts/manifest.asset.php could not be loaded');
} finally {
    restore_error_handler();
}

if (
    ! is_array($metadata) ||
    ! isset($metadata['dependencies'], $metadata['version']) ||
    ! is_array($metadata['dependencies']) ||
    ! array_is_list($metadata['dependencies']) ||
    ! is_string($metadata['version']) ||
    $metadata['version'] === ''
) {
    $fail('scripts/manifest.asset.php has an invalid structure');
}

foreach ($metadata['dependencies'] as $dependency) {
    if (! is_string($dependency) || $dependency === '') {
        $fail('scripts/manifest.asset.php dependencies must be non-empty strings');
    }
}

fwrite(STDOUT, "verify-build-metadata:valid\n");
PHP
); then
  exit 1
fi

if [ "$metadata_protocol" != "$metadata_sentinel" ]; then
  printf 'verify-build: metadata validator returned an invalid protocol\n' >&2
  exit 1
fi

printf 'verify-build: 7 assets and dependency metadata are valid\n'
