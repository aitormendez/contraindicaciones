<?php
/**
 * Sage includes
 *
 * The $sage_includes array determines the code library included in your theme.
 * Add or remove files to the array as needed. Supports child theme overrides.
 *
 * Please note that missing files will produce a fatal error.
 *
 * @link https://github.com/roots/sage/pull/1042
 */
$sage_includes = [
  'lib/assets.php',    // Scripts and stylesheets
  'lib/extras.php',    // Custom functions
  'lib/setup.php',     // Theme setup
  'lib/titles.php',    // Page titles
  'lib/wrapper.php',   // Theme wrapper class
  'lib/customizer.php', // Theme customizer
  'lib/wp_bootstrap_navwalker.php' // Incluir navwalker
];

foreach ($sage_includes as $file) {
  if (!$filepath = locate_template($file)) {
    trigger_error(sprintf(__('Error locating %s for inclusion', 'sage'), $file), E_USER_ERROR);
  }

  require_once $filepath;
}
unset($file, $filepath);


// POST POR PÁGINA EN AUTORES SINGLE
function autor_pagesize( $query ) {
    if ( is_admin() || ! $query->is_main_query() )
        return;

    if ( is_author() ) {
        $query->set( 'posts_per_page', 50 );
        return;
    }
}
add_action( 'pre_get_posts', 'autor_pagesize', 1 );


// ELIMINAR "CATEGORIA" DEL TITULO
//--------------------------------

add_filter( 'get_the_archive_title', function ( $title ) {
    if( is_category() ) {
        $title = single_cat_title( '', false );
    }
    elseif( is_archive() ) {
        $title = single_month_title( ' ', false );
    }
    return $title;
});

// EMBED VIDEO YOUTUBE
//--------------------------------




// TINY MCE
// http://www.codigonexo.com/blog/wordpress-programadores/estilos-personalizados-editor-tinymce-wordpress/
// Paso 1: Añade lo siguiente a functions.php:

add_filter( 'mce_buttons_2', 'my_mce_buttons_2' );
function my_mce_buttons_2( $buttons ) {
    array_unshift( $buttons, 'styleselect' );
    return $buttons;
}

// Paso 2: Justo debajo añade un array con tus estilos personalizados:

add_filter( 'tiny_mce_before_init', 'my_mce_before_init' );
function my_mce_before_init( $settings ) {
    $style_formats = array(
    	array(
    		'title' => 'Youtube',
    		'selector' => 'p',
    		'classes' => 'responsive-container'
    	)
    );
    $settings['style_formats'] = json_encode( $style_formats );
    return $settings;
}
