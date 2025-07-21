Rails.application.routes.draw do
  root "home#index"

  devise_for :users, controllers: {
    confirmations: "devise/confirmations"
  }

  resources :stocks, only: %i[index show]
  resources :trades, only: %i[new create index show]
  get "portfolio", to: "trades#portfolio"

  namespace :admin do
    resources :traders, only: [ :index, :show, :destroy ] do
      collection do
        get :pending
      end
      member do
        patch :approve
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
