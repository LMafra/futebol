require 'rails_helper'

RSpec.describe 'PWA instalável', type: :request do
  it 'serve o manifest com as cores da marca, ícones e abertura em tela cheia' do
    get '/manifest.json'

    expect(response).to have_http_status(:ok)
    manifest = response.parsed_body
    expect(manifest).to include('name' => 'Craquefy', 'short_name' => 'Craquefy', 'start_url' => '/',
                                'display' => 'standalone', 'theme_color' => '#0B6B3A', 'background_color' => '#F4F1EA')
    expect(manifest['icons'].map { _1.values_at('src', 'sizes', 'purpose') })
      .to include(['/icon-192.png', '192x192', 'any'], ['/icon.png', '512x512', 'any'],
                  ['/icon-maskable.png', '512x512', 'maskable'])
    manifest['icons'].each { expect(Rails.public_path.join(_1['src'].delete_prefix('/'))).to exist }
  end

  it 'serve o service worker com a página offline' do
    get '/service-worker.js'

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('text/javascript')
    expect(response.body).to include('/offline.html')
    expect(Rails.public_path.join('offline.html').read).to include('Você está sem conexão')
  end

  it 'liga o manifest, a cor do tema e o registro do service worker no site' do
    get '/'

    page = Nokogiri::HTML5(response.body)
    expect(page.at_css('link[rel="manifest"]')['href']).to eq('/manifest.json')
    expect(page.at_css('meta[name="theme-color"]')['content']).to eq('#0B6B3A')
    expect(page.at_css('link[rel="apple-touch-icon"]')['href']).to eq('/apple-touch-icon.png')
    expect(response.body).to include('import "pwa"')
  end

  context 'no Admin e no Gestor' do
    it 'liga o manifest e mostra o menu inferior abaixo de 640px, com as seções e "Mais"' do
      sign_in(create(:user, :manager))

      get '/gestor/championships'

      page = Nokogiri::HTML5(response.body)
      expect(page.at_css('link[rel="manifest"]')['href']).to eq('/manifest.json')
      nav = page.at_css('nav[data-role="admin-bottom-nav"]')
      expect(nav['class']).to include('sm:hidden', 'fixed', 'bottom-0')
      expect(nav.css('a').map { _1.text.squish }).to eq(%w[Painel Campeonatos Times Participantes])
      expect(nav.at_css('a[aria-current="page"]').text.squish).to eq('Campeonatos')
      expect(nav.at_css('button[data-drawer-show="main-menu"]').text.squish).to eq('Mais')
    end
  end
end
