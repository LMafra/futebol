require 'rails_helper'

RSpec.describe 'Public layout (TICKET-0082)', type: :request do
  def page_html = Nokogiri::HTML(response.body)

  it 'loads only the public stylesheets, never the Admin build' do
    get '/'

    hrefs = page_html.css('link[rel="stylesheet"]').map { _1['href'] }
    expect(hrefs).to include(a_string_matching(%r{/assets/tailwind-\h+\.css}))
    expect(hrefs.grep(/active_admin/)).to be_empty
  end

  it 'gives header controls a 48px target' do
    get '/'

    entrar = page_html.css('header a').find { _1.text.strip == 'Entrar' }
    expect(entrar['class'].split).to include('min-h-12')
  end
end
