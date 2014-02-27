(($, I18n) ->
  confirmationPopup = (link) ->
    message = link.data('confirm')
    html = $("""<div id="confirm-dialog" class="reveal-modal tiny" data-reveal>
        <p>#{message}</p>
        <a href="#" class="button button-ok">#{I18n.t('confirm.ok')}</a>
        <a href="#" class="button button-cancel">#{I18n.t('confirm.cancel')}</a>
      </div>""")

    html.find('.button-ok').on 'click', (event) ->
      event.preventDefault()
      $.rails.confirmLink link
      $(html).foundation('reveal', 'close')

    html.find('.button-cancel').on 'click', (event) ->
      event.preventDefault()
      $(html).foundation('reveal', 'close')

    $('body').append(html)
    $('#confirm-dialog').foundation()
    $('#confirm-dialog').on 'closed',  ->
      $(this).remove()
    $('#confirm-dialog').foundation('reveal', 'open')

  $.rails.allowAction = (link) ->
    return true if ! link.data('confirm') || link.data('confirmed') == true
    confirmationPopup( link )
    false

  $.rails.confirmLink = (link) ->
    link.data('confirmed', true)
    link.trigger('click.rails')

  $
)(jQuery, I18n)

