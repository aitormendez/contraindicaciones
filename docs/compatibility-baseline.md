# Validación integrada de compatibilidad con PHP 8.3

## Referencia y alcance

- Fecha de validación: 25 de julio de 2026.
- Rama: `codex/compatibilidad-php83`.
- Commit validado: `ecc98969a7ddb2fd865232e453984a04407d6a4e`.
- Origen de datos: copia temporal del release productivo
  `/srv/www/contraindicaciones.net/releases/20230712164651` y de sus uploads
  compartidos, obtenida por SSH en modo de solo lectura.
- Producción no se modificó. El volcado, los uploads, las credenciales locales y
  los datos editoriales de prueba no se añadieron al repositorio y se eliminaron
  al terminar.

La validación se ejecutó en una red Docker aislada y sin publicar la base de
datos ni SMTP. Solo se expusieron a `127.0.0.1` el sitio temporal y la interfaz
de Mailpit.

## Entorno validado

| Componente | Versión o configuración |
| --- | --- |
| PHP | `8.3.32` |
| Composer | `2.9.3` |
| WordPress | `7.0.2` |
| WP-CLI | `2.12.0` |
| MariaDB | `10.11.18` |
| Acorn | `6.2.0` |
| Node.js / Yarn | `14.21.3` / `1.22.19` |
| URL de prueba | `http://127.0.0.1:18083` |

No se pudo asignar `contraindicaciones.test` ni terminar TLS sin privilegios
del sistema. Se usó el origen loopback anterior con el mismo código, base de
datos y uploads; por tanto, HTTPS y la configuración Nginx/Trellis quedan para
la validación de infraestructura.

## Instalación reproducible

Antes de instalar se retiraron únicamente estos directorios ignorados del
worktree: `vendor`, `web/app/themes/ci/vendor`,
`web/app/themes/ci/node_modules` y `web/app/themes/ci/dist`.

Los tres comandos exigidos se ejecutaron desde cero y terminaron con código
`0`:

```sh
composer install --no-interaction --prefer-dist
composer install --working-dir=web/app/themes/ci --no-interaction --prefer-dist
web/app/themes/ci/scripts/build-production.sh
```

El build produjo y verificó `dist/mix-manifest.json` y los assets de scripts y
estilos previstos. Permanecen avisos no bloqueantes ya conocidos: la clase
`App\Autores_Widget` no cumple PSR-4, Browserslist está desactualizado y Yarn
informa de metadatos o peer dependencies legacy. Ningún comando terminó con
error.

## Restauración y WP-CLI

Se restauraron en el entorno aislado 23 tablas y 4.822 ficheros de uploads. La
base de datos de origen ocupaba aproximadamente 45 MB y la copia de uploads,
aproximadamente 1,2 GB. No se registraron nombres de usuarios, correos,
credenciales ni contenido privado en esta evidencia.

Resultados:

```text
wp core update-db                         código 0; esquema 49752 -> 61833
wp core verify-checksums                  código 0
wp plugin list --fields=name,status,version  código 0
wp theme list --fields=name,status,version   código 0
wp cron event list --due-now              código 0
wp cron event run --due-now               código 0; 7 eventos ejecutados
```

El tema `ci` `10.0.0-dev` quedó activo. También quedaron activos ACF Pro
`6.8.6`, Akismet `5.7`, Favicon by RealFaviconGenerator `1.3.49`, Safe SVG
`2.4.0`, The SEO Framework `5.1.4` y WP-Optimize `4.6.0`, además de los tres
mu-plugins de Bedrock previstos.

## Matriz funcional

El smoke HTTP terminó con código `0`:

```text
200 /
200 /wp/wp-login.php
200 /?s=arte
200 /feed/
200 /wp-json/
200 /robots.txt
```

`/sitemap.xml` devolvió `200`, `text/xml` y una estructura `urlset` válida;
`/robots.txt` devolvió `200`, `text/plain` y directivas `User-agent`.

Con Playwright se comprobaron correctamente:

- acceso al escritorio de WordPress;
- creación, edición, guardado, publicación y vista previa de una entrada
  temporal en Gutenberg;
- subida y registro de un PNG temporal en la biblioteca de medios;
- publicación y visualización de un comentario temporal;
- envío con `wp_mail()`, interceptado por Mailpit sin entrega externa.

La entrada, el comentario, el adjunto y el usuario local creados para la prueba
se eliminaron y se verificó su ausencia antes de destruir el entorno.

## Comparación visual

Se compararon producción y la copia local en escritorio (`1440x1000`) y móvil
(`390x844`). No se observaron regresiones bloqueantes de estructura,
tipografía, imágenes ni adaptación responsive. La posición instantánea de las
gotas decorativas varía por su animación y no constituye una diferencia de
layout.

Evidencias guardadas en el repositorio principal de migración, bajo
`docs/paperclip/contraindicaciones-validation/`:

- `production-desktop.png` y `local-desktop.png`;
- `production-mobile.png` y `local-mobile.png`;
- `local-draft-preview.png`.

En páginas de entrada individual, tanto producción como local registran los
mismos dos errores JavaScript relacionados con Infinite Scroll y un nodo DOM
ausente. Al reproducirse sin cambios en producción se consideran deuda previa,
no una regresión de esta rama. El editor de WordPress no registró errores de
consola.

## Logs y puerta de salida

`WP_DEBUG_LOG` resolvió a `/tmp/wordpress-debug.log`. Tras separar los fallos
iniciales del arnés y repetir la batería limpia, el log de WordPress, el log de
Sage y el log del servidor registraron cero fatales, excepciones no controladas,
warnings, deprecations o notices.

La puerta final terminó con código `0` en:

- instalación Composer limpia, `composer validate --strict`, auditoría,
  requisitos de plataforma y simulación de instalación;
- Pest: 3 tests y 6 aserciones;
- Pint y `composer lint`: 23 ficheros fuente limpios;
- lint de sintaxis PHP sobre `app`, `config`, `tests` y puntos de entrada;
- build de producción y verificador del manifiesto;
- WP-CLI, cron, smoke HTTP, sitemap y robots;
- comparación visual y recorridos editoriales.

El `composer test` global de la raíz no forma parte de esta puerta: su
`phpcs.xml` heredado analiza plugins de terceros y ficheros generados. Con el
límite por defecto agota 128 MB y con 512 MB informa cientos de miles de
incidencias de estilo ya inventariadas en la Tarea 2. La ejecución adicional
confirmó el mismo problema de alcance; debe corregirse en una tarea específica
sin mezclarlo con la compatibilidad funcional.

Pint también detecta el PHP generado `dist/scripts/manifest.asset.php` cuando
`dist` existe. La puerta se ejecutó en el orden del plan —Pint sobre fuentes y
build después— porque `dist` está ignorado, se regenera y no pertenece al
alcance fuente.

## Conclusión

La rama es instalable y ejecutable con PHP 8.3 y supera la puerta integrada
definida para iniciar el plan de infraestructura. Quedan como riesgos aceptados
la validación posterior de HTTPS/Nginx/Trellis, los avisos del toolchain legacy,
el alcance incorrecto del PHPCS global y los errores JavaScript preexistentes
de las páginas individuales.
