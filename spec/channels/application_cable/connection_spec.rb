require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  it 'aceita visitante sem sessão (página pública da partida)' do
    connect '/cable'

    expect(connection.current_user).to be_nil
  end

  it 'identifica o usuário pela sessão' do
    user = create(:user)
    session = user.sessions.create!

    cookies.signed[:session_id] = session.id
    connect '/cable'

    expect(connection.current_user).to eq(user)
  end
end
