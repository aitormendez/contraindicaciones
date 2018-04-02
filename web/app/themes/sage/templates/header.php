<header class="">
  <div class="container-fluid">

    <div class="site-branding hidden-sm hidden-md hidden-lg">
      <div class="logotipo">
        <img src="/app/themes/sage/dist/images/uEA0A-weblog.svg" alt="logotipo contraindicaciones">
      </div>
      <a class="site-title" href="<?= esc_url(home_url('/')); ?>"><?php bloginfo('name'); ?></a>
      <p class="site-description">
        <?php bloginfo('description'); ?>
      </p>
    </div>

    <div class="navbar navbar-default navbar-fixed-top hidden-sm hidden-md hidden-lg">
      <button type="button" class="navbar-toggle" data-toggle="offcanvas" data-target=".navmenu" data-canvas="body">
        <span class="sr-only"><?= __('Toggle navigation', 'sage'); ?></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
        <span class="icon-bar"></span>
      </button>
    </div>

    <nav class="navmenu navmenu-default navmenu-fixed-left offcanvas-xs" role="navigation"
    <?php
    if ( is_admin_bar_showing() ) {
    echo " style='top: 28px;'  ";
    }
    ?>>
      <div class="site-branding hidden-xs">
        <div class="logotipo">
          <img src="/app/themes/sage/dist/images/uEA0A-weblog.svg" alt="logotipo contraindicaciones">
        </div>


        <a class="site-title" href="<?= esc_url(home_url('/')); ?>"><?php bloginfo('name'); ?></a>
        <p class="site-description">
          <?php bloginfo('description'); ?>
        </p>
      </div>
      <div class="sidebar-abajo">
        <div class="row">
          <?php
          if (has_nav_menu('primary_navigation')) :
            wp_nav_menu(['theme_location' => 'primary_navigation', 'walker' => new wp_bootstrap_navwalker(), 'menu_class' => 'nav navbar-nav']);
          endif; ?>
        </div>

         <div class="">
           <?php get_search_form( true ); ?>
         </div>
        <?php get_template_part('templates/sidebar');?>
      </div>

    </nav>
  </div>
</header>
