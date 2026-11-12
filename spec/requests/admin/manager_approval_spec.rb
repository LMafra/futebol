require 'rails_helper'

RSpec.describe 'Admin manager approval', type: :request do
  let(:admin) { create(:user, :admin) }
  let(:pending_manager) { create(:user, :pending_manager) }

  before { sign_in(admin) }

  it 'renders approve and reject as PUT forms that work without Turbo' do
    get admin_user_path(pending_manager)

    page = Nokogiri::HTML(response.body)
    approve_form = page.at_css("form[action='#{approve_manager_admin_user_path(pending_manager)}']")
    reject_form = page.at_css("form[action='#{reject_manager_admin_user_path(pending_manager)}']")

    expect(approve_form.at_css('input[name=_method]')['value']).to eq('put')
    expect(reject_form.at_css('input[name=_method]')['value']).to eq('put')
    expect(approve_form.at_css('button')['data-confirm']).to be_present
    expect(response.body).not_to include('data-turbo-method', 'data-turbo-confirm')
  end

  it 'approves the request and redirects back with a flash' do
    put approve_manager_admin_user_path(pending_manager)

    expect(response).to redirect_to(admin_user_path(pending_manager))
    expect(flash[:notice]).to eq('Gestor aprovado.')
    expect(pending_manager.reload.manager_status).to eq('approved')
  end

  it 'rejects the request and redirects back with a flash' do
    put reject_manager_admin_user_path(pending_manager)

    expect(response).to redirect_to(admin_user_path(pending_manager))
    expect(flash[:notice]).to eq('Pedido recusado.')
    expect(pending_manager.reload.manager_status).to eq('rejected')
  end
end
