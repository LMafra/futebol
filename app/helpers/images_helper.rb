# Team crests and championship logos (Active Storage). Variants need libvips, which the Docker image has; without
# it (and for SVG, which is not variable) the original is served and scaled by CSS.
module ImagesHelper
  CREST_FALLBACK_CLASSES = 'inline-flex shrink-0 items-center justify-center rounded-sm border border-rule ' \
                           'text-xs font-bold tracking-wide'.freeze

  def self.variants? = defined?(@variants) ? @variants : (@variants = vips_loaded?)

  def self.vips_loaded?
    require 'vips'
    true
  rescue LoadError
    false
  end

  def team_crest(team, variant: :thumb, size: 'size-8')
    if team.crest.attached?
      image_tag(image_source(team.crest, variant), alt: team.name, class: "#{size} shrink-0 object-contain")
    else
      tag.span(team.short_name, class: "#{size} #{CREST_FALLBACK_CLASSES}")
    end
  end

  def championship_logo(championship, variant: :thumb, size: 'size-12')
    return unless championship.logo.attached?

    image_tag(image_source(championship.logo, variant), alt: "Logo de #{championship.name}",
                                                        class: "#{size} shrink-0 object-contain")
  end

  def image_source(attachment, variant)
    attachment.variable? && ImagesHelper.variants? ? attachment.variant(variant) : attachment
  end
end
