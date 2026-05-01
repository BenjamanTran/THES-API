# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do
    namespace :v1 do
      resources :games, only: %i[index show create] do
        collection do
          get :search
        end
        member do
          post :join
          post :leave
        end
      end
    end
  end

  get 'up' => 'rails/health#show', as: :rails_health_check
end
