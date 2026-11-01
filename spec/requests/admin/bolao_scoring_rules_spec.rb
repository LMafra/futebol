require 'rails_helper'

RSpec.describe 'Admin Bolão scoring rules (2 faixas)', type: :request do
  let(:pool) { create(:bolao_pool) }

  before { sign_in(create(:user, :admin)) }

  it 'shows the two fields on the rule form' do
    get '/admin/bolao_scoring_rules/new'

    expect(response.body).to include('Pontos por placar exato', 'Pontos por vencedor')
  end

  it 'creates a championship rule with both bands' do
    post '/admin/bolao_scoring_rules', params: { scoring_rule: {
      championship_id: pool.championship_id, exact_score_points: 12, winner_points: 6
    } }

    expect(Bolao::ScoringRule.for(pool)).to have_attributes(exact_score_points: 12, winner_points: 6)
  end

  it 'rejects winner points above exact score points' do
    post '/admin/bolao_scoring_rules', params: { scoring_rule: { exact_score_points: 3, winner_points: 5 } }

    expect(Bolao::ScoringRule.count).to eq(0)
    expect(response.body).to include('Pontos por vencedor')
  end

  it 'sets and removes a pool override from the pool form' do
    get "/admin/pools/#{pool.id}/edit"
    expect(response.body).to include('Pontuação própria')

    patch "/admin/pools/#{pool.id}",
          params: { pool: { scoring_rule_attributes: { exact_score_points: 20, winner_points: 7 } } }
    expect(pool.reload.scoring_rule).to have_attributes(exact_score_points: 20, winner_points: 7)

    patch "/admin/pools/#{pool.id}",
          params: { pool: { scoring_rule_attributes: { id: pool.scoring_rule.id, _destroy: '1' } } }
    expect(pool.reload.scoring_rule).to be_nil
  end

  it 'keeps the pool without override when both fields are blank' do
    blank_rule = { exact_score_points: '', winner_points: '' }
    patch "/admin/pools/#{pool.id}", params: { pool: { name: 'Renomeado', scoring_rule_attributes: blank_rule } }

    expect(pool.reload).to have_attributes(name: 'Renomeado', scoring_rule: nil)
  end
end
