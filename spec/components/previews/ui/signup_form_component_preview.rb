module Ui
  # @label Signup form
  class SignupFormComponentPreview < ViewComponent::Preview
    def default
      render SignupFormComponent.new(user: Core::User.new)
    end

    def loading
      render SignupFormComponent.new(state: :loading)
    end

    def empty
      render SignupFormComponent.new(state: :empty)
    end

    def error
      user = Core::User.new(name: 'Torcedor', email_address: 'torcedor@exemplo')
      user.errors.add(:email_address, 'não é um e-mail válido')
      user.errors.add(:password, 'deve ter pelo menos 8 caracteres')
      render SignupFormComponent.new(user:, state: :error)
    end
  end
end
