module AdminLabelsHelper
  REQUIRED_MARKER = ' <span class="font-normal text-graphite">(obrigatório)</span>'.freeze

  def admin_required_label(text) = safe_join([text, REQUIRED_MARKER.html_safe])

  def admin_match_status_label(status) = Ui::StatusBadgeComponent::LABELS.fetch(status.to_s.to_sym, status.to_s)

  def admin_match_status_options = Core::Match::STATUSES.map { [admin_match_status_label(_1), _1] }

  def admin_csv_import_status_label(status) = Ui::CsvImportStatusComponent::STATUS_LABELS.fetch(status, status)

  def admin_csv_import_status_options = Core::CsvImport::STATUSES.map { [admin_csv_import_status_label(_1), _1] }

  def admin_user_enum_label(enum, value) = I18n.t("activerecord.enums.core/user.#{enum}.#{value}")

  def admin_user_enum_options(enum)
    Core::User.public_send(enum.to_s.pluralize).keys.map { [admin_user_enum_label(enum, _1), _1] }
  end

  def admin_round_options = (1..38).to_a

  def admin_season_options = Core::Championship.distinct.order(season: :desc).pluck(:season)

  def admin_audit_log_options(attribute) = Core::AuditLog.distinct.order(attribute).pluck(attribute)
end
