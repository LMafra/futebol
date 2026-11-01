module Cartola
  # The checks Cartola::RecordScoutsService runs before saving a scout sheet; returns the messages for the admin.
  class ScoutSheetValidator
    SCOUT_LABELS = { goals: 'gols (G)', assists: 'assistências (A)', penalty_saves: 'defesas de pênalti (DP)',
                     saves: 'defesas (DE)', yellow_cards: 'cartões amarelos (CA)', red_cards: 'cartões vermelhos (CV)',
                     own_goals: 'gols contra (GC)' }.freeze

    def self.errors(match, rows) = new(match, rows).errors

    def initialize(match, rows)
      @match = match
      @rows = rows
    end

    def errors = status_errors.presence || (row_errors + highlight_errors + team_errors)

    private

    def status_errors
      return ['A partida já foi pontuada: reverta a pontuação antes de alterar os scouts.'] if @match.scored?
      return ['A partida ainda não começou.'] if @match.scheduled? && !@match.may_start_match?

      []
    end

    def row_errors
      players = Core::Player.where(id: @rows.map(&:player_id)).index_by(&:id)
      @rows.flat_map do |row|
        player = players[row.player_id]
        next ["Jogador ##{row.player_id} não encontrado."] unless player

        (bound_errors(row) + line_errors(row, player)).map { |message| "#{player.name}: #{message}" }
      end
    end

    def bound_errors(row)
      row.scouts.filter_map do |scout, value|
        range = PlayerScore::SCOUT_LIMITS.fetch(scout)
        next if value && range.cover?(value)

        "#{SCOUT_LABELS.fetch(scout)} deve ficar entre #{range.min} e #{range.max}."
      end
    end

    def line_errors(row, player)
      [
        ('o time não está nesta partida.' unless sides.include?(row.team_id)),
        ('defesas (DE) só contam para goleiros.' if row.count(:saves).positive? && player.position != 'GOL'),
        ('assistência e gol contra na mesma linha.' if row.count(:assists).positive? && row.count(:own_goals).positive?)
      ].compact
    end

    def highlight_errors = @rows.count(&:highlight) > 1 ? ['Escolha no máximo um destaque.'] : []

    def team_errors
      [@match.home_team, @match.away_team].filter_map do |team|
        team_rows = @rows.select { |row| row.team_id == team.id }
        goals = team_rows.sum { |row| row.count(:goals) }
        assists = team_rows.sum { |row| row.count(:assists) }
        "#{team.name}: #{assists} assistência(s) para #{goals} gol(s)." if assists > goals
      end
    end

    def sides = [@match.home_team_id, @match.away_team_id]
  end
end
