Rails.application.routes.draw do
  get "trades/new"
  get "trades/create"
  get "trades/index"
  get "stocks/index"
  get "stocks/show", to: "stocks#show"
  devise_for :users
   resources :stocks, only: %i[ index show ]
   resources :trades, only: %i[ new create index ]
  get "portfolio", to: "trades#portfolio"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "stocks#index"
end
