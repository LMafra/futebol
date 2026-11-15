module Ui
  # @label Form section
  class FormSectionComponentPreview < ViewComponent::Preview
    def default
      render FormSectionComponent.new(title: 'Dados') do |section|
        section.with_body { tag.p('Nome e temporada do campeonato.', class: 'text-sm text-graphite') }
      end
    end

    def loading
      render FormSectionComponent.new(state: :loading)
    end

    def empty
      render FormSectionComponent.new(state: :empty)
    end

    def error
      render FormSectionComponent.new(state: :error)
    end
  end
end
