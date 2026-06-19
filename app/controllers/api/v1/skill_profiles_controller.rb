# frozen_string_literal: true

module Api
  module V1
    class SkillProfilesController < BaseController
      def update
        UserSkillSnapshot.upsert_for_month!(
          user: @current_user,
          tier: params.require(:tier),
          month: Date.current,
          scores: skill_scores
        )

        @current_user.reload
        render json: auth_response(@current_user)
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
      rescue ArgumentError => e
        render json: { errors: [e.message] }, status: :unprocessable_content
      rescue ActionController::ParameterMissing => e
        render json: { errors: [e.message] }, status: :unprocessable_content
      end

      private

      def skill_scores
        params.require(:scores).permit(*UserSkillSnapshot::AXES).to_h.symbolize_keys.transform_values(&:to_i)
      end
    end
  end
end
