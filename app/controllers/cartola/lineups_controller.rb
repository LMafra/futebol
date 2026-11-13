module Cartola
  # One lineup per squad, championship and round (?round=, default 1; ?championship_id=, default the latest).
  # Without ?squad_id= it is the signed-in user's squad, created on first access; with it, someone else's lineup
  # (read-only for admins, 403 for everybody else). Players are bought from the user's wallet (WalletService), and
  # only players of the championship's teams can be picked.
  # ::ApplicationController: inside Cartola, the bare constant resolves to the engine's Cartola::ApplicationController.
  class LineupsController < ::ApplicationController
    rescue_from Pundit::NotAuthorizedError do |exception|
      render_forbidden(exception, message: 'Esta escalação pertence a outro usuário.')
    end

    before_action :set_lineup
    helper_method :lineup_location

    def show
      authorize @lineup
      load_budget
    end

    def edit
      authorize @lineup
      load_players
    end

    def update
      authorize @lineup
      assign_lineup

      if Cartola::WalletService.save(@lineup)
        redirect_to main_app.lineup_path(lineup_location), notice: 'Escalação salva.', status: :see_other
      else
        flash.now[:alert] = @lineup.errors.full_messages.to_sentence
        load_players
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize @lineup
      refund = Cartola::WalletService.destroy(@lineup)
      redirect_to main_app.lineup_path(lineup_location),
                  notice: format('Escalação desfeita: C$ %.2f devolvidos à carteira.', refund), status: :see_other
    end

    private

    def set_lineup
      squad = params[:squad_id] ? Cartola::Squad.find(params[:squad_id]) : current_squad
      @lineup = squad.lineups.includes(lineup_players: { player: :team })
                     .find_or_initialize_by(championship:, round:)
    end

    def championship
      @championship ||= if params[:championship_id]
                          Core::Championship.published.find(params[:championship_id])
                        else
                          Core::Championship.latest || raise(ActiveRecord::RecordNotFound, 'Nenhum campeonato')
                        end
    end

    def round = params.fetch(:round, 1).to_i.clamp(1, 38)

    def lineup_location(round: @lineup.round)
      { round:, squad_id: params[:squad_id], championship_id: params[:championship_id] }.compact
    end

    def current_squad
      Cartola::Squad.find_or_create_by!(user: current_user) do |squad|
        squad.name = "Time de #{current_user.name.presence || current_user.email_address}"
      end
    end

    def assign_lineup
      attributes = params.expect(lineup: [:formation, :captain_id, { player_ids: [] }])
      @lineup.formation = attributes[:formation]
      @lineup.assign_players(available_players.includes(:team).where(id: attributes[:player_ids]).to_a)
      @lineup.assign_captain(attributes[:captain_id])
    end

    # The championship's players, plus those already in the lineup so an older lineup stays editable.
    def available_players
      Core::Player.where(team: championship.teams).or(Core::Player.where(id: @lineup.lineup_players.map(&:player_id)))
    end

    def load_players
      @players = available_players.includes(:team).order(:position, :name).to_a
      @prices = Cartola::PlayerValue.prices_for(@players, championship)
      load_budget(@prices)
    end

    # spent: the selected players at current prices; budget: what the owner can spend on this lineup, the balance
    # plus the players already bought.
    def load_budget(prices = Cartola::PlayerValue.prices_for(@lineup.lineup_players.map(&:player), championship))
      @prices ||= prices
      bought = @lineup.lineup_players.reject(&:new_record?).map(&:player_id)
      @spent = @lineup.selected_players.sum { |player| prices.fetch(player.id) }
      @budget = Cartola::Wallet.balance_for(user: @lineup.squad.user, championship:) +
                bought.sum { |player_id| prices.fetch(player_id) }
    end
  end
end
