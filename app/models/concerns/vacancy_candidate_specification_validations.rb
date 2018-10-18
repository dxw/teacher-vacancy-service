module VacancyCandidateSpecificationValidations
  extend ActiveSupport::Concern
  include ApplicationHelper

  included do
    validates :experience, presence: {
      message: I18n.t('activerecord.errors.models.vacancy.attributes.experience.blank')
    }
    validates :education, presence: {
      message: I18n.t('activerecord.errors.models.vacancy.attributes.education.blank')
    }
    validates :qualifications, presence: {
      message: I18n.t('activerecord.errors.models.vacancy.attributes.qualifications.blank')
    }
    validates :experience, length: { minimum: 10, maximum: 1000 },
                           if: proc { |model| model.experience.present? }
    validates :education, length: { minimum: 10, maximum: 1000 },
                          if: proc { |model| model.education.present? }
    validates :qualifications, length: { minimum: 10, maximum: 1000 },
                               if: proc { |model| model.qualifications.present? }
  end

  def experience=(value)
    super(sanitize(value))
  end

  def qualifications=(value)
    super(sanitize(value))
  end

  def education=(value)
    super(sanitize(value))
  end
end
