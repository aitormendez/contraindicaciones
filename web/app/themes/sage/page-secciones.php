

<div class="central col-md-8 col-lg-6">
  <?php $terms = get_terms( 'category' );
  if ( ! empty( $terms ) && ! is_wp_error( $terms ) ){
      foreach ( $terms as $term ) {
        if ($term->slug !=="sin-categoria" ){
          $category_id = get_cat_ID( $term->name );
          $category_link = get_category_link( $category_id );
          ?>
          <?php query_posts( array(
            'category_name' => $term->slug,
            'posts_per_page'=> '10')
           ); ?>


              <div class="row seccion">
                <div class="cabecera">
                <?php  echo '<span class="s s-'.$term->slug.'"></span>'; ?>
                <h2><a href="<?php echo esc_url( $category_link ); ?>"><?php echo $term->name ; ?> </a></h2>

                <div class="descripcion">
                  <?php
                  echo '<p class="posts-number">'.$term->count.' entradas</p>';
                  echo category_description(); ?>
                </div>
              </div>
              <ul>
                <?php while ( have_posts() ) : the_post(); ?>
                	<?php get_template_part('templates/content-secciones', 'page'); ?>
                <?php endwhile; wp_reset_query(); ?>
                <li class="ver-todas"><a href="<?php echo esc_url( $category_link ); ?>">Ver todas</a></li>
              </ul>
              </div>
      <?php }
      }
  } ?>
</div>
