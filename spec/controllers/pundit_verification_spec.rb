require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    allow_unauthenticated_access

    def index = head(:ok)

    def show = head(:ok)

    def edit
      authorize Core::Match.new, :show?
      head :ok
    end
  end

  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  def sign_in_as(user)
    cookies.signed[:session_id] = user.sessions.create!(ip_address: '127.0.0.1').id
  end

  it 'raises AuthorizationNotPerformedError when a non-index action skips authorize' do
    expect { get :show, params: { id: 1 } }.to raise_error(Pundit::AuthorizationNotPerformedError)
  end

  it 'raises PolicyScopingNotPerformedError when index skips policy_scope' do
    expect { get :index }.to raise_error(Pundit::PolicyScopingNotPerformedError)
  end

  it 'passes verification once the action authorizes, with Current.user as the pundit user' do
    sign_in_as(admin)
    get :edit, params: { id: 1 }

    expect(response).to have_http_status(:ok)
    expect(controller.pundit_user).to eq(admin)
  end

  it 'redirects HTML requests with a flash when the policy denies' do
    sign_in_as(regular_user)
    get :edit, params: { id: 1 }

    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq('Você não tem permissão para esta ação.')
  end

  it 'answers JSON requests with 403 when the policy denies' do
    sign_in_as(regular_user)
    get :edit, params: { id: 1 }, format: :json

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body).to eq('error' => 'forbidden')
  end
end
