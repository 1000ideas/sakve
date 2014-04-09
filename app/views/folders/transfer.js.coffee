errors  = <%= @transfer.errors.full_messages.to_json.html_safe %>
if errors.length == 0
  if $('#folder-transfer-modal').length == 0
    sakve.modal 'folder-transfer-modal', "<%=j render('transfers/create') %>", {
      close: ->
        if sakve.transfer_status_timeout > 0
          clearTimeout(sakve.transfer_status_timeout)
          sakve.transfer_status_timeout = -1
      closed: ->
        if this.clipboard != null
          this.clipboard.destroy()
      opened: ->
        this.clipboard = ZeroClipboard( $('.copy-to-clipboard', this) )
        $.ajax
          url: '<%= status_transfer_path(@transfer, format: :js) %>'
    }
else
  console.error(errors);

