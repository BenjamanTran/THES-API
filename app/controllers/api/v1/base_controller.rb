# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      SESSION_COOKIE = :smashhub_session

      before_action :set_current_user

      private

      def set_current_user
        @current_user = find_current_user
        render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
      end

      def set_current_user_optional
        @current_user = find_current_user
      end

      def find_current_user
        user_from_cookie || user_from_dev_header
      end

      def user_from_cookie
        raw = cookies.signed[SESSION_COOKIE]
        return unless raw.is_a?(Hash)

        payload = raw.with_indifferent_access
        user = User.find_by(id: payload[:user_id])
        return unless user && user.session_token.present? && user.session_token == payload[:token]

        user
      end

      def user_from_dev_header
        return unless Rails.env.local?

        user_id = request.headers['X-User-Id']
        return if user_id.blank?

        User.find_by(id: user_id)
      end

      def sign_in!(user)
        user.ensure_session_token!
        cookies.signed[SESSION_COOKIE] = session_cookie_options.merge(
          value: { user_id: user.id, token: user.session_token },
          expires: 30.days.from_now
        )
      end

      def sign_out!
        @current_user&.rotate_session_token!
        cookies.delete(SESSION_COOKIE, session_cookie_delete_options)
      end

      # Shared cookie options for auth (separate from Rails session store key).
      def session_cookie_options
        opts = {
          httponly: true,
          secure: !Rails.env.development?,
          path: '/'
        }

        cookie_domain = ENV['COOKIE_DOMAIN'].to_s.strip.presence
        if cookie_domain.present?
          # Custom domain: app.example.com + api.example.com share cookie (SameSite=Lax).
          opts[:domain] = cookie_domain
          opts[:same_site] = :lax
        elsif Rails.env.development?
          opts[:same_site] = :lax
        else
          # Cross-site (*.run.app): None + Partitioned for Safari CHIPS.
          opts[:same_site] = :none
          opts[:partitioned] = true
        end

        opts
      end

      def session_cookie_delete_options
        session_cookie_options.except(:expires, :value)
      end

      def user_payload(user)
        user.slice(:id, :email, :name, :gender, :phone, :guest).merge(
          email_verified: user.email_verified?,
          rank: rank_payload(user.rank)
        )
      end

      def rank_payload(rank)
        return unless rank

        rank.slice(:tier, :division, :rating).merge(display_name: rank.display_name)
      end
    end
  end
end
