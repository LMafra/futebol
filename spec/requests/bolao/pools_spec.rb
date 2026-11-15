require 'rails_helper'

RSpec.describe 'Bolão pools', type: :request do
  let(:owner) { create(:user) }
  let(:championship) { create(:championship) }

  it 'não cria bolão pelo site público: só o gestor ou o admin criam (TICKET-0093)' do
    sign_in(owner)

    get pools_path
    expect(response.body).not_to include('Criar bolão')
    expect(Nokogiri::HTML(response.body).at_css('[data-role="join-hint"]').text).to include('gestor')

    expect { post pools_path, params: { pool: { name: 'Bolão da firma', championship_id: championship.id } } }
      .not_to change(Bolao::Pool, :count)
    expect(response).to have_http_status(:not_found)
  end

  it 'entra no pool com um código válido' do
    pool = create(:bolao_pool, owner:)
    member = create(:user)
    sign_in(member)

    expect { post join_pools_path, params: { code: pool.code.downcase } }
      .to change { pool.members.reload.count }.from(0).to(1)
    expect(response).to redirect_to(pool_path(pool))
  end

  it 'recusa entrar duas vezes no mesmo pool' do
    pool = create(:bolao_pool, owner:)
    member = create(:user)
    sign_in(member)
    post join_pools_path, params: { code: pool.code }

    expect { post join_pools_path, params: { code: pool.code } }.not_to change(Bolao::PoolMembership, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('Você já participa deste bolão.')
  end

  it 'só o owner deleta o pool' do
    pool = create(:bolao_pool, owner:)
    member = create(:user)
    pool.memberships.create!(user: member)

    sign_in(member)
    expect { delete pool_path(pool) }.not_to change(Bolao::Pool, :count)
    expect(response).to have_http_status(:forbidden)

    sign_in(owner)
    expect { delete pool_path(pool) }.to change(Bolao::Pool, :count).by(-1)
    expect(response).to redirect_to(pools_path)
  end

  it 'não-membro recebe 403 ao abrir o pool' do
    pool = create(:bolao_pool, owner:)
    sign_in(create(:user))

    get pool_path(pool)

    expect(response).to have_http_status(:forbidden)
    expect(response.body).not_to include(pool.code)
  end
end
