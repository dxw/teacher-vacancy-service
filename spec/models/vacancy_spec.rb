require 'rails_helper'
RSpec.describe Vacancy, type: :model do
  subject { Vacancy.new(school: build(:school)) }
  it { should belong_to(:school) }

  describe '.public_search' do
    context 'when there were no results' do
      it 'records the event in Rollbar' do
        filters = VacancyFilters.new(subject: 'subject', job_title: 'job title')
        expect(Rollbar).to receive(:log)
          .with(:info,
                'A search returned 0 results',
                location: nil,
                radius: nil,
                subject: 'subject',
                job_title: 'job title',
                minimum_salary: nil,
                working_pattern: nil,
                newly_qualified_teacher: nil,
                phases: nil)

        results = Vacancy.public_search(filters: filters, sort: VacancySort.new)

        expect(results.count).to eql(0)
      end
    end
  end

  describe 'validations' do
    context 'a new record' do
      it { should validate_presence_of(:job_title) }
      it { should validate_presence_of(:job_description) }
      it { should validate_presence_of(:working_patterns) }
      it { should validate_presence_of(:minimum_salary) }
    end

    context 'a record saved with job spec details' do
      subject { create(:vacancy) }

      it { should validate_presence_of(:education) }
      it { should validate_presence_of(:qualifications) }
      it { should validate_presence_of(:experience) }
    end

    context 'set minimum length of mandatory fields' do
      subject { build(:vacancy, :fail_minimum_validation) }
      before(:each) do
        subject.valid?
      end

      it '#job_title' do
        expect(subject.errors.messages[:job_title].first)
          .to eq(I18n.t('errors.messages.too_short.other', count: 4))
      end

      it '#job_description' do
        expect(subject.errors.messages[:job_description].first)
          .to eq(I18n.t('errors.messages.too_short.other', count: 10))
      end

      it '#experience' do
        expect(subject.errors.messages[:experience].first)
          .to eq(I18n.t('errors.messages.too_short.other', count: 10))
      end

      it '#education' do
        expect(subject.errors.messages[:education].first)
          .to eq(I18n.t('errors.messages.too_short.other', count: 10))
      end

      it '#qualifications' do
        expect(subject.errors.messages[:qualifications].first)
          .to eq(I18n.t('errors.messages.too_short.other', count: 10))
      end
    end

    context 'restrict maximum length of string fields' do
      subject { build(:vacancy, :fail_maximum_validation) }
      before(:each) do
        subject.valid?
      end

      it '#job_title' do
        expect(subject.errors.messages[:job_title].first)
          .to eq(I18n.t('errors.messages.too_long.other', count: 100))
      end
    end

    context 'restrict maximum length of text fields' do
      subject { build(:vacancy, :fail_maximum_validation) }
      before(:each) do
        subject.valid?
      end

      it '#job_description' do
        expect(subject.errors.messages[:job_description].first)
          .to eq(I18n.t('errors.messages.too_long.other', count: 50_000))
      end

      it '#experience' do
        expect(subject.errors.messages[:experience].first)
          .to eq(I18n.t('errors.messages.too_long.other', count: 1000))
      end

      it '#education' do
        expect(subject.errors.messages[:education].first)
          .to eq(I18n.t('errors.messages.too_long.other', count: 1000))
      end

      it '#qualifications' do
        expect(subject.errors.messages[:qualifications].first)
          .to eq(I18n.t('errors.messages.too_long.other', count: 1000))
      end
    end

    context '#minimum_salary and #maximum_salary combined validations' do
      it 'present minimum_salary and no maximum_salary' do
        job = build(:vacancy, minimum_salary: 20, maximum_salary: nil)

        expect(job.valid?).to be true
        expect(job.errors.messages[:minimum_salary]).to be_empty
        expect(job.errors.messages[:maximum_salary]).to be_empty
      end

      it 'no minimum_salary and no maximum_salary set' do
        job = build(:vacancy, minimum_salary: nil, maximum_salary: nil)

        expect(job.valid?).to be false
        expect(job.errors.messages[:minimum_salary]).to eq(['can\'t be blank'])
        expect(job.errors.messages[:maximum_salary]).to be_empty
      end

      it 'no minimum_salary and invalid maximum_salary' do
        job = build(:vacancy, minimum_salary: nil, maximum_salary: 'not a number')

        expect(job.valid?).to be false
        expect(job.errors.messages[:minimum_salary]).to eq(['can\'t be blank'])
        expect(job.errors.messages[:maximum_salary]).to be_empty
      end

      it 'invalid minimum_salary and no maximum_salary' do
        job = build(:vacancy, minimum_salary: 'A20000', maximum_salary: nil)

        expect(job.valid?).to be false
        expect(job.errors.messages[:minimum_salary])
          .to eq(['must be entered in one of the following formats: 25000 or 25000.00'])
        expect(job.errors.messages[:maximum_salary]).to be_empty
      end

      it 'invalid minimum_salary and invalid maximum_salary' do
        job = build(:vacancy, minimum_salary: 'A20000', maximum_salary: '20K')

        expect(job.valid?).to be false
        expect(job.errors.messages[:minimum_salary])
          .to eq(['must be entered in one of the following formats: 25000 or 25000.00'])
        expect(job.errors.messages[:maximum_salary]).to be_empty
      end

      it 'invalid minimum_salary and valid maximum_salary' do
        job = build(:vacancy, minimum_salary: 'A20000', maximum_salary: '20000')

        expect(job.valid?).to be false
        expect(job.errors.messages[:minimum_salary])
          .to eq(['must be entered in one of the following formats: 25000 or 25000.00'])
        expect(job.errors.messages[:maximum_salary]).to be_empty
      end

      it 'valid minimum_salary and invalid maximum_salary' do
        job = build(:vacancy, minimum_salary: 20000, maximum_salary: 'A20000')

        expect(job.valid?).to be false
        expect(job.errors.messages[:minimum_salary]).to be_empty
        expect(job.errors.messages[:maximum_salary])
          .to eq(['must be entered in one of the following formats: 25000 or 25000.00'])
      end

      it 'valid minimum_salary and greater than allowed maximum_salary' do
        job = build(:vacancy, minimum_salary: 20000, maximum_salary: 200000000000)

        expect(job).to_not be_valid
        expect(job.errors.messages[:minimum_salary]).to be_empty
        expect(job.errors.messages[:maximum_salary])
          .to eq(['must not be more than £200000'])
      end

      it 'greater than allowed minimum_salary and greater than allowed maximum_salary' do
        job = build(:vacancy, minimum_salary: 20000000000000, maximum_salary: 2000000000000000)

        expect(job).to_not be_valid
        expect(job.errors.messages[:minimum_salary])
          .to eq(['must not be more than £200000'])
        expect(job.errors.messages[:maximum_salary]).to be_empty
      end

      it 'greater than allowed minimum_salary and no maximum_salary' do
        job = build(:vacancy, minimum_salary: 20000000000000, maximum_salary: nil)

        expect(job).to_not be_valid
        expect(job.errors.messages[:minimum_salary])
          .to eq(['must not be more than £200000'])
        expect(job.errors.messages[:maximum_salary]).to be_empty
      end
    end

    context 'a record saved with job spec and candidate spec details, ' \
      'and empty contact_email' do

      subject { build(:vacancy, status: :draft) }
      before { subject.contact_email = '' }

      it 'should validate presence of contact email' do
        expect(subject.valid?).to be_falsy
        expect(subject.errors.messages[:contact_email]).not_to eql([])
      end

      it { should validate_presence_of(:publish_on) }
      it { should validate_presence_of(:expires_on) }
    end

    describe '#maximum_salary_greater_than_minimum' do
      it 'the minimum salary should be less than the maximum salary' do
        vacancy = build(:vacancy, minimum_salary: 20, maximum_salary: 10)

        expect(vacancy.valid?).to be false
        expect(vacancy.errors.messages[:maximum_salary]).to eq(['must be higher than the minimum salary'])
      end
    end

    describe '#working_hours' do
      it 'can not accept non-numeric values' do
        vacancy = build(:vacancy, weekly_hours: 'eight and a half')

        expect(vacancy.valid?).to be(false)
        expect(vacancy.errors.messages[:weekly_hours][0]).to eq('must be a valid number')
      end

      it 'can accept decimal values' do
        vacancy = build(:vacancy, weekly_hours: '0.5')

        expect(vacancy.valid?).to be true
        expect(vacancy.weekly_hours).to eq('0.5')
      end

      it 'must not have a negative value' do
        vacancy = build(:vacancy, weekly_hours: '-5')

        expect(vacancy.valid?).to be false
        expect(vacancy.errors.messages[:weekly_hours][0]).to eq('can\'t be negative')
      end
    end
  end

  describe 'friendly_id generated slug' do
    context '#slug' do
      it 'the slug cannot be duplicate' do
        green_school = build(:school, name: 'Green school', town: 'Greenway', county: 'Mars')
        blue_school = build(:school, name: 'Blue school')
        first_maths_teacher = create(:vacancy, :published, job_title: 'Maths Teacher', school: blue_school)
        second_maths_teacher = create(:vacancy, :published, job_title: 'Maths Teacher', school: green_school)
        third_maths_teacher = create(:vacancy, :published, job_title: 'Maths Teacher', school: green_school)
        fourth_maths_teacher = create(:vacancy, :published, job_title: 'Maths Teacher', school: green_school)

        expect(first_maths_teacher.slug).to eq('maths-teacher')
        expect(second_maths_teacher.slug).to eq('maths-teacher-green-school')
        expect(third_maths_teacher.slug).to eq('maths-teacher-green-school-greenway-mars')

        expect(fourth_maths_teacher.slug).to include('maths-teacher')
        expect(fourth_maths_teacher.slug).not_to eq('maths-teacher')
        expect(fourth_maths_teacher.slug).not_to eq('maths-teacher-green-school')
        expect(fourth_maths_teacher.slug).not_to eq('maths-teacher-green-school-greenway-mars')
      end
    end

    context '#refresh_slug' do
      it 'resets the current slug by accessing a friendly_id private method' do
        job = create(:vacancy, slug: 'the-wrong-slug')
        job.job_title = 'CS Teacher'
        job.refresh_slug

        expect(job.slug).to eq('cs-teacher')
      end
    end

    context '#listed?' do
      it 'returns true if the vacancy is currently listed' do
        job = create(:vacancy, :published)

        expect(job.listed?).to be true
      end

      it 'returns false if the vacancy is not yet listed' do
        job = build(:vacancy, :published, slug: 'value', publish_on: Time.zone.tomorrow)
        job.save(validate: false)

        expect(job.listed?).to be false
      end
    end
  end

  context 'actions' do
    describe '#trash!' do
      it 'sets a vacancy to trashed and does not retrieve it in the applicable scope' do
        vacancies = create_list(:vacancy, 4)
        vacancies.last.trashed!
        expect(Vacancy.active.count).to eq(3)
        vacancies.first.trashed!
        expect(Vacancy.active.count).to eq(2)
      end
    end
  end

  context 'scopes' do
    describe '#applicable' do
      it 'finds current vacancies' do
        expired = build(:vacancy, :expired)
        expired.send :set_slug
        expired.save(validate: false)
        expires_today = create(:vacancy, expires_on: Time.zone.today)
        expires_future = create(:vacancy, expires_on: 3.months.from_now)

        results = Vacancy.applicable
        expect(results).to include(expires_today)
        expect(results).to include(expires_future)
        expect(results).to_not include(expired)
      end
    end

    describe '#active' do
      it 'retrieves active vacancies that have a status of :draft or :published' do
        draft = create_list(:vacancy, 2, :draft)
        published = create_list(:vacancy, 5, :published)
        create_list(:vacancy, 4, :trashed)

        expect(Vacancy.active.count).to eq(draft.count + published.count)
      end
    end

    describe '#listed' do
      it 'retrieves vacancies that have a status of :published and a past publish_on date' do
        published = create_list(:vacancy, 5, :published)
        create_list(:vacancy, 3, :future_publish)
        create_list(:vacancy, 4, :trashed)

        expect(Vacancy.listed.count).to eq(published.count)
      end
    end

    describe '#pending' do
      it 'retrieves vacancies that have a status of :published, a future publish_on date & a future expires_on date' do
        create_list(:vacancy, 5, :published)
        pending = create_list(:vacancy, 3, :future_publish)

        expect(Vacancy.pending.count).to eq(pending.count)
      end
    end

    describe '#draft' do
      it 'retrieves vacancies that have a status of :draft' do
        create_list(:vacancy, 5, :published)
        draft = create_list(:vacancy, 3, :draft)

        expect(Vacancy.draft.count).to eq(draft.count)
      end
    end

    describe '#expired' do
      it 'retrieves vacancies that have a past expires_on date' do
        create_list(:vacancy, 5, :published)
        expired = build(:vacancy, :expired)
        expired.send :set_slug
        expired.save(validate: false)

        expect(Vacancy.expired.count).to eq(1)
      end
    end

    describe '#live' do
      let!(:live) { create_list(:vacancy, 5, :published) }

      it 'retrieves vacancies that have a status of :published, a past publish_on date & a future expires_on date' do
        expired = build(:vacancy, :expired)
        expired.send :set_slug
        expired.save(validate: false)
        create_list(:vacancy, 3, :future_publish)
        create_list(:vacancy, 4, :trashed)

        expect(Vacancy.live.count).to eq(live.count)
        expect(Vacancy.live).to_not include(expired)
      end

      it 'includes vacancies that expire today' do
        expires_today = create(:vacancy, status: :published, expires_on: Time.zone.today)

        expect(Vacancy.live).to include(expires_today)
      end
    end

    describe '#published_on_count(date)' do
      it 'retrieves vacancies listed on the specified date' do
        published_today = create_list(:vacancy, 3, :published_slugged)
        published_yesterday = build_list(:vacancy, 2, :published_slugged, publish_on: 1.day.ago)
        published_yesterday.each { |v| v.save(validate: false) }
        published_the_other_day = build_list(:vacancy, 1, :published_slugged, publish_on: 2.days.ago)
        published_the_other_day.each { |v| v.save(validate: false) }
        published_some_other_day = build_list(:vacancy, 6, :published_slugged, publish_on: 1.month.ago)
        published_some_other_day.each { |v| v.save(validate: false) }

        expect(Vacancy.published_on_count(Time.zone.today)).to eq(published_today.count)
        expect(Vacancy.published_on_count(1.day.ago)).to eq(published_yesterday.count)
        expect(Vacancy.published_on_count(2.days.ago)).to eq(published_the_other_day.count)
        expect(Vacancy.published_on_count(1.month.ago)).to eq(published_some_other_day.count)
      end
    end

    describe '#awaiting_feedback' do
      it 'gets all vacancies awaiting feedback' do
        expired_and_awaiting = create_list(:vacancy, 2, :expired)
        create_list(:vacancy, 3, :expired, listed_elsewhere: :listed_paid, hired_status: :hired_tvs)
        create_list(:vacancy, 3, :published_slugged)

        expect(Vacancy.awaiting_feedback.count).to eq(expired_and_awaiting.count)
      end
    end
  end

  describe 'delegate school_name' do
    it 'should return the school name for the vacancy' do
      school = create(:school, name: 'St James School')
      vacancy = create(:vacancy, school: school)

      expect(vacancy.school_name).to eq('St James School')
    end
  end

  describe '#application_link' do
    it 'returns the url' do
      vacancy = create(:vacancy, application_link: 'https://example.com')
      expect(vacancy.application_link).to eql('https://example.com')
    end

    context 'when a protocol was not provided' do
      it 'returns an absolute url with `http` as the protocol' do
        vacancy = create(:vacancy, application_link: 'example.com')
        expect(vacancy.application_link).to eql('http://example.com')
      end
    end

    context 'when only the `www` sub domain was provided' do
      it 'returns an absolute url with `http` as the protocol' do
        vacancy = create(:vacancy, application_link: 'www.example.com')
        expect(vacancy.application_link).to eql('http://www.example.com')
      end
    end
  end

  context 'content sanitization' do
    it '#job_description' do
      html = '<p> a paragraph <a href=\'link\'>with a link</a></p><br>'
      vacancy = build(:vacancy, job_description: html)

      sanitized_html = '<p> a paragraph with a link</p><br>'
      expect(vacancy.job_description).to eq(sanitized_html)
    end

    it '#job_title' do
      title = '<strong>School teacher </strong>'
      vacancy = build(:vacancy, job_title: title)

      sanitized_title = 'School teacher '
      expect(vacancy.job_title).to eq(sanitized_title)
    end

    it '#benefits' do
      benefits = '<ul><li><a href="">Gym membership</a></li></ul>'
      vacancy = build(:vacancy, benefits: benefits)

      sanitized_benefits = '<ul><li>Gym membership</li></ul>'
      expect(vacancy.benefits).to eq(sanitized_benefits)
    end

    it '#experience' do
      experience = '<strong>2 years experience</strong><script>'
      vacancy = build(:vacancy, experience: experience)

      sanitized_experience = '<strong>2 years experience</strong>'
      expect(vacancy.experience).to eq(sanitized_experience)
    end

    it '#qualifications' do
      qualifications = '<em>Degree in Teaching</em><br><a href="a-link">more info</a>'
      vacancy = build(:vacancy, qualifications: qualifications)

      sanitized_qualifications = '<em>Degree in Teaching</em><br>more info'
      expect(vacancy.qualifications).to eq(sanitized_qualifications)
    end

    it '#education' do
      education = '<p><a href="http://university-of-london">University of London</a></p>'
      vacancy = build(:vacancy, education: education)

      sanitized_education = '<p>University of London</p>'
      expect(vacancy.education).to eq(sanitized_education)
    end
  end

  context 'salary trimming' do
    it 'trims the minimum salary' do
      job = build(:vacancy, minimum_salary: " #{SalaryValidator::MIN_SALARY_ALLOWED} ")
      expect(job.minimum_salary).to eq(SalaryValidator::MIN_SALARY_ALLOWED)
    end

    it 'trims the maximum salary' do
      job = build(:vacancy, maximum_salary: " #{SalaryValidator::MIN_SALARY_ALLOWED} ")
      expect(job.maximum_salary).to eq(SalaryValidator::MIN_SALARY_ALLOWED)
    end
  end

  context '#flexible_working?' do
    context 'when no flexible working options are available' do
      let(:flexible_working) { nil }
      let(:job) { create(:vacancy, working_patterns: ['full_time'], flexible_working: flexible_working) }

      it 'returns false' do
        expect(job.flexible_working?).to eq(false)
      end

      context 'when flexible_working is set to true' do
        let(:flexible_working) { true }

        it 'returns true' do
          expect(job.flexible_working?).to eq(true)
        end
      end

      context 'when flexible_working is set to false' do
        let(:flexible_working) { false }

        it 'returns false' do
          expect(job.flexible_working?).to eq(false)
        end
      end
    end

    context 'when flexible working options are available' do
      let(:flexible_working) { nil }
      let(:job) { create(:vacancy, working_patterns: ['full_time', 'part_time'], flexible_working: flexible_working) }

      it 'returns true' do
        expect(job.flexible_working?).to eq(true)
      end

      context 'when flexible_working is set to true' do
        let(:flexible_working) { true }

        it 'returns true' do
          expect(job.flexible_working?).to eq(true)
        end
      end

      context 'when flexible_working is set to false' do
        let(:flexible_working) { false }

        it 'returns false' do
          expect(job.flexible_working?).to eq(false)
        end
      end
    end
  end

  context 'flexible working' do
    context 'when flexible_working is true and no flexible working options are available' do
      let(:job) { create(:vacancy, working_patterns: ['full_time'], flexible_working: true) }

      context 'and changing working patterns to part time only' do
        it 'clears flexible_working' do
          job.working_patterns = ['part_time']
          job.save

          expect(Vacancy.find(job.id).flexible_working).to eq(nil)
        end
      end

      context 'and changing working patterns to include part time' do
        it 'clears flexible_working' do
          job.working_patterns = ['full_time', 'part_time']
          job.save

          expect(Vacancy.find(job.id).flexible_working).to eq(nil)
        end
      end

      context 'and changing working patterns to include flexible working patterns' do
        it 'clears flexible_working' do
          job.working_patterns = ['full_time', 'job_share']
          job.save

          expect(Vacancy.find(job.id).flexible_working).to eq(nil)
        end
      end

      context 'and changing flexible_working to false' do
        it 'clears flexible_working' do
          job.flexible_working = false
          job.save

          expect(Vacancy.find(job.id).flexible_working).to eq(nil)
        end
      end

      context 'and not changing working_patterns or flexible_working' do
        it 'leaves flexible_working unchanged' do
          job.job_title = 'new title'
          job.save

          expect(Vacancy.find(job.id).flexible_working).to eq(job.flexible_working)
        end
      end
    end

    context 'when flexible_working is false and flexible working options are available' do
      let(:job) { create(:vacancy, working_patterns: ['part_time'], flexible_working: false) }

      context 'and changing working patterns to include full time' do
        it 'leaves flexible_working unchanged' do
          job.working_patterns = ['full_time', 'part_time']
          job.save

          expect(Vacancy.find(job.id).flexible_working).to eq(job.flexible_working)
        end
      end

      context 'and changing working patterns to include other flexible working patterns' do
        it 'leaves flexible_working unchanged' do
          job.working_patterns = ['part_time', 'job_share']
          job.save

          expect(Vacancy.find(job.id).flexible_working).to eq(job.flexible_working)
        end
      end

      context 'and changing working patterns to full time only' do
        it 'clears flexible_working' do
          job.working_patterns = ['full_time']
          job.save

          expect(Vacancy.find(job.id).flexible_working).to eq(nil)
        end
      end

      context 'and changing flexible_working to true' do
        it 'clears flexible_working' do
          job.flexible_working = true
          job.save

          expect(Vacancy.find(job.id).flexible_working).to eq(nil)
        end
      end

      context 'and not changing working_patterns or flexible_working' do
        it 'leaves flexible_working unchanged' do
          job.job_title = 'new title'
          job.save

          expect(Vacancy.find(job.id).flexible_working).to eq(job.flexible_working)
        end
      end
    end
  end

  context 'pro rata salary' do
    context 'when salary is pro rata' do
      context 'and working pattern is part time' do
        let(:job) { create(:vacancy, working_patterns: ['part_time'], pro_rata_salary: true) }

        context 'and changing working patterns to include full time' do
          it 'clears pro_rata_salary' do
            job.working_patterns = ['full_time', 'part_time']
            job.save

            expect(Vacancy.find(job.id).pro_rata_salary).to eq(nil)
          end
        end

        context 'and changing working patterns to include other flexible working patterns' do
          it 'leaves pro_rata_salary unchanged' do
            job.working_patterns = ['part_time', 'job_share']
            job.save

            expect(Vacancy.find(job.id).pro_rata_salary).to eq(job.pro_rata_salary)
          end
        end

        context 'and changing working patterns to remove part time' do
          it 'clears pro_rata_salary' do
            job.working_patterns = ['full_time', 'job_share']
            job.save

            expect(Vacancy.find(job.id).pro_rata_salary).to eq(nil)
          end
        end

        context 'and not changing working patterns' do
          it 'leaves pro_rata_salary unchanged' do
            job.job_title = 'new title'
            job.save

            expect(Vacancy.find(job.id).pro_rata_salary).to eq(job.pro_rata_salary)
          end
        end
      end

      context 'and working pattern is full time' do
        let(:job) { create(:vacancy, working_patterns: ['full_time'], pro_rata_salary: true) }

        context 'and changing working patterns to part time only' do
          it 'clears pro_rata_salary' do
            job.working_patterns = ['part_time']
            job.save

            expect(Vacancy.find(job.id).pro_rata_salary).to eq(nil)
          end
        end

        context 'and changing working patterns to include part time' do
          it 'clears pro_rata_salary' do
            job.working_patterns = ['full_time', 'part_time']
            job.save

            expect(Vacancy.find(job.id).pro_rata_salary).to eq(nil)
          end
        end

        context 'and changing working patterns to include flexible working patterns' do
          it 'clears pro_rata_salary' do
            job.working_patterns = ['full_time', 'job_share']
            job.save

            expect(Vacancy.find(job.id).pro_rata_salary).to eq(nil)
          end
        end

        context 'and not changing working patterns' do
          it 'leaves pro_rata_salary unchanged' do
            job.job_title = 'new title'
            job.save

            expect(Vacancy.find(job.id).pro_rata_salary).to eq(job.pro_rata_salary)
          end
        end
      end
    end

    context 'when salary is not pro rata' do
      context 'and working pattern is part time' do
        let(:job) { create(:vacancy, working_patterns: ['part_time'], pro_rata_salary: false) }

        context 'and changing working patterns to include full time' do
          it 'clears pro_rata_salary' do
            job.working_patterns = ['full_time', 'part_time']
            job.save

            expect(Vacancy.find(job.id).pro_rata_salary).to eq(nil)
          end
        end

        context 'and changing working patterns to include other flexible working patterns' do
          it 'clears pro_rata_salary' do
            job.working_patterns = ['part_time', 'job_share']
            job.save

            expect(Vacancy.find(job.id).pro_rata_salary).to eq(nil)
          end
        end

        context 'and changing working patterns to remove part time' do
          it 'clears pro_rata_salary' do
            job.working_patterns = ['full_time', 'job_share']
            job.save

            expect(Vacancy.find(job.id).pro_rata_salary).to eq(nil)
          end
        end

        context 'and not changing working patterns' do
          it 'clears pro_rata_salary' do
            job.job_title = 'new title'
            job.save

            expect(Vacancy.find(job.id).pro_rata_salary).to eq(nil)
          end
        end
      end

      context 'and working pattern is full time' do
        let(:job) { create(:vacancy, working_patterns: ['full_time'], pro_rata_salary: false) }

        context 'and changing working patterns to part time only' do
          it 'clears pro_rata_salary' do
            job.working_patterns = ['part_time']
            job.save

            expect(Vacancy.find(job.id).pro_rata_salary).to eq(nil)
          end
        end

        context 'and changing working patterns to include part time' do
          it 'clears pro_rata_salary' do
            job.working_patterns = ['full_time', 'part_time']
            job.save

            expect(Vacancy.find(job.id).pro_rata_salary).to eq(nil)
          end
        end

        context 'and changing working patterns to include flexible working patterns' do
          it 'clears pro_rata_salary' do
            job.working_patterns = ['full_time', 'job_share']
            job.save

            expect(Vacancy.find(job.id).pro_rata_salary).to eq(nil)
          end
        end

        context 'and not changing working patterns' do
          it 'leaves pro_rata_salary unchanged' do
            job.job_title = 'new title'
            job.save

            expect(Vacancy.find(job.id).pro_rata_salary).to eq(job.pro_rata_salary)
          end
        end
      end
    end
  end
end
