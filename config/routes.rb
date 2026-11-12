Rails.application.routes.draw do
  # 301 keeping the query string (redirect('/path') alone drops it).
  moved_to = lambda do |path|
    redirect do |params, request|
      [[path, params[:rest]].compact.join('/'), request.query_string.presence].compact.join('?')
    end
  end

  resource :session
  get 'entrar', to: 'sessions#new', as: :login
  # Before ActiveAdmin.routes, which would read "login" as a resource id.
  get 'admin/login', to: 'sessions#new', as: :admin_login, defaults: { area: 'admin' }
  get 'gestor/login', to: 'sessions#new', as: :gestor_login, defaults: { area: 'gestor' }
  resources :passwords, param: :token
  resources :users, only: %i[new create]
  get 'signup', to: 'users#new'
  resource :account, path: 'minha-conta', only: %i[show update]
  # Before ActiveAdmin.routes: /gestor is also the ActiveAdmin namespace of championship managers.
  get 'gestor/solicitar', to: 'manager_requests#new', as: :new_manager_request
  post 'gestor/solicitar', to: 'manager_requests#create', as: :manager_request
  get 'campeonatos/:id', to: 'championships#show', as: :public_championship, constraints: { id: /\d+/ }

  scope module: :bolao do
    resources :pools, only: %i[index new create show destroy] do
      post :join, on: :collection
      resources :bets, only: %i[index create update]
    end
  end

  scope module: :cartola do
    resource :lineup, only: %i[show edit update destroy]
    get 'esquadrao', to: 'lineups#show', as: :esquadrao
    get 'esquadrao/rankings', to: 'rankings#show', as: :esquadrao_rankings
  end
  get 'cartola', to: moved_to.call('/esquadrao')
  get 'cartola/rankings', to: moved_to.call('/esquadrao/rankings')

  scope module: :simulador do
    get 'simulador', to: 'simulations#index', as: :simulador
    post 'simulador/projecao', to: 'simulations#preview', as: :simulador_projecao
    get 'simulador/:championship_id', to: 'simulations#show', as: :simulador_championship,
                                      constraints: { championship_id: /\d+/ }
    post 'simulador/:championship_id/preview', to: 'simulations#preview', as: :simulador_preview,
                                               constraints: { championship_id: /\d+/ }
  end

  mount MissionControl::Jobs::Engine, at: '/admin/jobs'
  get 'admin/cartolarankings', to: moved_to.call('/admin/esquadraorankings')
  get 'admin/cartola_scoring_rules(/*rest)', to: moved_to.call('/admin/esquadrao_scoring_rules'), format: false
  get 'admin/squads(/*rest)', to: moved_to.call('/admin/esquadrao_squads'), format: false
  # ActiveAdmin registers comments in every namespace even with comments disabled for :gestor.
  match 'gestor/comments(/*rest)', to: proc { [404, { 'content-type' => 'text/plain' }, ['Not Found']] }, via: :all
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
