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
      results = search_elasticsearch
      success(games: results)
    rescue Faraday::ConnectionFailed, Elastic::Transport::Transport::Error
      success(games: fallback_sql)
    end

    private

    def search_elasticsearch
      response = Game.__elasticsearch__.search(@query_builder.build)
      ids = response.results.map { |r| r._id.to_i }
      games_by_id = Game.includes(:host).where(id: ids).index_by(&:id)

      response.results.filter_map { |r| build_result(r, games_by_id[r._id.to_i]) }
    end

    def build_result(result, game)
      return unless game

      source = result._source
      item = game.slice(:id, :start_time, :end_time, :status, :match_type,
                        :players_count, :max_players, :lat, :lng, :location,
                        :description, :min_tier, :max_tier)
      item[:host] = { id: game.host&.id, name: game.host&.name }
      item[:distance_km] = distance_km(result) if @query_builder.location_provided?
      item[:fit_level] = compute_fit_level(source) if @user&.rank
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

    def fallback_sql
      Game.includes(:host)
          .where(start_time: Time.current..)
          .where.not(status: :cancelled)
          .order(start_time: :asc)
          .limit(20)
          .map { |g| fallback_item(g) }
    end

    def fallback_item(game)
      item = game.slice(:id, :start_time, :end_time, :status, :match_type,
                        :players_count, :max_players, :lat, :lng, :location,
                        :description, :min_tier, :max_tier)
      item[:host] = { id: game.host&.id, name: game.host&.name }
      item[:fit_level] = game.fit_level(@user) if @user
      item
    end

    def user_tier
      return unless @user&.rank

      Game::TIERS[@user.rank.tier]
    end
  end
end
