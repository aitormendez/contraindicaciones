import anime from 'animejs';

$(document).ready(() => {
  let
    viewportHeight = $(window).height(),
    viewportWidth = $(window).width(),
    banner = $('.banner'),
    sidebar = $('.sidebar'),
    comentBtn = $('.comentarios'),
    secBtn = $('.secciones'),
    colabBtn = $('.colaboradores'),
    archivBtn = $('.archivos'),
    btnSide = $('#btnside'),
    contenido = $('.contenido');

  const sidebarObj = {
    estado: 'abierto',
    archivos: 'plegado',
    colaboradores: 'plegado',
    comentarios: 'plegado',
    comentarios: 'desplegado',

    cerrar: function() {
      this.estado = 'cerrado';
      contenido.removeClass('abierto');
      btnSide.addClass('cerrado');
      anime({
        targets:  '.sidebar',
        translateX: '+100%',
        easing: 'easeOutElastic(1, .6)',
        duration: 333
      });
    },
    abrir: function() {
      this.estado = 'abierto';
      contenido.addClass('abierto');
      btnSide.removeClass('cerrado');
      anime({
        targets:  '.sidebar',
        translateX: '0',
        easing: 'easeOutElastic(1, .6)',
        duration: 333
      });
    },
  }

  // botones menú seleccionan contenido sidebar

  $('.archivos').click(function() {
    console.log('click');
  });


  // botón flecha esconde sidebar

  $("#btnside").click(function() {
    if (sidebarObj.estado == 'cerrado') {
      sidebarObj.abrir();
    } else {
      sidebarObj.cerrar();
    }
  });

    // deslizar items menú en hover

  $("#nav-sidebar .menu-item a").mouseenter(function() {
    let ancho = $(this).width() - viewportWidth /100;
    anime({
      targets:  this,
      translateX: -ancho,
      easing: 'easeOutElastic(1, .6)',
      duration: 333
    });
  });

  $("#nav-sidebar .menu-item a").mouseout(function() {
    anime({
      targets:  this,
      translateX: '0',
      easing: 'easeOutElastic(1, .6)',
      duration: 333
    });
  });


  if (viewportWidth >= 768) {


  }

});
