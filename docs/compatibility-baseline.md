# Línea base de compatibilidad de PHP

## Referencia

- Rama: `codex/compatibilidad-php83`
- Commit de partida: `5dc8f5e12084bd8abf7af2cff2fc0bd0e1c68bde`

## Diagnóstico de Composer

El 25 de julio de 2026 se ejecutó:

```sh
composer install --working-dir=web/app/themes/ci --dry-run --no-interaction --no-scripts
```

El comando terminó con código `2` usando PHP `8.5.1`, al no poder instalar el
lockfile en una versión de PHP 8.x. Las restricciones que causan el fallo son:

- El tema requiere `php ^7.2.5`.
- `roots/acorn` está fijado a `v1.1.0` y requiere `php ^7.2.5`.
- Los paquetes `illuminate/*` están fijados a `v7.25.0` y requieren
  `php ^7.2.5`.
- `paragonie/random_compat v9.99.99` requiere `php ^7`.
- `filp/whoops v2.7.3` requiere `php ^5.5.9 || ^7.0`.

Por tanto, la línea base actual no es instalable en PHP 8.3 (ni en la versión
de PHP 8.5.1 usada para esta comprobación).
