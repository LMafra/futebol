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

  def step_up(player, scout, times)
    within("tr[data-player-id='#{player.id}']") do
      counter = find("input[name='scouts[#{player.id}][#{scout}]']").find(:xpath, '..')
      times.times { counter.click_on('mais') }
    end
  end

  it 'records the scouts with the counters, confirms the derived score and scores the bets' do
    sign_in_through_form(admin)

    visit "/admin/matchscouts?match_id=#{match.id}"
    step_up(home_striker, :goals, 2)
    check "#{home_striker.name} jogou"
    expect(page).to have_css("tr[data-player-id='#{home_striker.id}'] [data-role='points']", text: '17.00')

    click_on "Visitante · #{match.away_team.name}"
    step_up(away_striker, :goals, 1)
    click_on 'Salvar scouts'
    expect(page).to have_text('Scouts salvos · placar 2 × 1.')

    visit "/admin/matchfinalizer?match_id=#{match.id}"
    expect(page).to have_css('[data-role="derived-score"]', text: '2 × 1')
    fill_in 'finalization[score_confirmation]', with: '2x1'

    perform_enqueued_jobs do
      click_button 'Finalizar partida'
      expect(page).to have_text('Partida finalizada em 2 × 1; pontuação enfileirada.')
    end

    expect(match.reload).to have_attributes(status: 'scored', home_score: 2, away_score: 1)
    expect(Bolao::PredictionScore.kept.where(prediction: [exact_bet, wrong_bet]).pluck(:prediction_id, :points))
      .to contain_exactly([exact_bet.id, 10], [wrong_bet.id, 0])
  end
end
