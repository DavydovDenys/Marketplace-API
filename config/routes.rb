# frozen_string_literal: true

Rails.application.routes.draw do
  root 'home#home'

  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  resources :healthz, only: %i[index create]

  namespace :api do
    namespace :v1 do
      post 'auth/registry', to: 'authentication#registry'
      post 'auth/refresh', to: 'authentication#refresh'
      post 'auth/login', to: 'authentication#login'
    end
  end
end
