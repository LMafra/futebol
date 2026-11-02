# Points for the new scouts (SG, DP, DE, GC) and for "Jogou" and "Destaque". They start at 0: the admin sets them.
class AddScoutColumnsToCartolaScoringRules < ActiveRecord::Migration[8.1]
  COLUMNS = %i[clean_sheet_points penalty_save_points save_points own_goal_penalty played_points
               highlight_points].freeze

  def change
    COLUMNS.each do |column|
      add_column :cartola_scoring_rules, column, :decimal, precision: 5, scale: 2, null: false, default: 0
    end

    # A single rule row in production: validating inline locks nothing for long.
    safety_assured do
      COLUMNS.each do |column|
        add_check_constraint :cartola_scoring_rules, "#{column} >= 0",
                             name: "cartola_scoring_rules_#{column}_non_negative"
      end
    end
  end
end
