module RoundNavHelper
  ROUND_ARROW_PATHS = { previous: 'm15 18-6-6 6-6', next: 'm9 18 6-6-6-6' }.freeze

  def round_nav_link(round, path, direction:)
    arrow = round_arrow_svg(direction)
    label = tag.span("Rodada #{round}")
    link_to path, class: secondary_button_classes(size: :sm), rel: (direction == :previous ? 'prev' : 'next'),
                  data: { role: "round-#{direction}" } do
      direction == :previous ? arrow + label : label + arrow
    end
  end

  private

  def round_arrow_svg(direction)
    tag.svg(tag.path(d: ROUND_ARROW_PATHS.fetch(direction)),
            xmlns: 'http://www.w3.org/2000/svg', width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none',
            stroke: 'currentColor', 'stroke-width': 2, 'stroke-linecap': 'round', 'stroke-linejoin': 'round',
            aria: { hidden: true })
  end
end
