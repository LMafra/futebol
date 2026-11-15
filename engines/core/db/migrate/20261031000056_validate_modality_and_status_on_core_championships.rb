class ValidateModalityAndStatusOnCoreChampionships < ActiveRecord::Migration[8.1]
  def change
    %w[kind gender category level status].each do |column|
      validate_check_constraint :core_championships, name: "core_championships_#{column}_valid"
    end
  end
end
