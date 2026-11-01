class CreateCartolaScoringRules < ActiveRecord::Migration[8.1]
  POINT_COLUMNS = %i[goal_points assist_points yellow_card_penalty red_card_penalty].freeze

  def change
    create_table :cartola_scoring_rules do |t|
      t.string :name, null: false
      POINT_COLUMNS.each { |column| t.decimal column, precision: 5, scale: 2, null: false }

      t.timestamps
    end
    add_index :cartola_scoring_rules, :name, unique: true

    POINT_COLUMNS.each do |column|
      add_check_constraint :cartola_scoring_rules, "#{column} >= 0",
                           name: "cartola_scoring_rules_#{column}_non_negative"
    end
  end
end
