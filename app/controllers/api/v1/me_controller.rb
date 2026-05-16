# frozen_string_literal: true

module Api
  module V1
    class MeController < BaseController
      def show
        render json: auth_response(@current_user)
      end
    end
  end
end
