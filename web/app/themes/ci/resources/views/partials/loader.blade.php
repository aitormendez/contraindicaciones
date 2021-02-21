<div class="row">
  <div class="col-12 page-load-status d-flex justify-content-center">
    <div class="infinite-scroll-request py-3" style="display: none">
      <p>{{ __('Loading', 'sage') }}</p>
    </div>
    <p class="infinite-scroll-last py-3" style="display: none">{{ __('End of content', 'sage') }}</p>
    <p class="infinite-scroll-error py-3" style="display: none">{{ __('There is no more pages to load', 'sage') }}</p>
  </div>

  <div class="col-12 button-container d-none justify-content-center py-3">
    <button class="view-more-button boton">{{ __('Load more', 'sage') }}</button>
  </div>
</div>
