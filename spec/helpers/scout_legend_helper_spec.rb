require 'rails_helper'

RSpec.describe ScoutLegendHelper, type: :helper do
  it 'lists every scout abbreviation with its meaning, in the scoring order' do
    legend = Nokogiri::HTML.fragment(helper.scout_legend).at_css('dl[data-role="scout-legend"]')

    expect(legend.css('dt').map(&:text)).to eq(%w[G A SG DP DE CA CV GC])
    expect(legend.css('dd').map(&:text)).to eq(['Gol', 'Assistência', 'Jogo sem sofrer gols', 'Defesa de pênalti',
                                                'Defesa (só goleiros)', 'Cartão amarelo', 'Cartão vermelho',
                                                'Gol contra'])
  end

  it 'renders the header as abbr from 640px up and the full label on phones' do
    header = Nokogiri::HTML.fragment(helper.scout_header(:yellow_cards))

    expect(header.at_css('abbr').attributes.transform_values(&:value))
      .to include('title' => 'Cartão amarelo', 'class' => 'hidden no-underline sm:inline')
    expect(header.at_css('abbr').text).to eq('CA')
    expect(header.at_css('span.sm\:hidden').text).to eq('Cartão amarelo')
  end
end
