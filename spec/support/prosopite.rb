# An N+1 fails the spec with Prosopite::NPlusOneQueriesError. Scans cover one unit of work each: a request
# (Prosopite::Middleware::Rack in config/environments/test.rb), a job perform and a component render.
# Examples aren't scanned whole: repeating a unit (two requests, a job run twice) or looping in the spec is no N+1.
Prosopite.raise = true
Prosopite.rails_logger = true
Prosopite.allow_stack_paths = ['db/seeds']

ActiveJob::Base.around_perform { |_job, perform| Prosopite.scan { perform.call } }

module ProsopiteRenderInline
  def render_inline(...) = Prosopite.scan { super }
end

RSpec.configure do |config|
  config.prepend ProsopiteRenderInline, type: :component
end
