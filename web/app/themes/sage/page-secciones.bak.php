


<?php $terms = get_terms( 'category' );
if ( ! empty( $terms ) && ! is_wp_error( $terms ) ){
    foreach ( $terms as $term ) {
      if ($term->slug !=="sin-categoria" ){
        $category_id = get_cat_ID( $term->name );
        $category_link = get_category_link( $category_id );
        ?>

        <div class="row seccion">
        <?php  echo '<span class="s s-'.$term->slug.'"></span>'; ?>
        <h2><a href="<?php echo esc_url( $category_link ); ?>"><?php echo $term->name ; ?> </a></h2>

        <?php query_posts( array(
          'category_name' => $term->slug,
          'posts_per_page'=> '10')
         ); ?>
         <div class="descripcion">
           <?php
           $numero_de_posts = wp_count_posts();
           echo $numero_de_posts->publish;
           echo '<span class="posts-number">'.'</span>';
           echo category_description() ?>
         </div>
         <?php while ( have_posts() ) : the_post(); ?>
         	<?php get_template_part('templates/content-secciones', 'page'); ?>
         <?php endwhile; wp_reset_query(); ?>
      </div>
    <?php }
    }
} ?>
