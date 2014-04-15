class ContextMenu
  @position: (x, y, w, h, from_mouse) ->
    position = {}
    ww = window.innerWidth
    wh = window.innerHeight

    if x + w > ww or !from_mouse
      position.left = x - w
    else
      position.left = x

    if y + h > wh and y - h > 0 and from_mouse
      position.top = y - h
    else
      position.top = y

    position


  close_all_context_menus: ->
    $('[data-context-holder]')
      .trigger('context:close')
      .remove()

    $('[data-context-button].opened')
      .removeClass('opened')
    true

  open_context_menu_for: (element, x, y, from_mouse = true) ->
    @close_all_context_menus()

    if $(element).data('context-ajax')?
      $.ajax
        url: $(element).data('context-ajax')
        data: '_'
        type: 'POST'
        beforeSend: (jqXHR, settings) ->
          $(element).trigger('before:context:ajax', [jqXHR, settings, from_mouse])
        success: (data) ->
          $(data)
            .openContextMenu(x, y, from_mouse)
    else
      $(element)
        .find('[data-context-target]')
        .clone()
        .openContextMenu(x, y, from_mouse)

  constructor: ->
    $.fn.openContextMenu = (x, y, from_mouse = true) ->
      el = this
        .first()
        .attr('data-context-holder', true)
        .appendTo(document.body)
        .show()

      position = ContextMenu.position(x, y, el.outerWidth(), el.height(), from_mouse)

      el
        .toggleClass('from-mouse', from_mouse)
        .toggleClass('from-button', !from_mouse)
        .css(position)
        .trigger('context:open')

    $(document).on 'contextmenu', '[data-context]', (event) =>
      event.preventDefault()
      return if $(event.target).closest('[data-context-target]').length > 0

      @open_context_menu_for(event.currentTarget, event.pageX,  event.pageY)
      event.stopPropagation();

    $(document).on 'click', (event) =>
      @close_all_context_menus()

    $(document).on 'click', '[data-context-holder] a', (event) =>
      @close_all_context_menus()

    $(window).on 'blur', =>
      @close_all_context_menus()

    $(document).on 'click', 'a[data-context-button]', (event) =>
      event.preventDefault()
      event.stopPropagation();
      button = $(event.currentTarget)

      if button.hasClass('opened')
        @close_all_context_menus()
      else
        el = button.closest('[data-context]')
        offset = button.offset()
        @open_context_menu_for(el, offset.left, offset.top, false)
        button.addClass('opened')
      false

jQuery -> ( window.context_menu = new ContextMenu() )
