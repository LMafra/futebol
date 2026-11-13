module Scouts
  # The checks before recording or undoing a lance; the same limits as the scout sheet (Cartola::ScoutSheetValidator).
  module EventRules
    LABELS = Cartola::ScoutSheetValidator::SCOUT_LABELS

    def self.match_errors(match)
      return ['A partida já foi pontuada: reverta a pontuação antes de alterar os scouts.'] if match.scored?
      return ['A partida ainda não começou.'] if match.scheduled? && !match.may_start_match?

      []
    end

    def self.record_errors(event)
      return event.errors.full_messages unless event.valid?

      match_errors(event.match).presence || [*side_error(event), *position_error(event), *limit_error(event),
                                             *assist_error(event)]
    end

    def self.undo_errors(match, last)
      return match_errors(match) if match_errors(match).any?
      return ['Nada para desfazer.'] unless last
      return [] unless last.stat == 'goals' && team_total(match, last.team_id, 'assists') >=
                                               team_total(match, last.team_id, 'goals')

      ['Desfaça antes uma assistência: o time ficaria com mais assistências do que gols.']
    end

    def self.side_error(event)
      sides = [event.match.home_team_id, event.match.away_team_id]
      'O time do jogador não está nesta partida.' unless sides.include?(event.team_id)
    end

    def self.position_error(event)
      'Defesas (DE) só contam para goleiros.' if event.stat == 'saves' && event.player.position != 'GOL'
    end

    def self.limit_error(event)
      range = Cartola::PlayerScore::SCOUT_LIMITS.fetch(event.stat.to_sym)
      kept = Cartola::ScoutEvent.kept.where(match: event.match, player: event.player, stat: event.stat).count
      "#{event.player.name} já tem o máximo de #{LABELS.fetch(event.stat.to_sym)} (#{range.max})." if kept >= range.max
    end

    def self.assist_error(event)
      return unless event.stat == 'assists'
      return if team_total(event.match, event.team_id, 'assists') < team_total(event.match, event.team_id, 'goals')

      'Lance o gol antes da assistência: o time ficaria com mais assistências do que gols.'
    end

    def self.team_total(match, team_id, stat) = Cartola::ScoutEvent.kept.where(match:, team_id:, stat:).count
  end
end
