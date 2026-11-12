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

  it 'styles every footer link the same and announces the copied Pix key (TICKET-0083)' do
    get '/'

    footer = page_html.at_css('footer')
    expect(footer.css('a').map { _1['class'] }.uniq.size).to eq(1)
    summary = footer.at_css('[data-role="pix"] summary')
    expect(summary['class']).to include('[&::-webkit-details-marker]:hidden')
    expect(summary.at_css('svg[aria-hidden="true"]')).to be_present
    expect(footer.at_css('[data-role="pix-status"]')['aria-live']).to eq('polite')
  end
end
