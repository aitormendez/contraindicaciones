<?php

/**
 * Theme admin.
 */

namespace App;

use App\Support\MixManifest;
use WP_Customize_Manager;

/**
 * Register the `.brand` selector to the blogname.
 *
 * @param  WP_Customize_Manager  $wp_customize
 * @return void
 */
add_action('customize_register', function (WP_Customize_Manager $wp_customize) {
    $wp_customize->get_setting('blogname')->transport = 'postMessage';
    $wp_customize->selective_refresh->add_partial('blogname', [
        'selector' => '.brand',
        'render_callback' => function () {
            bloginfo('name');
        },
    ]);
});

/**
 * Register the customizer assets.
 *
 * @return void
 */
add_action('customize_preview_init', function () {
    wp_enqueue_script(
        'sage/customizer.js',
        MixManifest::fromTheme()->uri('scripts/customizer.js'),
        ['customize-preview'],
        null,
        true
    );
});
