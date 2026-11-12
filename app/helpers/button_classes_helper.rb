module ButtonClassesHelper
  BUTTON_BASE_CLASSES = 'inline-flex min-h-12 cursor-pointer items-center justify-center gap-2 rounded-sm ' \
                        'text-center font-bold transition-colors duration-fast ease-editorial ' \
                        'disabled:pointer-events-none disabled:opacity-60'.freeze
  BUTTON_SIZE_CLASSES = { sm: 'px-3 py-2 text-sm', md: 'px-4 py-2', lg: 'px-4 py-3 text-lg' }.freeze
  BUTTON_ROLE_CLASSES = {
    primary: 'bg-cartola text-ink hover:bg-ink hover:text-white',
    secondary: 'border border-graphite bg-white text-ink hover:border-ink hover:bg-rule',
    danger: 'bg-loss-solid text-white hover:bg-ink'
  }.freeze

  BUTTON_ROLE_CLASSES.each_key do |role|
    define_method(:"#{role}_button_classes") do |*extra, size: :md|
      [BUTTON_BASE_CLASSES, BUTTON_SIZE_CLASSES.fetch(size), BUTTON_ROLE_CLASSES[role], *extra].join(' ')
    end
  end

  # Section links styled as tabs: the current one is marked with aria-current, not role=tab.
  def tab_link_classes(current)
    state = current ? 'border-cartola bg-cartola' : 'border-graphite bg-white hover:border-ink hover:bg-rule'
    "inline-flex min-h-12 items-center rounded-sm border px-3 py-2 font-semibold text-ink #{state}"
  end
end
