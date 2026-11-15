module StateNoticeHelper
  ERROR_NOTICE_CLASSES = 'rounded-md border-l-4 border-ink bg-loss p-4 text-ink'.freeze

  def empty_notice(message, **)
    tag.p(message, class: 'rounded-md border border-dashed border-rule px-4 py-8 text-center text-graphite', **)
  end

  def error_classes(layout = 'flex flex-wrap items-center gap-3')
    "#{layout} #{ERROR_NOTICE_CLASSES}"
  end
end
