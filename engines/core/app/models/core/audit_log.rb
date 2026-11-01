module Core
  class AuditLog < ApplicationRecord
    belongs_to :user, class_name: 'Core::User', optional: true
    belongs_to :auditable, polymorphic: true, optional: true

    validates :action, presence: true
    validates :ip_address, presence: true

    def self.ransackable_attributes(_auth_object = nil) = %w[action user_id auditable_type created_at]
    def self.ransackable_associations(_auth_object = nil) = %w[user]

    def to_s = "#{action} ##{id}"
  end
end
