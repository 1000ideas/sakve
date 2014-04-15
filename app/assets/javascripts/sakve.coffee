class Sakve
  views:
    progressbar: (name) ->
      label = $('<span>')
        .addClass('name')
        .attr('title', name)
        .text( name )
      progress = $('<div>')
        .addClass('progress')
        .append $('<span>').addClass('meter').width("0%")
      value = $('<span>')
        .addClass('progress-value')
        .text("0%")
      file_progress = $('<div>')
        .addClass('file-progress')
        .append( label )
        .append( value )
        .append( progress )
      cancel = $('<a>')
        .text( I18n.t('confirm.cancel') )
        .addClass('cancel')
      $('<div>')
        .addClass('progress-info')
        .append('<i class="fa fa-spinner fa-2x">')
        .append(file_progress)
        .append(cancel)
    uploaded: (id, name, url) ->
      template = $( $('#transfer_uploaded_template').html() )
      template
        .find('span.name')
        .attr('title', name)
        .text(name)
      template
        .find('a.remove')
        .attr('href', url)
      template.attr('data-fid', id)
    collaborator_select: (ul, item) ->
      label = $('<a>')
        .append( "<strong>#{item.type_name}</strong>" )
        .append( item.name )
      $('<li>')
        .append( label )
        .appendTo( ul )
    share: (id, type) ->
      $('<input>')
        .attr('type', 'hidden')
        .attr('id', "with_#{type}_#{id}")
        .attr('name', "with[#{type}][]")
        .val(id)

  constructor: ->
    # console.profile('Setup');
    $(document).foundation();

    for module in ['tags', 'multiupload', 'transfer',
      'drag_drop', 'share', 'folders', 'selection', 'body_cover',
      'clipboard']
      @["_init_#{module}"]()

    @last_selected = null

    $(document).on 'click', '[data-reveal-close]', (event) ->
      $(this)
        .closest('[data-reveal]')
        .foundation('reveal', 'close')

    # console.profileEnd()
    true

  reload_list: (name) ->
    # items_url = $("##{name}-list").data('url');
    $.ajax(location.href)
      .done (data) =>
        $(data)
          .find("##{name}-list")
          .replaceAll("##{name}-list")
        @selection_changed()

  modal: (id, content, options = {}) ->
    on_close = (event) ->
      return unless $(event.target).is('[data-reveal]')
      options.closed.call(event.target) if options.closed?
      $(this).remove()

    $('<div data-reveal>')
      .addClass("reveal-modal #{options.size ? 'small'}")
      .attr('id', id)
      .html(content)
      .appendTo('body')
      .foundation()
      .on('opened', options.opened ? -> )
      .on('open', options.open ? -> )
      .on('close', options.close ? -> )
      .on('closed', on_close )
      .foundation('reveal', 'open')

  show_errors: (selector, content) ->
    errors = $(content)
    current = $(selector).find( "##{errors.attr('id')}" )
    if current.length > 0
      current.replaceWith errors
    else
      errors
        .hide()
        .prependTo(selector)
        .slideDown()
    $(selector).foundation(alert: {animation: 'slideUp'})
    # $(selector).foundation()

  start_ping: ->
    return if @ping_timeout_id?

    ping_func = =>
      @ping_timeout_id = null
      $.ajax('/ping')
      @start_ping()

    @ping_timeout_id = setTimeout(ping_func, 5000)

  stop_ping: ->
    if @ping_timeout_id?
      clearTimeout(@ping_timeout_id)
      @ping_timeout_id = null

  selection_changed: (element = null) ->
    @last_selected = element

    _selection_changed = =>
      all = $('.file-list input[type=checkbox]')
      selected = $('.file-list input[type=checkbox]:checked')
      $('.buttons-line').toggleClass('selected', selected.length > 0)

      folders = selected.filter (idx) ->
        this.name.match(/\[fids\]/i)

      transfers = selected.filter (idx) ->
        this.name.match(/\[tids\]/i)

      items = selected.filter (idx) ->
        this.name.match(/\[ids\]/i)

      _data = {
        selection: {
          fids: folders.map((idx, el) -> parseInt(el.value)).toArray()
          tids: transfers.map((idx, el) -> parseInt(el.value)).toArray()
          ids: items.map((idx, el) -> parseInt(el.value)).toArray()

        }
      }

      $('.buttons-line').toggleClass('folders-selected', folders.length > 0)

      if all.length > 0 and all.length == selected.length
        $('label#select-all').removeClass('unknown').addClass('checked')
      else if all.length > 0 and selected.length > 0
        $('label#select-all').removeClass('checked').addClass('unknown')
      else
        $('label#select-all').removeClass('checked unknown')

      if selected.length > 0 and @last_selected? and @last_selected.data('context-ajax')
        $.ajax
          url: @last_selected.data('context-ajax')
          type: 'POST'
          data: _data
          success: (data) ->
            $('.buttons-line .for-selection').html(data)

      @selection_changed_timeout = null

    unless @selection_changed_timeout?
      @selection_changed_timeout = setTimeout(_selection_changed, 100)

  _init_clipboard: ->
    ZeroClipboard.config
      swfPath: $('meta[name="zeroclipboard"]').attr('content')
      moviePath: $('meta[name="zeroclipboard"]').attr('content')
      debug: true

  _init_body_cover: ->
    path = $('[data-cover]').data('cover')
    if path?
      img = new Image()
      img.onload = (event) ->
        $('[data-cover]')
          .css('background-image', "url('#{path}')")
          .addClass('loaded')
      img.onerror = (event) ->
        $('[data-cover]')
          .addClass('loaded')
      img.src = path

  _init_selection: ->
    ## Duble click on folder
    $(document).on 'dblclick', '.file-list li.folder[data-url]', (event) =>
      event.preventDefault()
      window.location.href = $(event.currentTarget).data('url')

    $(document).on 'click', 'label#select-all', (event) =>
      event.preventDefault()
      event.stopPropagation()

      if $(event.currentTarget).hasClass('checked') || $(event.currentTarget).hasClass('unknown')
        $('.file-list input[type=checkbox]:checked').each (idx, el) ->
          $(el).prop('checked', false).change()
      else
        $('.file-list input[type=checkbox]:not(:checked)').each (idx, el) ->
          $(el).prop('checked', true).change()

    $(document).on 'change', '.file-list input[type=checkbox]', (event) =>
      checked = $(event.target).is(':checked')
      @selection_changed $(event.target).closest('li').toggleClass('selected', checked)
      event.stopPropagation()

    $(document).on 'click', (event) =>
      if $(event.target).closest('.file-list li').length == 0
        $('.file-list input[type=checkbox]:checked').each (idx, el) ->
          $(el).prop('checked', false).change()

    $(document).on 'click', '.file-list li', (event) =>
      return if $(event.target).closest('label.custom-check-box').length > 0
      event.preventDefault()

      input = $('input[type=checkbox]', event.target)
      form = $(event.target).closest('form')
      if event.shiftKey
        if $(event.currentTarget).nextAll().filter(@last_selected).length > 0
          $(event.currentTarget).nextUntil(@last_selected).each (idx, el) ->
            $('input[type=checkbox]', el).prop('checked', true).change()
        else if $(event.currentTarget).prevAll().filter(@last_selected).length > 0
          $(event.currentTarget).prevUntil(@last_selected).each (idx, el) ->
            $('input[type=checkbox]', el).prop('checked', true).change()
        input.prop('checked', true).change()
      else if event.ctrlKey
        input.prop('checked', !input.prop('checked')).change()
      else
        checked_count = form.find('input[type=checkbox]:checked').length
        if checked_count >= 1 and !input.prop('checked') or checked_count > 1 and input.prop('checked')
          form.find('input[type=checkbox]:checked').each (idx, el) ->
            $(el).prop('checked', false).change()
          input.prop('checked', true).change()
        else
          input.prop('checked', !input.prop('checked')).change()

    $('.file-list input[type=checkbox]:checked').each (idx, el) =>
      $(el).closest('li').toggleClass('selected', true)
      @selection_changed()

    $(document).on 'context:open', '[data-context-holder]', (event) ->
      event.target.clipboard = new ZeroClipboard $('[data-clipboard-text]', event.target)
      event.target.clipboard.on 'complete', (client, args) ->
        window.context_menu.close_all_context_menus()
    $(document).on 'context:close', '[data-context-holder]', (event) ->
      if event.target.clipboard?
        event.target.clipboard.destroy()

    $(document).on 'before:context:ajax', '#items-list [data-context]', (event, jqXHR, settings, from_mouse) ->
      input = $('input[type=checkbox]', event.target)
      form = $(event.target).closest('form')
      if from_mouse
        unless input.prop('checked')
          form.find('input[type=checkbox]:checked').each (idx, el) ->
            $(el).prop('checked', false).change()
          input.prop('checked', true).change()

        settings.data += "&#{form.serialize()}"
      else
        param = "#{input.attr('name')}=#{input.val()}"
        settings.data += "&#{encodeURI(param)}"
      true

  _init_folders: ->
    $(document).on 'click', '.folders-tree a .fa-caret', (event) ->
      event.preventDefault()
      $(event.target).closest('li.folder').toggleClass('open')

    $(document).on 'before:context:ajax', '#folders-list [data-context]', (event, jqXHR, settings, from_mouse) ->
      param = "selection[fids][]=#{$(event.target).data('fid')}"
      settings.data += "&#{encodeURI(param)}"
      true

  _init_tags: ->
    $('.tags-autocomplete').autocomplete(@defaults.tags_autocomplete)

  _init_multiupload: ->
    $('.fileupload').each (idx, el) =>
      @fileupload_with_dropzone el, {
        add: (event, data) =>
          group = $("#upload-in-progress", event.target.form)
          file = data.files[0]
          data.context = @views
            .progressbar( file.name )
            .appendTo( group )
          data.submit()
        progress: @defaults.on_progress
        done: (event, data) =>
          data
            .context
            .replaceWith(data.result.context)
          $(event.target.form).foundation(alert: {animation: 'slideUp'})
          @reload_list('items')
        start: (event, data) =>
          @start_ping()
        stop: (event, data) =>
          @stop_ping()
        fail: (event, data) ->
          data
            .context
            .replaceWith(data.jqXHR.responseJSON.context)
          $(event.target.form).foundation(alert: {animation: 'slideUp'})

      }

    $(document).on 'closed', '#multiupload-files-modal', (event) =>
      return unless $(event.target).is('[data-reveal]')
      $(event.target).find('[data-alert]').remove()

  _init_transfer: ->
    $('input[data-spin-box]').spinBox()
    $('#transfer_expires_in_infinity').change (event) ->
      checked = $(event.currentTarget).is(':checked')
      $(event.currentTarget).parent().toggleClass('checked', checked)
      spinbox = $('#transfer_expires_in').prop('spinBox')?
      if checked and spinbox
        $('#transfer_expires_in').prop('spinBox').infinity()
      else if spinbox
        $('#transfer_expires_in').prop('spinBox').revert_infinity()


    $('.transfer-fileupload').each (idx, el) =>
      @fileupload_with_dropzone el, {
        url: $(el).data('url')
        start: =>
          @start_ping()
        add: (event, data) =>
          group = $(event.target.form).children('.uploaded-files').first()
          file = data.files[0]
          data.context = @views
            .progressbar( file.name )
            .appendTo( group )
          jqXHR = data.submit()
          data.context.on 'click', 'a.cancel', (event) ->
            event.preventDefault()
            jqXHR.abort()
            data.context.slideUp ->
              data.context.remove()
          $("input[type=submit], button", data.form).prop('disabled', true)
        progress: @defaults.on_progress
        done: (event, data) =>
          result = data.result
          uploaded = @views
            .uploaded(result.id, result.name, data.jqXHR.getResponseHeader('Location'))
          data.context.replaceWith(uploaded)
          $("input[type=submit], button", data.form).prop('disabled', false)
        error: (event, data) ->
          $("input[type=submit], button", data.form).prop('disabled', false)
        stop: (event, data) =>
          @stop_ping()
          $("input[type=submit], button", data.form).prop('disabled', false)
      }

  _init_drag_drop: ->
    $( "ul.file-list li.draggable" ).draggable
      containment: $(this).parent().parent().parent()
      helper: "clone"
      cancel: ".actions"
      cursorAt: {top: -5, left: -5}
      distance: 20

    $( "section#folders-list h1.droppable, section#folders-list li.droppable" ).droppable
      accept: 'li.item'
      greedy: true
      tolerance: "pointer"
      drop: (e, ui) ->
        $.ajax
          type  : "POST"
          url   : "/change_folder/"
          data  : {
            'item_id': $(ui.draggable).attr( 'id' ).substr(5)
            'folder_id': $(this).attr( 'id' ).substr(7)
          },
          success: ->
            $(ui.draggable).fadeOut( 'slow' )
          error: ->
            alert('Not allowed')
          statusCode:
            403: ->
              alert('403: Permission denied')

    true

  _init_share: ->
    $(document).on 'click', '#share_users .remove, #share_groups .remove', (event) ->
      event.preventDefault()
      $(event.target).closest('li').slideUp ->
        $(this).remove()

  fileupload_with_dropzone: (element, options = {}) ->
    value = $(element).data('value')
    $(element).wrap $('<div>').addClass('fileupload-dropzone')
    $(element).wrap $('<div>').addClass('button round fileupload-button')
    $(element).after $('<span>').text( value )

    $(element).fileupload $.extend({
        singleFileUploads: true
        dataType: 'json'
        dropZone: $(element).parents('.fileupload-dropzone')
      }, options)

  defaults:
    collaborators_autocomplete:
      source: (request, response) ->
        $.getJSON "/collaborators.json", q: request.term, response
      select: ( event, ui ) ->
        if $('#with_' + ui.item.type + '_' + ui.item.id).length == 0
          remove_button = $('<a>').attr('href', '#').text(I18n.t('destroy')).addClass('remove')
          $('<li>')
            .append( sakve.views.share(ui.item.id, ui.item.type) )
            .append( ui.item.name )
            .append( remove_button )
            .appendTo( $('#share_' + ui.item.type) )
        this.value = ''
        false
    tags_autocomplete:
      source: (request, response) ->
        last_term = request.term.split(/,\s*/).pop()
        $.getJSON( "/tags.json", { q: last_term }, response )
      search: ->
        term = this.value.split(/,\s*/).pop()
        term.length > 0
      focus: ->
        false
      select: (event, ui) ->
        terms = this.value.split(/,\s*/)
        terms.pop()
        terms.push( ui.item.value )
        terms.push( '' )
        this.value = terms.join( ", " )
        false
    on_progress: (event, data) ->
      if data.context
        progress = "#{parseInt(data.loaded / data.total * 100, 10)}%"
        $('.meter', data.context).css('width', progress)
        $('.progress-value', data.context).text( progress)


jQuery -> (window.sakve = new Sakve())
