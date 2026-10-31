require_relative 'lib/bolao/version'

Gem::Specification.new do |spec|
  spec.name        = 'bolao'
  spec.version     = Bolao::VERSION
  spec.authors     = ['Futebol']
  spec.summary     = 'Score prediction pools.'
  spec.required_ruby_version = '>= 3.3'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'core'
  spec.add_dependency 'rails', '~> 8.1.2'
end
