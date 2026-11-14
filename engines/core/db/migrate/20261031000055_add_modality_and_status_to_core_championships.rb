class AddModalityAndStatusToCoreChampionships < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  # Existing championships are 11-a-side men's adult amateur ones, already public.
  COLUMNS = {
    kind: { default: 'campo', values: %w[campo society futsal futevolei] },
    gender: { default: 'masculino', values: %w[masculino feminino misto] },
    category: { default: 'adulto', values: %w[infantil base adulto master] },
    level: { default: 'amador', values: %w[amador profissional] },
    status: { default: 'published', values: %w[draft published] }
  }.freeze

  def change
    COLUMNS.each do |column, options|
      add_column :core_championships, column, :string, null: false, default: options[:default]
      add_check_constraint :core_championships, "#{column} IN (#{options[:values].map { "'#{_1}'" }.join(', ')})",
                           name: "core_championships_#{column}_valid", validate: false
    end
    add_index :core_championships, :status, algorithm: :concurrently
  end
end
