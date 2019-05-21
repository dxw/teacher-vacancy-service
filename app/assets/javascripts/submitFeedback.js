$(document).on('turbolinks:load', function(){


  $('.submit_feedback').on('submit', function(event) {
    var valid = true;
    var id = $(event.target).attr('id');

    $('select[form="'+ id +'"]').each(function() {
      if ($(this).val() == '') {
        valid = false;
        $(this).addClass('govuk-input--error');
      }
    })

    return valid;
  })

  $('.submit_feedback').on('ajax:success', function(event) {
    var form = $(event.target);
    var notification = $('.notification');
    var count = Number(notification.text()) - 1;
    var table = $('table.vacancies')
    var notice = $('#awaiting_notice')
    var notice_count = notice.find('.count');

    if (count > 0) {
      row = form.parents('tr');
      notification.text(count);
      notice_count.text(count);
      text = form.data('successMessage');
      row.html('<td class="govuk-table__cell" colspan="6">'+ text +'</td>');
      row.fadeOut(3000, function() {
        $(this).remove();
      })
    } else {
      notification.remove();
      notice.remove();
      table.remove();
      text = form.data('allSubmittedMessage');
      $('section.govuk-tabs__panel').append('<p class="govuk-body govuk-!-font-size-27">' + text + '</p>');
    }
  });
});