# frozen_string_literal: true

module Auth
  class PasswordResetService < ApplicationService
    def initialize(email: nil)
      @email = email.to_s.strip.downcase if email.present?
    end

    def request_reset
      return failure('Email is required') if @email.blank?
      user = User.find_by(email: @email)
      return success if user.nil? || user.guest?

      raw = user.issue_password_reset_token!
      Mail::UserMailer.password_reset(user, raw)
      success
    end

    def reset_password(raw_token:, password:, password_confirmation:)
      user = find_user_by_reset_token(raw_token)
      return failure('Token không hợp lệ hoặc đã hết hạn', :unprocessable_content) unless user

      user.password = password
      user.password_confirmation = password_confirmation
      if user.save
        user.clear_password_reset!
        user.end_session!
        success(user: user)
      else
        failure(user.errors.full_messages.join(', '))
      end
    end

    private

    def find_user_by_reset_token(raw)
      return nil if raw.blank?

      user = User.find_by(password_reset_digest: User.digest_token(raw))
      return nil unless user&.password_reset_valid?(raw)

      user
    end
  end
end
