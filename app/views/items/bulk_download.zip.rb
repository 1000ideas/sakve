headers['Content-Disposition'] = "disposition=attachment; filename=selection-#{Date.current.strftime('%d-%m-%Y')}.zip"
headers['Content-Transfer-Encoding'] = 'binary'
response.sending_file = true
response.cache_control[:public] ||= false

@selection.file

