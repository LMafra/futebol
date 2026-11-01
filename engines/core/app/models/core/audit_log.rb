module Core
  class AuditLog < ApplicationRecord
    belongs_to :user, class_name: 'Core::User', optional: true
    belongs_to :auditable, polymorphic: true, optional: true

    validates :action, presence: true
    validates :ip_address, presence: true
  end
end
