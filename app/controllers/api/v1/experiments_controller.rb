# frozen_string_literal: true

module Api
  module V1
    class ExperimentsController < BaseController
      skip_before_action :set_current_user
      before_action :set_current_user_optional

      def show
        render json: { experiments: Experiments::Catalog.assign(self, @current_user) }
      end
    end
  end
end
