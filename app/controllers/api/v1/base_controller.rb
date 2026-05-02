# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
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
        user_id = request.headers['X-User-Id']
        return if user_id.blank?

        User.find_by(id: user_id)
      end
    end
  end
end
