Rails.application.routes.draw do
  resources :users
  resources :appointments
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  get 'home/index', to: 'home#index'
  resources :patients
  resources :appointments

  get '/dashboard', to: 'patients#dashboard', as: 'patient_dashboard'
  get '/book', to: 'patients#book_appointment', as: 'patient_book_appointment'
  get '/book/weekly', to: 'patients#week_appointments', as: 'patient_week_appointments'
  post '/book/create', to: 'patients#create_appointment', as: 'patient_create_appointment'

  # Defines the root path route ("/")
  root "home#index"
end
