

<article <?php post_class(); ?>>
  <header>
    <h2 class="entry-title"><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h2>
    <div class="meta">
      <?php get_template_part('templates/entry-meta'); ?>
    </div>
  </header>


  <div class="gotas">

    <?php
        $gotas = array('g-gota-1', 'g-gota-2', 'g-gota-3', 'g-gota-4', 'g-gota-5', 'g-gota-6', 'g-gota-7', 'g-gota-8',); // array of filenames
        for ($i = 1; $i <= 6; $i++) {
            $g = rand(0, count($gotas)-1);
            $gota = "$gotas[$g]"; ?>
            <span class="g <?php echo $gota; ?>"></span>
        <?php }?>
  </div>
  <div class="luto"></div>



  <div class="entry-summary">
    <?php the_content( "Leer más" , TRUE ); ?>
  </div>
</article>
