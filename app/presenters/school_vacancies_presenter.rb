class SchoolVacanciesPresenter < BasePresenter
  attr_reader :vacancy_type, :school, :sort, :vacancies

  def initialize(school, sort, vacancy_type)
    @vacancy_type = vacancy_type&.to_sym || :published
    @school = school
    @sort = sort
    raise ArgumentError unless self.class.valid_types.include?(@vacancy_type)

    @vacancies = send(@vacancy_type).map { |v| SchoolVacancyPresenter.new(v) }
  end

  def self.valid_types
    %i[published pending draft expired awaiting_feedback]
  end

  private

  def draft
    @school.vacancies.draft.order(sort.column => sort.order)
  end

  def pending
    @school.vacancies.pending.order(sort.column => sort.order)
  end

  def expired
    @school.vacancies.expired.order(sort.column => sort.order)
  end

  def published
    @school.vacancies.live.order(sort.column => sort.order)
  end

  def awaiting_feedback
    @school.vacancies.awaiting_feedback.order(sort.column => sort.order)
  end
end