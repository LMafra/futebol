require 'rails_helper'

RSpec.describe 'Gestor dashboard', type: :request do
  it 'shows cards for championships managed by the signed-in manager' do
    manager = create(:user, :manager)
    create(:championship, manager:, name: 'Copa do Gestor')
    sign_in(manager)

    get '/gestor'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Copa do Gestor', 'data-role="gestor-championships"')
    expect(response.body).to include('lg:col-span-3', 'lg:col-span-9')
  end
end
