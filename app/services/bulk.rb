# Bulk actions of the Admin and Gestor listings. Each record goes through its own validations, callbacks and
# AuditLog, so the same queries repeat per record on purpose: the N+1 detector (development and test) is paused.
module Bulk
  def self.one_by_one(&) = defined?(Prosopite) ? Prosopite.pause(&) : yield
end
