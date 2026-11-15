# Builds removable filter chips from ActiveAdmin/Ransack query params (URL-backed).
module AdminFilterChipsHelper
  CHIP_LABELS = {
    'championship_id_eq' => 'Campeonato',
    'round_eq' => 'Rodada',
    'status_eq' => 'Situação',
    'match_date_gteq' => 'A partir de',
    'match_date_lteq' => 'Até',
    'name_cont' => 'Busca'
  }.freeze

  def admin_filter_chips(clear_path: request.path)
    q = params[:q]
    return [] unless q.respond_to?(:to_unsafe_h)

    q.to_unsafe_h.filter_map do |key, value|
      next if value.blank?

      remaining = q.to_unsafe_h.except(key)
      remove_path = remaining.present? ? url_for(q: remaining) : clear_path
      { label: chip_label(key, value), remove_path: remove_path }
    end
  end

  def admin_match_saved_views(namespace:)
    base = public_send(:"#{namespace}_matches_path")
    current = params[:scope].presence || 'pendencias'
    [
      { key: 'pendencias', label: 'Minhas Pendências', path: "#{base}?scope=pendencias", current: current == 'pendencias' },
      { key: 'rodada_atual', label: 'Rodada Atual', path: "#{base}?scope=rodada_atual", current: current == 'rodada_atual' },
      { key: 'all', label: 'Todas as Partidas', path: "#{base}?scope=all", current: current == 'all' }
    ]
  end

  private

  def chip_label(key, value)
    prefix = CHIP_LABELS[key.to_s] || key.to_s.humanize
    display = key.to_s == 'status_eq' ? admin_match_status_label(value) : value
    "#{prefix}: #{display}"
  end
end
