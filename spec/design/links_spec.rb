require 'rails_helper'

# docs/ux/links-e-botoes.md: a link says where it goes, and a text link is underlined at rest.
RSpec.describe 'Links e botões' do
  sources = Rails.root.glob('app/{views,components,admin,helpers}/**/*.{erb,rb}').sort
  vague = Regexp.union('Ver', 'ver', 'Clique aqui', 'clique aqui', 'aqui', 'Saiba mais', 'saiba mais',
                       'nesta página', 'Crie o primeiro')
  label = /["'](?:#{vague})["']/
  vague_calls = /\b(?:link_to|button_to|submit_tag|submit|admin_icon_action_link)\(?\s*#{label}/
  vague_buttons = %r{<button[^>]*>\s*(?:#{vague})\s*</button>}

  it 'has no vague link or button labels' do
    offenders = sources.flat_map do |path|
      File.readlines(path).each_with_index.filter_map do |line, index|
        "#{path.relative_path_from(Rails.root)}:#{index + 1}" if line.match?(vague_calls) || line.match?(vague_buttons)
      end
    end

    expect(offenders).to be_empty
  end

  it 'never underlines a text link only on hover (a whole clickable card may, through group-hover)' do
    offenders = sources.select { |path| File.read(path).match?(/(?<![\w-])hover:underline/) }
                       .map { |path| path.relative_path_from(Rails.root).to_s }

    expect(offenders).to be_empty
  end
end
