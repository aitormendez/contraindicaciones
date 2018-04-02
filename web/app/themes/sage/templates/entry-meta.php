
<div class="iconos-seccion">
  <?php foreach(get_the_category() as $category) { ?>
  <span class="icn-seccion s s-<?php echo $category->slug; ?>"></span>
  <?php } ?>
</div>

  <p>Publicado en <?php the_category( ', ' ); ?></p>

  <time class="updated" datetime="<?= get_post_time('c', true); ?>"><?= get_the_date(); ?></time>
<p class="byline author vcard"><?= __('By', 'sage'); ?> <a href="<?= get_author_posts_url(get_the_author_meta('ID')); ?>" rel="author" class="fn"><?= get_the_author(); ?></a></p>
