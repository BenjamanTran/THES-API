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
        return render json: { error: 'Trận đã bắt đầu — chỉ xem được lịch thi đấu' }, status: :unprocessable_content if @game.invite_play_live?
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
          Users::CreditPlayTimeForJoin.call(game: @game, user: user)
        end

        Users::ProfileCache.bust_for_user!(user.id)
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

      def invite_mode
        return 'closed' if @game.cancelled? || @game.finished?
        return 'live' if @game.invite_play_live?

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
            courts: @game.courts,
            mode: mode
          }
        }

        attach_invite_snapshot(payload) if %w[live closed].include?(mode)
        payload
      end

      def attach_invite_snapshot(payload)
        mode = payload[:game][:mode]
        game_id = @game.id

        Matches::AssignCourtService.backfill_ongoing!(@game) if mode == 'live'

        participations = GameParticipation.where(game_id: game_id).includes(user: :rank).to_a

        payload[:players] = participations
          .map { |gp| invite_player_payload(gp) }
          .sort_by { |p| p[:name].to_s.downcase }
        payload[:match_counts] = match_counts_for_game_id(game_id)

        matches = invite_matches_scope(game_id, mode)
                    .includes(match_participations: :user)
                    .to_a
        payload[:matches] = matches.map { |m| invite_match_summary(m) }
      end

      def invite_matches_scope(game_id, mode)
        scope = Match.where(game_id: game_id)
        if mode == 'live'
          ongoing = Match.statuses[:ongoing]
          pending = Match.statuses[:pending]
          scope = scope.where(status: %i[ongoing pending])
                       .order(
                         Arel.sql("CASE status WHEN #{ongoing} THEN 0 WHEN #{pending} THEN 1 ELSE 2 END"),
                         priority: :desc,
                         match_number: :asc
                       )
        else
          scope.order(status: :desc, match_number: :asc)
        end
      end

      def match_counts_for_game_id(game_id)
        counts = Match.where(game_id: game_id).group(:status).count
        {
          pending: counts['pending'] || counts[0] || 0,
          ongoing: counts['ongoing'] || counts[1] || 0,
          finished: counts['finished'] || counts[2] || 0
        }
      end

      def invite_player_payload(participation)
        user = participation.user
        payload = {
          id: user.id,
          name: user.name,
          gender: user.gender,
          session_matches: {
            played: participation.session_played_count,
            wins: 0,
            losses: 0
          },
          arrived_at_court: participation.arrived_at_court
        }.merge(player_avatar_fields(user))
        payload[:declared_rank] = declared_rank_payload(user.rank) if user.rank
        merge_session_skill!(payload, participation)
        payload
      end

      def invite_match_summary(match)
        participations = match.match_participations
        {
          id: match.id,
          match_number: match.match_number,
          status: match.status,
          priority: match.priority,
          court_number: match.court_number,
          winner_team: match.winner_team,
          team_a_score: match.team_a_score,
          team_b_score: match.team_b_score,
          team_a: participations.select(&:team_a?).map { |mp| invite_match_player(mp) },
          team_b: participations.select(&:team_b?).map { |mp| invite_match_player(mp) }
        }
      end

      def invite_match_player(mp)
        { id: mp.user.id, name: mp.user.name }.merge(player_avatar_fields(mp.user))
      end
    end
  end
end
