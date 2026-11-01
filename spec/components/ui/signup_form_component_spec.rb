require 'rails_helper'

RSpec.describe Ui::SignupFormComponent do
  it_behaves_like 'a ui component with four states', preview: Ui::SignupFormComponentPreview

  it 'requires a user in the default state' do
    expect { described_class.new }.to raise_error(ArgumentError, /user is required/)
  end

  it 'renders name, email, password and confirmation inputs posting to /users' do
    page = render_inline(described_class.new(user: Core::User.new))

    expect(page.at_css('form')['action']).to eq('/users')
    expect(page.css('input[required]').map { |input| input['name'] })
      .to eq(%w[user[name] user[email_address] user[password] user[password_confirmation]])
    expect(page.at_css('input[type="submit"]')['value']).to eq('Criar conta')
  end

  it 'flags invalid fields with their message and keeps the form' do
    user = Core::User.new(email_address: 'x')
    user.errors.add(:email_address, 'não é um e-mail válido')
    page = render_inline(described_class.new(user:, state: :error))

    expect(page.at_css('[role="alert"][data-role="errors"]')).to be_present
    expect(page.at_css('#user_email_address[aria-invalid="true"]')['aria-describedby'])
      .to eq('signup-email_address-error')
    expect(page.at_css('[data-role="field-error"]').text).to eq('E-mail não é um e-mail válido')
  end
end
