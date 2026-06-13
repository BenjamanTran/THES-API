# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      include Split::EncapsulatedHelper

      SESSION_COOKIE = :smashhub_session

      before_action :set_current_user

      private

      def set_current_user
        @current_user = find_current_user
        render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
      end

      def set_current_user_optional
        @current_user = find_current_user
      end

      def find_current_user
        user_from_cookie || user_from_token_header || user_from_dev_header
      end

      def user_from_cookie
        raw = cookies.signed[SESSION_COOKIE]
        return unless raw.is_a?(Hash)

        payload = raw.with_indifferent_access
        user = User.find_by(id: payload[:user_id])
        return unless user&.session_active?
        return unless user.session_token.present? && user.session_token == payload[:token]

        user
      end

      def user_from_token_header
        token = request.headers['X-Session-Token']
        return if token.blank?

        user = User.find_by(session_token: token)
        return unless user&.session_active?

        user
      end

      def user_from_dev_header
        return unless Rails.env.local?

        user_id = request.headers['X-User-Id']
        return if user_id.blank?

        User.find_by(id: user_id)
      end

      def sign_in!(user)
        user.start_session!
        cookies.signed[SESSION_COOKIE] = session_cookie_options.merge(
          value: { user_id: user.id, token: user.session_token },
          expires: User::SESSION_LIFETIME.from_now
        )
      end

      def sign_out!
        @current_user&.end_session!
        cookies.delete(SESSION_COOKIE, session_cookie_delete_options)
      end

      # Shared cookie options for auth (separate from Rails session store key).
      def session_cookie_options
        opts = {
          httponly: true,
          secure: !Rails.env.development?,
          path: '/'
        }

        cookie_domain = ENV['COOKIE_DOMAIN'].to_s.strip.presence
        if cookie_domain.present?
          # Custom domain: app.example.com + api.example.com share cookie (SameSite=Lax).
          opts[:domain] = cookie_domain
          opts[:same_site] = :lax
        elsif Rails.env.development?
          opts[:same_site] = :lax
        else
          # Cross-site (*.run.app): None + Partitioned for Safari CHIPS.
          opts[:same_site] = :none
          opts[:partitioned] = true
        end

        opts
      end

      def session_cookie_delete_options
        session_cookie_options.except(:expires, :value)
      end

      def auth_response(user)
        if user.persisted?
          Users::BackfillPlayTime.call(user: user)
          user.reload
        end

        resp = {
          user: user_payload(user),
          stats: Users::StatsPayload.call(user: user),
          profile: Users::ProfilePayload.call(user: user),
          experiments: Experiments::Catalog.assign(self, user),
          active_manage_game: Games::ActiveManageGame.call(user: user)
        }
        resp[:session_token] = user.session_token if user.session_token.present?
        resp
      end

      def user_payload(user)
        user.slice(:id, :email, :name, :gender, :phone, :guest).merge(
          email_verified: user.email_verified?,
          avatar_url: Users::AvatarStorage.display_url_for(user),
          rank: rank_payload(user.rank),
          declared_rank: declared_rank_payload(user.rank)
        )
      end

      def player_avatar_fields(user)
        { avatar_url: Users::AvatarStorage.display_url_for(user) }
      end

      def rank_payload(rank)
        return unless rank

        computed = Users::GlobalRatingCalculator.call(user: rank.user)
        rank.slice(:wins, :losses, :matches_count, :play_time_seconds).merge(
          tier: computed[:tier],
          division: computed[:division],
          rating: computed[:rating],
          display_name: computed[:display_name],
          host_rating_count: computed[:host_rating_count],
          host_base_rating: computed[:host_base_rating],
          match_points: computed[:match_points]
        )
      end

      def declared_rank_payload(rank)
        return unless rank

        tier_key = declared_tier_key(rank) || rank.tier
        return unless tier_key

        rating_val = rank.declared_rating.presence || rank.rating.presence || Rank.rating_from_tier_and_stars(tier_key, 3)

        {
          tier: tier_key.to_s,
          rating: rating_val,
          display_name: I18n.t("ranks.#{tier_key}")
        }
      end

      def declared_tier_key(rank)
        return unless rank.declared_tier.present?

        Rank.tiers.key(rank.declared_tier)
      end

      # Placeholders use host-assigned skill at creation, not global rating.
      def placeholder_rank_payload(rank)
        return unless rank

        tier_key = declared_tier_key(rank) || rank.tier
        rating_val = rank.declared_rating.presence || rank.rating

        rank.slice(:wins, :losses, :matches_count, :division).merge(
          tier: tier_key.to_s,
          rating: rating_val,
          display_name: I18n.t("ranks.#{tier_key}")
        )
      end

      def game_player_rank_payload(user, computed: true)
        return unless user.rank

        if computed && !user.placeholder?
          rank_payload(user.rank)
        else
          game_player_rank_stored(user)
        end
      end

      # Game/match screens: use persisted rank (avoids N× GlobalRatingCalculator queries).
      def game_player_rank_stored(user)
        return unless user.rank

        rank = user.rank
        if user.placeholder?
          placeholder_rank_payload(rank)
        else
          tier_key = rank.tier
          rank.slice(:wins, :losses, :matches_count, :division).merge(
            tier: tier_key.to_s,
            rating: rank.rating,
            display_name: I18n.t("ranks.#{tier_key}")
          )
        end
      end

      # In-game skill display/balance: host session rating only (not global rank).
      def host_rated_fields(participation)
        return {} unless participation&.host_rated_tier.present? && participation.host_rated_stars.present?

        fields = {
          host_rated_tier: participation.host_rated_tier_key,
          host_rated_stars: participation.host_rated_stars
        }
        fields[:host_rating_note] = participation.host_rating_note if participation.host_rating_note.present?
        fields
      end

      def session_skill_rank_from_participation(participation)
        return unless participation&.host_rated_tier.present? && participation.host_rated_stars.present?

        tier_key = participation.host_rated_tier_key
        rating_val = Rank.rating_from_tier_and_stars(tier_key.to_sym, participation.host_rated_stars)
        {
          tier: tier_key,
          rating: rating_val,
          display_name: I18n.t("ranks.#{tier_key}"),
          division: nil
        }
      end

      def merge_session_skill!(payload, participation)
        payload.merge!(host_rated_fields(participation))
        rank = session_skill_rank_from_participation(participation)
        payload[:rank] = rank if rank
        payload
      end
    end
  end
end
