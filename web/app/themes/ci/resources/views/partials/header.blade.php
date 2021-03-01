<header class="banner">
  <div class="container-fluid">

    <div class="row brand align-items-center flex-column flex-md-row">
      <a class="logo mr-sm-4" href="{{ home_url('/') }}">
        @svg('images.weblog', ['class' => 'browni'])
      </a>
      <a class="nombre mr-sm-4" href="{{ home_url('/') }}">
        {{ $siteName }}
      </a>
      <div class="description text-center text-md-left">
        {!! $siteDescription !!}
      </div>
    </div>

    <nav class="nav-mobile mt-3 d-md-none">
      @if (has_nav_menu('mobile_navigation'))
        {!! wp_nav_menu(['theme_location' => 'mobile_navigation', 'menu_class' => 'nav', 'echo' => false]) !!}
      @endif
    </nav>

  </div>

</header>

