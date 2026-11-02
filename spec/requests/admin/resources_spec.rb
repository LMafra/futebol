require 'rails_helper'

RSpec.describe 'ActiveAdmin resources (Pundit)', type: :request do
  let(:match) { create(:match) }
  let(:records) do
    {
      matches: match,
      championships: match.championship,
      teams: match.home_team,
      players: create(:player),
      bolao_scoring_rules: create(:bolao_scoring_rule),
      esquadrao_scoring_rules: create(:cartola_scoring_rule),
      csv_imports: create(:csv_import),
      pools: create(:bolao_pool),
      esquadrao_squads: create(:cartola_squad),
      audit_logs: create(:audit_log, auditable: match)
    }
  end

  context 'as an admin' do
    before { sign_in(create(:user, :admin)) }

    it 'admin acessa /admin/matches (200)' do
      match

      get '/admin/matches'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(match.to_s)
    end

    it 'renders index and show of every resource' do
      records.each do |resource, record|
        get "/admin/#{resource}"
        expect(response).to have_http_status(:ok), "index #{resource}: #{response.status}"

        get "/admin/#{resource}/#{record.id}"
        expect(response).to have_http_status(:ok), "show #{resource}: #{response.status}"
      end
    end

    it 'renders the form of the editable resources' do
      editable = %w[championships teams players bolao_scoring_rules esquadrao_scoring_rules csv_imports pools
                    esquadrao_squads]
      editable.each do |resource|
        get "/admin/#{resource}/new"
        expect(response).to have_http_status(:ok), "new #{resource}: #{response.status}"
      end
    end

    it 'creates a team through the admin' do
      expect do
        post '/admin/teams', params: { team: { name: 'Bahia', short_name: 'bah', external_id: 'bahia' } }
      end.to change(Core::Team, :count).by(1)
      expect(Core::Team.last.short_name).to eq('BAH')
    end

    it 'does not route create/update/destroy for matches (they change only through the admin pages)' do
      delete "/admin/matches/#{match.id}"

      expect(response).to have_http_status(:not_found)
      expect(match.reload).to be_persisted
    end
  end

  context 'as a signed-in user who is not an admin' do
    before { sign_in(create(:user)) }

    it 'não-admin recebe 403 (Pundit) em todos os resources' do
      records.each do |resource, record|
        get "/admin/#{resource}"
        expect(response).to have_http_status(:forbidden), "index #{resource}: #{response.status}"

        get "/admin/#{resource}/#{record.id}"
        expect(response).to have_http_status(:forbidden), "show #{resource}: #{response.status}"
      end
    end

    it 'cannot create records' do
      expect do
        post '/admin/teams', params: { team: { name: 'Bahia', short_name: 'BAH', external_id: 'bahia' } }
      end.not_to change(Core::Team, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  it 'redirects visitors without a session to the login' do
    get '/admin/matches'

    expect(response).to redirect_to(new_session_path)
  end
end
