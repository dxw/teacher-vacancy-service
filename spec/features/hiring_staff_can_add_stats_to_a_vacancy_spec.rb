require 'rails_helper'
RSpec.feature 'Adding feedback to a vacancy' do
  let(:school) { create(:school) }
  before(:each) do
    stub_hiring_staff_auth(urn: school.urn)
  end

  scenario 'feedback can be added to a vacancy' do
    vacancy = build(:vacancy, :expired, school: school)
    vacancy.save(validate: false)

    visit jobs_with_type_school_path(type: :awaiting_feedback)

    expect(page).to have_content(vacancy.job_title)

    select I18n.t('jobs.feedback.hired_status.hired_tvs'), from: 'vacancy_hired_status'
    select I18n.t('jobs.feedback.listed_elsewhere.listed_paid'), from: 'vacancy_listed_elsewhere'

    click_on I18n.t('buttons.submit')

    expect(page).to have_content(I18n.t('jobs.feedback_submitted'))
    expect(page).to_not have_content(vacancy.job_title)

    vacancy.reload

    expect(vacancy.hired_status).to eq('hired_tvs')
    expect(vacancy.listed_elsewhere).to eq('listed_paid')
  end
end