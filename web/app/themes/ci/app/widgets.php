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

    public $args = array(
        'before_title'  => '<h3 class="widgettitle">',
        'after_title'   => '</h3>',
        'before_widget' => '<div class="widget-wrap">',
        'after_widget'  => '</div></div>'
    );

    public function widget( $args, $instance ) {

        $autores = wp_list_authors(['echo' => false]);

        echo $args['before_widget'];

        if ( ! empty( $instance['title'] ) ) {
            echo $args['before_title'] . apply_filters( 'widget_title', $instance['title'] ) . $args['after_title'];
        }

        echo '<ul class="textwidget">';
        echo esc_html__( $instance['text'], 'text_domain' );

        echo $autores .'</ul>';
        echo $args['after_widget'];
    }

    public function form( $instance ) {

        $title = ! empty( $instance['title'] ) ? $instance['title'] : esc_html__( '', 'text_domain' );
        ?>
        <p>
        <label for="<?php echo esc_attr( $this->get_field_id( 'title' ) ); ?>"><?php echo esc_html__( 'Title:', 'text_domain' ); ?></label>
            <input class="widefat" id="<?php echo esc_attr( $this->get_field_id( 'title' ) ); ?>" name="<?php echo esc_attr( $this->get_field_name( 'title' ) ); ?>" type="text" value="<?php echo esc_attr( $title ); ?>">
        </p>
        <?php

    }

    public function update( $new_instance, $old_instance ) {

        $instance = array();

        $instance['title'] = ( !empty( $new_instance['title'] ) ) ? strip_tags( $new_instance['title'] ) : '';

        return $instance;
    }

}

function load_widget() {
    register_widget( 'App\\Autores_Widget' );
}
add_action( 'widgets_init', __NAMESPACE__ . '\\load_widget' );
