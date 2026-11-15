module Ui
  # Banner at the top of a form listing how many fields need attention (never a toast).
  class FormErrorSummaryComponent < BaseComponent
    attr_reader :count, :messages, :title

    def initialize(count: nil, messages: [], title: nil, state: :default)
      super(state:)
      @messages = Array(messages)
      @count = count.nil? ? @messages.size : count
      @title = title || default_title
    end

    def render?
      return true unless default?

      count.to_i.positive? || messages.any?
    end

    private

    def default_title
      n = count.to_i
      return 'Corrija os campos destacados' if n <= 0

      "#{n} #{n == 1 ? 'campo precisa' : 'campos precisam'} de atenção"
    end
  end
end
