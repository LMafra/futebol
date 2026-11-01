require 'rails_helper'

RSpec.describe 'User places a bet', type: :system do
  let(:user) { create(:user) }
  let(:pool) { create(:bolao_pool) }
  let!(:match) { create(:match, championship: pool.championship, match_date: 2.days.from_now + 3.hours) }

  it 'joins a pool by code, sees the live countdown and saves a bet' do
    sign_in_through_form(user)

    visit pools_path
    within('[data-role="join-form"]') do
      fill_in 'Entrar com código', with: pool.code.downcase
      click_on 'Entrar'
    end
    expect(page).to have_text("Você entrou no bolão #{pool.name}.")

    click_on 'Palpites'

    within("##{ActionView::RecordIdentifier.dom_id(match, :bet)}") do
      countdown = find('[data-controller="countdown"]', text: /\A2d \d{2}:\d{2}:\d{2}\z/)
      first_reading = countdown.text
      # The Stimulus controller ticks every second; a changed reading proves it runs in the browser.
      expect(page).to have_no_css('[data-controller="countdown"]', exact_text: first_reading)

      fill_in 'Gols do mandante', with: '2'
      fill_in 'Gols do visitante', with: '1'
      click_on 'Palpitar'
    end

    expect(page).to have_text('Palpite registrado.')
    expect(Bolao::Prediction.kept.find_by!(pool:, user:, match:)).to have_attributes(home_guess: 2, away_guess: 1)
  end
end
