require 'rails_helper'
RSpec.describe SchoolVacanciesPresenter do
  before do
    @school = create(:school)
    @draft_vacancies = create_list(:vacancy, 5, :draft, school: @school)
    @pending_vacancies = create_list(:vacancy, 4, :future_publish, school: @school)
    @expired_vacancies = begin
      expired_vacancies = []
      3.times do
        expired_vacancy = build(:vacancy, :expired, school: @school)
        expired_vacancy.save(validate: false)
        expired_vacancies << expired_vacancy
      end
      expired_vacancies
    end
    @published_vacancies = create_list(:vacancy, 7, :published, school: @school)
  end

  let(:type) { 'published' }
  let(:sort) { VacancySort.new }
  let(:presenter) { described_class.new(@school, sort, type) }

  it 'returns the school' do
    expect(presenter.school).to eq(@school)
  end

  describe 'sorting' do
    let(:vacancy_ids) do
      vacancies.sort_by { |vacancy| vacancy['job_title'].delete(' ') }.reverse.pluck(:id)
    end

    context 'when type is draft' do
      let(:type) { 'draft' }
      let(:vacancies) { @draft_vacancies }

      it 'returns sorted draft vacancies' do
        sort.update(column: 'job_title', order: 'desc')

        expect(presenter.vacancies.pluck(:id)).to eq(vacancy_ids)
      end
    end

    context 'when type is pending' do
      let(:type) { 'pending' }
      let(:vacancies) { @pending_vacancies }

      it 'returns sorted pending vacancies' do
        sort.update(column: 'job_title', order: 'desc')

        expect(presenter.vacancies.pluck(:id)).to eq(vacancy_ids)
      end
    end

    context 'when type is expired' do
      let(:type) { 'expired' }
      let(:vacancies) { @expired_vacancies }

      it 'returns sorted expired vacancies' do
        sort.update(column: 'job_title', order: 'desc')

        expect(presenter.vacancies.pluck(:id)).to eq(vacancy_ids)
      end
    end

    context 'when type is published' do
      let(:type) { 'published' }
      let(:vacancies) { @published_vacancies }

      it 'returns sorted published vacancies' do
        sort.update(column: 'job_title', order: 'desc')

        expect(presenter.vacancies.pluck(:id)).to match_array(vacancy_ids)
      end
    end
  end

  context 'when type is draft' do
    let(:type) { 'draft' }

    it 'returns the vacancy type' do
      expect(presenter.vacancy_type).to eq(:draft)
    end

    it 'returns draft vacancies' do
      expect(presenter.vacancies.count).to eq(@draft_vacancies.count)
    end
  end

  context 'when type is pending' do
    let(:type) { 'pending' }

    it 'returns the vacancy type' do
      expect(presenter.vacancy_type).to eq(:pending)
    end

    it 'returns pending vacancies' do
      expect(presenter.vacancies.count).to eq(@pending_vacancies.count)
    end
  end

  context 'when type is expired' do
    let(:type) { 'expired' }

    it 'returns the vacancy type' do
      expect(presenter.vacancy_type).to eq(:expired)
    end

    it 'returns expired vacancies' do
      expect(presenter.vacancies.count).to eq(@expired_vacancies.count)
    end
  end

  context 'when type is published' do
    let(:type) { 'published' }

    it 'returns the vacancy type' do
      expect(presenter.vacancy_type).to eq(:published)
    end

    it 'returns published vacancies' do
      expect(presenter.vacancies.count).to eq(@published_vacancies.count)
    end
  end

  context 'when type is awaiting_feedback' do
    let(:type) { 'awaiting_feedback' }

    before do
      vacancy_with_feedback = @expired_vacancies[0]
      vacancy_with_feedback.listed_elsewhere = :listed_paid
      vacancy_with_feedback.hired_status = :hired_tvs
      vacancy_with_feedback.save
    end

    it 'returns the vacancy type' do
      expect(presenter.vacancy_type).to eq(:awaiting_feedback)
    end

    it 'returns published vacancies' do
      expect(presenter.vacancies.count).to eq(@expired_vacancies.count - 1)
    end
  end

  context 'when type is not recognised' do
    let(:type) { 'something' }

    it 'raises an error ' do
      expect { presenter }.to raise_error(ArgumentError)
    end
  end
end
