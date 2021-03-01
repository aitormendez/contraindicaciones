/**
 * External Dependencies
 */
import 'jquery';
import 'bootstrap';
import './sidebar.js';
var InfiniteScroll = require('infinite-scroll');

// import anime from 'animejs';

$(document).ready(() => {
  let viewportHeight = $(window).height(),
  viewportWidth = $(window).width(),
  banner = $('.banner');

  if (viewportWidth >= 768) {
    window.onscroll = function() {
      if (window.scrollY > 1) {
        banner.addClass('cerrado');
      } else {
        banner.removeClass('cerrado');
      }
    };
  }

});

    // infinite-scroll
    // -----------------------------------------------

    let buttonCont = $('.button-container');


    let main = new InfiniteScroll( '.infinite-scroll-container', {
      path: '.nav-previous a',
      append: 'article',
      history: false,
      hideNav: '.posts-navigation',
      button: '.view-more-button',
      status: '.page-load-status',
      debug: true,
    });

    // function onPageLoad() {
    //   if ( main.loadCount == 1 ) {
    //     main.options.loadOnScroll = false;
    //     buttonCont.removeClass('d-none');
    //     buttonCont.addClass('d-flex');
    //     main.off( 'load', onPageLoad );
    //   }
    // }

    // function onAppend() {
    //   botonesDesplegar = $('.btn-desplegar');
    //   botonesDesplegar.click(desplegar);
    // }

    // main.on( 'load', onPageLoad );
    // main.on( 'append', onAppend );

    // main.on( 'last', function() {
    //   buttonCont.hide();
    // });


    // hamburger
    // -----------------------------------------------

    // $('.hamburger').click(function() {
    //   $(this).toggleClass('is-active');
    // });
