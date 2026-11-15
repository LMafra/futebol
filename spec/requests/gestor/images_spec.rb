require 'rails_helper'

RSpec.describe 'Escudo e logo', type: :request do
  let(:manager) { create(:user, :manager) }
  let(:team) { create(:team, manager:, name: 'Unidos da Vila') }
  let(:championship) { create(:championship, manager:, name: 'Copa do Bairro') }
  let(:png) { Rack::Test::UploadedFile.new(file_fixture('crest.png'), 'image/png') }

  before { sign_in(manager) }

  it 'o gestor envia o escudo do time e o vê na página do time' do
    get "/gestor/teams/#{team.id}/edit"
    expect(response.body).to include('data-controller="image-preview"', 'PNG, JPEG, WebP ou SVG, até 2 MB.')

    patch "/gestor/teams/#{team.id}", params: { team: { crest: png } }

    expect(team.reload.crest).to be_attached
    follow_redirect!
    expect(response.body).to include('alt="Unidos da Vila"', '/rails/active_storage/')
  end

  it 'recusa arquivo que não é imagem' do
    text = Rack::Test::UploadedFile.new(StringIO.new('texto'), 'text/plain', original_filename: 'escudo.txt')

    patch "/gestor/teams/#{team.id}", params: { team: { crest: text } }

    expect(team.reload.crest).not_to be_attached
    expect(response.body).to include('deve ser PNG, JPEG, WebP ou SVG')
  end

  it 'mostra o logo do campeonato na página pública' do
    patch "/gestor/championships/#{championship.id}", params: { championship: { logo: png } }

    get "/campeonatos/#{championship.id}"

    expect(response.body).to include('alt="Logo de Copa do Bairro"')
  end

  it 'mostra o escudo na classificação pública' do
    team.crest.attach(io: file_fixture('crest.png').open, filename: 'crest.png', content_type: 'image/png')
    create(:match, championship:, home_team: team, status: 'finished', home_score: 1, away_score: 0,
                   match_date: 1.day.ago)

    get "/campeonatos/#{championship.id}", params: { tab: 'times' }

    expect(response.body).to include('alt="Unidos da Vila"')
  end
end
