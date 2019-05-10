$(document).on('turbolinks:load', function(){
  $('.submit_feedback').on('ajax:success', function(event) {
    form = $(event.target);
    notification = $('.notification');
    count = Number(notification.text()) - 1;
    table = $('table.vacancies')

    if (count > 0) {
      row = form.parents('tr');
      notification.text(count);
      text = form.data('successMessage');
      row.html('<td class="govuk-table__cell" colspan="6">'+ text +'</td>');
      row.fadeOut(3000, function() {
        $(this).remove();
      })
    } else {
      notification.remove();
      table.remove();
      text = form.data('allSubmittedMessage');
      $('section.govuk-tabs__panel').append('<p class="govuk-body govuk-!-font-size-27">' + text + '</p>');
    }
  });
});