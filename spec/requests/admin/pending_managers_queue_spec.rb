require 'rails_helper'

RSpec.describe 'Admin pending managers queue (TICKET-0075)', type: :request do
  let(:admin) { create(:user, :admin) }
  let!(:candidate) { create(:user, :pending_manager, name: 'Rita Gestora', email_address: 'rita@example.com') }

  before do
    create(:audit_log, action: 'user.manager_requested', user: candidate, auditable: candidate, created_at: 2.days.ago)
    sign_in(admin)
  end

  def page_html = Nokogiri::HTML(response.body)

  it 'shows the queue right below the KPIs with counters and inline triage' do
    get '/admin'

    metrics_at = response.body.index('data-role="admin-metrics"')
    expect(metrics_at).to be < response.body.index('data-role="admin-pending-managers"')
    expect(page_html.at_css('[data-role="pending-managers-count"]').text.squish).to eq('1 pendente · 1 há mais de 24h')
    headers = page_html.css('#pending-managers thead th').map { _1.text.squish }
    expect(headers).to eq(['Nome', 'E-mail', 'Pedido em', 'Ações'])
    row = page_html.at_css("#pending-managers-item-#{candidate.id}")
    expect(row.at_css('[data-role="overdue"]')).to be_present
    expect(row.text).to include('Rita Gestora', 'rita@example.com', '+24h')
    approve = row.at_css('form[data-role="approve-manager-form"]')
    expect(approve['action']).to eq(approve_manager_admin_user_path(candidate))
    expect(approve.at_css('input[name="return_to"]')['value']).to eq('dashboard')
    expect(row.at_css('details textarea[name="reason"][required]')).to be_present
    expect(row.at_css('label').text).to include('Motivo da recusa')
  end

  it 'approves from the queue and comes back to the dashboard' do
    put approve_manager_admin_user_path(candidate), params: { return_to: 'dashboard' }

    expect(response).to redirect_to(admin_root_path)
    expect(flash[:notice]).to eq('Gestor aprovado: Rita Gestora.')
    expect(candidate.reload).to have_attributes(manager_status: 'approved', role: 'manager')
  end

  it 'keeps the request pending and flags the field when the reason is blank' do
    put reject_manager_admin_user_path(candidate), params: { return_to: 'dashboard', reason: '  ' }

    expect(response).to redirect_to(admin_root_path)
    expect(candidate.reload.manager_status).to eq('pending')
    follow_redirect!
    row = page_html.at_css("#pending-managers-item-#{candidate.id}")
    expect(row.at_css('details')['open']).not_to be_nil
    textarea = row.at_css('textarea[name="reason"]')
    expect(textarea['aria-invalid']).to eq('true')
    expect(row.at_css("##{textarea['aria-describedby']}").text).to eq('Informe o motivo da recusa.')
    expect(page_html.css('[data-role="admin-toast"]').map { _1.text.squish }).to eq(['Informe o motivo da recusa.'])
  end

  it 'rejects with a reason recorded in the audit metadata' do
    put reject_manager_admin_user_path(candidate), params: { return_to: 'dashboard', reason: 'Sem campeonato ativo' }

    expect(response).to redirect_to(admin_root_path)
    expect(candidate.reload.manager_status).to eq('rejected')
    log = Core::AuditLog.find_by!(action: 'user.manager_rejected', auditable: candidate)
    expect(log.metadata).to eq('reason' => 'Sem campeonato ativo')
  end

  it 'shows an empty state when nobody is waiting' do
    candidate.update!(manager_status: :approved)

    get '/admin'

    expect(page_html.at_css('[data-role="admin-pending-managers"] [data-role="empty-state"]').text)
      .to include('Nenhum pedido de gestor pendente.')
  end
end
