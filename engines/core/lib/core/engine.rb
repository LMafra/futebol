module Core
  class Engine < ::Rails::Engine
    isolate_namespace Core

    initializer 'core.append_migrations' do |app|
      next if app.root.to_s == root.to_s

      config.paths['db/migrate'].expanded.each { |path| app.config.paths['db/migrate'] << path }
    end
  end
end
