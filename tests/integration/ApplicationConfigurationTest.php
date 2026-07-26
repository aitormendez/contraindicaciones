<?php

declare(strict_types=1);

$projectRoot = dirname(__DIR__, 2);
$fixtureRoot = sys_get_temp_dir() . '/contraindicaciones-dotenv-' . bin2hex(random_bytes(8));
$fixtureConfigDirectory = $fixtureRoot . '/config';
$bootstrapFile = $fixtureRoot . '/bootstrap.php';

if (!mkdir($fixtureConfigDirectory, 0700, true) && !is_dir($fixtureConfigDirectory)) {
    throw new RuntimeException('No se pudo crear el directorio temporal de configuración.');
}

try {
    if (!copy($projectRoot . '/config/application.php', $fixtureConfigDirectory . '/application.php')) {
        throw new RuntimeException('No se pudo copiar la configuración de la aplicación.');
    }

    file_put_contents(
        $fixtureRoot . '/.env',
        implode(PHP_EOL, [
            "DB_NAME='fixture_database'",
            "DB_USER='fixture_user'",
            "DB_PASSWORD='fixture_password'",
            "WP_HOME='https://fixture.example.test'",
            "WP_SITEURL='https://fixture.example.test/wp'",
            '',
        ])
    );

    file_put_contents(
        $bootstrapFile,
        <<<'PHP'
<?php

declare(strict_types=1);

require $argv[1] . '/vendor/autoload.php';

$_ENV = [];
$_SERVER = [];

foreach (['DB_NAME', 'DB_USER', 'DB_PASSWORD', 'WP_HOME', 'WP_SITEURL'] as $name) {
    putenv($name);
}

require $argv[2] . '/config/application.php';

echo json_encode([
    'environment' => [
        'DB_NAME' => Env\env('DB_NAME'),
        'DB_USER' => Env\env('DB_USER'),
        'DB_PASSWORD' => Env\env('DB_PASSWORD'),
    ],
    'constants' => [
        'DB_NAME' => DB_NAME,
        'DB_USER' => DB_USER,
        'DB_PASSWORD' => DB_PASSWORD,
    ],
], JSON_THROW_ON_ERROR);
PHP
    );

    $command = implode(' ', [
        escapeshellarg(PHP_BINARY),
        escapeshellarg($bootstrapFile),
        escapeshellarg($projectRoot),
        escapeshellarg($fixtureRoot),
    ]);
    exec($command . ' 2>&1', $output, $exitCode);

    if ($exitCode !== 0) {
        throw new RuntimeException(implode(PHP_EOL, $output));
    }

    $actual = json_decode(implode(PHP_EOL, $output), true, 512, JSON_THROW_ON_ERROR);
    $expected = [
        'environment' => [
            'DB_NAME' => 'fixture_database',
            'DB_USER' => 'fixture_user',
            'DB_PASSWORD' => 'fixture_password',
        ],
        'constants' => [
            'DB_NAME' => 'fixture_database',
            'DB_USER' => 'fixture_user',
            'DB_PASSWORD' => 'fixture_password',
        ],
    ];

    if ($actual !== $expected) {
        throw new RuntimeException(sprintf(
            "La configuración de base de datos no recibió las variables del .env.\nEsperado: %s\nActual: %s",
            json_encode($expected, JSON_THROW_ON_ERROR),
            json_encode($actual, JSON_THROW_ON_ERROR)
        ));
    }

    echo "Application configuration environment propagation test passed.\n";
} finally {
    foreach ([$bootstrapFile, $fixtureRoot . '/.env', $fixtureConfigDirectory . '/application.php'] as $file) {
        if (is_file($file)) {
            unlink($file);
        }
    }

    if (is_dir($fixtureConfigDirectory)) {
        rmdir($fixtureConfigDirectory);
    }

    if (is_dir($fixtureRoot)) {
        rmdir($fixtureRoot);
    }
}
