$(document).on 'change', '#sec_year', ->
  $.ajax(
    type: 'GET'
    url: '/attendances/get_change_month'
    data: {
      id: $(this).val()
    }
  ).done (data) ->
    $('.month-area').html(data)
