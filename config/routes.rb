Rails.application.routes.draw do
  root "home#index"

  devise_for :users, controllers: {
    confirmations: "devise/confirmations"
  }

  resources :stocks, only: %i[index show]
  resources :trades, only: %i[new create index show]
  get "portfolio", to: "trades#portfolio"

  namespace :admin do
    resources :traders do
      collection do
        get :pending
      end
      member do
        patch :approve
      end
    end
    resources :trades, only: [ :index ]
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "/500", to: "errors#internal_server_error"
  match "*path", to: "errors#errors", via: :all
end
