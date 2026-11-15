require 'rails_helper'

RSpec.describe Ui::CollectionComponent do
  let(:items) do
    item = Struct.new(:id, :name, :team, :points, keyword_init: true)
    [item.new(id: 1, name: 'Ana', team: 'Várzea FC', points: 42),
     item.new(id: 2, name: 'Bruno', team: 'Vila', points: 37)]
  end

  it_behaves_like 'a ui component with four states', preview: Ui::CollectionComponentPreview

  def render_collection(**options, &extra)
    render_inline(described_class.new(items:, id: 'people', **options)) do |c|
      c.column(:name, label: 'Nome', primary: true, sortable: true)
      c.column(:team, label: 'Time', mobile_label: 'Equipe')
      c.column(:points, label: 'Pontos', numeric: true, sortable: true)
      extra&.call(c)
    end
  end

  it 'rejects unknown options and modes' do
    expect { described_class.new(colour: :red) }.to raise_error(ArgumentError, /unknown options: colour/)
    expect { render_inline(described_class.new(items:, mode: :carousel)) }.to raise_error(ArgumentError, /invalid mode/)
  end

  describe 'table mode' do
    it 'marks the primary column as the row header and labels the other cells for the stacked cards' do
      page = render_collection

      row = page.at_css('[data-role="collection-item"]')
      expect(row.at_css('th[scope="row"]').text).to eq('Ana')
      expect(row.css('td').map { _1['data-label'] }).to eq(%w[Equipe Pontos])
      expect(page.at_css('thead')['class']).to include('max-md:sr-only')
    end

    it 'prints a number returned by a column block' do
      page = render_collection { |c| c.column(:double, label: 'Dobro', numeric: true) { |item| item.points * 2 } }

      expect(page.at_css('[data-label="Dobro"]').text).to eq('84')
    end

    it 'links sortable headers, flags the current sort and flips its direction' do
      with_request_url('/pools?sort=points&dir=asc') { @page = render_collection(sort: 'points', direction: 'asc') }

      points = @page.css('thead th').find { _1.text.include?('Pontos') }
      expect(points['aria-sort']).to eq('ascending')
      expect(points.at_css('a')['href']).to eq('/pools?dir=desc&sort=points')
      expect(@page.css('thead th').find { _1.text.include?('Time') }.at_css('a')).to be_nil
      expect(@page.css('[data-role="mobile-sort"] a').map(&:text)).to eq(['Nome', 'Pontos ↑'])
    end
  end

  describe 'views' do
    it 'renders the toggle with the current view and falls back to the first one' do
      with_request_url('/pools?view=table&page=2') do
        @page = render_collection(views: { grid: 'Grade', table: 'Tabela' }, view: 'table')
      end

      links = @page.css('[data-role="view-toggle"] a')
      expect(links.map(&:text)).to eq(%w[Grade Tabela])
      expect(links.last['aria-current']).to eq('true')
      expect(links.first['href']).to eq('/pools?page=2&view=grid')
      expect(@page.at_css('section')['data-collection-views-value']).to eq('["grid","table"]')
      expect(render_collection(views: { grid: 'Grade', table: 'Tabela' }, view: 'agenda')
        .at_css('[data-role="collection-grid"]')).to be_present
    end
  end

  it 'renders cards with the primary column as title and label/value pairs' do
    card = render_collection(mode: :cards).at_css('[data-role="collection-item"]')

    expect(card.at_css('[data-role="collection-primary"]').text).to eq('Ana')
    expect(card.css('dt').map(&:text)).to eq(%w[Equipe Pontos])
  end

  it 'groups items in an accordion, opening the chosen group' do
    groups = render_collection(mode: :grouped, group_by: :team, open_group: 'Vila').css('details')

    expect(groups.map { _1.at_css('summary span').text }).to eq(['Várzea FC', 'Vila'])
    expect(groups.map { _1.key?('open') }).to eq([false, true])
  end

  it 'renders the agenda headed by group' do
    page = render_collection(mode: :agenda, group_by: :team, group_label: ->(team) { "Time #{team}" })

    expect(page.css('[data-role="collection-group"] h3').map(&:text)).to eq(['Time Várzea FC', 'Time Vila'])
  end

  describe 'master_detail mode' do
    it 'links each item to ?item=ID and shows the selected one, with a way back on phones' do
      with_request_url('/pools') do
        @page = render_collection(mode: :master_detail, selected: 2) do |c|
          c.detail { |item| "Detalhe de #{item.name}" }
        end
      end

      links = @page.css('[data-role="collection-item"] a')
      expect(links.map { _1['href'] }).to eq(['/pools?item=1', '/pools?item=2'])
      expect(links.last['aria-current']).to eq('true')
      expect(@page.at_css('[data-role="collection-detail"]').text).to include('Detalhe de Bruno', 'Voltar para a lista')
    end

    it 'asks to pick an item when none is selected' do
      page = render_collection(mode: :master_detail) { |c| c.detail(&:name) }

      expect(page.at_css('[data-role="collection-detail"]').text).to include('Escolha um item na lista.')
    end
  end

  it 'renders the bulk bar tied to the row checkboxes' do
    page = render_collection(selectable: true) do |c|
      c.bulk_action('Excluir', url: '/times/bulk', method: :delete, confirm: 'Excluir os selecionados?', danger: true)
    end

    expect(page.css('input[name="ids[]"]').map { _1['form'] }).to all(eq('people-bulk'))
    button = page.at_css('form#people-bulk button')
    expect(%w[formaction name value data-collection-confirm-param].map { button[_1] })
      .to eq(['/times/bulk', '_method', 'delete', 'Excluir os selecionados?'])
  end

  it 'renders the custom empty content when there are no items' do
    page = render_inline(described_class.new(items: [])) { |c| c.empty { 'Cadastre o primeiro time.' } }

    expect(page.at_css('section')['data-ui-state']).to eq('empty')
    expect(page.text).to include('Cadastre o primeiro time.')
  end
end
