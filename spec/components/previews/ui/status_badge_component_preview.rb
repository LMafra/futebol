module Ui
  # @label Status badge
  class StatusBadgeComponentPreview < ViewComponent::Preview
    def default
      render StatusBadgeComponent.new(status: :live)
    end

    def loading
      render StatusBadgeComponent.new(status: :scheduled, state: :loading)
    end

    def empty
      render StatusBadgeComponent.new(status: :finished, state: :empty)
    end

    def error
      render StatusBadgeComponent.new(status: :reverted, state: :error)
    end
  end
end
