require 'rails_helper'

RSpec.describe 'ActiveAdmin Placar de Domingo theme', type: :request do
  let(:admin_css) { Rails.root.join('app/assets/builds/active_admin.css') }

  before { sign_in(create(:user, :admin)) }

  it 'loads the admin with Craquefy Admin title and Placar tokens in the stylesheet' do
    get '/admin'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Craquefy Admin')
    expect(response.body).to match(%r{/assets/active_admin-\h+\.css})
    expect(admin_css).to exist
    css = admin_css.read
    expect(css).to include('--color-paper', '--color-pitch', '--color-cartola')
    expect(css).to include('.attributes-table')
  end
end
