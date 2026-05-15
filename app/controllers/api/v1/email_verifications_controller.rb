# frozen_string_literal: true

module Api
  module V1
    class EmailVerificationsController < BaseController
      skip_before_action :set_current_user, only: :verify
      before_action :set_current_user_optional, only: :verify

      def verify
        result = Auth::EmailVerificationService.new(raw_token: params[:token]).verify
        if result.success?
          sign_in!(result.data[:user]) if result.data[:user]
          render json: {
            message: 'Email đã được xác minh.',
            user: user_payload(result.data[:user])
          }
        else
          render json: { error: result.error }, status: result.status
        end
      end

      def resend
        result = Auth::EmailVerificationService.new(user: @current_user).send_verification
        if result.success?
          render json: { message: 'Email xác minh đã được gửi.' }
        else
          render json: { error: result.error }, status: :unprocessable_content
        end
      end
    end
  end
end
