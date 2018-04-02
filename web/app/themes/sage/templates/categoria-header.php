<?php use Roots\Sage\Titles; ?>

<div class="page-header">
  <?php $cat = get_query_var('cat');
  $yourcat = get_category ($cat); ?>
  <div class="s s-<?php echo $yourcat->slug; ?>"></div>
  <h1><?= Titles\title(); ?></h1>
</div>
