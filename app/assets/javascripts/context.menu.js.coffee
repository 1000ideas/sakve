class ContextMenu
  close_all_context_menus: (except = null) ->
    $('[data-context-target]:visible')
      .not(except)
      .hide()
      .removeClass('from-mouse')

  open_context_menu_for: (element, x, y) ->
    @close_all_context_menus()
    menu = $(element).find('[data-context-target]')

    menu
      .addClass('from-mouse')
      .css(top: y, left: x)
      .show()

  constructor: ->
    # $(document).on 'click', '[data-context-target] a', ->
      # console.log(this)

    $(document).on 'contextmenu', '[data-context]', (event) =>
      event.preventDefault()
      return if $(event.target).closest('[data-context-target]').length > 0

      offset = $(event.currentTarget).offset()

      @open_context_menu_for(event.currentTarget, $(document).scrollLeft() + event.clientX - offset.left,  $(document).scrollTop() + event.clientY - offset.top)

    $(document).on 'click', (event) =>
      # return if $(event.target).closest('[data-context-target]').length > 0
      return if $(event.target).closest('[data-context-button]').length > 0
      @close_all_context_menus()

    $(window).on 'blur', =>
      @close_all_context_menus()

    $(document).on 'click', 'a[data-context-button]', (event) =>
      event.preventDefault()

      menu = $(event.currentTarget)
        .siblings('[data-context-target]')

      @close_all_context_menus(menu[0])

      menu
        .removeClass('from-mouse')
        .css(top: '', left: '')
        .toggle()
      false

jQuery -> ( context_menu = new ContextMenu() )
