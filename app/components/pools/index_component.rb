module Pools
  class IndexComponent < Ui::BaseComponent
    attr_reader :pools, :error

    def initialize(pools: nil, error: nil, state: :default)
      super(state:)
      @pools = pools
      @error = error
      require_in_default_state!(:pools, pools)
    end

    private

    def error_message = error.presence || 'Não foi possível carregar seus bolões.'

    def listed_pools = Array(pools)
  end
end
