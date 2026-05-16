# frozen_string_literal: true

module Api
  module V1
    class ProfileController < BaseController
      def update
        ActiveRecord::Base.transaction do
          @current_user.update!(user_params)
          apply_tier_change!(params[:tier]) if params.key?(:tier)
        end
        render json: auth_response(@current_user)
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
      rescue ArgumentError => e
        render json: { errors: [e.message] }, status: :unprocessable_content
      end

      private

      def user_params
        permitted = params.permit(:name, :gender, :phone)
        permitted.delete(:phone) unless params.key?(:phone)

        if @current_user.guest? && params[:email].present? && params[:password].present?
          permitted[:email] = params[:email]
          permitted[:password] = params[:password]
          permitted[:password_confirmation] = params[:password_confirmation]
          permitted[:guest] = false
        end

        permitted
      end

      def apply_tier_change!(tier)
        tier_sym = tier.to_s.to_sym
        raise ArgumentError, 'Trình độ không hợp lệ' unless Rank.tiers.key?(tier_sym.to_s)

        stars = params[:stars].present? ? params[:stars].to_i : 1
        rating = Rank.rating_from_tier_and_stars(tier_sym, stars)
        division = tier_sym == :professional ? nil : 3

        rank = @current_user.rank || @current_user.build_rank
        rank.assign_attributes(
          tier: tier_sym,
          rating: rating,
          division: division,
          declared_tier: Rank.tiers[tier_sym],
          declared_rating: rating
        )
        rank.save!
      end
    end
  end
end
