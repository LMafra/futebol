require 'rails_helper'

RSpec.describe 'Admin finalizes a match', type: :system do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :admin) }
  let(:match) { create(:match, status: 'live', match_date: 2.hours.ago) }
  let!(:home_striker) { create(:player, team: match.home_team, position: 'ATA') }
  let!(:away_striker) { create(:player, team: match.away_team, position: 'ATA') }
  let!(:exact_bet) { create(:bolao_prediction, match:, home_guess: 2, away_guess: 1) }
  let!(:wrong_bet) { create(:bolao_prediction, match:, home_guess: 0, away_guess: 3) }

  before do
    create(:bolao_scoring_rule, pool_id: nil, exact_score_points: 10, winner_points: 5)
    create(:cartola_scoring_rule, name: Cartola::ScoringRule::DEFAULT_NAME, goal_points: 8, played_points: 1)
  end

  def record_goal(player, minute)
    within("[data-role='player-line'][data-player-id='#{player.id}']") { click_link '+ Gol' }
    within('dialog#modal-lance') do
      fill_in 'Minuto', with: minute
      click_button 'Registrar lance'
    end
    expect(page).to have_text("Lance registrado: Gol · #{player.name} · #{minute}'")
  end

  it 'records the lances on the match page, confirms the derived score and scores the bets' do
    sign_in_through_form(admin)

    visit "/admin/matches/#{match.id}"
    record_goal(home_striker, 10)
    record_goal(home_striker, 30)
    click_on "Visitante · #{match.away_team.name}"
    record_goal(away_striker, 80)
    expect(page).to have_css('[data-role="scoreboard"] [data-role="score"]', text: '2 × 1')
    expect(page).to have_css('[data-role="timeline-event"]', count: 3)

    click_link 'Finalizar partida'
    within('dialog#modal-finalize') do
      fill_in 'finalize[score_confirmation]', with: '2x1'
      perform_enqueued_jobs { click_button 'Finalizar partida' }
    end
    expect(page).to have_text('Partida finalizada em 2 × 1; pontuação enfileirada.')

    expect(match.reload).to have_attributes(status: 'scored', home_score: 2, away_score: 1)
    expect(Bolao::PredictionScore.kept.where(prediction: [exact_bet, wrong_bet]).pluck(:prediction_id, :points))
      .to contain_exactly([exact_bet.id, 10], [wrong_bet.id, 0])
  end
end
