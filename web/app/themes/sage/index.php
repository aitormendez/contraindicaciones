
<?php // first loop to display only my single, MOST RECENT sticky post



$sticky = get_option('sticky_posts');
$mi_query_sticky = new WP_Query(array(
    'post__in'            => $sticky,
    'order'               => 'DESC'
  )); ?>

<?php if(!is_front_page()) {
    get_template_part('templates/page', 'header');
  } ?>

  <?php if (!have_posts()) : ?>
    <div class="alert alert-warning">
      <?php _e('Sorry, no results were found.', 'sage'); ?>
    </div>
    <?php get_search_form(); ?>
  <?php endif; ?>

<div class="stickies" <?php
if ( is_admin_bar_showing() ) {
echo " style='top: 28px;'  ";
}
?> >

  <div class="cabecera">
    <p>
      Destacados
    </p>


  </div>
  <?php while ($mi_query_sticky->have_posts()) : $mi_query_sticky->the_post(); ?>
    <?php get_template_part('templates/content', get_post_type() != 'post' ? get_post_type() : get_post_format()); ?>

  <?php endwhile; wp_reset_query(); ?>
</div>


<div class="entradas"  <?php
if ( is_admin_bar_showing() ) {
echo " style='margin-top: 28px;'  ";
}
?>>
  <div class="cabecera">
    <p>
      Entradas
    </p>
  </div>
  <?php $mi_query_sin_sticky = new WP_Query( array(
      'post__not_in'   => get_option( 'sticky_posts' ),
      'posts_per_page' => '10',
      'paged'          => ( get_query_var('paged') ) ? get_query_var('paged') : 1,
    )); ?>

  <?php while ($mi_query_sin_sticky->have_posts()) : $mi_query_sin_sticky->the_post(); ?>
    <?php get_template_part('templates/content', get_post_type() != 'post' ? get_post_type() : get_post_format()); ?>
  <?php endwhile;?>

  <?php the_posts_navigation(); ?>

</div>
