class SpinBox
  constructor: (element) ->
    @element = $(element)
      .on 'change', (event) =>
        val = @value()
        if isNaN(val)
          @element.val(@minimum)
        else if val < @minimum
          @element.val(@minimum)
        else if val > @maximum
          @infinity()
        else
          @element.val(val)
      .wrap('<div class="spin-box">')


    @minimum = parseInt @element.attr('min')
    @maximum = parseInt @element.attr('max')
    @turn_infinity = @element.data('spin-box') == 'infinity'

    @minus = $('<button>')
      .attr('type', 'button')
      .addClass('button gray round tiny minus')
      .append( $('<i>').addClass('fa fa-minus') )
      .insertBefore(@element)
      .on 'click', (event) =>
        event.preventDefault()
      .on 'mousedown', (event) =>
        event.preventDefault()
        event.currentTarget.isDown = true
        @_timeout_decrement(1000)
      .on 'mouseup mouseleave', (event) =>
        event.preventDefault()
        event.currentTarget.isDown = false
        if @_timeout_decrement_id?
          clearTimeout @_timeout_decrement_id
          @_timeout_decrement_id = null


    @plus = $('<button>')
      .addClass('button gray round tiny plus')
      .append( $('<i>').addClass('fa fa-plus') )
      .insertAfter(@element)
      .click (event) =>
        event.preventDefault()
      .on 'mousedown', (event) =>
        event.preventDefault()
        event.currentTarget.isDown = true
        @_timeout_increment(1000)
      .on 'mouseup mouseleave', (event) =>
        event.preventDefault()
        event.currentTarget.isDown = false
        if @_timeout_increment_id?
          clearTimeout @_timeout_increment_id
          @_timeout_increment_id = null

    @element.prop('spinBox', this)

  value: ->
    parseInt(@element.val())

  disabled: ->
    @element.prop('disabled')

  increment: ->
    return if @disabled()
    val = parseInt(@element.val())
    return if isNaN(val)
    if val == @maximum
      @infinity() if @turn_infinity
      return
    @element
      .val( val + 1 )
      .change()
      .trigger('spinbox:increment')

  decrement: ->
    return if @disabled()
    val = parseInt(@element.val())
    if isNaN(val) && @turn_infinity
      val = @maximum + 1
    return if isNaN(val) || val == @minimum
    @element
      .val( val - 1 )
      .change()
      .trigger('spinbox:decrement')

  _timeout_decrement: (timeout = 100) ->
    if @minus.prop('isDown')
      @decrement()
      @_timeout_decrement_id = setTimeout((=> @_timeout_decrement()), timeout)

  _timeout_increment: (timeout = 100) ->
    if @plus.prop('isDown')
      @increment()
      @_timeout_increment_id = setTimeout((=> @_timeout_increment()), timeout)

  infinity: ->
    @last_value = @element.val()
    @element
      .prop('disabled', true)
      .val( '∞' )
      .trigger('spinbox:infinity')

  revert_infinity: ->
    @element
      .prop('disabled', false)
      .val( @last_value )
      .trigger('spinbox:revert_infinity')




jQuery.fn.extend
  spinBox: ->
    this.each ->
      new SpinBox(this)
