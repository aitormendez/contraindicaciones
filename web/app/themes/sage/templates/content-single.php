<?php while (have_posts()) : the_post(); ?>
  <article <?php post_class(); ?>>
    <header>
      <h1 class="entry-title"><?php the_title(); ?></h1>
      <?php get_template_part('templates/entry-meta'); ?>

    </header>
    <div class="gotas">

      <?php
          $gotas = array('g-gota-1', 'g-gota-2', 'g-gota-3', 'g-gota-4', 'g-gota-5', 'g-gota-6', 'g-gota-7', 'g-gota-8',); // array of filenames
          for ($i = 1; $i <= 5; $i++) {
              $g = rand(0, count($gotas)-1);
              $gota = "$gotas[$g]"; ?>
              <span class="g <?php echo $gota; ?>"></span>
          <?php }?>
    </div>
    <div class="luto"></div>







    <div class="entry-content">
      <?php the_content(); ?>
    </div>
    <footer>
      <?php wp_link_pages(['before' => '<nav class="page-nav"><p>' . __('Pages:', 'sage'), 'after' => '</p></nav>']); ?>
    </footer>
    <?php comments_template('/templates/comments.php'); ?>
  </article>
<?php endwhile; ?>
