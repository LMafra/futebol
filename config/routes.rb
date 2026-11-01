Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :users, only: %i[new create]
  get 'signup', to: 'users#new'

  scope module: :bolao do
    resources :pools, only: %i[index new create show destroy] do
      post :join, on: :collection
      resources :bets, only: %i[index create update]
    end
  end

  scope module: :cartola do
    resource :lineup, only: %i[show edit update destroy]
    get 'cartola/rankings', to: 'rankings#show', as: :cartola_rankings
  end

  mount MissionControl::Jobs::Engine, at: '/admin/jobs'
  ActiveAdmin.routes(self)
  mount Lookbook::Engine, at: '/lookbook' if defined?(Lookbook::Engine)
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root 'home#index'
end
