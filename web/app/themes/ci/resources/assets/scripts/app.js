/**
 * External Dependencies
 */
import 'jquery';
import 'bootstrap';
import './sidebar.js';
var InfiniteScroll = require('infinite-scroll');
import anime from 'animejs';

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

  main.on( 'append', function( body, path, items, response ) {
    // crearGotas(items);
  });


  // movimiento browniano
  // -----------------------------------------------

  let brownies = $('.browni');

  function browni() {
    $('.browniano').on('animationiteration webkitAnimationIteration oanimationiteration MSAnimationIteration', function(e) {
      let deg = 0;
      deg = deg + Math.floor(Math.random() * 40 - 20);
      $(this).css({top: Math.floor(Math.random() * 5 - 3) + 'px'},0);
      $(this).css({left: Math.floor(Math.random() * 5 -3) + 'px'},0);
      $(this).css({transform: 'rotate(' + deg + 'deg)'},0);
    });

  }

  brownies.mouseenter(function() {
    $(this).addClass('browniano');
    browni();
  })

  brownies.mouseleave(function() {
    $(this).removeClass('browniano');
  })


  // gotas
  // -----------------------------------------------

  function htmlToElement(html) {
    var template = document.createElement('template');
    template.innerHTML = html;
    return template.content.firstChild;
  }

  let gota = htmlToElement('<div class="gota"><div class="gota-rastro"><div class="rastro"></div></div><div class="gota-cabeza"></div></div>');

  let gotean = document.getElementsByClassName('gotea');

  // esto creaba todas las gotas a la vez
  // function crearGotas(nodeList) {
  //   for (let i = 0; i < nodeList.length; i++) {

  //     let numGotas = Math.floor(Math.random() * 5);

  //     for (let index = 0; index < numGotas; index++) {
  //       nodeList[i].appendChild(gota.cloneNode(true));
  //     }

  //     let estasGotas = nodeList[i].getElementsByClassName('gota');

  //     for (let g = 0; g < estasGotas.length; g++) {
  //       let posX = Math.random() * 90 + '%';
  //       let laGota = estasGotas[g];
  //       laGota.style.left = posX;
  //       let elRastro = laGota.getElementsByClassName('gota-rastro');
  //       let long = Math.random() * 100 + 'px';
  //       let dur = Math.random() * 5000 + 1000;
  //       anime({
  //         targets: elRastro,
  //         height: long,
  //         easing: 'easeInOutQuad',
  //         duration: dur,
  //       });

  //     }
  //   }
  // }
  // crearGotas(gotean);



  function crearGotas(node) {
      let numGotas = Math.floor(Math.random() * 5);

      for (let index = 0; index < numGotas; index++) {
        node.appendChild(gota.cloneNode(true));
        console.log(node);
      }

      let gotas = node.getElementsByClassName('gota');

      for (let g = 0; g < gotas.length; g++) {
        let posX = Math.random() * 90 + '%';
        let laGota = gotas[g];
        laGota.style.left = posX;
        let elRastro = laGota.getElementsByClassName('gota-rastro');
        let long = Math.random() * 100 + 'px';
        let dur = Math.random() * 5000 + 1000;
        anime({
          targets: elRastro,
          height: long,
          easing: 'easeInOutQuad',
          duration: dur,
        });

      }
      node.setAttribute("class", `goteando ${node.classList}`)
  }

  crearGotas(gotean[0]);

  // comprobar si está en viewport
  // https://www.javascripttutorial.net/dom/css/check-if-an-element-is-visible-in-the-viewport/

  function isInViewport(el) {
    const rect = el.getBoundingClientRect();
    return (
        rect.top >= 0 && rect.top <= (window.innerHeight || document.documentElement.clientHeight)
      )
  }

  document.addEventListener('scroll', function () {

    for (let i = 0; i < gotean.length; i++) {

      let gotea = gotean[i];

      if (isInViewport(gotea) && !gotea.classList.contains('goteando')) {
        crearGotas(gotea);
        // gotea.setAttribute("class", `goteando ${gotea.classList}`);
      }
    }
  });


});

