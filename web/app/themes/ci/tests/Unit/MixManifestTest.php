<?php

use App\Support\MixManifest;

it('resolves a versioned mix asset', function () {
    $path = tempnam(sys_get_temp_dir(), 'mix-');
    file_put_contents($path, json_encode([
        '/styles/app.css' => '/styles/app.css?id=abc123',
    ], JSON_THROW_ON_ERROR));

    $manifest = new MixManifest($path, 'https://example.test/app/themes/ci/dist');

    expect($manifest->uri('/styles/app.css'))
        ->toBe('https://example.test/app/themes/ci/dist/styles/app.css?id=abc123');
});

it('rejects an asset missing from the manifest', function () {
    $path = tempnam(sys_get_temp_dir(), 'mix-');
    file_put_contents($path, '{}');

    (new MixManifest($path, 'https://example.test'))
        ->uri('/scripts/app.js');
})->throws(RuntimeException::class, 'Missing Mix asset: /scripts/app.js');
