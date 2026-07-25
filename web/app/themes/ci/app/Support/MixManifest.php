<?php

namespace App\Support;

use RuntimeException;

class MixManifest
{
    public function __construct(
        protected string $manifestPath,
        protected string $baseUri,
    ) {}

    public static function fromTheme(): self
    {
        return new self(
            get_theme_file_path('dist/mix-manifest.json'),
            get_theme_file_uri('dist'),
        );
    }

    public function uri(string $asset): string
    {
        if (! is_file($this->manifestPath)) {
            throw new RuntimeException("Missing Mix manifest: {$this->manifestPath}");
        }

        $contents = file_get_contents($this->manifestPath);

        if ($contents === false) {
            throw new RuntimeException("Unable to read Mix manifest: {$this->manifestPath}");
        }

        $manifest = json_decode($contents, true, 512, JSON_THROW_ON_ERROR);
        $asset = '/'.ltrim($asset, '/');

        if (! is_array($manifest) || ! array_key_exists($asset, $manifest)) {
            throw new RuntimeException("Missing Mix asset: {$asset}");
        }

        return rtrim($this->baseUri, '/').'/'.ltrim($manifest[$asset], '/');
    }
}
