# frozen_string_literal: true

module Games
  class SearchQueryBuilder
    MAX_RADIUS = '20km'
    DEFAULT_RADIUS = '5km'

    def initialize(params:, user_tier: nil)
      @params = params
      @user_tier = user_tier
    end

    def build
      {
        query: {
          function_score: {
            query: { bool: { filter: build_filters } },
            functions: build_score_functions,
            score_mode: 'sum',
            boost_mode: 'replace'
          }
        },
        size: page_size,
        from: offset
      }
    end

    def location_provided?
      @params[:lat].present? && @params[:lng].present?
    end

    def lat
      @params[:lat].to_f
    end

    def lng
      @params[:lng].to_f
    end

    private

    def build_filters
      filters = [time_filter]
      filters << status_filter if @params[:status].present?
      filters << geo_filter if location_provided?
      filters.concat(tier_filters) if @user_tier
      filters
    end

    def time_filter
      { range: { start_time: { gte: @params[:from_time] || 'now' } } }
    end

    def status_filter
      { term: { status: @params[:status] } }
    end

    def geo_filter
      { geo_distance: { distance: clamped_radius, location: { lat: lat, lon: lng } } }
    end

    def tier_filters
      [
        { range: { min_tier: { lte: @user_tier } } },
        { range: { max_tier: { gte: @user_tier } } }
      ]
    end

    def build_score_functions
      functions = []
      functions << distance_decay if location_provided?
      functions << time_decay
      functions
    end

    def distance_decay
      { gauss: { location: { origin: { lat: lat, lon: lng }, scale: '3km' } }, weight: 3 }
    end

    def time_decay
      { gauss: { start_time: { origin: 'now', scale: '2h' } }, weight: 1 }
    end

    def clamped_radius
      radius = @params[:radius].presence || DEFAULT_RADIUS
      radius.to_f > MAX_RADIUS.to_f ? MAX_RADIUS : radius
    end

    def page_size
      [@params.fetch(:per_page, 20).to_i, 50].min.clamp(1, 50)
    end

    def offset
      ([@params.fetch(:page, 1).to_i, 1].max - 1) * page_size
    end
  end
end
