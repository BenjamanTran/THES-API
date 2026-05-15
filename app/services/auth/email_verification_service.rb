# frozen_string_literal: true

module Auth
  class EmailVerificationService < ApplicationService
    def initialize(user: nil, raw_token: nil)
      @user = user
      @raw_token = raw_token
    end

    def send_verification
      return failure('Guest không cần xác minh') if @user.guest?
      return success if @user.email_verified?

      raw = @user.issue_email_verification_token!
      Mail::UserMailer.email_verification(@user, raw)
      success
    end

    def verify
      user = @user || find_user_by_token(@raw_token)
      return failure('Token không hợp lệ hoặc đã hết hạn', :unprocessable_content) unless user
      return failure('Email đã được xác minh') if user.email_verified?

      user.verify_email!
      success(user: user)
    end

    private

    def find_user_by_token(raw)
      return nil if raw.blank?

      user = User.find_by(email_verification_digest: User.digest_token(raw))
      return nil unless user&.email_verification_valid?(raw)

      user
    end
  end
end
