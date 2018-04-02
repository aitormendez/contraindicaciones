<div class="central col-md-8 col-lg-6">
  <?php get_template_part('templates/page', 'header'); ?>
  <?php while (have_posts()) : the_post(); ?>
    <?php get_template_part('templates/content'); ?>
  <?php endwhile; ?>
</div>
