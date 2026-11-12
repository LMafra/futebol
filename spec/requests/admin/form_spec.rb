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
end
