require 'rails_helper'

RSpec.describe 'Craquefy brand', type: :request do
  def page = Nokogiri::HTML(response.body)

  it 'names the public pages Craquefy, with the brand description and no Futebol' do
    get root_path

    expect(page.at_css('title').text).to eq('Craquefy')
    expect(page.at_css('meta[name="application-name"]')['content']).to eq('Craquefy')
    expect(page.at_css('meta[name="description"]')['content']).to eq(I18n.t('brand.description'))
    expect(response.body).not_to include('Futebol')
  end

  it 'credits the author and shows the Pix key to buy a coffee in the footer' do
    get root_path

    footer = page.at_css('footer')
    expect(footer.at_css('[data-role="author-link"]')['href']).to eq('https://github.com/LMafra')
    expect(footer.text.squish).to include('Desenvolvido por LMafra')
    pix = footer.at_css('[data-role="pix"]')
    expect(pix.at_css('summary').text).to eq('Pague o Café')
    expect(pix.at_css('[data-clipboard-target="source"]').text).to eq('chagas.lucas.mafra@gmail.com')
    expect(pix.at_css('button[data-action="clipboard#copy"]').text).to eq('Copiar chave')
  end

  it 'suffixes page titles with the brand' do
    sign_in(create(:user))
    get pools_path

    expect(page.at_css('title').text).to eq('Meus bolões · Craquefy')
  end

  it 'titles the admin with the brand' do
    sign_in(create(:user, :admin))

    get '/admin'

    expect(page.at_css('title').text).to end_with('Craquefy')
    expect(response.body).not_to include('Futebol')
  end

  it 'signs e-mails and names the PWA manifest with the brand' do
    mail = PasswordsMailer.reset(create(:user))
    manifest = JSON.parse(ApplicationController.render(template: 'pwa/manifest', formats: [:json]))

    expect([mail.html_part.body.to_s, mail.text_part.body.to_s]).to all(include('Craquefy · O campeonato do seu jeito'))
    expect(manifest).to include('name' => 'Craquefy', 'description' => I18n.t('brand.description'))
  end
end
