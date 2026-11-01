require 'rails_helper'

RSpec.describe 'Health check (/up)', type: :request do
  it 'answers 200 without a session (Render health check and keep-alive ping)' do
    get '/up'

    expect(response).to have_http_status(:ok)
  end
end
