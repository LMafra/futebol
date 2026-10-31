RSpec.configure do |config|
  config.before(:suite) do
    builds = %w[tailwind.css active_admin.css].map { |file| Rails.root.join('app/assets/builds', file) }
    system('bin/rails', 'tailwindcss:build', exception: true) unless builds.all?(&:exist?)
  end
end
