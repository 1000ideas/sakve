if $('#download-folder-modal').length == 0
  sakve.modal('download-folder-modal', '<%= render("download", folder: @folder) %>')
else
  $('#download-folder-modal').html('<%= render("download", folder: @folder) %>')
<% if @folder.zip_file.nil? %>
$.ajax
    url: '<%= download_folder_path(@folder, format: :js) %>'
<% end %>
