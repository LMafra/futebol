# Run using bin/ci

CI.run do
  step 'Setup', 'bin/setup --skip-server'

  step 'Style: Ruby', 'bin/rubocop'
  step 'Design: anti-AI grep',
       "! grep -rEn 'bg-gradient|backdrop-blur|shadow-[a-z]+-[0-9]{3}' " \
       'app/components app/views app/helpers app/javascript app/assets/tailwind config/tailwind.config.js'

  step 'Security: Gem audit', 'bin/bundler-audit'
  step 'Security: Importmap vulnerability audit', 'bin/importmap audit'
  step 'Security: Brakeman code analysis', 'bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error'

  step 'Boundaries: Packwerk', 'bin/packwerk validate && bin/packwerk check'
  step 'Autoload: Zeitwerk', 'bin/rails zeitwerk:check'
  step 'Schema: database_consistency',
       'RAILS_ENV=test bundle exec database_consistency -c config/database_consistency.todo.yml'
  step 'Tests: RSpec', 'bundle exec rspec'

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
