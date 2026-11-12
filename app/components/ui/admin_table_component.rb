module Ui
  # Editorial data table for ActiveAdmin custom pages (Placar de Domingo).
  #   headers: [{ label:, numeric: false }, ...] or plain strings
  #   rows:    array of arrays of cell content (HTML-safe strings or numbers)
  class AdminTableComponent < BaseComponent
    TEXTS = { label: 'Tabela', empty: 'Nenhum registro.' }.freeze

    attr_reader :headers, :rows, :table_role

    def initialize(headers: [], rows: [], texts: {}, table_role: 'admin-table', state: :default)
      super(state:)
      @headers = normalize_headers(headers)
      @rows = rows
      @texts = TEXTS.merge(texts)
      @table_role = table_role
    end

    def text(key) = @texts.fetch(key)

    private

    def rendered_state = default? && rows.empty? ? :empty : state

    def normalize_headers(list)
      list.map do |header|
        case header
        when Hash then { label: header.fetch(:label), numeric: header.fetch(:numeric, false) }
        else { label: header, numeric: false }
        end
      end
    end
  end
end
