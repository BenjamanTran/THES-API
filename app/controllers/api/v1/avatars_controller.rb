# frozen_string_literal: true

module Api
  module V1
    class AvatarsController < BaseController
      def create
        result = Users::UploadAvatarService.call(user: @current_user, file: params[:avatar])
        if result.success?
          render json: auth_response(@current_user)
        else
          render json: { errors: [result.error] }, status: result.status
        end
      end

      def destroy
        Users::DeleteAvatarService.call(user: @current_user)
        render json: auth_response(@current_user)
      end
    end
  end
end
