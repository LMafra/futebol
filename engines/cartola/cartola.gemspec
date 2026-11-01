require_relative 'lib/cartola/version'

Gem::Specification.new do |spec|
  spec.name        = 'cartola'
  spec.version     = Cartola::VERSION
  spec.authors     = ['Futebol']
  spec.summary     = 'Fantasy football squads and lineups.'
  spec.required_ruby_version = '>= 3.3'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'core'
  spec.add_dependency 'rails', '~> 8.1.4'
end
