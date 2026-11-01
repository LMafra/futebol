module Pools
  class NewComponent < Ui::BaseComponent
    attr_reader :pool, :championships

    def initialize(pool: nil, championships: [], state: :default)
      super(state:)
      @pool = pool
      @championships = championships
      require_in_default_state!(:pool, pool)
    end

    private

    def show_form? = pool.present? && (default? || error?)

    def error_messages
      messages = pool&.errors&.full_messages
      messages.presence || ['Não foi possível criar o bolão.']
    end

    def field_error(attribute) = pool.errors[attribute].first
  end
end
