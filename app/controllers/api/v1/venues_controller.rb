# frozen_string_literal: true

module Api
  module V1
    class VenuesController < BaseController
      skip_before_action :set_current_user, only: [:index]
      before_action :set_current_user_optional, only: [:index]

      def index
        venues = Venue.by_city(params[:city]).search(params[:q]).verified_first.limit(50)
        render json: { venues: venues.map { |v| venue_payload(v) } }
      end

      def create
        if @current_user.guest?
          return render json: { error: 'Tài khoản khách không thể thêm sân' }, status: :forbidden
        end

        venue = Venue.new(venue_params)
        venue.created_by = @current_user
        venue.save!
        render json: { venue: venue_payload(venue) }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_content
      end

      private

      def venue_params
        params.permit(:name, :address, :city, :district, :lat, :lng)
      end

      def venue_payload(venue)
        {
          id: venue.id,
          name: venue.name,
          address: venue.address,
          city: venue.city,
          district: venue.district,
          lat: venue.lat,
          lng: venue.lng,
          verified: venue.verified
        }
      end
    end
  end
end
