

<div class="central col-md-8 col-lg-6">


<?php
$user_query = new WP_User_Query( array( 'who' => 'authors', 'blog_id' => 0 ) );
$authors = $user_query->get_results();
if (!empty($authors)) {
    echo '<ul>';
    // loop trough each author
    foreach ($authors as $author) {

        $author_info = get_userdata($author->ID); ?>
        <div class="cabecera">
        <h2><a href="<?= get_author_posts_url($author_info->ID); ?>"><?php echo $author_info->display_name ; ?> </a></h2>

        <?php
        echo '<p class="numero-posts">'.count_user_posts( $author_info->ID ).' entradas</p>'; ?>
      </div>

        <?php query_posts( array(
          'author' => $author_info->ID,
          'posts_per_page'=> '10')
         ); ?>
         <ul class="entradas-autor">
         <?php while ( have_posts() ) : the_post(); ?>
          <?php get_template_part('templates/content-secciones', 'page'); ?>
        <?php endwhile; wp_reset_query(); ?>
        <li class="ver-todas"><a href="<?= get_author_posts_url($author_info->ID); ?>">Ver todas</a></li>
        </ul>
        <?php
    }
   } ?>
</div>
