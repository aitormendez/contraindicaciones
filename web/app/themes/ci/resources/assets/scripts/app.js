/**
 * External Dependencies
 */
import 'jquery';
import 'bootstrap';
import anime from 'animejs';

$(document).ready(() => {
  let viewportHeight = $(window).height(),
  viewportWidth = $(window).width(),
  banner = $('.banner');

  if (viewportWidth >= 768) {
    window.onscroll = function() {
      console.log(window.scrollY);
      if (window.scrollY > 1) {
        banner.addClass('cerrado');
      } else {
        banner.removeClass('cerrado');
      }
    };
  }

});
