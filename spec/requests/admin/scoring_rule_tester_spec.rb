require 'rails_helper'

RSpec.describe 'Admin ScoringRuleTester page', type: :request do
  let(:pool) { create(:bolao_pool) }

  before do
    { exact_score: 10, winner_and_goal_diff: 7, winner: 5, draw: 3 }.each do |kind, points|
      create(:bolao_scoring_rule, pool_id: nil, kind:, points:)
    end
    sign_in(create(:user, :admin))
  end

  def result_text(role) = Nokogiri::HTML(response.body).at_css("[data-role='#{role}']").text.squish

  it 'renders the rules of both games' do
    get '/admin/scoringruletester'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('exact_score', 'Cartola')
  end

  it 'applies the Bolão rules (with pool overrides) to a guess and a result' do
    create(:bolao_scoring_rule, pool:, kind: 'winner', points: 4)

    get '/admin/scoringruletester',
        params: { bolao: { pool_id: pool.id, guess_home: 3, guess_away: 0, result_home: 1, result_away: 0 } }

    expect(result_text('bolao-result')).to eq('4 pontos · regra: winner')
  end

  it 'applies a Cartola rule to scouts' do
    rule = create(:cartola_scoring_rule, goal_points: 8, assist_points: 5, yellow_card_penalty: 1, red_card_penalty: 3)

    get '/admin/scoringruletester',
        params: { cartola: { rule_id: rule.id, goals: 2, assists: 1, yellow_cards: 1, red_cards: 0 } }

    expect(result_text('cartola-result')).to eq("20.0 pontos · regra: #{rule.name}")
  end

  it 'reports invalid input' do
    get '/admin/scoringruletester',
        params: { bolao: { pool_id: '', guess_home: -1, guess_away: 0, result_home: 1, result_away: 0 } }

    expect(result_text('bolao-result')).to include('números inteiros')
  end
end
