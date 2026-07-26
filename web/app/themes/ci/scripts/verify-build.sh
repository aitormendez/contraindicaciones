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

$source = file_get_contents($metadataPath);

if (! is_string($source) || $source === '') {
    $fail('scripts/manifest.asset.php could not be read');
}

try {
    $rawTokens = token_get_all($source, TOKEN_PARSE);
} catch (ParseError $exception) {
    $fail('scripts/manifest.asset.php is not valid PHP syntax');
}

$allowedTokenIds = [
    T_OPEN_TAG,
    T_RETURN,
    T_ARRAY,
    T_CONSTANT_ENCAPSED_STRING,
    T_DOUBLE_ARROW,
    T_WHITESPACE,
    T_COMMENT,
    T_DOC_COMMENT,
];
$allowedCharacters = ['[', ']', '(', ')', ',', ';'];
$tokens = [];

foreach ($rawTokens as $token) {
    if (is_array($token)) {
        [$tokenId] = $token;

        if (in_array($tokenId, [T_WHITESPACE, T_COMMENT, T_DOC_COMMENT], true)) {
            continue;
        }

        if (! in_array($tokenId, $allowedTokenIds, true)) {
            $fail('scripts/manifest.asset.php contains executable or unsupported syntax');
        }
    } elseif (! in_array($token, $allowedCharacters, true)) {
        $fail('scripts/manifest.asset.php contains executable or unsupported syntax');
    }

    $tokens[] = $token;
}

$position = 0;
$isToken = static fn (mixed $token, int $tokenId): bool => is_array($token) && $token[0] === $tokenId;
$isCharacter = static fn (mixed $token, string $character): bool => is_string($token) && $token === $character;
$decodeString = static function (string $literal) use ($fail): string {
    $length = strlen($literal);

    if ($length < 2) {
        $fail('scripts/manifest.asset.php contains an invalid string literal');
    }

    $quote = $literal[0];
    $value = substr($literal, 1, -1);

    if (($quote !== "'" && $quote !== '"') || $literal[$length - 1] !== $quote) {
        $fail('scripts/manifest.asset.php contains an invalid string literal');
    }

    if (preg_match('/\\A[A-Za-z0-9_.\\/@:+-]*\\z/D', $value) !== 1) {
        $fail('scripts/manifest.asset.php contains an unsupported string literal');
    }

    return $value;
};

$parseValue = null;
$parseValue = static function () use (
    &$parseValue,
    &$position,
    $tokens,
    $isToken,
    $isCharacter,
    $decodeString,
    $fail
): array|string {
    $token = $tokens[$position] ?? null;

    if ($isToken($token, T_CONSTANT_ENCAPSED_STRING)) {
        $position++;

        return $decodeString($token[1]);
    }

    if ($isCharacter($token, '[')) {
        $closingCharacter = ']';
        $position++;
    } elseif ($isToken($token, T_ARRAY)) {
        $position++;

        if (! $isCharacter($tokens[$position] ?? null, '(')) {
            $fail('scripts/manifest.asset.php contains an invalid array literal');
        }

        $closingCharacter = ')';
        $position++;
    } else {
        $fail('scripts/manifest.asset.php must contain only arrays and string literals');
    }

    $value = [];

    if ($isCharacter($tokens[$position] ?? null, $closingCharacter)) {
        $position++;

        return $value;
    }

    while (true) {
        $entry = $parseValue();

        if ($isToken($tokens[$position] ?? null, T_DOUBLE_ARROW)) {
            if (! is_string($entry)) {
                $fail('scripts/manifest.asset.php array keys must be string literals');
            }

            $position++;

            if (array_key_exists($entry, $value)) {
                $fail('scripts/manifest.asset.php contains a duplicate array key');
            }

            $value[$entry] = $parseValue();
        } else {
            $value[] = $entry;
        }

        if ($isCharacter($tokens[$position] ?? null, ',')) {
            $position++;

            if ($isCharacter($tokens[$position] ?? null, $closingCharacter)) {
                $position++;

                return $value;
            }

            continue;
        }

        if (! $isCharacter($tokens[$position] ?? null, $closingCharacter)) {
            $fail('scripts/manifest.asset.php contains an invalid array literal');
        }

        $position++;

        return $value;
    }
};

if (! $isToken($tokens[$position] ?? null, T_OPEN_TAG)) {
    $fail('scripts/manifest.asset.php must begin with a PHP opening tag');
}

$position++;

if (! $isToken($tokens[$position] ?? null, T_RETURN)) {
    $fail('scripts/manifest.asset.php must contain exactly one return statement');
}

$position++;
$metadata = $parseValue();

if (! $isCharacter($tokens[$position] ?? null, ';')) {
    $fail('scripts/manifest.asset.php return statement must end with a semicolon');
}

$position++;

if ($position !== count($tokens)) {
    $fail('scripts/manifest.asset.php contains statements after its return value');
}

if (
    ! is_array($metadata) ||
    count($metadata) !== 2 ||
    ! array_key_exists('dependencies', $metadata) ||
    ! array_key_exists('version', $metadata) ||
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
