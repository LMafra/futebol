require 'capybara/cuprite'

# Headless Chrome through Ferrum. BROWSER_PATH points at a Chrome/Chromium binary when it isn't on the PATH.
Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1280, 900],
    headless: ENV['HEADFUL'].blank?,
    process_timeout: 30,
    timeout: 15,
    browser_options: { 'no-sandbox' => nil }
  )
end

Capybara.default_max_wait_time = 5
Capybara.disable_animation = true
# The bet inputs are labelled by aria-label only ("Gols do mandante").
Capybara.enable_aria_label = true

module SystemAuthenticationHelpers
  def sign_in_through_form(user, password: 'password123')
    visit new_session_path
    fill_in 'E-mail', with: user.email_address
    fill_in 'Senha', with: password
    click_on 'Entrar'
    expect(page).to have_no_current_path(new_session_path)
  end
end

CHROME_AVAILABLE = ENV['BROWSER_PATH'].present? || Ferrum::Browser::Options::Chrome.options.detect_path.present?

RSpec.configure do |config|
  config.include SystemAuthenticationHelpers, type: :system
  config.before(:each, type: :system) do
    # CI always has Chrome, so a missing browser there must fail instead of skipping.
    skip 'Chrome/Chromium não encontrado: instale ou defina BROWSER_PATH' unless CHROME_AVAILABLE || ENV['CI']
    driven_by :cuprite
  end
end
