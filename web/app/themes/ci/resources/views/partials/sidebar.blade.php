<div class="botones d-none d-md-flex">
  <nav class="nav-sidebar d-none d-md-block">
    @if (has_nav_menu('primary_navigation'))
      {!! wp_nav_menu([
        'theme_location' => 'primary_navigation',
        'menu_id' => 'nav-sidebar',
        'menu_class' => 'nav nav-sidebar',
        'echo' => false,
        'container' => false
      ]) !!}
    @endif

    <a href="#" id="btnside">
      @svg('images.flecha-izq')
      @svg('images.flecha-der')
    </a>
  </nav>
</div>

@php(dynamic_sidebar('sidebar-primary'))

