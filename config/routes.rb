Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  namespace :api do
    namespace :v1 do
      resources :games, only: %i[create show] do
        member do
          post :join
          post :leave
        end
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
