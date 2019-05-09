require 'elasticsearch/model'
require 'auditor'

class Vacancy < ApplicationRecord
  FLEXIBLE_WORKING_PATTERN_OPTIONS = {
    'part_time' => 100,
    'job_share' => 101,
    'compressed_hours' => 102,
    'staggered_hours' => 103
  }.freeze

  WORKING_PATTERN_OPTIONS = {
    'full_time' => 0
  }.merge(FLEXIBLE_WORKING_PATTERN_OPTIONS).freeze

  include ApplicationHelper
  include Auditor::Model

  include VacancyJobSpecificationValidations
  include VacancyCandidateSpecificationValidations
  include VacancyApplicationDetailValidations

  include Elasticsearch::Model
  include Redis::Objects

  index_name [Rails.env, model_name.collection.tr('\/', '-')].join('_')
  document_type 'vacancy'
  settings index: {
    analysis: {
      analyzer: {
        stopwords: {
          tokenizer: 'standard',
          filter: ['standard', 'lowercase', 'english_stopwords', 'stopwords']
        }
      },
      filter: {
        english_stopwords: {
          type: 'stop',
          stopwords: '_english_'
        },
        stopwords: {
          type: 'stop',
          stopwords: ['part', 'full', 'time']
        }
      }
    }
  } do
    mappings dynamic: 'false' do
      indexes :job_title, type: :text, analyzer: :stopwords
      indexes :job_description, analyzer: 'english'

      indexes :school do
        indexes :name, analyzer: 'english'
        indexes :phase, type: :keyword
        indexes :postcode, type: :text
        indexes :town, type: :text
        indexes :county, type: :text
        indexes :address, type: :text
      end

      indexes :subject do
        indexes :name, type: :text
      end

      indexes :first_supporting_subject do
        indexes :name, type: :text
      end

      indexes :second_supporting_subject do
        indexes :name, type: :text
      end

      indexes :expires_on, type: :date
      indexes :starts_on, type: :date
      indexes :updated_at, type: :date
      indexes :publish_on, type: :date
      indexes :status, type: :keyword
      indexes :working_patterns, type: :keyword
      indexes :minimum_salary, type: :integer
      indexes :maximum_salary, type: :integer
      indexes :coordinates, type: :geo_point, ignore_malformed: true
      indexes :newly_qualified_teacher, type: :boolean
    end
  end

  extend FriendlyId
  extend ArrayEnum

  friendly_id :slug_candidates, use: %w[slugged history]

  enum status: %i[published draft trashed]
  enum working_pattern: %i[full_time part_time] # Deprecated
  array_enum working_patterns: WORKING_PATTERN_OPTIONS
  enum listed_elsewhere: %i[
    listed_paid
    listed_free
    listed_mix
    not_listed
    listed_dont_know
  ]
  enum hired_status: %i[
    hired_tvs
    hired_other_free
    hired_paid
    hired_free
    not_filled_ongoing
    not_filled_readvertised
    not_filled_not_looking
    hired_dont_know
  ]

  belongs_to :school, optional: false
  belongs_to :subject, optional: true
  belongs_to :first_supporting_subject, class_name: 'Subject', optional: true
  belongs_to :second_supporting_subject, class_name: 'Subject', optional: true
  belongs_to :min_pay_scale, class_name: 'PayScale', optional: true
  belongs_to :max_pay_scale, class_name: 'PayScale', optional: true
  belongs_to :leadership, optional: true

  has_one :publish_feedback, class_name: 'VacancyPublishFeedback'

  delegate :name, to: :school, prefix: true, allow_nil: false
  delegate :geolocation, to: :school, prefix: true, allow_nil: true

  acts_as_gov_uk_date :starts_on, :ends_on, :publish_on, :expires_on

  scope :applicable, (-> { where('expires_on >= ?', Time.zone.today) })
  scope :active, (-> { where(status: %i[published draft]) })
  scope :listed, (-> { published.where('publish_on <= ?', Time.zone.today) })
  scope :published_on_count, (->(date) { published.where(publish_on: date.all_day).count })
  scope :pending, (-> { published.where('publish_on > ?', Time.zone.today) })
  scope :expired, (-> { published.where('expires_on < ?', Time.zone.today) })
  scope :live, (-> { published.where('publish_on <= ?', Time.zone.today).where('expires_on >= ?', Time.zone.today) })

  paginates_per 10

  validates :slug, presence: true

  before_save :update_flexible_working, if: :will_save_change_to_working_patterns_or_flexible_working?
  before_save :update_pro_rata_salary, if: :will_save_change_to_working_patterns?

  after_commit on: %i[create update] do
    __elasticsearch__.index_document
  end

  counter :page_view_counter
  counter :get_more_info_counter

  def self.public_search(filters:, sort:)
    query = VacancySearchBuilder.new(filters: filters, sort: sort).call
    results = ElasticSearchFinder.new.call(query[:search_query], query[:search_sort])

    Rollbar.log(:info, 'A search returned 0 results', filters.to_hash) if results.count.zero?
    results
  end

  def location
    @location ||= SchoolPresenter.new(school).location
  end

  def coordinates
    return if school_geolocation.nil?

    {
      lat: school_geolocation.x.to_f,
      lon: school_geolocation.y.to_f
    }
  end

  def listed?
    published? && !publish_on.future? && expires_on.future?
  end

  # rubocop:disable Naming/UncommunicativeMethodParamName
  def as_indexed_json(_ = {})
    as_json(
      methods: %i[coordinates],
      include: {
        school: { only: %i[phase name postcode address town] },
        subject: { only: %i[name] },
        first_supporting_subject: { only: %i[name] },
        second_supporting_subject: { only: %i[name] }
      }
    )
  end
  # rubocop:enable Naming/UncommunicativeMethodParamName

  def trash!
    self.status = :trashed
    save(validate: false)
  end

  def application_link=(value)
    # Data may not include a scheme/protocol so we must be careful when creating
    # links that Rails doesn't make them incorrectly relative.
    begin
      value = Addressable::URI.heuristic_parse(value).to_s
    rescue Addressable::URI::InvalidURIError
      Rails.logger.debug('Validation error: Invalid application link format')
    end
    super(value)
  end

  def refresh_slug
    self.slug = nil
    send(:set_slug)
  end

  def minimum_salary=(salary)
    self[:minimum_salary] = salary.to_s.strip
  end

  def maximum_salary=(salary)
    self[:maximum_salary] = salary.to_s.strip
  end

  def weekly_hours?
    weekly_hours.present? && derived_flexible_working?
  end

  def flexible_working?
    return flexible_working unless flexible_working.nil?

    derived_flexible_working?
  end

  def attributes
    super().merge('working_patterns' => working_patterns)
  end

  def skip_update_callbacks(value = true)
    @skip_update_callbacks = value
  end

  def skip_update_callbacks?
    @skip_update_callbacks.present?
  end

  private

  def slug_candidates
    [
      :job_title,
      %i[job_title school_name],
      %i[job_title location],
    ]
  end

  def derived_flexible_working?
    working_patterns.select { |working_pattern| FLEXIBLE_WORKING_PATTERN_OPTIONS.key?(working_pattern) }.any?
  end

  def will_save_change_to_working_patterns_or_flexible_working?
    will_save_change_to_working_patterns? || will_save_change_to_flexible_working?
  end

  def update_flexible_working
    return if skip_update_callbacks?
    return if flexible_working.nil?

    self.flexible_working = nil if flexible_working == derived_flexible_working?
  end

  def update_pro_rata_salary
    return if skip_update_callbacks?

    self.pro_rata_salary = nil if pro_rata_salary.blank?

    return if pro_rata_salary.nil?

    self.pro_rata_salary = working_patterns == ['part_time'] ? true : nil
  end
end
