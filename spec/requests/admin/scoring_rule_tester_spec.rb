require 'rails_helper'

RSpec.describe 'Admin ScoringRuleTester page', type: :request do
  let(:pool) { create(:bolao_pool) }

  before do
    create(:bolao_scoring_rule, pool_id: nil, exact_score_points: 10, winner_points: 5)
    sign_in(create(:user, :admin))
  end

  def result_text(role) = Nokogiri::HTML(response.body).at_css("[data-role='#{role}']").text.squish

  it 'renders the rules of both games' do
    get '/admin/scoringruletester'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Pontos por placar exato', 'Pontos por vencedor', 'Esquadrão')
  end

  it 'applies the Bolão rules (with pool overrides) to a guess and a result' do
    create(:bolao_scoring_rule, pool:, exact_score_points: 9, winner_points: 4)

    get '/admin/scoringruletester',
        params: { bolao: { pool_id: pool.id, guess_home: 3, guess_away: 0, result_home: 1, result_away: 0 } }

    expect(result_text('bolao-result')).to eq('4 pontos · faixa: vencedor')
  end

  it 'applies a Cartola rule to scouts' do
    rule = create(:cartola_scoring_rule, goal_points: 8, assist_points: 5, yellow_card_penalty: 1, red_card_penalty: 3)

    get '/admin/scoringruletester',
        params: { cartola: { rule_id: rule.id, goals: 2, assists: 1, yellow_cards: 1, red_cards: 0 } }

    expect(result_text('cartola-result')).to eq("20.0 pontos · regra: #{rule.name}")
  end

  it 'covers the new scouts, SG, Jogou and Destaque' do
    rule = create(:cartola_scoring_rule, goal_points: 8, clean_sheet_points: 5, penalty_save_points: 7, save_points: 1,
                                         own_goal_penalty: 3, played_points: 1, highlight_points: 5)

    get '/admin/scoringruletester', params: { cartola: { rule_id: rule.id, goals: 0, assists: 0, penalty_saves: 1,
                                                         saves: 4, yellow_cards: 0, red_cards: 0, own_goals: 1,
                                                         clean_sheet: '1', played: '1', highlight: '1' } }

    expect(result_text('cartola-result')).to eq("19.0 pontos · regra: #{rule.name}")
  end

  it 'edits the six new columns of a Cartola rule in the admin form' do
    get '/admin/esquadrao_scoring_rules/new'

    page = Nokogiri::HTML(response.body)
    %w[clean_sheet_points penalty_save_points save_points own_goal_penalty played_points
       highlight_points].each do |column|
      expect(page.at_css("input[name='scoring_rule[#{column}]']")).to be_present, column
    end
    expect(response.body).to include('Jogo sem sofrer gols (SG)', 'Destaque', 'Gol contra (GC, desconta)')
  end

  it 'reports invalid input' do
    get '/admin/scoringruletester',
        params: { bolao: { pool_id: '', guess_home: -1, guess_away: 0, result_home: 1, result_away: 0 } }

    expect(result_text('bolao-result')).to include('números inteiros')
  end
end
