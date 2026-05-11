# frozen_string_literal: true

module Api
  module V1
    class ProfileController < BaseController
      def update
        ActiveRecord::Base.transaction do
          @current_user.update!(user_params)
          apply_tier_change!(params[:tier]) if params.key?(:tier)
        end
        render json: { user: user_payload(@current_user.reload) }
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
      rescue ArgumentError => e
        render json: { errors: [e.message] }, status: :unprocessable_content
      end

      private

      def user_params
        permitted = params.permit(:name, :gender, :phone)
        permitted.delete(:phone) unless params.key?(:phone)
        permitted
      end

      def apply_tier_change!(tier)
        tier_sym = tier.to_s.to_sym
        raise ArgumentError, 'Trình độ không hợp lệ' unless Rank.tiers.key?(tier_sym.to_s)

        rating = lower_bound_for(tier_sym)
        division = tier_sym == :professional ? nil : 3

        rank = @current_user.rank || @current_user.build_rank
        rank.assign_attributes(tier: tier_sym, rating: rating, division: division)
        rank.save!
      end

      def lower_bound_for(tier_sym)
        entry = Rank::RATING_TIERS.find { |_range, t| t == tier_sym }
        return 0 unless entry

        range = entry.first
        range.begin || 0
      end
    end
  end
end
