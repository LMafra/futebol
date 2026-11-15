require 'rails_helper'

RSpec.describe 'Classificação com dedução de pontos', type: :request do
  let(:manager) { create(:user, :manager) }
  let(:championship) { create(:championship, manager:, name: 'Copa do Bairro') }
  let(:home) { create(:team, manager:, name: 'Unidos da Vila') }
  let(:away) { create(:team, manager:, name: 'Real Várzea') }
  let(:tab) { "/gestor/championships/#{championship.id}?aba=classificacao" }

  before do
    create(:match, championship:, home_team: home, away_team: away, status: 'finished', home_score: 2, away_score: 0)
  end

  def deduct(path_prefix, points: 4, reason: 'W.O. na 2ª rodada', team: home)
    post "#{path_prefix}/championships/#{championship.id}/deduct_points",
         params: { modal: 'deduction', return_to: "#{path_prefix}/championships/#{championship.id}?aba=classificacao",
                   deduction: { team_id: team.id, points:, reason: } }
  end

  def standing_points(body)
    Nokogiri::HTML(body).css('[data-role="standing-row"]').to_h do |row|
      [row.at_css('th').xpath('.//text()').map(&:text).reject(&:blank?).last.squish, row.css('td')[1].text.to_i]
    end
  end

  context 'as the gestor of the championship' do
    before { sign_in(manager) }

    it 'shows the Classificação tab with the Dedução column and the dialog' do
      get tab

      expect(response.body).to include('Seções do campeonato', 'Deduzir pontos', 'Dedução', 'Nenhuma dedução')
      expect(standing_points(response.body)).to eq('Unidos da Vila' => 3, 'Real Várzea' => 0)
    end

    it 'deducts points with a reason and an audit log' do
      expect { deduct('/gestor') }.to change(Core::AuditLog.where(action: 'championship.points_deducted'), :count).by(1)

      expect(Core::PointDeduction.last).to have_attributes(team: home, points: 4, created_by: manager)
      follow_redirect!
      expect(response.body).to include('Unidos da Vila perdeu 4 pontos', 'W.O. na 2ª rodada')
      expect(standing_points(response.body)).to eq('Real Várzea' => 0, 'Unidos da Vila' => -1)
    end

    it 'reopens the dialog with the errors when the reason is missing' do
      expect { deduct('/gestor', points: 0, reason: '') }.not_to change(Core::PointDeduction, :count)

      expect(response).to redirect_to("#{tab}&modal=deduction")
      follow_redirect!
      expect(response.body).to include('precisam de atenção', 'Motivo não pode ficar em branco')
    end

    it 'revokes a deduction and keeps it in the history' do
      deduct('/gestor')
      deduction = Core::PointDeduction.last

      patch "/gestor/championships/#{championship.id}/revoke_deduction", params: { deduction_id: deduction.id }

      expect(deduction.reload).to have_attributes(revoked?: true, revoked_by: manager)
      expect(Core::AuditLog.where(action: 'championship.points_deduction_revoked').count).to eq(1)
      follow_redirect!
      expect(response.body).to include('Dedução de Unidos da Vila revogada', 'revogada por')
      expect(standing_points(response.body)).to eq('Unidos da Vila' => 3, 'Real Várzea' => 0)
    end
  end

  it 'keeps another gestor out of the championship' do
    sign_in(create(:user, :manager))

    deduct('/gestor')

    expect(Core::PointDeduction.count).to eq(0)
    expect(response).to have_http_status(:forbidden).or have_http_status(:not_found).or redirect_to('/gestor')
  end

  it 'lets the admin deduct on any championship' do
    sign_in(create(:user, :admin))

    deduct('/admin', points: 1)
    follow_redirect!

    expect(response.body).to include('Classificação', 'Unidos da Vila perdeu 1 ponto')
    expect(standing_points(response.body)['Unidos da Vila']).to eq(2)
  end

  describe 'public pages' do
    before do
      PointDeductions.deduct(championship:, attributes: { team_id: home.id, points: 4, reason: 'W.O. na 2ª rodada' },
                             actor: manager, ip_address: '127.0.0.1')
    end

    it 'shows the deduction and its reason on the championship table' do
      get "/campeonatos/#{championship.id}"

      page = Nokogiri::HTML(response.body)
      expect(page.css('th').map { |th| th.text.squish }).to include('Dedução')
      expect(page.at_css('[data-role="deduction-notes"]').text.squish)
        .to eq('Unidos da Vila: −4 pontos (W.O. na 2ª rodada)')
      expect(standing_points(response.body)).to eq('Real Várzea' => 0, 'Unidos da Vila' => -1)
    end

    it 'shows the deduction next to the leaders on the home' do
      get '/'

      card = Nokogiri::HTML(response.body).at_css("[data-championship-id='#{championship.id}']")
      expect(card.at_css('[data-role="standings-leaders"]').text.squish)
        .to include('Unidos da Vila −4', 'Unidos da Vila: −4 pontos (W.O. na 2ª rodada)')
    end

    it 'drops a revoked deduction' do
      PointDeductions.revoke(Core::PointDeduction.last, actor: manager, ip_address: '127.0.0.1')

      get "/campeonatos/#{championship.id}"

      expect(response.body).not_to include('W.O. na 2ª rodada')
      expect(standing_points(response.body)).to eq('Unidos da Vila' => 3, 'Real Várzea' => 0)
    end
  end
end
