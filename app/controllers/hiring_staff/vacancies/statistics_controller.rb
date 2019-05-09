class HiringStaff::Vacancies::StatisticsController < HiringStaff::Vacancies::ApplicationController
  def update
    vacancy = Vacancy.find(vacancy_id)
    vacancy.update(statistics_params)

    flash[:success] = I18n.t('jobs.feedback_submitted')

    redirect_to jobs_with_type_school_path(type: :awaiting_feedback)
  end

  private

  def statistics_params
    params.require(:vacancy).permit(:listed_elsewhere, :hired_status)
  end
end