// Track when someone submits the search form
$(document).on('submit', 'form.filters-form', function() {
    gtag('event', 'search_form_complete');
  }
);

// Track when someone views a vacancy from a list of results
$(document).on('click', '.view-vacancy-link', function() {
    gtag('event', 'vacancy_visited');
  }
);

// Track when someone applies for a vacancy
$(document).on('click', '.vacancy-apply-link', function() {
    gtag('event', 'vacancy_applied');
  }
);

// Track when someone shares a vacancy on social media
$(document).on('click', '.vacancy-share-link', function() {
    gtag('event', 'vacancy_shared', {
      'event_label': $(this).data('target')
    });
  }
);