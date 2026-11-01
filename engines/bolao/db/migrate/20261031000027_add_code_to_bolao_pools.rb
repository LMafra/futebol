class AddCodeToBolaoPools < ActiveRecord::Migration[8.1]
  # Same alphabet as Bolao::Pool::CODE_ALPHABET; duplicated so the migration never depends on the model.
  ALPHABET = %w[A B C D E F G H J K L M N P Q R S T U V W X Y Z 2 3 4 5 6 7 8 9].freeze

  def up
    add_column :bolao_pools, :code, :string, limit: 6
    backfill_codes
    change_column_null :bolao_pools, :code, false
    add_index :bolao_pools, :code, unique: true
  end

  def down
    remove_column :bolao_pools, :code
  end

  private

  def backfill_codes
    taken = Set.new
    select_values('SELECT id FROM bolao_pools ORDER BY id').each do |id|
      code = loop do
        candidate = Array.new(6) { ALPHABET.sample }.join
        break candidate if taken.add?(candidate)
      end
      execute("UPDATE bolao_pools SET code = #{quote(code)} WHERE id = #{Integer(id)}")
    end
  end
end
