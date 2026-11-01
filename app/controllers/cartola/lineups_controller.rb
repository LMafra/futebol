module Cartola
  # One lineup per squad and round (?round=, default 1). Without ?squad_id= it is the signed-in user's squad,
  # created on first access; with it, someone else's lineup (read-only for admins, 403 for everybody else).
  # ::ApplicationController: inside Cartola, the bare constant resolves to the engine's Cartola::ApplicationController.
  class LineupsController < ::ApplicationController
    rescue_from Pundit::NotAuthorizedError do |exception|
      render_forbidden(exception, message: 'Esta escalação pertence a outro usuário.')
    end

    before_action :set_lineup

    def show
      authorize @lineup
    end

    def edit
      authorize @lineup
      load_players
    end

    def update
      authorize @lineup
      assign_lineup

      if @lineup.save
        redirect_to main_app.lineup_path(round: @lineup.round), notice: 'Escalação salva.', status: :see_other
      else
        flash.now[:alert] = @lineup.errors.full_messages.to_sentence
        load_players
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_lineup
      squad = params[:squad_id] ? Cartola::Squad.find(params[:squad_id]) : current_squad
      @lineup = squad.lineups.includes(lineup_players: { player: :team }).find_or_initialize_by(round:)
    end

    def round = params.fetch(:round, 1).to_i.clamp(1, 38)

    def current_squad
      Cartola::Squad.find_or_create_by!(user: current_user) do |squad|
        squad.name = "Time de #{current_user.name.presence || current_user.email_address}"
      end
    end

    def assign_lineup
      attributes = params.expect(lineup: [:formation, { player_ids: [] }])
      @lineup.formation = attributes[:formation]
      @lineup.assign_players(Core::Player.where(id: attributes[:player_ids]).to_a)
    end

    def load_players
      @players = Core::Player.includes(:team).order(:position, :name)
    end
  end
end
