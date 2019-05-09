# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_05_16_213012) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "activities", force: :cascade do |t|
    t.uuid "trackable_id"
    t.string "trackable_type"
    t.string "session_id"
    t.string "key"
    t.text "parameters"
    t.uuid "owner_id"
    t.string "owner_type"
    t.uuid "recipient_id"
    t.string "recipient_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type"
    t.index ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type"
    t.index ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type"
  end

  create_table "alert_runs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "subscription_id"
    t.date "run_on"
    t.string "job_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0
    t.index ["subscription_id"], name: "index_alert_runs_on_subscription_id"
  end

  create_table "audit_data", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "category"
    t.json "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "detailed_school_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code"
    t.text "label"
    t.index ["code"], name: "index_detailed_school_types_on_code", unique: true
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.uuid "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "general_feedbacks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "rating"
    t.text "comment"
    t.integer "visit_purpose"
    t.text "visit_purpose_comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "leaderships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title", null: false
    t.index ["title"], name: "index_leaderships_on_title", unique: true
  end

  create_table "pay_scales", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "label", null: false
    t.string "code"
    t.integer "index"
    t.index ["label"], name: "index_pay_scales_on_label", unique: true
  end

  create_table "regions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "code"
    t.index ["code"], name: "index_regions_on_code", unique: true
    t.index ["name"], name: "index_regions_on_name", unique: true
  end

  create_table "school_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "label", null: false
    t.text "code"
    t.index ["code"], name: "index_school_types_on_code", unique: true
    t.index ["label"], name: "index_school_types_on_label", unique: true
  end

  create_table "schools", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "urn", null: false
    t.string "address", null: false
    t.string "town", null: false
    t.string "county"
    t.string "postcode", null: false
    t.integer "phase"
    t.string "url"
    t.integer "minimum_age"
    t.integer "maximum_age"
    t.uuid "school_type_id"
    t.uuid "region_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "locality"
    t.text "address3"
    t.uuid "detailed_school_type_id"
    t.text "easting"
    t.text "northing"
    t.point "geolocation"
    t.index ["detailed_school_type_id"], name: "index_schools_on_detailed_school_type_id"
    t.index ["region_id"], name: "index_schools_on_region_id"
    t.index ["school_type_id"], name: "index_schools_on_school_type_id"
    t.index ["urn"], name: "index_schools_on_urn", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "subjects", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.index ["name"], name: "index_subjects_on_name", unique: true
  end

  create_table "subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email"
    t.integer "frequency"
    t.date "expires_on"
    t.jsonb "search_criteria"
    t.string "reference", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transaction_auditors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "task"
    t.boolean "success"
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["task", "date"], name: "index_transaction_auditors_on_task_and_date", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "oid"
    t.datetime "accepted_terms_at"
    t.index ["oid"], name: "index_users_on_oid", unique: true
  end

  create_table "vacancies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "job_title", null: false
    t.string "slug", null: false
    t.text "job_description", null: false
    t.string "minimum_salary", null: false
    t.string "maximum_salary"
    t.text "benefits"
    t.integer "working_pattern"
    t.string "weekly_hours"
    t.date "starts_on"
    t.date "ends_on"
    t.uuid "subject_id"
    t.uuid "min_pay_scale_id"
    t.uuid "leadership_id"
    t.text "education"
    t.text "qualifications"
    t.text "experience"
    t.string "contact_email"
    t.integer "status"
    t.date "expires_on"
    t.date "publish_on"
    t.uuid "school_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "reference", default: -> { "gen_random_uuid()" }, null: false
    t.string "application_link"
    t.boolean "flexible_working"
    t.uuid "max_pay_scale_id"
    t.boolean "newly_qualified_teacher", default: false, null: false
    t.integer "weekly_pageviews"
    t.integer "total_pageviews"
    t.datetime "weekly_pageviews_updated_at"
    t.datetime "total_pageviews_updated_at"
    t.uuid "first_supporting_subject_id"
    t.uuid "second_supporting_subject_id"
    t.integer "total_get_more_info_clicks"
    t.datetime "total_get_more_info_clicks_updated_at"
    t.integer "working_patterns", array: true
    t.boolean "pro_rata_salary"
    t.integer "listed_elsewhere"
    t.integer "hired_status"
    t.index ["expires_on"], name: "index_vacancies_on_expires_on"
    t.index ["first_supporting_subject_id"], name: "index_vacancies_on_first_supporting_subject_id"
    t.index ["leadership_id"], name: "index_vacancies_on_leadership_id"
    t.index ["max_pay_scale_id"], name: "index_vacancies_on_max_pay_scale_id"
    t.index ["min_pay_scale_id"], name: "index_vacancies_on_min_pay_scale_id"
    t.index ["school_id"], name: "index_vacancies_on_school_id"
    t.index ["second_supporting_subject_id"], name: "index_vacancies_on_second_supporting_subject_id"
    t.index ["subject_id"], name: "index_vacancies_on_subject_id"
  end

  create_table "vacancy_publish_feedbacks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "vacancy_id"
    t.integer "rating"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["user_id"], name: "index_vacancy_publish_feedbacks_on_user_id"
    t.index ["vacancy_id"], name: "index_vacancy_publish_feedbacks_on_vacancy_id", unique: true
  end

  add_foreign_key "schools", "detailed_school_types"
end
