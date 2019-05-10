class HiringStaff::Vacancies::StatisticsController < HiringStaff::Vacancies::ApplicationController
  def update
    if valid?
      vacancy = Vacancy.find(vacancy_id)
      vacancy.update(statistics_params)

      flash_type = :success
      flash_message = I18n.t('jobs.feedback_submitted')
    else
      flash_type = :error
      flash_message = I18n.t('jobs.feedback_error')
    end

    return if request.format.js?

    flash[flash_type] = flash_message
    redirect_to jobs_with_type_school_path(type: :awaiting_feedback)
  end

  private

  def valid?
    statistics_params[:listed_elsewhere].present? && statistics_params[:hired_status].present?
  end

  def statistics_params
    params.require(:vacancy).permit(:listed_elsewhere, :hired_status)
  end
end