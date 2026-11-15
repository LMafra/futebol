module Cartola
  # Lineup lock T-15 before the round's first scheduled kickoff (app-layer deadline).
  module LineupDeadlines
    extend ActiveSupport::Concern

    private

    def load_lineup_deadline
      @lineup_deadline = Users::LineupDeadline.for(championship: @lineup.championship, round: @lineup.round)
    end

    def render_lineup_closed
      @lineup_errors = ['Escalação fechada: o prazo encerrou 15 minutos antes do primeiro jogo da rodada.']
      flash.now[:alert] = @lineup_errors.first
      load_players
      render :edit, status: :unprocessable_content
    end
  end
end
