Rails.application.routes.draw do
  Rails.application.routes.default_url_options[:host]
  get 'clinic_special_cases/create'
  get 'clinic_special_cases/update'
  # resources :users
  get '/webhook', to: 'callback#index'
  post '/webhook', to: 'callback#received_data'

  get '/profile/webhook', to: 'callback#get_user_profile'
  post '/profile/webhook', to: 'callback#post_user_profile'
  
  require 'sidekiq/web'
  Rails6Webdass::Application.routes.draw do
    authenticate :user, lambda { |u| u.doctor? || u.secretary? } do
      mount Sidekiq::Web => "/sidekiq" # mount Sidekiq::Web in your Rails app
    end
  end

  resources :appointments do
    get :autocomplete_schedule, on: :collection
  end
  resources :clinics do
    resources :clinic_schedules
  end

  # get '/clinics/:clinic_id/clinic_schedules/:id'

  devise_for :users
  resources :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  get 'home/index', to: 'home#index'
  resources :patients
  resources :clinic_schedules do
    resources :clinic_special_cases
  end

  # get 'clinic_queues/export', to: 'doctor/clinic_queues#export'

  resource :doctor do
    resources :appointments, module: :doctors
    resources :clinic_queues, module: :doctors do
      get :export, on: :collection, defaults: { format: :csv }
      get :queue_autocomplete_patient, on: :collection
      post :next_patient, on: :collection
      post :cancel_todays_queue, on: :collection
      post :start_queue, on: :collection
      post :toggle_skip_for_now, on: :member
    end
    get :autocomplete_patient, on: :collection
    get :autocomplete_schedule, on: :collection
  end

  get '/dashboard', to: 'patients#dashboard', as: 'patient_dashboard'
  get '/my_appointments', to: 'patients#my_appointments', as: 'patient_my_appointments'
  get '/book', to: 'patients#book_appointment', as: 'patient_book_appointment'
  post '/book', to: 'patients#book_patient_appointment', as: 'user_book_patient_appointment'
  post '/book/patient', to: 'patients#book_existing_patient_appointment', as: 'patient_book_patient_appointment'
  get '/book/weekly', to: 'patients#week_appointments', as: 'patient_week_appointments'
  post '/book/create', to: 'patients#create_appointment', as: 'patient_create_appointment'

  get '/doctor/dashboard', to: 'doctors#dashboard', as: 'doctor_dashboard'
  get '/doctor/book', to: 'doctors#book_appointment', as: 'doctor_book_appointment'
  get '/doctor/patients', to: 'doctors#patients_index', as: 'doctor_patients'
  get '/doctor/clinics', to: 'doctors#clinics_index', as: 'doctor_clinics'
  get '/doctor/staffs', to: 'doctors#staffs_index', as: 'doctor_staffs'
  post '/doctor/staffs', to: 'doctors#create_staff', as: 'doctor_staffs_create'
  post '/doctor/clinics/:id', to: 'doctors#destroy_clinic', as: 'doctor_destroy_clinic'
  get '/doctor/queue', to: 'doctors#queue_index', as: 'doctor_queue'

  # post '/doctor/queue/patient/create', to: 'doctors#add_existing_patient_to_queue', as: 'add_existing_patient_to_queue'

  post '/doctor/book', to: 'doctors#book_patient_appointment', as: 'book_patient_appointment'
  post '/doctor/book/existing', to: 'doctors#book_existing_patient_appointment', as: 'book_existing_patient_appointment'

  resources :clinic_queues

  post '/doctor/clinic_queues/walkin', to: 'doctors/clinic_queues#add_patient_to_queue', as: 'add_patient_to_queue'

  post '/doctor/clinic_queues/existing', to: 'doctors/clinic_queues#add_existing_patient_to_queue', as: 'add_existing_patient_to_queue'

  # resources :doctors do
  #   get :autocomplete_patient, :on => :collection
  # end
  get :search, controller: :doctors
  get :autocomplete, to: 'pages#autocomplete'
  # get '/doctor/queue/:id', to: 'doctors#queue_show', as: 'doctor_queue_show'

  # get '/doctor/queue', to: 'clinic_queues#setup_show_page'
  # resources :clinic_queues, only: [:show, :edit, :update]

  # Defines the root path route ("/")
  root "home#index"
end
