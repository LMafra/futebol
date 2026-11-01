require 'rails_helper'

RSpec.describe 'Admin scoring dashboard', type: :request do
  it 'lists live matches with links to preview and finalize, and finished matches pending scoring' do
    live = create(:match, status: 'live', match_date: 1.hour.ago)
    pending = create(:match, status: 'finished', home_score: 1, away_score: 1, match_date: 1.day.ago)
    sign_in(create(:user, :admin))

    get '/admin'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(live.to_s, pending.to_s, "/admin/matchfinalizer?match_id=#{live.id}")
  end
end
