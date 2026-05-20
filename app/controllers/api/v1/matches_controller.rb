# frozen_string_literal: true

module Api
  module V1
    class MatchesController < BaseController
      before_action :set_game
      before_action :set_match, only: %i[update start finish undo_finish destroy priority]

      def index
        matches = @game.matches.includes(match_participations: { user: :rank }).ordered
        if params[:status].present?
          status = params[:status].to_s
          unless Match.statuses.key?(status)
            return render json: { error: 'Invalid status' }, status: :unprocessable_content
          end
          matches = matches.where(status: status)
        end
        render json: { matches: matches.map { |m| match_payload(m) } }
      end

      def create
        result = Matches::CreateService.call(user: @current_user, game: @game, params: create_params)
        if result.success?
          broadcast_match_event('match.created', result.data[:match])
          render json: match_payload(result.data[:match]), status: :created
        else
          render json: { error: result.error }, status: result.status
        end
      end

      def generate_batch
        result = Matches::GenerateBatchService.call(
          user: @current_user,
          game: @game,
          count: params[:count]
        )
        if result.success?
          matches = result.data[:matches]
          matches.each { |m| broadcast_match_event('match.created', m) }
          render json: { matches: matches.map { |m| match_payload(m) } }, status: :created
        else
          render json: { error: result.error }, status: result.status
        end
      end

      def update
        result = Matches::UpdateService.call(
          user: @current_user,
          game: @game,
          match: @match,
          params: create_params
        )
        if result.success?
          broadcast_match_event('match.updated', result.data[:match])
          render json: match_payload(result.data[:match])
        else
          render json: { error: result.error }, status: result.status
        end
      end

      def start
        unless @game.host_or_co_host?(@current_user)
          return render json: { error: 'Only host or co-host can start matches' }, status: :forbidden
        end
        unless @match.pending?
          return render json: { error: 'Match already started' }, status: :unprocessable_content
        end
        unless @game.within_play_time?
          return render json: { error: 'Chưa tới giờ trận, không thể bắt đầu' }, status: :unprocessable_content
        end

        @match.update!(status: :ongoing, started_at: Time.current, priority: false)
        broadcast_match_event('match.started', @match)
        render json: match_payload(@match)
      end

      def finish
        result = Matches::FinishService.call(user: @current_user, match: @match, params: finish_params)
        if result.success?
          payload = {
            match: match_payload(result.data[:match]),
            participants: result.data[:participants]
          }
          broadcast_match_event('match.finished', result.data[:match])
          render json: payload
        else
          render json: { error: result.error }, status: result.status
        end
      end

      def undo_finish
        result = Matches::UndoFinishService.call(user: @current_user, match: @match)
        if result.success?
          broadcast_match_event('match.undo', result.data[:match])
          render json: { match: match_payload(result.data[:match]) }
        else
          render json: { error: result.error }, status: result.status
        end
      end

      def priority
        unless @game.host_or_co_host?(@current_user)
          return render json: { error: 'Only host or co-host can set priority' }, status: :forbidden
        end
        unless @match.pending?
          return render json: { error: 'Only pending matches can be prioritized' }, status: :unprocessable_content
        end

        new_priority = !@match.priority
        Match.transaction do
          @game.matches.pending.where(priority: true).where.not(id: @match.id).update_all(priority: false) if new_priority
          @match.update!(priority: new_priority)
        end
        broadcast_match_event('match.updated', @match)
        render json: match_payload(@match.reload)
      end

      def destroy
        unless @game.host_or_co_host?(@current_user)
          return render json: { error: 'Only host or co-host can delete matches' }, status: :forbidden
        end
        if @match.finished?
          return render json: { error: 'Cannot delete a finished match' }, status: :unprocessable_entity
        end

        match_id = @match.id
        @match.destroy!
        broadcast_match_deleted(match_id)
        render json: { message: 'Match deleted' }
      end

      def destroy_pending
        unless @game.host_or_co_host?(@current_user)
          return render json: { error: 'Only host or co-host can delete matches' }, status: :forbidden
        end

        pending = @game.matches.pending.to_a
        match_ids = pending.map(&:id)
        return render json: { deleted_count: 0, match_ids: [] } if match_ids.empty?

        Match.transaction { pending.each(&:destroy!) }
        match_ids.each { |id| broadcast_match_deleted(id) }
        render json: { deleted_count: match_ids.size, match_ids: match_ids }
      end

      private

      def broadcast_match_event(event, match)
        Games::CableBroadcaster.broadcast(
          game: @game,
          event: event,
          payload: { match: match_payload(match) }
        )
      end

      def broadcast_match_deleted(match_id)
        Games::CableBroadcaster.broadcast(
          game: @game,
          event: 'match.deleted',
          payload: { match_id: match_id }
        )
      end

      def set_game
        @game = Game.find(params[:game_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Game not found' }, status: :not_found
      end

      def set_match
        @match = @game.matches.includes(match_participations: { user: :rank }).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Match not found' }, status: :not_found
      end

      def create_params
        params.permit(team_a: [], team_b: [])
      end

      def finish_params
        params.permit(:team_a_score, :team_b_score, :winner_team)
      end

      def match_payload(match)
        mp = match.match_participations.loaded? ? match.match_participations : match.match_participations.includes(user: :rank)
        team_a = mp.select(&:team_a?)
        team_b = mp.select(&:team_b?)
        {
          id: match.id,
          match_number: match.match_number,
          status: match.status,
          team_a_score: match.team_a_score,
          team_b_score: match.team_b_score,
          winner_team: match.winner_team,
          started_at: match.started_at,
          finished_at: match.finished_at,
          priority: match.priority,
          team_a: team_a.map { |mp_entry| player_entry(mp_entry) },
          team_b: team_b.map { |mp_entry| player_entry(mp_entry) }
        }
      end

      def player_entry(mp_entry)
        user = mp_entry.user
        entry = { id: user.id, name: user.name, gender: user.gender, winner: mp_entry.winner }
               .merge(player_avatar_fields(user))
        entry[:rank] = game_player_rank_payload(user) if user.rank
        entry
      end
    end
  end
end
