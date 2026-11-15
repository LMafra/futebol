require 'rails_helper'

RSpec.describe 'ActiveAdmin Placar forms', type: :request do
  before { sign_in(create(:user, :admin)) }

  it 'styles championship form inputs and submit with Placar tokens' do
    get '/admin/championships/new'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('border-rule', 'bg-paper', 'font-body', 'font-semibold', 'text-ink')
    expect(response.body).to include('bg-cartola')
    expect(response.body).to match(/formtastic|championship/i)
  end

  it 'keeps checkboxes compact instead of full-width text-field styling' do
    get '/admin/championships/new'

    checkbox = Nokogiri::HTML(response.body).at_css('input#championship_private[type="checkbox"]')
    expect(checkbox['class'].split).to include('h-5', 'w-5', 'text-pitch')
    expect(checkbox['class'].split).not_to include('w-full', 'min-h-10')
  end

  it 'groups championship form into Dados, Esquadrão, Bolão and Premiação' do
    get '/admin/championships/new'

    expect(response.body).to include('Dados', 'Esquadrão', 'Bolão', 'Premiação')
    expect(response.body).to include('Regras do Bolão')
    expect(response.body).to include('fieldset')
  end

  it 'shows Campeonato atualizado after saving' do
    championship = create(:championship)

    patch "/admin/championships/#{championship.id}", params: {
      championship: { name: 'Copa Atualizada', season: championship.season }
    }

    expect(response).to redirect_to(admin_championship_path(championship))
    follow_redirect!
    expect(response.body).to include('Campeonato atualizado', 'data-role="admin-toast"')
  end
end
