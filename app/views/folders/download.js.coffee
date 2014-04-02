sakve.folder_download_timeout ?= -1
if $('#download-folder-modal').length == 0
  sakve.modal 'download-folder-modal', '<%= render("download", folder: @folder) %>', {
    close: ->
      if sakve.folder_download_timeout > 0
        clearTimeout sakve.folder_download_timeout
        sakve.folder_download_timeout = -1
  }

else
  $('#download-folder-modal').html('<%= render("download", folder: @folder) %>')
<% if @folder.zip_file.nil? %>
call_again = ->
  $.ajax(url: '<%= download_folder_path(@folder, format: :js) %>')
sakve.folder_download_timeout = setTimeout(call_again, 1500)
<% end %>
