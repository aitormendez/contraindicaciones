<article @php(post_class('gotea'))>
  <header>
    <h2 class="entry-title">
      <a href="{{ get_permalink() }}">
        {!! $title !!}
      </a>
    </h2>

    @include('partials/entry-meta')
  </header>

  <div class="entry-summary">
    @thumbnail('large')
    @php(the_excerpt())
  </div>
</article>
