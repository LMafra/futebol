require 'rails_helper'

RSpec.describe 'Admin/Gestor visual base (TICKET-0080)' do
  let(:root) { Rails.root }
  let(:source_css) { root.join('app/assets/stylesheets/active_admin.css').read }

  it 'keeps the admin light-only even when the OS prefers dark' do
    config = root.join('tailwind-active_admin.config.js').read
    expect(config).to include('darkMode: ["selector", "[data-theme=never]"]')

    admin_js = root.join('app/javascript/admin.js').read
    expect(admin_js).to include('localStorage.setItem("theme", "light")')
  end

  it 'gives every form control a white fill with a graphite border' do
    expect(source_css)
      .to match(%r{:root :is\(\[type=datetime-local\].*select, textarea\) \{\s*@apply border-graphite/70 bg-white}m)
    expect(source_css).to match(%r{:root \[type=file\]::file-selector-button \{\s*@apply border-graphite/70 bg-white})
  end

  it 'never paints text in cartola' do
    expect(source_css).not_to match(%r{text-cartola(?!/)})
    admin_views = Dir[root.join('app/views/{active_admin,admin,gestor}/**/*.erb')].map { |path| File.read(path) }
    expect(admin_views.grep(/text-cartola/)).to be_empty
  end

  it 'exposes the solid danger token for destructive actions' do
    expect(source_css).to include('--color-loss-solid: #A4161A')
    expect(AdminHelper::ADMIN_DANGER_BUTTON_CLASSES).to include('bg-loss-solid', 'text-paper')
  end

  it 'gives every admin button role a 40px target and a visible ink focus ring' do
    [AdminHelper::ADMIN_BUTTON_CLASSES, AdminHelper::ADMIN_SECONDARY_BUTTON_CLASSES,
     AdminHelper::ADMIN_DANGER_BUTTON_CLASSES].each do |classes|
      expect(classes).to include('min-h-10', 'focus-visible:ring-2', 'focus-visible:ring-ink')
    end
  end

  it 'ships the compiled base rules ahead of the plugin defaults' do
    built = root.join('app/assets/builds/active_admin.css').read
    expect(built).to include(':root a{color:var(--color-pitch)')
    expect(built).not_to match(/\.dark\\:[\w-]+:where\(\.dark/)
  end
end
