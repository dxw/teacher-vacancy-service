class HiringStaff::SchoolsController < HiringStaff::BaseController
  def show
    @school = SchoolPresenter.new(current_school)
    @sort = VacancySort.new.update(column: params[:sort_column], order: params[:sort_order])
    @vacancy_presenter = SchoolVacanciesPresenter.new(@school, @sort, params[:type])
  end

  def edit
    @school = current_school
    return if params[:description].nil?

    @school.description = params[:description].presence
    @school.valid?
  end

  def update
    school = current_school
    school.description = params[:school][:description]

    if school.valid?
      Auditor::Audit.new(school, 'school.update', current_session_id).log do
        school.save
      end
      redirect_to school_path
    else
      redirect_to edit_school_path(description: school.description)
    end
  end
end
