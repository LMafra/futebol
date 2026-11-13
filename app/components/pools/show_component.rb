module Pools
  class ShowComponent < Ui::BaseComponent
    attr_reader :pool, :memberships

    def initialize(pool: nil, memberships: [], can_destroy: false, state: :default)
      super(state:)
      @pool = pool
      @memberships = memberships
      @can_destroy = can_destroy
      require_in_default_state!(:pool, pool)
    end

    private

    def can_destroy? = @can_destroy && pool.present?

    def organizer_label = pool.owner&.name.presence || 'o gestor do campeonato'

    def member_label(membership) = membership.user.name.presence || membership.user.email_address

    def joined_on(membership) = I18n.l(membership.joined_at.to_date, format: '%d/%m/%Y')
  end
end
