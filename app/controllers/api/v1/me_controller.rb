# frozen_string_literal: true

module Api
  module V1
    class MeController < BaseController
      def show
        render json: auth_response(@current_user)
      end

      def activity
        limit = params[:limit].presence&.to_i
        limit = Users::RecentActivityFeed::PAGE_LIMIT if limit.nil? || limit <= 0
        offset = params[:offset].presence&.to_i || 0

        render json: Users::RecentActivityFeed.call(
          user: @current_user,
          limit: limit,
          offset: offset
        )
      end
    end
  end
end
