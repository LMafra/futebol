module AdminHelper
  def scoring_path(page, **params) = public_send("#{active_admin_namespace.name}_#{page}_path", **params)

  def scoring_url(page, **params) = public_send("#{active_admin_namespace.name}_#{page}_url", **params)

  def scoring_match_path(match) = public_send("#{active_admin_namespace.name}_match_path", match)

  def scoring_admin_namespace? = active_admin_namespace.name.to_sym == :admin
  ADMIN_LABEL_CLASSES = 'mb-1 block text-sm font-medium text-gray-900 dark:text-white'.freeze
  ADMIN_INPUT_CLASSES = 'block w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 ' \
                        'tabular-nums focus:border-blue-600 focus:ring-blue-600 dark:border-gray-600 ' \
                        'dark:bg-gray-800 dark:text-white'.freeze
  ADMIN_BUTTON_CLASSES = 'action-item-button cursor-pointer'.freeze
  ADMIN_DANGER_BUTTON_CLASSES = 'inline-flex cursor-pointer items-center rounded-md bg-red-700 px-3 py-2 ' \
                                'text-sm font-semibold text-white hover:bg-red-800 focus:outline-none ' \
                                'focus:ring-4 focus:ring-red-300'.freeze

  def admin_score(match)
    [match.home_score, match.away_score].map { |goals| goals.nil? ? '–' : goals }.join(' × ')
  end

  def admin_match_option(match)
    "#{match.match_date&.strftime('%d/%m %H:%M')} · #{match} · #{match.status} · #{admin_score(match)}"
  end

  def admin_auditable_link(log)
    return unless log.auditable_type

    label = "#{log.auditable_type} ##{log.auditable_id}"
    log.auditable_type == 'Core::Match' ? link_to(label, admin_match_path(log.auditable_id)) : label
  end
end
