# frozen_string_literal: true

module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :set_current_user, only: %i[create]
      before_action :set_current_user_optional, only: %i[create]

      def create
        user = User.find_by(email: params[:email].to_s.strip.downcase)
        if user&.authenticate(params[:password].to_s)
          sign_in!(user)
          render json: { user: user_payload(user) }
        else
          render json: { error: 'Email hoặc mật khẩu không đúng' }, status: :unauthorized
        end
      end

      def destroy
        sign_out!
        render json: { status: 'signed_out' }
      end
    end
  end
end
