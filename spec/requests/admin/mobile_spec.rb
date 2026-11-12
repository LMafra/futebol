require 'rails_helper'

RSpec.describe 'ActiveAdmin mobile chrome', type: :request do
  before { sign_in(create(:user, :admin)) }

  it 'collapses the sidebar below md with a header toggle' do
    get '/admin'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-role="craquefy-admin-sidebar"', '-translate-x-full', 'md:translate-x-0')
    expect(response.body).to include('data-role="admin-sidebar-toggle"', 'md:hidden', 'data-drawer-target="main-menu"')
    expect(response.body).to include('md:ms-60')
  end

  it 'stacks admin KPI cards to a single column on small screens' do
    get '/admin'

    expect(response.body).to include('grid-cols-1', 'sm:grid-cols-2', 'lg:grid-cols-4')
  end
end
