<header class="banner">
  <div class="container-fluid">

    <div class="row brand align-items-center flex-column flex-md-row">
      <a class="logo mr-sm-4" href="{{ home_url('/') }}">
        @svg('images.weblog')
      </a>
      <a class="nombre mr-sm-4" href="{{ home_url('/') }}">
        {{ $siteName }}
      </a>
      <div class="description text-center text-md-left">
        {!! $siteDescription !!}
      </div>
    </div>

    <nav class="nav-primary mt-3 mt-md-0">
      @if (has_nav_menu('primary_navigation'))
        {!! wp_nav_menu(['theme_location' => 'primary_navigation', 'menu_class' => 'nav', 'echo' => false]) !!}
      @endif
    </nav>

  </div>
</header>

