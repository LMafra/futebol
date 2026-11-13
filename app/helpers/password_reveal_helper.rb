module PasswordRevealHelper
  EYE_PATH = 'M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12Z M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z'.freeze
  EYE_OFF_PATH = 'M3 3l18 18 M10.6 5.1A10 10 0 0 1 12 5c6.4 0 10 7 10 7a17 17 0 0 1-3.2 4.1 ' \
                 'M6.6 6.6A17 17 0 0 0 2 12s3.6 7 10 7a9.7 9.7 0 0 0 5.4-1.6 M9.9 9.9a3 3 0 0 0 4.2 4.2'.freeze
  # The input inside the block needs the `pr-12` padding so the text never runs under the 48px button.
  PASSWORD_INPUT_PADDING = 'pr-12'.freeze

  # Wraps a password field with a "Mostrar senha" toggle. The button stays hidden until Stimulus connects,
  # so without JavaScript the field is a plain password field.
  def password_reveal(&)
    tag.div(class: 'relative mt-1', data: { controller: 'password-reveal' }) do
      safe_join([capture(&), password_reveal_button])
    end
  end

  private

  def password_reveal_button
    tag.button(type: 'button', hidden: true, title: 'Mostrar senha',
               class: 'group absolute top-0 right-0 inline-flex size-12 cursor-pointer items-center justify-center ' \
                      'rounded-sm text-graphite hover:text-ink',
               aria: { label: 'Mostrar senha', pressed: 'false' },
               data: { password_reveal_target: 'button', action: 'password-reveal#toggle' }) do
      safe_join([password_reveal_icon(EYE_PATH, 'group-aria-pressed:hidden'),
                 password_reveal_icon(EYE_OFF_PATH, 'hidden group-aria-pressed:block')])
    end
  end

  def password_reveal_icon(path, visibility)
    tag.svg(class: "size-6 #{visibility}", viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor',
            'stroke-width': 2, 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'aria-hidden': true) do
      tag.path(d: path)
    end
  end
end
