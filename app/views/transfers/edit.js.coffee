if $('#edit-transfer-modal').length == 0
  sakve.modal('edit-transfer-modal',
    '<%= j render("edit_form") %>')
