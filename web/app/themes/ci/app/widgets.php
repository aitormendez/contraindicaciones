<?php

/**
 * Theme widgets.
 */

namespace App;

class Autores_Widget extends \WP_Widget {
    function __construct() {

        $widget_ops = [
            'name' => 'Autores',
            'description' => 'Lista HTML de autores'
        ];
        parent::__construct( 'Autores_Widget', 'Autores', $widget_ops );
    }
}

function load_widget() {
    register_widget( 'App\\Autores_Widget' );
}
add_action( 'widgets_init', __NAMESPACE__ . '\\load_widget' );
