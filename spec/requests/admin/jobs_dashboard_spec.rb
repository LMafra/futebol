require 'rails_helper'

RSpec.describe 'Solid Queue dashboard (/admin/jobs)', type: :request do
  it 'redirects visitors to the login page' do
    get '/admin/jobs'

    expect(response).to redirect_to('/session/new')
  end

  it 'answers 403 to signed-in non-admins' do
    sign_in(create(:user))

    get '/admin/jobs'

    expect(response).to have_http_status(:forbidden)
    expect(response.body).to include('Acesso negado')
  end

  it 'shows the Solid Queue queues to admins' do
    SolidQueue::Job.create!(queue_name: 'scoring', class_name: 'ProcessMatchPointsJob', arguments: {})
    sign_in(create(:user, :admin))

    get '/admin/jobs'
    follow_redirect! while response.redirect?

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('scoring')
  end

  it 'keeps non-admins out of nested pages' do
    sign_in(create(:user))

    get '/admin/jobs/applications/futebol/failed/jobs'

    expect(response).to have_http_status(:forbidden)
  end
end
