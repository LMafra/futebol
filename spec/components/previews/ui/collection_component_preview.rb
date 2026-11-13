module Ui
  # @label Collection
  class CollectionComponentPreview < ViewComponent::Preview
    Item = Struct.new(:id, :name, :team, :points, :round, keyword_init: true)

    # @param mode select { choices: [table, cards, grid, grouped, agenda, master_detail, timeline] }
    # @param selectable toggle
    def default(mode: :table, selectable: false)
      render_with_template(locals: { items: sample_items, mode: mode.to_sym, selectable: })
    end

    def loading
      render CollectionComponent.new(state: :loading)
    end

    def empty
      render CollectionComponent.new(items: [], texts: { empty: 'Nenhum time cadastrado.' })
    end

    def error
      render CollectionComponent.new(state: :error)
    end

    private

    def sample_items
      [
        Item.new(id: 1, name: 'Ana Souza', team: 'Várzea FC', points: 42, round: 1),
        Item.new(id: 2, name: 'Bruno Lima', team: 'Unidos da Vila', points: 37, round: 1),
        Item.new(id: 3, name: 'Carla Dias', team: 'Várzea FC', points: 29, round: 2)
      ]
    end
  end
end
