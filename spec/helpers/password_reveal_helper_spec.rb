require 'rails_helper'

RSpec.describe PasswordRevealHelper, type: :helper do
  let(:html) do
    Nokogiri::HTML.fragment(helper.password_reveal { helper.password_field_tag(:senha, nil, id: 'senha') })
  end

  it 'wraps the field with the password-reveal controller' do
    expect(html.at_css('div[data-controller="password-reveal"] input#senha[type="password"]')).to be_present
  end

  it 'adds a 48px toggle button, hidden until JavaScript connects, labeled and not pressed' do
    button = html.at_css('button[data-password-reveal-target="button"]')

    expect(button.attributes).to include('hidden')
    expect(button.attributes.transform_values(&:value))
      .to include('type' => 'button', 'aria-label' => 'Mostrar senha', 'aria-pressed' => 'false',
                  'data-action' => 'password-reveal#toggle')
    expect(button['class'].split).to include('size-12')
    expect(button.css('svg[aria-hidden="true"]').size).to eq(2)
  end
end
