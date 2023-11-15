# frozen_string_literal: true

Rails.application.routes.draw do
  root 'home#home'

  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  resources :healthz, only: %i[index create]
end
