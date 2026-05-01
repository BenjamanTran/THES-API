# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      before_action :set_current_user

      private

      def set_current_user
        @current_user = User.find_by(id: request.headers['X-User-Id'])
        render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
      end

      def set_current_user_optional
        @current_user = User.find_by(id: request.headers['X-User-Id'])
      end
    end
  end
end
