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

  it 'renders the bottom nav with Mais drawer trigger on mobile chrome' do
    get '/admin'

    expect(response.body).to include('data-role="admin-bottom-nav"', 'data-role="admin-bottom-nav-more"', 'Mais')
    expect(response.body).not_to include('data-role="fab"')
  end

  it 'stacks match rows as cards below md with an in-card primary action' do
    create(:match, status: 'live', match_date: 1.hour.ago)

    get '/admin/matches', params: { scope: 'all', view: 'table' }

    expect(response.body).to include('max-md:flex max-md:flex-col', 'data-role="match-primary-action"', 'min-h-11')
  end
end
