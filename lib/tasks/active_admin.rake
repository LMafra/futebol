namespace :active_admin do
  desc 'Build ActiveAdmin CSS with the standalone Tailwind CLI'
  task build: :environment do
    input = Rails.root.join('app/assets/stylesheets/active_admin.css')
    output = Rails.root.join('app/assets/builds/active_admin.css')
    command = [Tailwindcss::Ruby.executable, '-i', input.to_s, '-o', output.to_s, '--minify']
    system(*command, exception: true)
  end

  desc 'Watch and rebuild ActiveAdmin CSS'
  task watch: :environment do
    input = Rails.root.join('app/assets/stylesheets/active_admin.css')
    output = Rails.root.join('app/assets/builds/active_admin.css')
    system(Tailwindcss::Ruby.executable, '-i', input.to_s, '-o', output.to_s, '--watch')
  end
end

Rake::Task['tailwindcss:build'].enhance(['active_admin:build'])
