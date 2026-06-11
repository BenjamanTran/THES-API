# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  Sidekiq::Web.use Rack::Auth::Basic, 'Sidekiq' do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(username, ENV.fetch('SIDEKIQ_USERNAME', 'admin')) &
      ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch('SIDEKIQ_PASSWORD', 'admin'))
  end

  mount Sidekiq::Web => '/sidekiq'
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do
    namespace :v1 do
      post   '/signup',  to: 'registrations#create'
      post   '/login',   to: 'sessions#create'
      delete '/logout',  to: 'sessions#destroy'

      post '/passwords/forgot', to: 'passwords#forgot'
      post '/passwords/reset',  to: 'passwords#reset'
      post '/email_verifications/verify', to: 'email_verifications#verify'
      post '/email_verifications/resend', to: 'email_verifications#resend'
      get    '/me',              to: 'me#show'
      get    '/experiments',     to: 'experiments#show'
      get    '/me/activity',     to: 'me#activity'
      patch  '/me',      to: 'profile#update'
      put    '/me',      to: 'profile#update'
      post   '/me/avatar', to: 'avatars#create'
      delete '/me/avatar', to: 'avatars#destroy'

      resources :venues, only: %i[index create]

      get  '/games/invite/:code', to: 'invites#show'
      post '/games/invite/:code/join', to: 'invites#join'

      resources :games, only: %i[index show create] do
        collection do
          get :search
        end
        member do
          patch :update
          post :join
          post :leave
          post :promote
          post :kick
          patch :rate_player
          patch :update_player
          patch 'players/:user_id/session_played', action: :adjust_session_played
          patch 'players/:user_id/arrived', action: :toggle_arrived
          post :transition
        end

        resources :placeholders, only: %i[create update destroy], controller: 'placeholders'
        resources :player_pairs, only: %i[create destroy], controller: 'player_pairs'

        resource :settlement, only: %i[show update], controller: 'settlements' do
          post :publish
        end

        resources :matches, only: %i[index create update destroy], controller: 'matches' do
          collection do
            delete :pending, action: :destroy_pending
          end
          member do
            post :start
            post :finish
            post :undo_finish
            post :priority
          end
        end
      end
    end
  end

  mount ActionCable.server => '/cable'

  mount Split::Dashboard, at: '/split'

  get '/avatars/:user_id/:filename', to: 'avatars#show',
      constraints: { user_id: /\d+/, filename: %r{[^/]+} }

  get 'up' => 'rails/health#show', as: :rails_health_check

  get 'sidekiq-health' => lambda { |_env|
    require 'sidekiq/api'
    ps = Sidekiq::ProcessSet.new
    cron_jobs = Sidekiq::Cron::Job.all
    body = {
      sidekiq_running: ps.size > 0,
      processes: ps.size,
      cron_jobs: cron_jobs.map { |j| { name: j.name, cron: j.cron, last_enqueue: j.last_enqueue_time&.iso8601, status: j.status } },
      redis: Sidekiq.redis { |c| c.ping } == 'PONG',
      fe_origin: ENV.fetch('FE_ORIGIN', nil),
      rails_env: ENV.fetch('RAILS_ENV', nil)
    }
    [200, { 'Content-Type' => 'application/json' }, [body.to_json]]
  }
end
