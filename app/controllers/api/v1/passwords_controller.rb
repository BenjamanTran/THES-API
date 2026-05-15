# frozen_string_literal: true

module Api
  module V1
    class PasswordsController < BaseController
      skip_before_action :set_current_user

      def forgot
        Auth::PasswordResetService.new(email: params[:email]).request_reset
        render json: { message: 'Nếu email tồn tại, bạn sẽ nhận link đặt lại mật khẩu.' }
      end

      def reset
        result = Auth::PasswordResetService.new(email: nil).reset_password(
          raw_token: params[:token],
          password: params[:password],
          password_confirmation: params[:password_confirmation]
        )
        if result.success?
          sign_in!(result.data[:user])
          render json: { user: user_payload(result.data[:user]), message: 'Mật khẩu đã được cập nhật.' }
        else
          render json: { error: result.error }, status: result.status
        end
      end
    end
  end
end
