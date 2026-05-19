# frozen_string_literal: true

module Api
  module V1
    class InvitesController < BaseController
      skip_before_action :set_current_user

      before_action :set_game_by_code

      def show
        render json: invite_payload
      end

      def join
        return render json: { error: 'Trận đã bắt đầu — chỉ xem được lịch thi đấu' }, status: :unprocessable_content if session_started?
        return render json: { error: 'Game is not open for joining' }, status: :unprocessable_content unless joinable?

        user = nil
        ActiveRecord::Base.transaction do
          user = User.create!(
            name: params[:name],
            gender: params[:gender] || :unspecified,
            guest: true
          )

          tier_key = params[:tier]&.to_sym || :newbie
          stars = params[:stars] || 3
          rating = Rank.rating_from_tier_and_stars(tier_key, stars)
          user.create_rank!(tier: tier_key, rating: rating, division: tier_key == :professional ? nil : 3)

          team = assign_team
          @game.game_participations.create!(user: user, team: team)
          @game.update!(players_count: @game.players_count + 1)
          @game.update!(status: :full) if @game.players_count >= @game.max_players
        end

        sign_in!(user)
        render json: { user: user_payload(user), game_id: @game.id }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_content
      end

      private

      def set_game_by_code
        @game = Game.includes(:host).find_by!(invite_code: params[:code])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Invite link not found' }, status: :not_found
      end

      def joinable?
        !@game.finished? && !@game.cancelled? && @game.players_count < @game.max_players
      end

      def session_started?
        @game.ongoing? ||
          Time.current >= @game.start_time ||
          @game.matches.where(status: %i[ongoing pending]).exists?
      end

      def invite_mode
        return 'closed' if @game.cancelled? || @game.finished?
        return 'live' if session_started?

        'join'
      end

      def assign_team
        a = @game.game_participations.team_a.count
        b = @game.game_participations.team_b.count
        a <= b ? :team_a : :team_b
      end

      def invite_payload
        mode = invite_mode
        payload = {
          game: {
            id: @game.id,
            description: @game.description,
            match_type: @game.match_type,
            status: @game.status,
            players_count: @game.players_count,
            max_players: @game.max_players,
            start_time: @game.start_time,
            end_time: @game.end_time,
            location: @game.location,
            host_name: @game.host&.name,
            mode: mode
          }
        }

        attach_invite_snapshot(payload) if %w[live closed].include?(mode)
        payload
      end

      def attach_invite_snapshot(payload)
        mode = payload[:game][:mode]
        game = Game.includes(
          game_participations: { user: :rank },
          matches: { match_participations: { user: :rank } }
        ).find(@game.id)

        session_stats = session_match_stats_for_game(game)
        payload[:players] = game.game_participations.map do |gp|
          invite_player_payload(gp, session_stats[gp.user_id])
        end.sort_by { |p| p[:name].to_s.downcase }
        payload[:match_counts] = match_counts_for_game(game)

        scope = game.matches.order(status: :desc, match_number: :asc)
        scope = scope.where(status: %i[ongoing pending]) if mode == 'live'
        payload[:matches] = scope.map { |m| invite_match_summary(m) }
      end

      def session_match_stats_for_game(game)
        rows = MatchParticipation.joins(:match)
                                 .where(matches: { game_id: game.id, status: Match.statuses[:finished] })
                                 .group(:user_id)
                                 .pluck(
                                   :user_id,
                                   Arel.sql('COUNT(*)'),
                                   Arel.sql('SUM(CASE WHEN match_participations.winner THEN 1 ELSE 0 END)')
                                 )
        rows.each_with_object({}) do |(user_id, played, wins), acc|
          wins_i = wins.to_i
          played_i = played.to_i
          acc[user_id] = { played: played_i, wins: wins_i, losses: played_i - wins_i }
        end
      end

      def match_counts_for_game(game)
        counts = game.matches.group(:status).count
        {
          pending: counts['pending'] || counts[0] || 0,
          ongoing: counts['ongoing'] || counts[1] || 0,
          finished: counts['finished'] || counts[2] || 0
        }
      end

      def invite_player_payload(participation, session_stats)
        user = participation.user
        {
          id: user.id,
          name: user.name,
          gender: user.gender,
          session_matches: session_stats || { played: 0, wins: 0, losses: 0 }
        }
      end

      def invite_match_summary(match)
        {
          id: match.id,
          match_number: match.match_number,
          status: match.status,
          priority: match.priority,
          winner_team: match.winner_team,
          team_a_score: match.team_a_score,
          team_b_score: match.team_b_score,
          team_a: match.match_participations.select(&:team_a?).map { |mp| { id: mp.user.id, name: mp.user.name } },
          team_b: match.match_participations.select(&:team_b?).map { |mp| { id: mp.user.id, name: mp.user.name } }
        }
      end
    end
  end
end
