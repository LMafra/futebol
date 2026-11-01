require 'rails_helper'

RSpec.describe 'Design system ("Placar de Domingo")' do
  let(:tailwind_config) { Rails.root.join('config/tailwind.config.js').read }
  let(:ui_sources) do
    Rails.root.glob('{app/components,app/views,app/helpers,app/javascript,app/assets/tailwind}/**/*.{rb,erb,js,css}') +
      [Rails.root.join('config/tailwind.config.js')]
  end

  it 'derives the 60-30-10 palette and semantic tints from docs/design/0001-direction.md' do
    { paper: '#F4F1EA', pitch: '#0B6B3A', cartola: '#E85D04', ink: '#161616', graphite: '#4A4A45',
      rule: '#D9D3C4', night: '#0E1A13' }.each do |token, hex|
      expect(tailwind_config).to match(/#{token}: '#{hex}'/)
    end
    expect(tailwind_config).to include("win: 'rgb(11 107 58 / 0.15)'", "draw: 'rgb(138 133 119 / 0.15)'",
                                       "loss: 'rgb(164 22 26 / 0.15)'")
  end

  it 'pairs a display serif with a humanist sans' do
    expect(tailwind_config).to include("display: ['Fraunces', 'Bitter', 'Georgia', 'serif']")
    expect(tailwind_config).to include(%(sans: ['"Source Sans 3"', '"IBM Plex Sans"', 'system-ui', 'sans-serif']))
  end

  it 'loads the config from the Tailwind entrypoint' do
    expect(Rails.root.join('app/assets/tailwind/application.css').read)
      .to include('@config "../../../config/tailwind.config.js";')
  end

  it 'has no AI-slop styling (gradients, backdrop blur, colored shadows) in UI sources' do
    offenders = ui_sources.select { |path| path.read.match?(/bg-gradient|backdrop-blur|shadow-[a-z]+-\d{3}|glow/) }

    expect(offenders.map { |path| path.relative_path_from(Rails.root).to_s }).to be_empty
  end

  it 'never uses Inter, Roboto or Space Grotesk' do
    offenders = ui_sources.select { |path| path.read.match?(/\b(Inter|Roboto|Space Grotesk)\b/) }

    expect(offenders.map { |path| path.relative_path_from(Rails.root).to_s }).to be_empty
  end

  it 'only sets display type at text-xl or larger' do
    small_display = ui_sources.select do |path|
      path.read.scan(/class="([^"]*)"/).flatten.any? do |classes|
        classes.include?('font-display') && classes.match?(/\btext-(xs|sm|base|lg)\b/)
      end
    end

    expect(small_display.map { |path| path.relative_path_from(Rails.root).to_s }).to be_empty
  end
end
