module Bolao
  class PoolMembership < ApplicationRecord
    belongs_to :pool, class_name: 'Bolao::Pool'
    belongs_to :user, class_name: 'Core::User'

    attribute :joined_at, default: -> { Time.current }

    validates :user_id, uniqueness: { scope: :pool_id, message: 'já participa deste bolão' }
  end
end
