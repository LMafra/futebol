class TransferBolaoPoolsToManagers < ActiveRecord::Migration[8.1]
  def up = Bolao::PoolOwnershipTransfer.new(connection).up
  def down = Bolao::PoolOwnershipTransfer.new(connection).down
end
