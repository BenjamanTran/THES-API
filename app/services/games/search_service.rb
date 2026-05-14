# frozen_string_literal: true

module Games
  class SearchService < ApplicationService
    def initialize(params:, user: nil)
      super()
      @params = params
      @user = user
      @query_builder = SearchQueryBuilder.new(params: params, user_tier: user_tier)
    end

    def call
      return success(fallback_payload) unless Rails.application.config.x.elasticsearch_enabled

      results = search_elasticsearch
      success(games: results, meta: es_meta(results.length))
    rescue Faraday::ConnectionFailed, Elastic::Transport::Transport::Error
      success(fallback_payload)
    end

    private

    def search_elasticsearch
      response = Game.__elasticsearch__.search(@query_builder.build)
      ids = response.results.map { |r| r._id.to_i }
      games_by_id = Game.includes(:host, :matches).where(id: ids).index_by(&:id)

      response.results.filter_map { |r| build_result(r, games_by_id[r._id.to_i]) }
    end

    def build_result(result, game)
      return unless game

      source = result._source
      item = game.slice(:id, :start_time, :end_time, :status, :match_type,
                        :players_count, :max_players, :lat, :lng, :location,
                        :description, :title, :min_tier, :max_tier)
      item[:host] = { id: game.host&.id, name: game.host&.name }
      item[:distance_km] = distance_km(result) if @query_builder.location_provided?
      item[:fit_level] = compute_fit_level(source) if @user&.rank
      loaded_m = game.matches.loaded? ? game.matches : game.matches.load
      item[:matches_count] = loaded_m.length
      item[:matches_finished] = loaded_m.count(&:finished?)
      item
    end

    def distance_km(result)
      loc = result._source.location
      return unless loc

      haversine_distance(@query_builder.lat, @query_builder.lng, loc.lat, loc.lon)
    rescue StandardError
      nil
    end

    def haversine_distance(lat1, lng1, lat2, lng2)
      GeoCalculator.distance_km(lat1, lng1, lat2, lng2)
    end

    def compute_fit_level(source)
      return unless user_tier

      if user_tier.between?(source.min_tier || 0, source.max_tier || 0)
        'good'
      elsif (user_tier - (source.min_tier || 0)).abs <= 1 || (user_tier - (source.max_tier || 0)).abs <= 1
        'warning'
      else
        'hard'
      end
    end

    def fallback_query
      scope = Game.includes(:host)
                  .where(end_time: Time.current..)
                  .where.not(status: :cancelled)

      scope = apply_status_filter(scope)
      scope = apply_match_type_filter(scope)
      scope = apply_tier_filter(scope)
      scope = apply_not_full_filter(scope)
      scope = apply_price_filter(scope)
      scope = apply_radius_filter_sql(scope) if @query_builder.location_provided?
      scope = apply_sort(scope)

      scope.page(fallback_page).per(fallback_per_page)
    end

    def apply_status_filter(scope)
      return scope if @params[:status].blank?

      scope.where(status: @params[:status])
    end

    def apply_match_type_filter(scope)
      return scope if @params[:match_type].blank?

      scope.where(match_type: @params[:match_type])
    end

    def apply_tier_filter(scope)
      tier = @params[:tier]
      return scope if tier.blank? || !Game::TIERS.key?(tier)

      tier_val = Game::TIERS[tier]
      scope.where('min_tier <= ? AND max_tier >= ?', tier_val, tier_val)
    end

    def apply_not_full_filter(scope)
      return scope unless ActiveModel::Type::Boolean.new.cast(@params[:not_full])

      scope.where('players_count < max_players')
    end

    def apply_price_filter(scope)
      raw = @params[:price_max]
      return scope if raw.blank?

      max = raw.to_i
      return scope if max <= 0

      scope.where('min_price <= ?', max)
    end

    def apply_sort(scope)
      case @params[:sort].to_s
      when 'start_time_asc' then scope.order(start_time: :asc)
      when 'created_at_asc' then scope.order(created_at: :asc)
      else
        if @query_builder.location_provided?
          scope.order(Arel.sql('distance_km ASC'))
        else
          scope.order(created_at: :desc)
        end
      end
    end

    def apply_radius_filter_sql(scope)
      lat = @query_builder.lat
      lng = @query_builder.lng
      radius_meters = parse_radius_km * 1000

      distance_sql = ActiveRecord::Base.sanitize_sql_array([
        'ST_Distance_Sphere(POINT(games.lng, games.lat), POINT(?, ?)) / 1000 AS distance_km',
        lng, lat
      ])
      where_sql = ActiveRecord::Base.sanitize_sql_array([
        'games.lat IS NOT NULL AND games.lng IS NOT NULL ' \
        'AND ST_Distance_Sphere(POINT(games.lng, games.lat), POINT(?, ?)) <= ?',
        lng, lat, radius_meters
      ])

      scope.select('games.*').select(Arel.sql(distance_sql)).where(Arel.sql(where_sql))
    end

    def parse_radius_km
      raw = @params[:radius].to_s
      n = raw.gsub(/km$/i, '').to_f
      n.positive? ? n : 5.0
    end

    def fallback_per_page
      raw = @params[:per_page].to_i
      raw = 20 if raw <= 0
      raw.clamp(1, 50)
    end

    def fallback_page
      raw = @params[:page].to_i
      raw < 1 ? 1 : raw
    end

    def fallback_payload
      paginated = fallback_query
      {
        games: paginated.map { |g| fallback_item(g) },
        meta: kaminari_meta(paginated)
      }
    end

    def kaminari_meta(collection)
      {
        page: collection.current_page,
        per_page: collection.limit_value,
        total: collection.total_count,
        total_pages: collection.total_pages,
        has_more: collection.current_page < collection.total_pages
      }
    end

    def es_meta(size)
      { page: fallback_page, per_page: fallback_per_page, has_more: size >= fallback_per_page }
    end

    def fallback_item(game)
      item = game.slice(:id, :start_time, :end_time, :status, :match_type,
                        :players_count, :max_players, :lat, :lng, :location,
                        :description, :title, :min_tier, :max_tier,
                        :min_price, :max_price)
      item[:host] = { id: game.host&.id, name: game.host&.name }
      item[:fit_level] = game.fit_level(@user) if @user
      item[:distance_km] = game.try(:distance_km)&.to_f&.round(2) if @query_builder.location_provided?
      item[:matches_count] = game.matches_count
      item[:matches_finished] = game.matches_count.positive? ? game.matches.where(status: :finished).count : 0
      item
    end

    def user_tier
      return unless @user&.rank

      Game::TIERS[@user.rank.tier]
    end
  end
end
