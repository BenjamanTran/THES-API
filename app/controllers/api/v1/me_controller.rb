# frozen_string_literal: true

module Api
  module V1
    class MeController < BaseController
      def show
        render json: { user: user_payload(@current_user) }
      end
    end
  end
end
