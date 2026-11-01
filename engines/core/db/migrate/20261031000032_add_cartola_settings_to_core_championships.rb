class AddCartolaSettingsToCoreChampionships < ActiveRecord::Migration[8.1]
  LIMITS = %i[cartola_goalkeeper_limit cartola_defender_limit cartola_midfielder_limit cartola_forward_limit].freeze

  def change
    { cartola_goalkeeper_limit: 1, cartola_defender_limit: 2, cartola_midfielder_limit: 3,
      cartola_forward_limit: 3 }.each do |column, default|
      add_column :core_championships, column, :integer, null: false, default:
    end
    add_column :core_championships, :cartola_initial_budget, :decimal, precision: 10, scale: 2, null: false,
                                                                       default: 100
    add_column :core_championships, :cartola_base_player_value, :decimal, precision: 6, scale: 2, null: false,
                                                                          default: 5

    # A handful of championships, all with the column defaults: validating inline locks nothing for long.
    safety_assured do
      add_check_constraint :core_championships, LIMITS.map { |column| "#{column} >= 0" }.join(' AND '),
                           name: 'core_championships_cartola_limits_non_negative'
      add_check_constraint :core_championships,
                           'cartola_defender_limit + cartola_midfielder_limit + cartola_forward_limit > 0',
                           name: 'core_championships_cartola_line_limits_positive'
      add_check_constraint :core_championships, 'cartola_initial_budget >= 0 AND cartola_base_player_value >= 0',
                           name: 'core_championships_cartola_money_non_negative'
    end
  end
end
