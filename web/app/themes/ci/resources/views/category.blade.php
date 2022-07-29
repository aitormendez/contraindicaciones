@extends('layouts.app')

@section('content')
  <div class="contenido-wrap d-flex justify-content-center">
    <div class="contenido d-flex flex-wrap abierto justify-content-center">
        @include('partials.page-header')
    </div>
  </div>

  @if (! have_posts())
    <x-alert type="warning">
      {!! __('Sorry, no results were found.', 'sage') !!}
    </x-alert>

    {!! get_search_form(false) !!}
  @endif

  <div class="contenido-wrap d-flex justify-content-center">
    <div class="contenido d-flex flex-wrap abierto justify-content-center">
      <section class="infinite-scroll-container">
        @while(have_posts()) @php(the_post())
          @includeFirst(['partials.content-' . get_post_type(), 'partials.content'])
        @endwhile
      </section>
    </div>
  </div>

  {!! get_the_posts_navigation() !!}
@endsection

@section('sidebar')
  @include('partials.sidebar')
@endsection
