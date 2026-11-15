module FormControlHelper
  FORM_CONTROL_CLASSES = 'min-h-12 rounded-sm bg-white px-3 py-2 text-ink placeholder:text-graphite ' \
                         'focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-pitch ' \
                         'disabled:cursor-not-allowed disabled:bg-rule disabled:text-graphite'.freeze

  # Public inputs: white field, graphite border (3:1 on paper), pitch focus ring, 48px tall.
  def form_control_classes(*extra, invalid: false)
    border = invalid ? 'border-2 border-ink' : 'border border-graphite'
    [FORM_CONTROL_CLASSES, border, *extra].join(' ')
  end
end
