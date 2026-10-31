require 'rails_helper'

RSpec.describe 'Engine boot' do
  engines = {
    'core' => 'Core::Engine',
    'bolao' => 'Bolao::Engine',
    'cartola' => 'Cartola::Engine',
    'simulador' => 'Simulador::Engine'
  }

  engines.each do |name, engine_class|
    describe engine_class do
      it 'is defined and loaded as a Rails engine' do
        engine = engine_class.safe_constantize

        expect(engine).to be < Rails::Engine
        expect(Rails.application.railties).to include(engine.instance)
      end

      it 'isolates its namespace' do
        expect(engine_class.safe_constantize.isolated?).to be(true)
      end

      it "lives under engines/#{name}" do
        expect(engine_class.safe_constantize.root).to eq(Rails.root.join('engines', name))
      end
    end
  end
end
