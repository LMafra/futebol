require 'rails_helper'

RSpec.describe MatchHistoryHelper, type: :helper do
  let(:players) { { 7 => 'Atacante Casa' } }

  def text(action, **metadata) = helper.match_history_text(Core::AuditLog.new(action:, metadata:), players)

  it 'describes lances and participation with the player name' do
    expect(text('cartola.scout_event_recorded', player_id: 7, stat: 'goals', period: 'second_half', minute: 32))
      .to eq("Lance registrado: Gol · Atacante Casa · 32' · 2º tempo")
    expect(text('cartola.scout_event_undone', player_id: 7, stat: 'yellow_cards'))
      .to eq('Lance desfeito: Cartão amarelo · Atacante Casa')
    expect(text('cartola.participation_marked', player_id: 7, played: true)).to eq('Jogou marcado: Atacante Casa')
    expect(text('cartola.participation_marked', player_id: 7, highlight: false))
      .to eq('Destaque desmarcado: Atacante Casa')
  end

  it 'describes finalizing, rescoring and reverting with the score before and after' do
    expect(text('finalize', home_score: 2, away_score: 1, scoring_token: 'a'))
      .to eq('Partida finalizada em 2 × 1 e pontuada')
    expect(text('finalize', home_score: 2, away_score: 1)).to eq('Partida finalizada em 2 × 1')
    expect(text('rescore', home_score: 2, away_score: 2, before: { home_score: 2, away_score: 1 }))
      .to eq('Placar e pontos refeitos: 2 × 1 → 2 × 2')
    expect(text('rescore', home_score: 2, away_score: 1, before: { home_score: 2, away_score: 1 }))
      .to eq('Pontos refeitos, placar mantido em 2 × 1')
    expect(text('revert', reason: 'Gol anulado')).to eq('Pontuação revertida. Motivo: Gol anulado')
  end

  it 'describes a rescheduling and falls back to a generic line' do
    expect(text('match.rescheduled', reason: 'Chuva', to: Time.zone.parse('2026-12-20 16:00').iso8601))
      .to eq('Partida remarcada para 20/12 16:00. Motivo: Chuva')
    expect(text('something.else')).to eq('Alteração na partida')
  end

  it 'names the author by name, then e-mail' do
    named = Core::AuditLog.new(user: Core::User.new(name: 'Ana Gestora', email_address: 'ana@x.dev'))
    unnamed = Core::AuditLog.new(user: Core::User.new(email_address: 'bia@x.dev'))

    expect([named, unnamed, Core::AuditLog.new].map { helper.match_history_author(_1) })
      .to eq(['Ana Gestora', 'bia@x.dev', 'Sistema'])
  end
end
