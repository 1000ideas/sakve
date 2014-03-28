if @folder.zip_file.present?
  headers['Content-Disposition'] = "disposition=attachment; filename=#{@folder.name.parameterize}.zip"
  headers['Content-Transfer-Encoding'] = 'binary'
  response.sending_file = true
  response.cache_control[:public] ||= false

  @folder.zip_file.read
else
  head 404
end


