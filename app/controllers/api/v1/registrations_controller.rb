# frozen_string_literal: true

module Api
  module V1
    class RegistrationsController < BaseController
      skip_before_action :set_current_user, only: %i[create]
      before_action :set_current_user_optional, only: %i[create]

      def create
        user = User.new(registration_params)
        if user.save
          sign_in!(user)
          render json: { user: user_payload(user) }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_content
        end
      end

      private

      def registration_params
        params.permit(:email, :name, :password, :password_confirmation)
      end
    end
  end
end
