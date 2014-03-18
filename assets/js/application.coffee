#= require jquery/dist/jquery
#= require bootstrap/dist/js/bootstrap
#= require bootstrap-datepicker/js/bootstrap-datepicker

$ ->
  $result = $('#result')
  $picker = $('input[data-role="datepicker"]')
  $button = $('input#view-schedule')
  $form   = $('#when-form')

  $button.button('loading') unless $picker.val()

  check_day = (date, callback) ->
    $.ajax
      type: 'POST'
      url: '/check'
      dataType: 'json'
      data:
        date: date
      complete: (event) ->
        callback(event.responseJSON.events.length isnt 0)

  $form.on 'submit', (event) ->
    unless event.isTrigger
      event.preventDefault()
      $picker.trigger('changeDate')
      false

  $picker
    .datepicker
      format: 'yyyy-mm-dd'
    .on 'changeDate', (event) ->
      $button.button('loading')
      $result.text('')
      $(@).datepicker('hide')
      check_day event.target.value, (result) ->
        $result.text(if result then 'Yes' else 'Not yet')
        $button.button('reset') if result
    .on 'blur', (event) ->
      $button.button('loading') if event.target.value is ''

  $button
    .on 'click', (event) ->
      $form.submit()

  $('#change-day').on 'click', (event) ->
    window.history.back()
