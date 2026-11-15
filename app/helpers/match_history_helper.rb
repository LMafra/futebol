# The lines of "Histórico da partida" (TICKET-0112): one sentence per Core::AuditLog entry of a match.
module MatchHistoryHelper
  PARTICIPATION_LABELS = { 'played' => 'Jogou', 'highlight' => 'Destaque' }.freeze
  HISTORY_TEXTS = {
    'cartola.scout_event_recorded' => :history_lance_recorded, 'cartola.scout_event_undone' => :history_lance_undone,
    'cartola.participation_marked' => :history_participation, 'cartola.scouts_recorded' => :history_scout_sheet,
    'finalize' => :history_finalize, 'rescore' => :history_rescore, 'revert' => :history_revert,
    'match.rescheduled' => :history_reschedule
  }.freeze

  def match_history_text(log, players)
    text = HISTORY_TEXTS[log.action]
    text ? send(text, log.metadata.to_h.with_indifferent_access, players) : 'Alteração na partida'
  end

  def match_history_author(log) = log.user&.name.presence || log.user&.email_address || 'Sistema'

  private

  def history_lance_recorded(data, players) = "Lance registrado: #{history_lance(data, players)}"

  def history_lance_undone(data, players) = "Lance desfeito: #{history_lance(data, players)}"

  def history_scout_sheet(_data, _players) = 'Estatísticas registradas pela ficha'

  def history_finalize(data, _players)
    "Partida finalizada em #{history_score(data)}#{' e pontuada' if data[:scoring_token]}"
  end

  def history_rescore(data, _players)
    before = history_score(data[:before].to_h)
    after = history_score(data)
    before == after ? "Pontos refeitos, placar mantido em #{after}" : "Placar e pontos refeitos: #{before} → #{after}"
  end

  def history_revert(data, _players) = history_with_reason('Pontuação revertida', data)

  def history_reschedule(data, _players)
    date = data[:to] && l(Time.zone.parse(data[:to]), format: '%d/%m %H:%M')
    history_with_reason(['Partida remarcada', date].compact.join(' para '), data)
  end

  def history_lance(data, players)
    [scout_label(data[:stat].to_sym), players[data[:player_id]], data[:minute] && "#{data[:minute]}'",
     Cartola::ScoutEvent::PERIODS[data[:period]]].compact.join(' · ')
  end

  def history_participation(data, players)
    flags = PARTICIPATION_LABELS.filter_map do |key, label|
      "#{label} #{data[key] ? 'marcado' : 'desmarcado'}" if data.key?(key)
    end
    "#{flags.join(', ')}: #{players[data[:player_id]]}"
  end

  def history_score(data) = "#{data['home_score']} × #{data['away_score']}"

  def history_with_reason(text, data) = [text, data[:reason].presence && "Motivo: #{data[:reason]}"].compact.join('. ')
end
