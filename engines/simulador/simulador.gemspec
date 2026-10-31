require_relative 'lib/simulador/version'

Gem::Specification.new do |spec|
  spec.name        = 'simulador'
  spec.version     = Simulador::VERSION
  spec.authors     = ['Futebol']
  spec.summary     = 'Read-only championship simulations over core data.'
  spec.required_ruby_version = '>= 3.3'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'core'
  spec.add_dependency 'rails', '~> 8.1.2'
end
