class CreateCartolaSquads < ActiveRecord::Migration[8.1]
  def change
    create_table :cartola_squads do |t|
      t.references :user, null: false, foreign_key: { to_table: :core_users }
      t.string :name, null: false

      t.timestamps
    end
  end
end
