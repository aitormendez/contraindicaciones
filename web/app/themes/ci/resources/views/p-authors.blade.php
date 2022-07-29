{{--
  Template Name: Authors Template
--}}

@extends('layouts.app')

@section('content')
  @while(have_posts()) @php(the_post())
  <div class="contenido-wrap d-flex justify-content-center">
    <div class="contenido d-flex flex-wrap abierto">
      @include('partials.page-header')
      @includeFirst(['partials.content-authors-page', 'partials.content'])
    </div>
  </div>
  @endwhile
@endsection

@section('sidebar')
  @include('partials.sidebar')
@endsection
