require 'rails_helper'

RSpec.describe 'Gestor creates bolões (TICKET-0093)', type: :request do
  let(:manager) { create(:user, :manager) }
  let(:championship) { create(:championship, manager:) }

  before { sign_in(manager) }

  it 'offers "Criar bolão" on the championship page, prefilled with the championship' do
    get "/gestor/championships/#{championship.id}"
    link = Nokogiri::HTML(response.body).css('a').find { _1.text.strip == 'Criar bolão' }

    get link['href']
    selected = Nokogiri::HTML(response.body).at_css('#pool_championship_id option[selected]')
    expect(selected['value']).to eq(championship.id.to_s)
  end

  it 'creates the pool owned by the gestor, without making him a participant' do
    expect { post '/gestor/pools', params: { pool: { name: 'Bolão da Várzea', championship_id: championship.id } } }
      .to change(Bolao::Pool, :count).by(1)

    pool = Bolao::Pool.last
    expect(pool).to have_attributes(owner: manager, championship:)
    expect(pool.members).to be_empty
    expect(response).to redirect_to("/gestor/pools/#{pool.id}")
    follow_redirect!
    expect(response.body).to include("Compartilhe o código #{pool.code}")
  end

  it "refuses a pool on another gestor's championship" do
    foreign = create(:championship, manager: create(:user, :manager))

    expect { post '/gestor/pools', params: { pool: { name: 'Intruso', championship_id: foreign.id } } }
      .not_to change(Bolao::Pool, :count)
  end
end
