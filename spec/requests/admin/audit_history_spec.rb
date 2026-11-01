require 'rails_helper'

RSpec.describe 'Admin AuditHistory page', type: :request do
  let(:admin) { create(:user, :admin, email_address: 'chefe@futebol.test') }
  let(:match) { create(:match) }

  before do
    create(:audit_log, action: 'revert', user: admin, auditable: match, ip_address: '203.0.113.9',
                       metadata: { reason: 'súmula corrigida' })
    create(:audit_log, action: 'anonymize', ip_address: '198.51.100.1')
  end

  it 'lists the audit trail (who, what, IP, reason) for admins' do
    sign_in(admin)

    get '/admin/audithistory'

    expect(response).to have_http_status(:ok)
    rows = Nokogiri::HTML(response.body).css('[data-role="audit-logs"] tbody tr').map { _1.text.squish }
    expect(rows.size).to eq(2)
    expect(rows.join).to include('revert', 'chefe@futebol.test', "Core::Match ##{match.id}", '203.0.113.9',
                                 'súmula corrigida')
  end

  it 'filters by action and by match' do
    sign_in(admin)

    get '/admin/audithistory', params: { audit_action: 'revert', match_id: match.id }

    expect(Nokogiri::HTML(response.body).css('[data-role="audit-logs"] tbody tr').size).to eq(1)
  end

  it 'answers 403 to non-admins' do
    sign_in(create(:user))

    get '/admin/audithistory'

    expect(response).to have_http_status(:forbidden)
  end
end
