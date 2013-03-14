(($, I18n) ->
  confirmationPopup = (link) ->
    message = link.data('confirm')
    html = """
      <div id="confirm-dialog" title="#{I18n.t('confirm.title')}">
        <p>#{message}</p>
      </div>
      """

    buttons = {}
    buttons[I18n.t('confirm.ok')] = ->
      $.rails.confirmLink link
      $(this).dialog 'close'
    buttons[I18n.t('confirm.cancel')] = ->
      $(this).dialog 'close'

    $( html ).dialog
      resizable: false
      modal: true
      buttons: buttons

  $.rails.allowAction = (link) ->
    return true if ! link.data('confirm') || link.data('confirmed') == true
    confirmationPopup( link )
    false

  $.rails.confirmLink = (link) ->
    link.data('confirmed', true)
    link.trigger('click.rails')

  $
)(jQuery, I18n)

