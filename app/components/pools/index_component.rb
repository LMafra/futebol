module Pools
  class IndexComponent < Ui::BaseComponent
    PoolCard = Data.define(:pool, :position, :members_count, :show_code)

    attr_reader :pools, :error, :query, :pool_cards

    def initialize(pools: nil, error: nil, query: nil, pool_cards: nil, state: :default)
      super(state:)
      @pools = pools
      @error = error
      @query = query.to_s
      @pool_cards = pool_cards || default_cards
      require_in_default_state!(:pools, pools) unless empty? || error?
    end

    private

    def error_message = error.presence || 'Não foi possível carregar seus bolões.'

    def listed_cards = Array(pool_cards)

    def join_error? = error.present?

    def searching? = query.present?

    def empty_title
      return 'Nenhum bolão encontrado' if searching?

      'Você ainda não está em nenhum bolão'
    end

    def empty_description
      return 'Tente outro nome ou peça o código ao organizador.' if searching?

      'Peça o código ao organizador.'
    end

    def default_cards
      Array(pools).map { |pool| default_card(pool) }
    end

    def default_card(pool)
      PoolCard.new(pool:, position: nil, members_count: pool.memberships.size, show_code: false)
    end
  end
end
