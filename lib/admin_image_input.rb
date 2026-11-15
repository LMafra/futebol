# File input for a crest or logo in the ActiveAdmin forms: accepted types, the current image in the hint, a preview
# of the chosen file (image_preview_controller.js) and a "Remover" checkbox while one is attached.
module AdminImageInput
  HINT = 'PNG, JPEG, WebP ou SVG, até 2 MB.'.freeze

  def self.render(form, name, label:)
    attachment = form.object.public_send(name)
    form.input name, as: :file, label:, hint: hint(form.template, attachment, label),
                     input_html: { accept: Core::ImageAttachment::CONTENT_TYPES.join(','),
                                   data: { controller: 'image-preview', action: 'image-preview#show',
                                           image_preview_max_bytes_value: Core::ImageAttachment::MAX_SIZE } }
    form.input :"remove_#{name}", as: :boolean, label: "Remover #{label.downcase}" if attachment.attached?
  end

  def self.hint(template, attachment, label)
    return HINT unless attachment.attached? && attachment.blob.persisted?

    current = template.image_tag(template.image_source(attachment, :thumb), alt: "#{label} atual",
                                                                            class: 'size-16 object-contain')
    template.safe_join([current, " Atual. Para trocar, escolha outro arquivo. #{HINT}"])
  end
end
