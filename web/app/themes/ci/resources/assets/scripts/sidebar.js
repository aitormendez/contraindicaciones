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
    contenido = $('.contenido'),
    solapaAutores = $('.widget_autores_widget'),
    solapaArchivos = $('.widget_archive'),
    solapaCategorias = $('.widget_categories'),
    solapaComentarios = $('.widget_recent_comments')
    ;

  // objeto sidebar

  const sidebarObj = {
    estado: 'abierto',

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

  //solapas interiores sidebar

  const solapasSidebar = {
    mostrando: 'comentarios',
    archivos: function() {
      this.mostrando = 'archivos';
      solapaArchivos.removeClass("d-none");
      solapaAutores.addClass("d-none");
      solapaCategorias.addClass("d-none");
      solapaComentarios.addClass("d-none");
    },
    autores: function() {
      this.mostrando = 'archivos';
      solapaArchivos.addClass("d-none");
      solapaAutores.removeClass("d-none");
      solapaCategorias.addClass("d-none");
      solapaComentarios.addClass("d-none");
    },
    categorias: function() {
      this.mostrando = 'archivos';
      solapaArchivos.addClass("d-none");
      solapaAutores.addClass("d-none");
      solapaCategorias.removeClass("d-none");
      solapaComentarios.addClass("d-none");
    },
    comentarios: function() {
      this.mostrando = 'archivos';
      solapaArchivos.addClass("d-none");
      solapaAutores.addClass("d-none");
      solapaCategorias.addClass("d-none");
      solapaComentarios.removeClass("d-none");
    }
  }

  // botones menú seleccionan contenido sidebar

  $('.nav-sidebar .archivos a').click(function() {
    solapasSidebar.archivos();
  });
  $('.nav-sidebar .comentarios a').click(function() {
    solapasSidebar.comentarios();
  });
  $('.nav-sidebar .colaboradores a').click(function() {
    solapasSidebar.autores();
  });
  $('.nav-sidebar .secciones a').click(function() {
    solapasSidebar.categorias();
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
