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
    $ =>
      @_on_load()

  _on_load: ->
    # console.profile('Setup');
    $(document).foundation();

    for module in ['tags', 'multiupload', 'drag_drop',
      'share', 'folders', 'selection', 'body_cover',
      'clipboard', 'scrollpane', 'backgrounds_files', 'download_page']
      @["_init_#{module}"]()

    @last_selected = null

    $(document).on 'click', '[data-reveal-close]', (event) ->
      $(this)
        .closest('[data-reveal]')
        .foundation('reveal', 'close')

    $(document).on 'dragenter dragleave', 'body', (event) ->
      event.preventDefault()
      event.stopPropagation()
      dragCount = $(event.currentTarget).data('dragCount') || 0
      offset = if event.type == 'dragenter' then +1 else -1
      dragCount += offset
      $(event.currentTarget).data('dragCount', dragCount)

      $(event.currentTarget).toggleClass('file-drop-over', dragCount > 0)
      $(event.currentTarget).find('div.draggable-background').toggle()

    $(document).on 'drop', (event) ->
      $('body')
        .data('dragCount', 0)
        .removeClass('file-drop-over')
        .find('div.draggable-background')
        .hide()


    $(window)
      .on 'resize', (event) ->
        wh = $(window).innerHeight()
        $('.file-list').each (idx, el) ->
          height = wh - $(el).offset().top;
          if height > 0
            list = $(el)
              .css(marginBottom: 0)
              .height(height)
            if list.is('.scroll-pane')
              list.data('jsp').reinitialise()
        $('body > .cover').each (idx, el) ->
          $(el).height $(document).height()
      .resize()
    true

    if /Safari/.test(navigator.userAgent) && /Apple Computer/.test(navigator.vendor)
      $(document).on 'keydown', '#user_password', (event) ->
        if event.keyCode == 9 and !event.shiftKey
          event.preventDefault()
          $(event.target).blur()
          $('input#user_remember_me').get(0).focus()


  _init_backgrounds_files: ->
    $('#bg-manage .fileupload-button input').change ->
      names = []
      for f in @.files
        names.push(f.name)

      $('#bg-manage .added-files').text(names.join(', '))

  _init_scrollpane: ->
    $('.scroll-pane')
      .jScrollPane()
      .on 'jsp-scroll-start jsp-scroll-stop', (event) ->
        $(event.target).toggleClass('jspScrolling', event.type.match(/-start/))

  reload_list: (name) ->
    # items_url = $("##{name}-list").data('url');
    $.ajax(location.href)
      .done (data) =>
        $(data)
          .find("##{name}-list")
          .replaceAll("##{name}-list")
        @selection_changed()
        @_init_scrollpane()
        $(window).resize()

  modal: (id, content, options = {}) ->
    on_close = (event) ->
      return unless $(event.target).is('[data-reveal]')
      options.closed.call(event.target) if options.closed?
      $(this).remove()

    $('<div data-reveal>')
      .addClass("reveal-modal #{options.size ? 'small'}")
      .attr('id', id)
      .html(content)
      .append( $('<a class="close-reveal-modal">&#215;</a>') )
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

  enableBeforeClose: ->
    window.onbeforeunload = (event) ->
      I18n.t('onbeforeunload')

  disableBeforeClose: ->
    window.onbeforeunload = null

  start_ping: ->
    return if @ping_timeout_id?
    @enableBeforeClose()

    ping_func = =>
      @ping_timeout_id = null
      @user_auth_token ?= $('#user_auth_token').val()
      $.ajax(url: '/ping', headers: {'X-Auth-Token': @user_auth_token})
      @start_ping()

    @ping_timeout_id = setTimeout(ping_func, 5000)

  stop_ping: ->
    @disableBeforeClose()

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
          if data.jqXHR.responseJSON?
            data
              .context
              .replaceWith(data.jqXHR.responseJSON.context)
          $(event.target.form).foundation(alert: {animation: 'slideUp'})

      }

    $(document).on 'closed', '#multiupload-files-modal', (event) =>
      return unless $(event.target).is('[data-reveal]')
      $(event.target).find('[data-alert]').remove()

  create_transfer_after_upload: ->
    input = $('.transfer-fileupload')
    form = $( input.prop('form') )
    active_transfers = input.data('blueimp-fileupload')._active
    if  active_transfers == 0 && form.data('send-after')
      button = form.find('button')
      button
        .text( form.data('revert-text-send-after') )
      if $('.transfer-file .errors').length == 0
        form.submit()

  _init_transfer: ->
    $('input[data-spin-box]').spinBox()
    $('#transfer_expires_in_infinity')
      .change (event) ->
        checked = $(event.currentTarget).is(':checked')
        $(event.currentTarget).parent().toggleClass('checked', checked)
        spinbox = $('#transfer_expires_in').prop('spinBox')?
        if checked and spinbox
          $('#transfer_expires_in').prop('spinBox').infinity()
        else if spinbox
          $('#transfer_expires_in').prop('spinBox').revert_infinity()
      .change()

    $('input#show_recipients').change (event) ->
      if $(event.currentTarget).is(':checked')
        $('#transfer_recipients').slideDown 300, ->
          $('#transfer_message').slideDown 300
      else
        $('#transfer_message').slideUp 300,  ->
          $('#transfer_recipients').slideUp 300

    $('button', $('.transfer-fileupload').prop('form') ).click (event) ->
      if $('.transfer-fileupload').data('blueimp-fileupload')._active > 0
        event.preventDefault()
        button = $(event.target)
        text = button.text()
        button
          .text( button.data('text-send-after') )
          .prop('disabled', true)
        $.data( button.prop('form'), 'send-after', true)
        $.data( button.prop('form'), 'revert-text-send-after', text )
        false

    $(document).on 'click', '.uploaded-files .transfer-file[data-fid]', (event) ->
      return if $(event.current).is('a')
      $(event.currentTarget).toggleClass('selected')
      $('.uploaded-files-panel .remove-selected').toggle($('.uploaded-files .selected').length > 0)

    $('.uploaded-files-panel .remove-all').click (event) ->
      event.preventDefault()
      ids = $('.uploaded-files .transfer-file[data-fid]').slideUp( -> $(this).remove() ).map( (idx, el) -> $(el).data('fid') ).toArray()
      $.ajax
        url: $(event.target).attr('href')
        type: 'POST'
        data:
          _method: 'delete'
          ids: ids
      $(event.target).hide().next().hide()


    $('.uploaded-files-panel .remove-selected').hide().click (event) ->
      event.preventDefault()
      ids = $('.uploaded-files .selected.transfer-file[data-fid]').slideUp( -> $(this).remove() ).map( (idx, el) -> $(el).data('fid') ).toArray()
      $.ajax
        url: $(event.target).attr('href')
        type: 'POST'
        data:
          _method: 'delete'
          ids: ids
      $(event.target).hide().prev().toggle $('.uploaded-files .transfer-file[data-fid]:not(.selected)').length > 0

    $('.transfer-fileupload').each (idx, el) =>
      @fileupload_with_dropzone el, {
        url: $(el).data('url')
        limitConcurrentUploads: 3
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
          # $("input[type=submit], button", data.form).prop('disabled', true)
          $(window).resize()
        progress: @defaults.on_progress
        beforeSend: (xhr, settings) ->
          xhr.setRequestHeader('X-Auth-Token', $('#user_auth_token').val() )
          true
        always: (event, data) ->
          sakve.create_transfer_after_upload()
          $('.uploaded-files-panel .remove-all').toggle( $('.uploaded-files .transfer-file[data-fid]').length > 0 )
        done: (event, data) =>
          result = data.result
          uploaded = @views
            .uploaded(result.id, result.name, data.jqXHR.getResponseHeader('Location'))
          data.context.replaceWith(uploaded)
          # $("input[type=submit], button", data.form).prop('disabled', false)
        error: (event, data) ->
          # $("input[type=submit], button", data.form).prop('disabled', false)
        stop: (event, data) =>
          if $('.transfer-fileupload').data('blueimp-fileupload')._active == 0
            @stop_ping()
          # $("input[type=submit], button", data.form).prop('disabled', false)
        fail: (event, data) ->
          if data.jqXHR.responseJSON?
            _content = $(data.jqXHR.responseJSON.context)
            data
              .context
              .replaceWith(_content)
            data.context = _content
              .find 'a.remove'
              .on 'click', (event) ->
                event.preventDefault()
                $(event.target)
                  .closest('.progress-info')
                  .slideUp ->
                    $(this).remove()
          else
            data
              .context
              .slideUp ->
                    $(this).remove()
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

  _init_download_page: ->
    title = document.title
    $(window).on 'focus', ->
      document.title = title

    @.update_status()

  update_status: =>
    $.ajax(
      url: "/transfers/#{$('#download-container').data('id')}/status",
      dataType: 'json'
    ).done (data) =>
      if data == true
        $('.download #download-container').load("#{location.href} #download-container>*", '')
        if !document.hasFocus()
          document.title = 'Przetworzono pliki!'
          if document.getElementById('notify_me').checked
            alert 'Przetworzono pliki!'
      else
        setTimeout(@.update_status, 1500)

  fileupload_with_dropzone: (element, options = {}) ->
    value = $(element).data('value')
    # $(element).wrap $('<div>').addClass('fileupload-dropzone')
    $(element).wrap $('<div>').addClass('button round fileupload-button')
    $(element).after $('<span>').text( value )

    $(element).fileupload $.extend({
        singleFileUploads: true
        dataType: 'json'
        dropZone: $(element).parents('body')
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


window.sakve = new Sakve()
