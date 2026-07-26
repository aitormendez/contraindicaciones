<?php

declare(strict_types=1);

$projectRoot = dirname(__DIR__, 2);
$fixtureRoot = sys_get_temp_dir() . '/contraindicaciones-dotenv-' . bin2hex(random_bytes(8));
$fixtureConfigDirectory = $fixtureRoot . '/config';
$bootstrapFile = $fixtureRoot . '/bootstrap.php';

function runConfigurationScenario(
    string $bootstrapFile,
    string $projectRoot,
    string $fixtureRoot,
    array $environment,
    array $expectedDatabaseValues
): array {
    $process = proc_open(
        [
            PHP_BINARY,
            $bootstrapFile,
            $projectRoot,
            $fixtureRoot,
            $expectedDatabaseValues['DB_NAME'],
            $expectedDatabaseValues['DB_USER'],
            $expectedDatabaseValues['DB_PASSWORD'],
        ],
        [
            1 => ['pipe', 'w'],
            2 => ['pipe', 'w'],
        ],
        $pipes,
        null,
        $environment
    );

    if (!is_resource($process)) {
        throw new RuntimeException('No se pudo iniciar el bootstrap aislado.');
    }

    $stdout = stream_get_contents($pipes[1]);
    $stderr = stream_get_contents($pipes[2]);
    fclose($pipes[1]);
    fclose($pipes[2]);
    $exitCode = proc_close($process);

    if ($exitCode !== 0) {
        throw new RuntimeException(sprintf(
            'El bootstrap aislado falló (código %d; stdout=%s; stderr=%s).',
            $exitCode,
            $stdout === '' ? 'vacío' : 'presente',
            $stderr === '' ? 'vacío' : 'presente'
        ));
    }

    return [
        'result' => json_decode($stdout, true, 512, JSON_THROW_ON_ERROR),
        'stdout' => $stdout,
        'stderr' => $stderr,
    ];
}

function collectFailedChecks(array $expected, mixed $actual, string $prefix = ''): array
{
    $failedChecks = [];

    foreach ($expected as $name => $expectedValue) {
        $path = $prefix === '' ? (string) $name : $prefix . '.' . $name;
        $actualValue = is_array($actual) && array_key_exists($name, $actual) ? $actual[$name] : null;

        if (is_array($expectedValue)) {
            $failedChecks = array_merge($failedChecks, collectFailedChecks($expectedValue, $actualValue, $path));
        } elseif ($actualValue !== $expectedValue) {
            $failedChecks[] = $path;
        }
    }

    return $failedChecks;
}

function assertScenarioResult(string $scenario, array $execution, array $sensitiveMarkers): void
{
    foreach ($sensitiveMarkers as $marker) {
        if (str_contains($execution['stdout'], $marker) || str_contains($execution['stderr'], $marker)) {
            throw new RuntimeException(sprintf(
                'El escenario %s expuso un valor sensible en la salida del proceso.',
                $scenario
            ));
        }
    }

    $expected = [
        'database_url_absent' => true,
        'environment' => [
            'DB_NAME' => true,
            'DB_USER' => true,
            'DB_PASSWORD' => true,
        ],
        'constants' => [
            'DB_NAME' => true,
            'DB_USER' => true,
            'DB_PASSWORD' => true,
        ],
    ];
    $failedChecks = collectFailedChecks($expected, $execution['result']);

    if ($failedChecks !== []) {
        throw new RuntimeException(sprintf(
            'Fallaron comprobaciones seguras en %s: %s.',
            $scenario,
            implode(', ', $failedChecks)
        ));
    }
}

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

putenv('DATABASE_URL');

require $argv[2] . '/config/application.php';

$expectedDatabaseValues = [
    'DB_NAME' => $argv[3],
    'DB_USER' => $argv[4],
    'DB_PASSWORD' => $argv[5],
];
$environmentChecks = [];
$constantChecks = [];

foreach ($expectedDatabaseValues as $name => $expectedValue) {
    $environmentValue = Env\env($name);
    $constantValue = constant($name);
    $environmentChecks[$name] = is_string($environmentValue) && hash_equals($expectedValue, $environmentValue);
    $constantChecks[$name] = is_string($constantValue) && hash_equals($expectedValue, $constantValue);
}

echo json_encode([
    'database_url_absent' => Env\env('DATABASE_URL') === null,
    'environment' => $environmentChecks,
    'constants' => $constantChecks,
], JSON_THROW_ON_ERROR);
PHP
    );

    $fixtureDatabaseValues = [
        'DB_NAME' => 'fixture_database',
        'DB_USER' => 'fixture_user',
        'DB_PASSWORD' => 'fixture_password',
    ];
    $inheritedDatabaseUrl = 'mysql://inherited_user:inherited_password@fixture-db.example.test/inherited_database';
    $isolatedExecution = runConfigurationScenario(
        $bootstrapFile,
        $projectRoot,
        $fixtureRoot,
        ['DATABASE_URL' => $inheritedDatabaseUrl],
        $fixtureDatabaseValues
    );
    assertScenarioResult(
        'DATABASE_URL heredada',
        $isolatedExecution,
        [$inheritedDatabaseUrl, 'inherited_user', 'inherited_password', 'inherited_database']
    );

    $externalDatabaseName = 'external_database_marker';
    $conflictExecution = runConfigurationScenario(
        $bootstrapFile,
        $projectRoot,
        $fixtureRoot,
        ['DB_NAME' => $externalDatabaseName],
        array_merge($fixtureDatabaseValues, ['DB_NAME' => $externalDatabaseName])
    );
    assertScenarioResult('variable externa inmutable', $conflictExecution, [$externalDatabaseName]);

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
