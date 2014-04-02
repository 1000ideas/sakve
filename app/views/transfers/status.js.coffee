$('#transfer-processing-status')
  .text('<%= t("transfers.create.#{@transfer.done? ? :done : :processing }") %>')

call_again = ->
  $.ajax url: '<%= status_transfer_path(@transfer, format: :js) %>'

sakve.transfer_status_timeout = setTimeout(call_again, 1500)

