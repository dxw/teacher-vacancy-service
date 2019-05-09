module VacanciesHelper
  SALARY_OPTIONS = {
    '£20,000' => 20000,
    '£30,000' => 30000,
    '£40,000' => 40000,
    '£50,000' => 50000,
    '£60,000' => 60000,
    '£70,000' => 70000
  }.freeze

  def working_pattern_options
    Vacancy::WORKING_PATTERN_OPTIONS.map do |key, _value|
      [Vacancy.human_attribute_name("working_patterns.#{key}"), key]
    end
  end

  def school_phase_options
    School.phases.keys.map { |key| [key.humanize, key] }
  end

  def listed_elsewhere_options
    Vacancy.listed_elsewheres.keys.map { |k| [t("jobs.feedback.listed_elsewhere.#{k}"), k] }
  end

  def hired_status_options
    Vacancy.hired_statuses.keys.map { |k| [t("jobs.feedback.hired_status.#{k}"), k] }
  end

  def link_to_sort_by(title, column:, order:, sort:)
    if column == sort.column
      order = sort.reverse_order
      active_class = ' active'
    end
    link_to title,
            jobs_path(vacancy_params(sort_column: column,
                                     sort_order: order)),
            class: "govuk-link sortby--#{order}#{active_class || ''}",
            'aria-label': t('jobs.aria_labels.sort_by_link', column: title, order: order)
  end

  def vacancy_params_whitelist
    %i[sort_column sort_order page].concat(VacancyFilters::AVAILABLE_FILTERS)
  end

  def vacancy_params(overwrite = {})
    params.merge(overwrite).permit(vacancy_params_whitelist)
  end

  def radius_filter_options
    [1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 70, 80, 90, 100, 200].inject([]) do |radii, radius|
      radii << ["Within #{radius} miles", radius]
    end
  end

  def pay_scale_options
    @pay_scale_options ||= PayScale.all
  end

  def subject_options
    @subject_options ||= Subject.all
  end

  def phase_checked?(phase)
    return false if phases.blank?

    phases.include?(phase)
  end

  def nqt_suitable_checked?(newly_qualified_teacher)
    newly_qualified_teacher == 'true'
  end
end
