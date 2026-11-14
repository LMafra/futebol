require 'rails_helper'

RSpec.describe 'Admin Cartola settings', type: :request do
  before { sign_in(create(:user, :admin)) }

  let(:championship) { create(:championship) }

  it 'shows the six Cartola fields on the championship form' do
    get "/admin/championships/#{championship.id}/edit"

    expect(response.body).to include('Limite de goleiros', 'Limite de defensores', 'Limite de meio-campistas',
                                     'Limite de atacantes', 'Orçamento inicial', 'Valor base do jogador')
  end

  it 'updates the limits, budget and base value of a championship' do
    patch "/admin/championships/#{championship.id}", params: { championship: {
      cartola_goalkeeper_limit: 1, cartola_defender_limit: 4, cartola_midfielder_limit: 4, cartola_forward_limit: 2,
      cartola_initial_budget: 120, cartola_base_player_value: 6.5
    } }

    expect(championship.reload).to have_attributes(cartola_limits: { goalkeeper: 1, defender: 4, midfielder: 4,
                                                                     forward: 2 },
                                                   cartola_initial_budget: 120, cartola_base_player_value: 6.5)
  end

  it 'edits the private flag of a championship' do
    get "/admin/championships/#{championship.id}/edit"
    expect(response.body).to include('Campeonato privado?')

    patch "/admin/championships/#{championship.id}", params: { championship: { private: '1' } }

    expect(championship.reload).to be_private
  end

  it 'rejects limits without any outfield player' do
    patch "/admin/championships/#{championship.id}", params: { championship: {
      cartola_defender_limit: 0, cartola_midfielder_limit: 0, cartola_forward_limit: 0
    } }

    expect(response.body).to include('Defina pelo menos um jogador de linha')
    expect(championship.reload.cartola_defender_limit).to eq(2)
  end

  it 'sets the base value of a player' do
    player = create(:player)

    patch "/admin/players/#{player.id}", params: { player: { base_value: 9.5 } }

    expect(player.reload.base_value).to eq(9.5)
  end

  it 'shows the Esquadrão ranking of a championship with points and coins' do
    ana = create(:user, name: 'Ana')
    create(:cartola_lineup, championship:, squad: create(:cartola_squad, user: ana))
    create(:cartola_wallet, championship:, balance: 42, user: ana)

    get "/admin/esquadrao?championship_id=#{championship.id}"

    expect(response).to have_http_status(:ok)
    page = Nokogiri::HTML5(response.body)
    expect(page.at_css('[data-role="ranking-row"]').text.squish).to eq('1 Ana 0.00 C$ 42.00')
  end

  it 'links the championship page to its Esquadrão' do
    get "/admin/championships/#{championship.id}"

    expect(response.body).to include("/admin/esquadrao?championship_id=#{championship.id}")
  end

  it 'redirects the old Cartola admin URLs (301)' do
    {
      "/admin/cartolarankings?championship_id=#{championship.id}" =>
        "/admin/esquadrao?championship_id=#{championship.id}",
      "/admin/esquadraorankings?championship_id=#{championship.id}" =>
        "/admin/esquadrao?championship_id=#{championship.id}",
      '/admin/cartola_scoring_rules' => '/admin/esquadrao_scoring_rules',
      '/admin/cartola_scoring_rules/3/edit' => '/admin/esquadrao_scoring_rules/3/edit',
      '/admin/squads/5' => '/admin/esquadrao_squads/5'
    }.each do |old_url, new_url|
      get old_url

      expect(response).to have_http_status(:moved_permanently), old_url
      expect(response).to redirect_to(new_url)
    end
  end

  it 'labels the admin menu as Esquadrão' do
    get '/admin/esquadrao'

    expect(response.body).to include('Esquadrão', 'Times do Esquadrão', 'Regras do Esquadrão')
    expect(response.body).not_to include('Cartola')
  end
end
