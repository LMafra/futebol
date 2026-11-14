module Ui
  # Every listing of the app (docs/ux/listagens.md): Admin, Gestor and public pages pick a mode, declare the
  # columns once and get the same behavior.
  #
  #   render Ui::CollectionComponent.new(items: teams, id: 'teams', views: { grid: 'Grade', table: 'Tabela' },
  #                                      view: params[:view], sort: params[:sort], direction: params[:dir]) do |c|
  #     c.column(:name, label: 'Nome', primary: true, sortable: true) { |team| link_to team, team_path(team) }
  #     c.column(:players_count, label: 'Jogadores', numeric: true)
  #     c.empty { render Ui::EmptyStateComponent.new(...) }
  #   end
  #
  # Modes: table (stacked cards below 768px: the primary column is the card title, the others label/value pairs),
  # cards, grid, grouped (accordion by group_by:), agenda (headed by day), master_detail (?detail_param=ID, a
  # list then the item on phones) and timeline. The caller sorts the items; the component only links ?sort=&dir=.
  class CollectionComponent < BaseComponent
    MODES = %i[table cards grid grouped agenda master_detail timeline].freeze
    OPTIONS = %i[mode views view sort direction selectable group_by group_label open_group detail_param selected
                 texts item_id].freeze
    TEXTS = { label: 'Lista', empty: 'Nada por aqui ainda.', selected: 'Selecionados:',
              select_all: 'Selecionar todos', select_item: 'Selecionar', pick_detail: 'Escolha um item na lista.',
              back: 'Voltar para a lista', sort: 'Ordenar por' }.freeze
    COLUMN_FLAGS = { primary: false, mobile_label: nil, sortable: false, numeric: false, media: false }.freeze
    Column = Data.define(:key, :label, :primary, :mobile_label, :sortable, :numeric, :media, :block)
    BulkAction = Data.define(:label, :url, :http_method, :confirm, :danger)

    attr_reader :items, :id, :columns, :bulk_actions

    def initialize(items: [], id: 'collection', state: :default, **options)
      super(state:)
      unknown = options.keys - OPTIONS
      raise ArgumentError, "unknown options: #{unknown.join(', ')}" if unknown.any?

      @items = items.to_a
      @id = id
      @options = options
      @columns = []
      @bulk_actions = []
    end

    # flags: primary:, mobile_label:, sortable:, numeric:, media: (the image of cards and grid tiles).
    def column(key, label:, **flags, &block)
      unknown = flags.keys - COLUMN_FLAGS.keys
      raise ArgumentError, "unknown column flags: #{unknown.join(', ')}" if unknown.any?

      flags = COLUMN_FLAGS.merge(flags)
      flags[:mobile_label] ||= label
      @columns << Column.new(key:, label:, block:, **flags)
      nil
    end

    def card(&block) = (@card = block) && nil
    def detail(&block) = (@detail = block) && nil
    def empty(&block) = (@empty = block) && nil
    # Fields the bulk actions share (a target team, a reason), inside the selection bar's form.
    def bulk_fields(&block) = (@bulk_fields = block) && nil

    def bulk_action(label, url:, method: :post, confirm: nil, danger: false)
      @bulk_actions << BulkAction.new(label:, url:, http_method: method, confirm:, danger:)
      nil
    end

    def before_render = content

    def text(key) = @options.fetch(:texts, {}).fetch(key) { TEXTS.fetch(key) }

    def views = @options.fetch(:views, {})

    def mode
      @mode ||= begin
        requested = @options[:view].presence&.to_sym
        chosen = views.key?(requested) ? requested : (views.keys.first || @options.fetch(:mode, :table))
        MODES.include?(chosen) ? chosen : raise(ArgumentError, "invalid mode #{chosen.inspect}")
      end
    end

    def primary_column = columns.find(&:primary) || columns.reject(&:media).first
    def media_column = columns.find(&:media)
    def detail_columns = columns - [primary_column, media_column]
    def selectable? = @options.fetch(:selectable, false)
    def bulk_bar? = selectable? && bulk_actions.any?
    def mobile_sort? = mode == :table && columns.any?(&:sortable)
    def custom_card? = @card.present?
    def empty_content = @empty && helpers.capture(&@empty)
    def bulk_fields_content = @bulk_fields && helpers.capture(&@bulk_fields)

    # capture drops a block's non-String value (a count), so it goes through to_s.
    def cell(column, item)
      return helpers.capture(item) { |record| column.block.call(record).to_s } if column.block

      item.public_send(column.key)
    end

    def card_body(item) = helpers.capture(item, &@card)
    def detail_body(item) = helpers.capture(item, &@detail)

    def item_id(item) = @options.fetch(:item_id, :id.to_proc).call(item)
    def item_dom_id(item) = "#{id}-item-#{item_id(item)}"

    def groups
      grouper = @options.fetch(:group_by) { raise ArgumentError, "group_by: is required in #{mode} mode" }
      items.group_by(&grouper)
    end

    def group_label(key) = (@options[:group_label] || :to_s.to_proc).call(key)

    def group_open?(key)
      open = @options[:open_group]
      open.respond_to?(:call) ? open.call(key) : open == key
    end

    def selected_item
      return if @options[:selected].blank?

      items.find { |item| item_id(item).to_s == @options[:selected].to_s }
    end

    def detail_url(item) = url_with(detail_param => item_id(item))
    def list_url = url_with(detail_param => nil)
    def view_url(view) = url_with(view: view)

    def sort_url(column)
      direction = current_sort?(column) && @options[:direction].to_s != 'desc' ? 'desc' : 'asc'
      url_with(sort: column.key, dir: direction)
    end

    def current_sort?(column) = @options[:sort].to_s == column.key.to_s

    def aria_sort(column)
      return unless current_sort?(column)

      @options[:direction].to_s == 'desc' ? 'descending' : 'ascending'
    end

    def sort_arrow(column)
      { 'ascending' => ' ↑', 'descending' => ' ↓' }.fetch(aria_sort(column).to_s, '')
    end

    def row_classes(index) = index.even? ? 'bg-paper' : 'bg-white'

    private

    def detail_param = @options.fetch(:detail_param, 'item')

    def url_with(changes)
      query = helpers.request.query_parameters.merge(changes.transform_keys(&:to_s)).compact_blank
      query.empty? ? helpers.request.path : "#{helpers.request.path}?#{query.to_query}"
    end

    def rendered_state = default? && items.empty? ? :empty : state
  end
end
