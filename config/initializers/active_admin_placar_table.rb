# Adds Placar thead classes to every ActiveAdmin TableFor (index + table_for).
Rails.application.config.to_prepare do
  next unless defined?(ActiveAdmin::Views::TableFor)

  ActiveAdmin::Views::TableFor.class_eval do
    def build_table_head
      @thead = thead(class: 'bg-pitch text-paper') do
        @header_row = tr
      end
    end
  end
end
