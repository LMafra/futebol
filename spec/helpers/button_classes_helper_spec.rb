require 'rails_helper'

RSpec.describe ButtonClassesHelper, type: :helper do
  def classes(role, ...) = helper.public_send(:"#{role}_button_classes", ...).split

  it 'shares one base (48px, bold, transition, legible disabled) across the three roles' do
    %i[primary secondary danger].each do |role|
      expect(classes(role)).to include('min-h-12', 'font-bold', 'rounded-sm', 'px-4', 'py-2', 'disabled:opacity-60')
    end
  end

  it 'maps the roles to the Placar de Domingo tokens, never cartola as text' do
    expect(classes(:primary)).to include('bg-cartola', 'text-ink')
    expect(classes(:secondary)).to include('border-graphite', 'bg-white', 'text-ink', 'hover:bg-rule')
    expect(classes(:danger)).to include('bg-loss-solid', 'text-white')
    expect(%i[primary secondary danger].flat_map { classes(_1) }).not_to include('text-cartola', 'bg-pitch')
  end

  it 'accepts a size and extra classes' do
    expect(classes(:primary, 'self-start', size: :lg)).to include('px-4', 'py-3', 'text-lg', 'self-start')
    expect(classes(:secondary, size: :sm)).to include('px-3', 'text-sm')
  end
end
