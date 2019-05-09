Rails.application.routes.draw do
  root 'vacancies#index'

  get 'check' => 'application#check'
  get 'sitemap' => 'sitemap#show', format: 'xml'

  get '/pages/*id' => 'pages#show', as: :page, format: false

  resources :jobs, only: %i[index show], controller: 'vacancies' do
    resources :interests, only: %i[new]
  end

  # Backward compatibility after changing routes to 'jobs'
  resources :vacancies, only: [:show], controller: 'vacancies' do
    resources :interests, only: %i[new]
  end

  resource :feedback, controller: 'general_feedback', only: %i[new create]

  resources :subscriptions, only: %i[new create] do
    get :unsubscribe
    resource :confirmation, only: [:show]
  end

  namespace :api do
    scope 'v:api_version', api_version: /[1]/ do
      resources :jobs, only: %i[index show], controller: 'vacancies'
    end
  end

  resources :stats, only: [:index]

  resource :identifications, only: %i[new create], controller: 'hiring_staff/identifications'

  # Sign in
  resource :sessions, only: %i[destroy], controller: 'hiring_staff/sessions'

  # DfE Sign In
  resource :sessions,
           only: %i[create new],
           as: :dfe,
           path: '/dfe/sessions',
           controller: 'hiring_staff/sign_in/dfe/sessions'
  get '/auth/dfe/callback', to: 'hiring_staff/sign_in/dfe/sessions#create'
  get '/auth/failure', to: 'hiring_staff/sign_in/dfe/sessions#new'

  resource :terms_and_conditions, only: %i[show update], controller: 'hiring_staff/terms_and_conditions'

  resource :school, only: %i[show edit update], controller: 'hiring_staff/schools' do
    scope constraints: { type: /(published|draft|pending|expired|awaiting_feedback)/ } do
      get 'jobs(/:type)', to: 'hiring_staff/schools#show', defaults: { type: :published }, as: :jobs_with_type
    end
    resources :jobs, only: %i[new edit destroy delete show], controller: 'hiring_staff/vacancies' do
      get 'review'
      get 'summary'
      post :publish, to: 'hiring_staff/vacancies/publish#create'
      get :publish, to: 'hiring_staff/vacancies/publish#create'
      resource :job_specification, only: %i[edit update],
                                   controller: 'hiring_staff/vacancies/job_specification'
      resource :candidate_specification, only: %i[edit update],
                                         controller: 'hiring_staff/vacancies/candidate_specification'
      resource :application_details, only: %i[edit update],
                                     controller: 'hiring_staff/vacancies/application_details'

      resource :feedback, controller: 'hiring_staff/vacancies/vacancy_publish_feedback', only: %i[new create]
      resource :copy, only: %i[new create],
                      controller: 'hiring_staff/vacancies/copy'
    end

    resource :job, only: [] do
      get :job_specification, to: 'hiring_staff/vacancies/job_specification#new'
      post :job_specification, to: 'hiring_staff/vacancies/job_specification#create'
      get :candidate_specification, to: 'hiring_staff/vacancies/candidate_specification#new'
      post :candidate_specification, to: 'hiring_staff/vacancies/candidate_specification#create'
      get :application_details, to: 'hiring_staff/vacancies/application_details#new'
      post :application_details, to: 'hiring_staff/vacancies/application_details#create'
    end
  end

  match '/401', to: 'errors#unauthorised', via: :all
  match '/404', to: 'errors#not_found', via: :all
  match '/422', to: 'errors#unprocessable_entity', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
  match '*path', to: 'errors#not_found', via: :all

  # External URL

  direct :roll_out_blog do
    'https://dfedigital.blog.gov.uk/2018/09/21/how-were-rolling-out-our-search-and-listing-service-to-more-schools-to-support-their-teacher-recruitment-needs/'
  end
end
