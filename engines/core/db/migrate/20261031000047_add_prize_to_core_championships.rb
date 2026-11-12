class AddPrizeToCoreChampionships < ActiveRecord::Migration[8.1]
  def change
    add_column :core_championships, :prize_description, :text
    add_column :core_championships, :prize_rules, :jsonb, default: {}, null: false
  end
end
