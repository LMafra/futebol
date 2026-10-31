require_relative 'lib/core/version'

Gem::Specification.new do |spec|
  spec.name        = 'core'
  spec.version     = Core::VERSION
  spec.authors     = ['Futebol']
  spec.summary     = 'Shared domain: teams, matches, championships, users, audit logs, CSV imports.'
  spec.required_ruby_version = '>= 3.3'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'rails', '~> 8.1.2'
end
