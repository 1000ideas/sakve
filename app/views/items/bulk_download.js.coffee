sakve.selection_download_timeout ?= -1
if $('#download-selection-modal').length == 0
  sakve.modal 'download-selection-modal', '<%= render("bulk_download", selection: @selection) %>', {
    close: ->
      if sakve.selection_download_timeout > 0
        clearTimeout sakve.selection_download_timeout
        sakve.selection_download_timeout = -1
  }

else
  $('#download-selection-modal').html('<%= render("bulk_download", selection: @selection) %>')
<% unless @selection.done? %>
call_again = ->
  $.ajax(url: '<%= bulk_download_items_path(token: @selection.id, format: :js) %>')
sakve.selection_download_timeout = setTimeout(call_again, 1500)
<% end %>
