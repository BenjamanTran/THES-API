# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do
    namespace :v1 do
      post   '/signup',  to: 'registrations#create'
      post   '/login',   to: 'sessions#create'
      delete '/logout',  to: 'sessions#destroy'
      get    '/me',      to: 'me#show'
      patch  '/me',      to: 'profile#update'
      put    '/me',      to: 'profile#update'

      resources :venues, only: %i[index create]

      get  '/games/invite/:code', to: 'invites#show'
      post '/games/invite/:code/join', to: 'invites#join'

      resources :games, only: %i[index show create] do
        collection do
          get :search
        end
        member do
          post :join
          post :leave
          post :promote
          post :kick
          patch :rate_player
        end

        resources :matches, only: %i[index create destroy], controller: 'matches' do
          member do
            post :start
            post :finish
          end
        end
      end
    end
  end

  get 'up' => 'rails/health#show', as: :rails_health_check
end
