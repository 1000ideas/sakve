class Sakve
  views:
    progressbar: (name) ->
      label = $('<span>')
        .addClass('name')
        .text( name )
      progress = $('<div>')
        .addClass('progress')
        .append $('<span>').addClass('meter').width("0%")
      value = $('<span>')
        .addClass('progress-value')
        .text("0%")
      $('<div>')
        .addClass('file-progress')
        .append( label )
        .append( progress )
        .append( value )
    uploaded: (id, name, url) ->
      label = $('<span>')
        .addClass('name')
        .text( name )
      destroy = $('<a>')
        .text(I18n.t('destroy'))
        .attr
          href: url
          'data-method': 'delete'
          'data-confirm': I18n.t('confirm.text')
          'data-remote': true
      $('<div>')
        .addClass('transfer-file')
        .attr('data-fid', id)
        .append( label )
        .append( destroy )
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

    for module in ['tags', 'multiupload', 'transfer', 'drag_drop', 'share', 'folders', 'selection', 'body_cover']
      @["_init_#{module}"]()

    @last_selected = null

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


  selection_changed: (element = null) ->
    @last_selected = element

    selected = $('.file-list input[type=checkbox]:checked')
    $('.buttons-line').toggleClass('selected', selected.length > 0)

    folders = selected.filter (idx) ->
      this.name.match(/fid/i)
    $('.buttons-line').toggleClass('folders-selected', folders.length > 0)


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
    $(document).on 'change', '.file-list input[type=checkbox]', (event) =>
      checked = $(event.target).is(':checked')
      @selection_changed $(event.target).closest('li').toggleClass('selected', checked)
      event.stopPropagation()

    $(document).on 'click', '.file-list li', (event) =>
      return if $(event.target).closest('label.custom-check-box').length > 0

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
        input.prop('checked', true).change()
      else
        form.find('input[type=checkbox]:checked').each (idx, el) ->
          $(el).prop('checked', false).change()
        input.prop('checked', true).change()

    $('.file-list input[type=checkbox]:checked').each (idx, el) =>
      $(el).closest('li').toggleClass('selected', true)
      @selection_changed()

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
          data.context.fadeOut ->
            $(this).remove()
          @reload_list('items')
        error: (event, data) ->
          true
      }

  _init_transfer: ->
    default_value = $( "#transfer_expires_in" ).data('default')
    $( "#expires_in_slider" )
      .slider
        value: default_value
        min: 1
        max: 31
        step: 1
        animate: "fast"
        slide: ( event, ui ) ->
          $( "#transfer_expires_at" ).val( if ui.value == 31 then '\u221e' else ui.value )
    $( "#transfer_expires_at" ).val( default_value )

    $('.transfer-fileupload').each (idx, el) =>
      @fileupload_with_dropzone el, {
        url: $(el).data('url')
        add: (event, data) =>
          group = $(event.target.form).children('.uploaded-files').first()
          file = data.files[0]
          data.context = @views
            .progressbar( file.name )
            .appendTo( group )
          $("input[type=submit], button", data.form).prop('disabled', true)
          data.submit()
        progress: @defaults.on_progress
        done: (event, data) =>
          result = data.result
          uploaded = @views
            .uploaded(result.id, result.name, data.jqXHR.getResponseHeader('Location'))
            .appendTo $(event.target.form).children('.uploaded-files')
          data.context.remove()
          $("input[type=submit], button", data.form).prop('disabled', false)
        error: (event, data) ->
          $("input[type=submit], button", data.form).prop('disabled', false)
        stop: (event, data) ->
          $("input[type=submit], button", data.form).prop('disabled', false)
      }

  _init_drag_drop: ->
    $( "ul.file-list li.draggable" ).draggable
      containment: $(this).parent().parent().parent()
      helper: "clone"
      cancel: ".actions"
      cursorAt: {top: -5, left: -5}
      distance: 20

    $( "section#left-menu ul li h1.droppable, section#left-menu ul li ul li.droppable" ).droppable
      accept: 'ul.file-list li'
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
    true

  _init_share: ->
    $(document).on 'click', '#share_users .remove, #share_groups .remove', (event) ->
      event.preventDefault()
      $(event.target).closest('li').slideUp ->
        $(this).remove()

  fileupload_with_dropzone: (element, options = {}) ->
    value = $(element).data('value')
    $(element).wrap $('<div>').addClass('fileupload-dropzone')
    $(element).wrap $('<div>').addClass('button fileupload-button')
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
