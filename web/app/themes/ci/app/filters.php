<?php

/**
 * Theme filters.
 */

namespace App;
use WP_Query;

/**
 * Add "… Continued" to the excerpt.
 *
 * @return string
 */
add_filter('excerpt_more', function () {
    return ' &hellip; <a href="' . get_permalink() . '">' . __('Continued', 'sage') . '</a>';
});

/**
 * excluir post destacados del cronológico en portada
 */

add_action( 'pre_get_posts', function($query) {
    if (! is_admin() && $query->is_main_query() && is_home() ) {

        $query->set('meta_key', 'destacado');
        $query->set('meta_value', 0);
    }
});

/**
 * esto es para usar una sola vez.
 * añade el campo destacado a todos los posts
 * o los actualiza a 0 o 1
 * mantener comentado
 */
// $args = array(
//     'fields'          => 'ids',
//     'posts_per_page'  => -1,
//     'post_type'       => 'post',
// );

// $mi_query = new WP_Query( $args );

// $entradas = $mi_query->posts;

// var_dump($entradas);

// foreach( $entradas as $entrada ) {
//     add_post_meta($entrada, 'destacado', 0);
    // update_post_meta( $entrada, 'destacado', 0 );
// }

/**
 * eliminar category del title.
 */

add_filter( 'get_the_archive_title', function ( $title ) {
    if( is_category() ) {
        $title = single_cat_title( '', false );
    }
    return $title;
});
