# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      user = user_from_cookie || user_from_dev_header
      reject_unauthorized_connection unless user

      user
    end

    def user_from_cookie
      raw = cookies.signed[Api::V1::BaseController::SESSION_COOKIE]
      return unless raw.is_a?(Hash)

      payload = raw.with_indifferent_access
      user = User.find_by(id: payload[:user_id])
      return unless user&.session_active?
      return unless user.session_token.present? && user.session_token == payload[:token]

      user
    end

    def user_from_dev_header
      return unless Rails.env.local?

      user_id = request.headers['X-User-Id']
      return if user_id.blank?

      User.find_by(id: user_id)
    end
  end
end
