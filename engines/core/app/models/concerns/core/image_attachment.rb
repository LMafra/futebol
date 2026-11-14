module Core
  # Crest and logo uploads (ADR 0006): PNG, JPEG, WebP or SVG up to 2 MB, with thumb and medium variants, and a
  # remove_<name> flag for the "Remover" checkbox of the forms.
  module ImageAttachment
    extend ActiveSupport::Concern

    CONTENT_TYPES = %w[image/png image/jpeg image/webp image/svg+xml].freeze
    MAX_SIZE = 2.megabytes
    VARIANTS = { thumb: [64, 64], medium: [256, 256] }.freeze

    class_methods do
      def image_attachment(name)
        has_one_attached(name) do |attachable|
          VARIANTS.each { |variant, size| attachable.variant(variant, resize_to_limit: size) }
        end
        attribute :"remove_#{name}", :boolean, default: false
        validate { validate_image(name) }
        after_save { public_send(name).purge_later if public_send(:"remove_#{name}") && !attachment_changes[name.to_s] }
      end
    end

    private

    def validate_image(name)
      attachment = public_send(name)
      return unless attachment_changes[name.to_s] && attachment.attached?

      errors.add(name, 'deve ser PNG, JPEG, WebP ou SVG') unless CONTENT_TYPES.include?(attachment.blob.content_type)
      errors.add(name, 'deve ter até 2 MB') if attachment.blob.byte_size > MAX_SIZE
    end
  end
end
