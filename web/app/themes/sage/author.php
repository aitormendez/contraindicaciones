

<div class="central col-md-8 col-lg-6">

<?php if (!have_posts()) : ?>
  <div class="alert alert-warning">
    <?php _e('Sorry, no results were found.', 'sage'); ?>
  </div>
  <?php get_search_form(); ?>
<?php endif; ?>

<?php
$curauth = (isset($_GET['author_name'])) ? get_user_by('slug', $author_name) : get_userdata(intval($author));
?>
<div class="cabecera">
  <h2>
    <?php echo $curauth->nickname; ?>
  </h2>
  <?php if ($curauth->user_url != '') { ?>
    <p class="web"><a href="<?php echo $curauth->user_url; ?>"> <?php echo $curauth->user_url ?></a></p>
  <?php } ?>

  <?php if ($curauth->description != '') {
    echo '<p class="bio">'.$curauth->description.'</p>';
  } ?>
</div>

<ul <?php post_class(); ?>>
  <?php while (have_posts()) : the_post(); ?>
    <?php get_template_part('templates/content-author', get_post_type() != 'post' ? get_post_type() : get_post_format()); ?>
  <?php endwhile; ?>
  <?php the_posts_navigation(); ?>
</ul>
</div>
