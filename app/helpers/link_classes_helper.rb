# Text links (docs/ux/links-e-botoes.md): always underlined at rest, never color or hover alone.
# Links that look like buttons (CTAs) use ButtonClassesHelper / AdminHelper instead.
module LinkClassesHelper
  LINK_BASE_CLASSES = 'underline underline-offset-2'.freeze
  INLINE_LINK_TONES = { pitch: 'text-pitch', ink: 'text-ink' }.freeze

  # A link inside a sentence or a card: bold, the tone's color, underline that drops on hover.
  def inline_link_classes(*extra, tone: :pitch)
    [LINK_BASE_CLASSES, 'font-semibold hover:no-underline', INLINE_LINK_TONES.fetch(tone), *extra].join(' ')
  end

  # A card or row title that is a link: keeps the heading's font and color, adds the underline.
  def title_link_classes(*extra)
    [LINK_BASE_CLASSES, 'decoration-2 hover:no-underline', *extra].join(' ')
  end

  # Secondary navigation (back, cancel, "forgot your password?"): quieter, darkens on hover.
  def support_link_classes(*extra)
    [LINK_BASE_CLASSES, 'text-graphite hover:text-ink', *extra].join(' ')
  end
end
