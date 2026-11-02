module Ui
  class SignupFormComponent < BaseComponent
    Field = Data.define(:attribute, :label, :input, :autocomplete)

    FIELDS = [
      Field.new(:name, 'Nome', :text_field, 'name'),
      Field.new(:email_address, 'E-mail', :email_field, 'username'),
      Field.new(:password, 'Senha', :password_field, 'new-password'),
      Field.new(:password_confirmation, 'Confirme a senha', :password_field, 'new-password')
    ].freeze

    attr_reader :user, :public_profile_consent

    def initialize(user: nil, public_profile_consent: false, state: :default)
      super(state:)
      @user = user
      @public_profile_consent = public_profile_consent
      require_in_default_state!(:user, user)
    end

    private

    def form? = user.present? && (default? || error?)

    def field_error(attribute) = user.errors[attribute].first

    def field_options(field)
      options = { required: true, autocomplete: field.autocomplete, class: input_classes(field.attribute) }
      options.merge!(minlength: 8, maxlength: 72) if field.input == :password_field
      return options unless field_error(field.attribute)

      options.merge(aria: { invalid: true, describedby: error_id(field.attribute) })
    end

    def error_id(attribute) = "signup-#{attribute}-error"

    def input_classes(attribute)
      border = field_error(attribute) ? 'border-2 border-ink' : 'border border-rule'
      "mt-1 block w-full rounded-sm #{border} bg-white px-3 py-2 focus:outline-2 focus:outline-pitch"
    end

    def button_classes
      'cursor-pointer rounded-sm bg-cartola px-4 py-2 font-bold text-ink transition-colors duration-fast ' \
        'ease-editorial hover:bg-pitch hover:text-white'
    end
  end
end
