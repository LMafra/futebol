require 'rails_helper'

RSpec.describe 'Admin finalizes a match', type: :system do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :admin) }
  let(:match) { create(:match, status: 'live', match_date: 2.hours.ago) }
  let!(:exact_bet) { create(:bolao_prediction, match:, home_guess: 2, away_guess: 1) }
  let!(:wrong_bet) { create(:bolao_prediction, match:, home_guess: 0, away_guess: 3) }

  before do
    { exact_score: 10, winner_and_goal_diff: 7, winner: 5, draw: 3 }.each do |kind, points|
      create(:bolao_scoring_rule, pool_id: nil, kind:, points:)
    end
  end

  it 'previews a candidate score, confirms it on the finalizer and scores the bets' do
    sign_in_through_form(admin)

    visit '/admin/bolaopreview'
    find('select#match_id').find('option', text: match.to_s).select_option
    click_on 'Abrir'
    fill_in 'candidate_home', with: '2'
    fill_in 'candidate_away', with: '1'
    click_on 'Calcular preview'

    within('[data-role="preview"]') do
      expect(page).to have_css('[data-role="candidate-score"]', text: '2 × 1')
      expect(page).to have_css('[data-role="total"]', text: '10')
      click_on 'Confirmar este placar na finalização'
    end

    expect(page).to have_field('finalization[home_score]', with: '2')
    expect(page).to have_field('finalization[away_score]', with: '1')
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
