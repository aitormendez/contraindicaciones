<?php

use Symfony\Component\Process\Process;

it('boots Acorn with its default services and the Sage theme provider', function () {
    $themePath = dirname(__DIR__, 2);
    $bootstrap = <<<'PHP'
        $themePath = $argv[1];
        $GLOBALS['themePath'] = $themePath;
        $GLOBALS['registeredFilters'] = [];
        $GLOBALS['registeredFieldGroups'] = [];

        define('ABSPATH', $themePath.'/');
        define('WP_CONTENT_DIR', $themePath.'/storage');
        define('WP_PLUGIN_DIR', $themePath.'/plugins');
        define('WP_DEBUG', false);
        define('WP_DEBUG_DISPLAY', false);
        define('DB_HOST', '127.0.0.1');
        define('DB_NAME', 'wordpress');
        define('DB_USER', 'wordpress');
        define('DB_PASSWORD', 'wordpress');
        define('DB_CHARSET', 'utf8mb4');

        $GLOBALS['wpdb'] = (object) [
            'collate' => 'utf8mb4_unicode_ci',
            'prefix' => 'wp_',
        ];

        function get_theme_file_path(string $path = ''): string
        {
            return $GLOBALS['themePath'].($path !== '' ? '/'.ltrim($path, '/') : '');
        }

        function get_parent_theme_file_path(string $path = ''): string
        {
            return get_theme_file_path($path);
        }

        function get_theme_file_uri(string $path = ''): string
        {
            return 'https://example.test/app/themes/ci'.($path !== '' ? '/'.ltrim($path, '/') : '');
        }

        function get_template_directory(): string
        {
            return $GLOBALS['themePath'];
        }

        function get_stylesheet_directory(): string
        {
            return $GLOBALS['themePath'];
        }

        function wp_get_theme(): object
        {
            return new class {
                public function get(string $key): string
                {
                    return $key === 'Name' ? 'Contraindicaciones' : 'ci';
                }
            };
        }

        function get_option(string $key, mixed $default = false): mixed
        {
            return match ($key) {
                'active_plugins' => [],
                'home' => 'https://example.test',
                default => $default,
            };
        }

        function get_locale(): string
        {
            return 'es_ES';
        }

        function home_url(string $path = ''): string
        {
            return 'https://example.test'.($path !== '' ? '/'.ltrim($path, '/') : '');
        }

        function content_url(string $path = ''): string
        {
            return 'https://example.test/app'.($path !== '' ? '/'.ltrim($path, '/') : '');
        }

        function site_url(string $path = ''): string
        {
            return 'https://example.test/wp'.($path !== '' ? '/'.ltrim($path, '/') : '');
        }

        function apply_filters(string $hook, mixed $value = null, mixed ...$args): mixed
        {
            return $value;
        }

        function add_filter(string $hook, callable|string $callback, int $priority = 10, int $acceptedArgs = 1): bool
        {
            $GLOBALS['registeredFilters'][$hook][$priority][] = $callback;

            return true;
        }

        function add_action(string $hook, callable|string $callback, int $priority = 10, int $acceptedArgs = 1): bool
        {
            return true;
        }

        function did_action(string $hook): int
        {
            return 0;
        }

        function is_multisite(): bool
        {
            return false;
        }

        function is_admin(): bool
        {
            return false;
        }

        function acf_add_local_field_group(array $fieldGroup): void
        {
            $GLOBALS['registeredFieldGroups'][] = $fieldGroup;
        }

        require $themePath.'/vendor/autoload.php';

        $app = Roots\Acorn\Application::configure($themePath)
            ->withProviders([App\Providers\ThemeServiceProvider::class])
            ->create();

        $app->make(Illuminate\Contracts\Http\Kernel::class)->bootstrap();

        $ensure = static function (bool $condition, string $message): void {
            if (! $condition) {
                fwrite(STDERR, $message.PHP_EOL);
                exit(1);
            }
        };

        $configuredProviders = $app['config']->get('app.providers', []);
        $defaultProviders = Roots\Acorn\ServiceProvider::defaultProviders()->toArray();

        foreach ($defaultProviders as $provider) {
            $ensure(in_array($provider, $configuredProviders, true), "Missing default provider: {$provider}");
        }

        $configuredAliases = $app['config']->get('app.aliases', []);

        foreach (Illuminate\Support\Facades\Facade::defaultAliases() as $alias => $class) {
            $ensure(($configuredAliases[$alias] ?? null) === $class, "Missing default alias: {$alias}");
        }

        foreach (['files', 'view', 'sage'] as $binding) {
            $ensure($app->bound($binding), "Missing container binding: {$binding}");
        }

        $loadedProviders = $app->getLoadedProviders();

        foreach ([
            Illuminate\Filesystem\FilesystemServiceProvider::class,
            Roots\Acorn\Filesystem\FilesystemServiceProvider::class,
            Roots\Acorn\View\ViewServiceProvider::class,
            Log1x\AcfComposer\Providers\AcfComposerServiceProvider::class,
            App\Providers\ThemeServiceProvider::class,
        ] as $provider) {
            $ensure(isset($loadedProviders[$provider]), "Provider was not loaded: {$provider}");
        }

        $ensure($app->bound('AcfComposer'), 'The ACF Composer binding was not registered.');

        $acfComposer = $app->make('AcfComposer');
        $ensure($acfComposer->booted(), 'ACF Composer was not booted.');

        $discoveredComposers = [];

        foreach ($acfComposer->composers() as $composers) {
            foreach ($composers as $composer) {
                $discoveredComposers[] = $composer;
            }
        }

        $ensure(
            in_array(App\Fields\Posts::class, $discoveredComposers, true),
            'App\\Fields\\Posts was not discovered by ACF Composer.'
        );

        $acfInitFilters = $GLOBALS['registeredFilters']['acf/init'] ?? [];
        $ensure($acfInitFilters !== [], 'The ACF init hook was not captured.');
        ksort($acfInitFilters);

        foreach ($acfInitFilters as $callbacks) {
            foreach ($callbacks as $callback) {
                $ensure(is_callable($callback), 'An ACF init callback is not callable.');
                $callback();
            }
        }

        $fieldGroup = null;

        foreach ($GLOBALS['registeredFieldGroups'] ?? [] as $candidate) {
            if (($candidate['key'] ?? null) === 'group_cat_img') {
                $fieldGroup = $candidate;
                break;
            }
        }

        $ensure(is_array($fieldGroup), 'group_cat_img was not registered with ACF.');

        $field = null;

        foreach ($fieldGroup['fields'] ?? [] as $candidate) {
            if (($candidate['key'] ?? null) === 'field_cat_img_destacado') {
                $field = $candidate;
                break;
            }
        }

        $ensure(is_array($field), 'field_cat_img_destacado was not registered with ACF.');
        $ensure(($field['name'] ?? null) === 'destacado', 'The destacado field name changed.');

        $blade = $app['view']->getEngineResolver()->resolve('blade')->getCompiler();
        $ensure(array_key_exists('asset', $blade->getCustomDirectives()), 'The asset Blade directive was not registered.');

        foreach (['partials.entry-meta', 'partials.content-secciones-page'] as $view) {
            $ensure($app['events']->hasListeners("composing: {$view}"), "View composer was not registered: {$view}");
        }

        $manifest = $app['config']->get('assets.manifests.theme', []);
        $ensure(($manifest['path'] ?? null) === get_theme_file_path('dist'), 'Invalid assets manifest path.');
        $ensure(($manifest['url'] ?? null) === get_theme_file_uri('dist'), 'Invalid assets manifest URL.');
        $ensure(($manifest['assets'] ?? null) === get_theme_file_path('dist/mix-manifest.json'), 'Invalid assets manifest file.');
        PHP;

    $process = new Process([PHP_BINARY, '-r', $bootstrap, $themePath], $themePath);
    $process->setTimeout(30);
    $process->run();

    expect($process->getErrorOutput())->toBe('')
        ->and($process->getOutput())->toBe('')
        ->and($process->getExitCode())->toBe(0);
});
