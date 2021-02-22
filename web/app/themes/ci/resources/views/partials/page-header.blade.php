<div class="page-header">
  @if (is_category())
      @php
        $clase = get_queried_object()->slug;
      @endphp
      <div class="d-flex flex-column align-items-center">
        <div class="icon {{ $clase }}"></div>
        <h1 class="mt-3">{!! $title !!}</h1>
      </div>
  @else
    <h1>{!! $title !!}</h1>
  @endif
</div>
