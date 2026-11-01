require 'rails_helper'

RSpec.describe 'Bolão pools', type: :request do
  let(:owner) { create(:user) }
  let(:championship) { create(:championship) }

  def create_pool(name: 'Bolão da firma')
    post pools_path, params: { pool: { name:, championship_id: championship.id } }
    Bolao::Pool.order(:id).last
  end

  it 'cria o pool com a membership do owner e um código de 6 caracteres' do
    sign_in(owner)

    expect { create_pool }.to change(Bolao::Pool, :count).by(1).and change(Bolao::PoolMembership, :count).by(1)

    pool = Bolao::Pool.last
    expect(response).to redirect_to(pool_path(pool))
    expect(pool.owner).to eq(owner)
    expect(pool.code).to match(/\A[A-HJ-NP-Z2-9]{6}\z/)
    expect(pool.members).to contain_exactly(owner)
  end

  it 'gera códigos únicos e troca o código quando há colisão' do
    sign_in(owner)
    first = create_pool(name: 'Primeiro')
    allow(Bolao::Pool).to receive(:generate_code).and_return(first.code, 'ZZZZZZ')

    second = create_pool(name: 'Segundo')

    expect(second.code).to eq('ZZZZZZ')
    expect(Bolao::Pool.distinct.count(:code)).to eq(2)
  end

  it 'entra no pool com um código válido' do
    pool = create(:bolao_pool, owner:)
    member = create(:user)
    sign_in(member)

    expect { post join_pools_path, params: { code: pool.code.downcase } }
      .to change { pool.members.reload.count }.from(1).to(2)
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
